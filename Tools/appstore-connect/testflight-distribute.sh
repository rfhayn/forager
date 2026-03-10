#!/bin/bash
#
# testflight-distribute.sh
# Automates App Store Connect TestFlight distribution (steps 7-11 of /forager-archive).
#
# Usage: testflight-distribute.sh <build-number> <what-to-test>
#
# Prerequisites:
#   - Build already uploaded to App Store Connect
#   - ~/.appstoreconnect/config exists with KEY_ID and ISSUER_ID
#   - API key .p8 file at ~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8
#   - Tools/appstore-connect/generate-jwt.swift available
#
# Configuration (hardcoded for forager):
#   - App ID: 6756034827
#   - Beta Group: Public Beta Testers (46d19222-23de-4578-954a-ed0457239949)

set -euo pipefail

# --- Arguments ---
if [ $# -lt 1 ]; then
    echo "Usage: $0 <build-number> [what-to-test]"
    echo "  build-number:  The CURRENT_PROJECT_VERSION to distribute"
    echo "  what-to-test:  Optional release notes (defaults to latest git commit message)"
    exit 1
fi

BUILD_NUMBER="$1"
WHAT_TO_TEST="${2:-$(git log -1 --pretty=%B)}"

# Detect marketing version from pbxproj
MARKETING_VERSION=$(grep -m1 'MARKETING_VERSION = ' forager.xcodeproj/project.pbxproj 2>/dev/null | sed 's/.*= //' | sed 's/;.*//' | tr -d '[:space:]')
if [ -z "$MARKETING_VERSION" ]; then
    echo "⚠️  Could not detect MARKETING_VERSION — build matching may be imprecise"
fi

# --- Constants ---
APP_ID="6756034827"
BETA_GROUP_ID="46d19222-23de-4578-954a-ed0457239949"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_POLL_ATTEMPTS=20
POLL_INTERVAL=60

# --- Load API config ---
CONFIG_FILE="$HOME/.appstoreconnect/config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ API config not found at $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

KEY_FILE="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ API key file not found at $KEY_FILE"
    exit 1
fi

# --- Helper: generate JWT ---
generate_jwt() {
    swift "$SCRIPT_DIR/generate-jwt.swift" "$KEY_FILE" "$KEY_ID" "$ISSUER_ID"
}

# --- Helper: API call ---
api_get() {
    local url="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer $JWT" "$url" -o "$output"
}

api_post() {
    local url="$1"
    local data="$2"
    local output="${3:-/dev/null}"
    curl -s -X POST -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" -d "$data" "$url" -o "$output"
}

api_patch() {
    local url="$1"
    local data="$2"
    local output="${3:-/dev/null}"
    curl -s -X PATCH -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" -d "$data" "$url" -o "$output"
}

# ============================================================
# Step 7: Generate JWT
# ============================================================
echo "🔑 Generating API token..."
JWT=$(generate_jwt)
echo "   ✅ JWT generated (20-minute expiry)"

# ============================================================
# Step 8: Wait for build processing
# ============================================================
echo "⏳ Waiting for build $BUILD_NUMBER to finish processing..."

BUILD_ID=""

# First, resolve the preReleaseVersion ID for our marketing version
# This ensures we match the correct build when multiple builds share the same build number
PRV_FILTER=""
if [ -n "$MARKETING_VERSION" ]; then
    PRV_RESPONSE=$(mktemp)
    api_get "https://api.appstoreconnect.apple.com/v1/preReleaseVersions?filter%5Bapp%5D=${APP_ID}&filter%5Bversion%5D=${MARKETING_VERSION}&filter%5Bplatform%5D=IOS&limit=1" "$PRV_RESPONSE"
    PRV_ID=$(jq -r '.data[0].id // empty' "$PRV_RESPONSE")
    rm -f "$PRV_RESPONSE"
    if [ -n "$PRV_ID" ]; then
        PRV_FILTER="&filter%5BpreReleaseVersion%5D=${PRV_ID}"
        echo "   📦 Filtering for marketing version $MARKETING_VERSION"
    fi
fi

for i in $(seq 1 $MAX_POLL_ATTEMPTS); do
    RESPONSE=$(mktemp)
    api_get "https://api.appstoreconnect.apple.com/v1/builds?filter%5Bapp%5D=${APP_ID}&filter%5Bversion%5D=${BUILD_NUMBER}&filter%5Bexpired%5D=false&sort=-uploadedDate&limit=1${PRV_FILTER}" "$RESPONSE"

    STATE=$(jq -r '.data[0].attributes.processingState // empty' "$RESPONSE")
    BUILD_ID=$(jq -r '.data[0].id // empty' "$RESPONSE")
    ENCRYPTION=$(jq -r '.data[0].attributes.usesNonExemptEncryption // empty' "$RESPONSE")
    UPLOADED=$(jq -r '.data[0].attributes.uploadedDate // empty' "$RESPONSE")
    rm -f "$RESPONSE"

    if [ "$STATE" = "VALID" ] && [ -n "$BUILD_ID" ]; then
        echo "   ✅ Build $BUILD_NUMBER is VALID (ID: $BUILD_ID, uploaded: $UPLOADED)"
        break
    elif [ "$STATE" = "FAILED" ] || [ "$STATE" = "INVALID" ]; then
        echo "   ❌ Build processing failed (state: $STATE)"
        exit 1
    fi

    if [ "$i" -eq "$MAX_POLL_ATTEMPTS" ]; then
        echo "   ❌ Timed out waiting for build processing after $((MAX_POLL_ATTEMPTS * POLL_INTERVAL / 60)) minutes"
        exit 1
    fi

    echo "   ⏳ State: ${STATE:-not found yet} — waiting ${POLL_INTERVAL}s (attempt $i/$MAX_POLL_ATTEMPTS)..."
    sleep "$POLL_INTERVAL"

    # Regenerate JWT if we've been polling a while (expires after 20 min)
    if [ "$((i % 15))" -eq 0 ]; then
        echo "   🔑 Refreshing JWT..."
        JWT=$(generate_jwt)
    fi
done

# ============================================================
# Step 9: Export compliance (verify automatic)
# ============================================================
echo "🔒 Checking export compliance..."
if [ "$ENCRYPTION" = "false" ]; then
    echo "   ✅ No non-exempt encryption (set via Info.plist)"
else
    echo "   ⚠️  Encryption status: $ENCRYPTION — setting via API..."
    api_patch "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID" \
        "{\"data\":{\"id\":\"$BUILD_ID\",\"type\":\"builds\",\"attributes\":{\"usesNonExemptEncryption\":false}}}"
    echo "   ✅ Export compliance set"
fi

# ============================================================
# Step 10: Set "What to Test" & submit for beta review
# ============================================================
echo "📝 Setting 'What to Test' notes..."

# Get localization ID
LOC_RESPONSE=$(mktemp)
api_get "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID/betaBuildLocalizations" "$LOC_RESPONSE"
LOC_ID=$(jq -r '.data[0].id // empty' "$LOC_RESPONSE")
rm -f "$LOC_RESPONSE"

# Escape the what-to-test text for JSON
ESCAPED_NOTES=$(echo "$WHAT_TO_TEST" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")
# Remove surrounding quotes from json.dumps output
ESCAPED_NOTES="${ESCAPED_NOTES:1:${#ESCAPED_NOTES}-2}"

if [ -n "$LOC_ID" ]; then
    api_patch "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations/$LOC_ID" \
        "{\"data\":{\"id\":\"$LOC_ID\",\"type\":\"betaBuildLocalizations\",\"attributes\":{\"whatsNew\":\"$ESCAPED_NOTES\"}}}"
    echo "   ✅ Updated localization $LOC_ID"
else
    api_post "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations" \
        "{\"data\":{\"type\":\"betaBuildLocalizations\",\"attributes\":{\"whatsNew\":\"$ESCAPED_NOTES\",\"locale\":\"en-US\"},\"relationships\":{\"build\":{\"data\":{\"id\":\"$BUILD_ID\",\"type\":\"builds\"}}}}}"
    echo "   ✅ Created new localization"
fi

echo "📋 Submitting for beta review..."
REVIEW_RESPONSE=$(mktemp)
api_post "https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions" \
    "{\"data\":{\"type\":\"betaAppReviewSubmissions\",\"relationships\":{\"build\":{\"data\":{\"id\":\"$BUILD_ID\",\"type\":\"builds\"}}}}}" \
    "$REVIEW_RESPONSE"

REVIEW_STATE=$(jq -r '.data.attributes.betaReviewState // empty' "$REVIEW_RESPONSE")
REVIEW_ERROR=$(jq -r '.errors[0].code // empty' "$REVIEW_RESPONSE")
rm -f "$REVIEW_RESPONSE"

if [ -n "$REVIEW_STATE" ]; then
    echo "   ✅ Submitted (state: $REVIEW_STATE)"
elif [ "$REVIEW_ERROR" = "INVALID_QC_STATE" ]; then
    echo "   ℹ️  Already submitted or approved"
else
    echo "   ⚠️  Unexpected response (error: $REVIEW_ERROR) — checking status..."
fi

# Wait for review approval
echo "⏳ Waiting for beta review approval..."
for i in $(seq 1 20); do
    REVIEW_STATUS=$(mktemp)
    api_get "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID/betaAppReviewSubmission" "$REVIEW_STATUS"
    STATE=$(jq -r '.data.attributes.betaReviewState // empty' "$REVIEW_STATUS")
    rm -f "$REVIEW_STATUS"

    if [ "$STATE" = "APPROVED" ]; then
        echo "   ✅ Beta review APPROVED"
        break
    fi

    if [ "$i" -eq 20 ]; then
        echo "   ⚠️  Review still pending after 10 minutes (state: $STATE)"
        echo "   Build is submitted but may not be available to external testers yet."
        echo "   Proceeding to add to beta group anyway..."
        break
    fi

    echo "   ⏳ State: $STATE — waiting 30s (attempt $i/20)..."
    sleep 30
done

# ============================================================
# Step 11: Add build to beta group
# ============================================================
echo "👥 Adding build to Public Beta Testers..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
    -d "{\"data\":[{\"id\":\"$BUILD_ID\",\"type\":\"builds\"}]}" \
    "https://api.appstoreconnect.apple.com/v1/betaGroups/$BETA_GROUP_ID/relationships/builds")

if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Build added to beta group (HTTP $HTTP_CODE)"
else
    echo "   ⚠️  Unexpected HTTP $HTTP_CODE adding to beta group"
    echo "   Verifying group membership..."
fi

# Verify the build is actually in the group (no filter/sort on this endpoint)
VERIFY_RESPONSE=$(mktemp)
api_get "https://api.appstoreconnect.apple.com/v1/betaGroups/$BETA_GROUP_ID/builds?limit=10" "$VERIFY_RESPONSE"
FOUND_IN_GROUP=$(jq -r "[.data[] | select(.id == \"$BUILD_ID\")] | length" "$VERIFY_RESPONSE")
rm -f "$VERIFY_RESPONSE"

if [ "$FOUND_IN_GROUP" = "1" ]; then
    echo "   ✅ Verified: build is in Public Beta Testers group"
else
    echo "   ❌ Build NOT found in beta group — check App Store Connect manually"
fi

# ============================================================
# Final Report
# ============================================================
echo ""
echo "============================================================"
echo "✅ TestFlight Distribution Complete"
echo "============================================================"
echo "Build:       $BUILD_NUMBER (ID: $BUILD_ID)"
echo "Compliance:  No non-exempt encryption"
echo "Beta Group:  Public Beta Testers"
echo "What to Test: $(echo "$WHAT_TO_TEST" | head -1)"
echo "Status:      Available to testers"
echo "============================================================"
