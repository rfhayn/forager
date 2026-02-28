---
name: archive
description: Archive and distribute forager to TestFlight. Auto-increments build number, archives for Release, uploads to App Store Connect, waits for processing, sets export compliance, and adds to beta test group.
---

# Archive & Distribute to TestFlight

Full pipeline: version bump → archive → upload → wait for processing → export compliance → add to beta group.

## Current State

- Marketing version: !`grep -m1 'MARKETING_VERSION' forager.xcodeproj/project.pbxproj`
- Build number: !`grep -m1 'CURRENT_PROJECT_VERSION' forager.xcodeproj/project.pbxproj`
- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- API key configured: !`ls ~/.appstoreconnect/config`

## Prerequisites: App Store Connect API Key

The TestFlight automation steps (8-11) require an App Store Connect API key. Check if configured:

```bash
test -f ~/.appstoreconnect/config && cat ~/.appstoreconnect/config || echo "NOT CONFIGURED"
```

**If not configured**, guide the user through setup:

1. Go to **App Store Connect → Users and Access → Integrations → App Store Connect API**
2. Click **Generate API Key** (or use existing)
3. Role: **Developer** (minimum for TestFlight management)
4. Download the `.p8` file (can only download ONCE)
5. Note the **Key ID** and **Issuer ID** shown on the page

Then create the config:
```bash
mkdir -p ~/.appstoreconnect/private_keys

# User provides these values:
cat > ~/.appstoreconnect/config << 'EOF'
KEY_ID=XXXXXXXXXX
ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
EOF

# User places their .p8 file:
# cp ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
```

Verify the key works:
```bash
source ~/.appstoreconnect/config
JWT=$(swift Tools/appstore-connect/generate-jwt.swift \
  ~/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8 \
  "$KEY_ID" "$ISSUER_ID")
curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=com.richhayn.forager" | jq '.data[0].attributes.name'
```

If this returns `"forager"`, the API key is working. Proceed to Step 1.

**If API key is not set up and user wants to skip TestFlight automation**, run steps 1-7 only and report that steps 8-11 were skipped.

## Step 1: Pre-Flight Checks

Verify before archiving:
- [ ] On `main` branch (archives should be from main after PR merge)
- [ ] Working tree is clean (no uncommitted changes)
- [ ] Build succeeds in Release configuration

If not on main or there are uncommitted changes, warn the user and ask whether to proceed.

## Step 2: Auto-Increment Build Number

The build number (`CURRENT_PROJECT_VERSION`) auto-increments on every archive.

**Read current value** from `project.pbxproj` (the app target has two entries — Debug and Release):
```bash
# Extract current build number (app target only — first two occurrences)
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION = ' forager.xcodeproj/project.pbxproj | sed 's/[^0-9]//g')
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "Build number: $CURRENT_BUILD → $NEW_BUILD"
```

**Update both Debug and Release** configurations for the app target only:
```bash
# Replace the first two occurrences (app target Debug + Release)
# Test targets have CURRENT_PROJECT_VERSION = 1 — leave those alone
awk -v old="$CURRENT_BUILD" -v new="$NEW_BUILD" '
  /CURRENT_PROJECT_VERSION = / && count < 2 {
    sub("CURRENT_PROJECT_VERSION = " old, "CURRENT_PROJECT_VERSION = " new)
    count++
  }
  { print }
' forager.xcodeproj/project.pbxproj > /tmp/pbxproj_tmp && mv /tmp/pbxproj_tmp forager.xcodeproj/project.pbxproj
```

**Show result** and confirm with user:
```
Version: 1.2 (build 24)
```

## Step 3: Optional — Bump Marketing Version

Only if the user explicitly requests a version bump (e.g., `/archive --version 1.3`):

```bash
# $ARGUMENTS may contain: --version X.Y
# If present, update MARKETING_VERSION in the first two occurrences (app target only)
```

Marketing version format: `MAJOR.MINOR` (e.g., 1.2, 1.3, 2.0). Validate format before applying.

## Step 4: Commit Version Bump

Use the current milestone from `docs/current-story.md` for the commit prefix. If no active milestone, use a generic prefix.

```bash
git add forager.xcodeproj/project.pbxproj
git commit -m "Bump build number to $NEW_BUILD for TestFlight"
git push
```

## Step 5: Archive

```bash
xcodebuild archive \
  -project forager.xcodeproj \
  -scheme forager \
  -archivePath ~/Desktop/forager-$MARKETING_VERSION-$NEW_BUILD.xcarchive \
  -destination 'generic/platform=iOS' \
  2>&1 | tail -5
```

This uses Release configuration by default (CloudKit enabled).

On success, report:
- Archive path
- Version and build number
- Archive size

On failure:
- Show full error output
- Check signing issues first (most common)

## Step 6: Export & Upload to App Store Connect

```bash
# Create ExportOptions.plist
cat > /tmp/ForagerExportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>93FT2PT9NM</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath ~/Desktop/forager-$MARKETING_VERSION-$NEW_BUILD.xcarchive \
  -exportOptionsPlist /tmp/ForagerExportOptions.plist \
  -exportPath ~/Desktop/forager-export \
  -allowProvisioningUpdates \
  2>&1 | tail -10
```

The `destination: upload` auto-uploads to App Store Connect. If upload fails, fall back to:
```bash
xcrun notarytool submit ... # or Transporter.app / Xcode Organizer
```

## Step 7: Generate API Token

All remaining steps use the App Store Connect API. Generate a JWT:

```bash
source ~/.appstoreconnect/config
JWT=$(swift Tools/appstore-connect/generate-jwt.swift \
  ~/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8 \
  "$KEY_ID" "$ISSUER_ID")

# Get the app's App Store Connect numeric ID (cache this — it doesn't change)
APP_ID=$(curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=com.richhayn.forager" \
  | jq -r '.data[0].id')
echo "App Store Connect App ID: $APP_ID"
```

**Note**: The JWT expires after 20 minutes. If later steps take longer, regenerate it.

## Step 8: Wait for Build Processing

After upload, App Store Connect processes the build (typically 5-15 minutes). Poll until ready:

```bash
# Poll every 60 seconds, max 15 minutes
for i in $(seq 1 15); do
  RESULT=$(curl -s -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$APP_ID&filter[version]=$NEW_BUILD&sort=-uploadedDate&limit=1")

  STATE=$(echo "$RESULT" | jq -r '.data[0].attributes.processingState // "NOT_FOUND"')
  BUILD_ID=$(echo "$RESULT" | jq -r '.data[0].id // "null"')

  echo "[$i/15] Processing state: $STATE"

  if [ "$STATE" = "VALID" ]; then
    echo "Build $NEW_BUILD is ready! (Build ID: $BUILD_ID)"
    break
  elif [ "$STATE" = "FAILED" ] || [ "$STATE" = "INVALID" ]; then
    echo "ERROR: Build processing failed with state: $STATE"
    echo "Check App Store Connect for details."
    # Stop here — don't proceed to compliance/beta group
    break
  fi

  if [ "$i" -eq 15 ]; then
    echo "Timeout: build still processing after 15 minutes."
    echo "Check App Store Connect manually. You can re-run steps 9-11 later."
    break
  fi

  sleep 60
done
```

**If the build is not found** (STATE = NOT_FOUND), the upload may still be propagating. Wait 2 minutes and try again.

**If processing fails**, stop and report. Do not proceed to steps 9-11.

**Only proceed to Step 9 if STATE = VALID.**

## Step 9: Export Compliance (Automatic)

Export compliance is handled automatically via `ITSAppUsesNonExemptEncryption = NO` in `forager/App/Info.plist`. No API call needed — App Store Connect reads this from the binary during processing.

Verify it was picked up:
```bash
# Should show false (meaning: no non-exempt encryption, compliance auto-cleared)
curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID" \
  | jq '.data.attributes.usesNonExemptEncryption'
```

If it shows `null`, the build may still be finalizing. Wait 30 seconds and retry. If it stays null, fall back to the API:
```bash
curl -s -X PATCH \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"id\": \"$BUILD_ID\",
      \"type\": \"builds\",
      \"attributes\": {
        \"usesNonExemptEncryption\": false
      }
    }
  }" \
  "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID" | jq '.data.attributes.usesNonExemptEncryption'
echo "Export compliance: set via API fallback"
```

## Step 10: Add Build to Beta Test Group

Default group: **Public Beta Testers** (`46d19222-23de-4578-954a-ed0457239949`).

Override with `--group "Group Name"` argument (see Arguments section).

```bash
# Default to "Public Beta Testers" unless --group argument provided
GROUP_ID="46d19222-23de-4578-954a-ed0457239949"
GROUP_NAME="Public Beta Testers"

# If --group "Some Name" was passed, look up the group ID:
# curl -s -H "Authorization: Bearer $JWT" \
#   "https://api.appstoreconnect.apple.com/v1/betaGroups?filter%5Bapp%5D=6756034827" \
#   | jq -r '.data[] | select(.attributes.name == "REQUESTED_NAME") | .id'

curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": [
      {
        \"id\": \"$BUILD_ID\",
        \"type\": \"builds\"
      }
    ]
  }" \
  "https://api.appstoreconnect.apple.com/v1/betaGroups/$GROUP_ID/relationships/builds"

echo "Build $NEW_BUILD added to beta group: $GROUP_NAME"
```

## Step 11: Set "What to Test" & Submit for Beta Review

Set the "What to Test" notes from the latest git commit message, then submit for beta app review (required for external groups).

```bash
# Get latest commit message, escaped for JSON
WHATS_NEW=$(git log -1 --pretty=%B | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")

# Get (or create) the beta build localization for en-US
LOCALIZATION_ID=$(curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID/betaBuildLocalizations" \
  | jq -r '.data[] | select(.attributes.locale == "en-US") | .id')

if [ -n "$LOCALIZATION_ID" ]; then
  # Update existing localization
  curl -s -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "{
      \"data\": {
        \"id\": \"$LOCALIZATION_ID\",
        \"type\": \"betaBuildLocalizations\",
        \"attributes\": {
          \"whatsNew\": $WHATS_NEW
        }
      }
    }" \
    "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations/$LOCALIZATION_ID" > /dev/null
else
  # Create new localization
  curl -s -X POST \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "{
      \"data\": {
        \"type\": \"betaBuildLocalizations\",
        \"attributes\": {
          \"whatsNew\": $WHATS_NEW,
          \"locale\": \"en-US\"
        },
        \"relationships\": {
          \"build\": {
            \"data\": {
              \"id\": \"$BUILD_ID\",
              \"type\": \"builds\"
            }
          }
        }
      }
    }" \
    "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations" > /dev/null
fi

echo "What to Test: set from latest commit"

# Submit for beta app review (required for external test groups)
curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"type\": \"betaAppReviewSubmissions\",
      \"relationships\": {
        \"build\": {
          \"data\": {
            \"id\": \"$BUILD_ID\",
            \"type\": \"builds\"
          }
        }
      }
    }
  }" \
  "https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions" > /dev/null

echo "Submitted for beta app review"
```

## Step 12: Final Report

```
✅ Archive & TestFlight Distribution Complete

Version:       $MARKETING_VERSION (build $NEW_BUILD)
Archive:       ~/Desktop/forager-$MARKETING_VERSION-$NEW_BUILD.xcarchive
Processing:    VALID
Compliance:    No non-exempt encryption
Beta Group:    $GROUP_NAME
What to Test:  (from latest commit)
Review Status: WAITING_FOR_REVIEW
Status:        Submitted — testers notified once review completes
```

## Arguments

- No arguments: full pipeline (archive → upload → wait → compliance → add to **Public Beta Testers**)
- `--version X.Y`: also bump marketing version (e.g., `/archive --version 1.3`)
- `--group "Group Name"`: use a different beta group (e.g., `/archive --group "forager beta testing v1"`)
- `--no-upload`: archive and export only, skip TestFlight upload and steps 8-11
- `--no-wait`: upload only, skip steps 8-11 (processing wait + compliance + beta group)
- `--dry-run`: show what would happen without making changes
- `--testflight-only`: skip archive/upload, run only steps 7-11 (for builds already uploaded)

## Configuration

- **Team ID**: 93FT2PT9NM
- **Bundle ID**: com.richhayn.forager
- **Signing**: Automatic (Apple Development → Distribution managed by Xcode)
- **CloudKit**: Enabled in Release, disabled in Debug
- **API Key Config**: `~/.appstoreconnect/config` (KEY_ID, ISSUER_ID)
- **API Key File**: `~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8`
- **JWT Generator**: `Tools/appstore-connect/generate-jwt.swift`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `No signing certificate` | Open Xcode → Signing & Capabilities → resolve. Or: `security find-identity -v -p codesigning` |
| `Provisioning profile` | Xcode auto-manages. Try: Xcode → Preferences → Accounts → Download Manual Profiles |
| `Export failed` | Try `xcodebuild -exportArchive` with `-allowProvisioningUpdates` flag |
| `Upload rejected` | Check build number isn't reused. App Store Connect rejects duplicate build numbers per version |
| `JWT generation failed` | Verify .p8 file path and format. Run: `swift Tools/appstore-connect/generate-jwt.swift <path> <key-id> <issuer-id>` manually |
| `API returns 401` | JWT may be expired (20 min). Regenerate with Step 7 |
| `API returns 403` | API key role too restrictive. Needs at least "Developer" role |
| `Build not found after upload` | Wait 2-5 minutes for propagation, then retry Step 8 |
| `Build stuck in PROCESSING` | Normal for up to 15 min. If >30 min, check App Store Connect web UI |
| `Export compliance already set` | Info.plist has `ITSAppUsesNonExemptEncryption`. Step 9 is automatic — no action needed |
