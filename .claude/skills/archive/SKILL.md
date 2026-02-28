---
name: archive
description: Archive and distribute forager to TestFlight. Auto-increments build number, archives for Release, uploads to App Store Connect, waits for processing, sets export compliance, and adds to beta test group.
---

# Archive & Distribute to TestFlight

Full pipeline: version bump → archive → upload → wait for processing → export compliance → add to beta group.

**CRITICAL: Permission-safe execution.** Run each operation as a SEPARATE Bash tool call. Never chain commands with `&&`, `||`, or pipes. Never combine multiple operations in one Bash call. One command per call. This ensures all commands match pre-approved permission patterns.

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

**Read current value** — run as separate calls:
```bash
grep -m1 'CURRENT_PROJECT_VERSION = ' forager.xcodeproj/project.pbxproj
```
Parse the number from output. Compute NEW_BUILD = CURRENT_BUILD + 1.

**Update both Debug and Release** — run as two separate calls:
```bash
# Call 1: awk to create temp file
awk -v old="CURRENT_BUILD" -v new="NEW_BUILD" '/CURRENT_PROJECT_VERSION = / && count < 2 { sub("CURRENT_PROJECT_VERSION = " old, "CURRENT_PROJECT_VERSION = " new); count++ } { print }' forager.xcodeproj/project.pbxproj > /tmp/pbxproj_tmp
```
```bash
# Call 2: move temp file back
mv /tmp/pbxproj_tmp forager.xcodeproj/project.pbxproj
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

Run as three separate calls:
```bash
git add forager.xcodeproj/project.pbxproj
```
```bash
git commit -m "Bump build number to $NEW_BUILD for TestFlight"
```
```bash
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

Use the Write tool to create `/tmp/ForagerExportOptions.plist` with this content:
```xml
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
```

Then run export as a separate call:
```bash
xcodebuild -exportArchive -archivePath ~/Desktop/forager-$MARKETING_VERSION-$NEW_BUILD.xcarchive -exportOptionsPlist /tmp/ForagerExportOptions.plist -exportPath ~/Desktop/forager-export -allowProvisioningUpdates
```

The `destination: upload` auto-uploads to App Store Connect. If upload fails, fall back to:
```bash
xcrun notarytool submit ... # or Transporter.app / Xcode Organizer
```

## Step 7: Generate API Token

All remaining steps use the App Store Connect API. Generate a JWT and save it to a temp file.

**CRITICAL**: Each Bash call is a fresh shell — variables do NOT persist between calls. Use `/tmp/forager_jwt.txt` and `/tmp/forager_build_id.txt` to share state between calls. Never use `$JWT` or `$BUILD_ID` shell variables — always inline with `$(cat /tmp/forager_jwt.txt)` or `$(cat /tmp/forager_build_id.txt)`.

Generate and save the JWT to a file (single command):
```bash
swift Tools/appstore-connect/generate-jwt.swift ~/.appstoreconnect/private_keys/AuthKey_QBAG38ZPZR.p8 QBAG38ZPZR fbdd459e-6ae5-4dc5-82d0-c2bf095392e4 > /tmp/forager_jwt.txt
```

The App ID is always `6756034827`.

**Note**: The JWT expires after 20 minutes. If later steps take longer, regenerate by re-running the command above.

## Step 8: Wait for Build Processing

After upload, App Store Connect processes the build (typically 5-15 minutes). Poll until ready.

**Check build status** — save response to a temp file (single command, no pipes):
```bash
curl -s -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" "https://api.appstoreconnect.apple.com/v1/builds?filter%5Bapp%5D=6756034827&filter%5Bversion%5D=$NEW_BUILD&filter%5Bexpired%5D=false&sort=-uploadedDate&limit=1" -o /tmp/forager_build_response.json
```

**Parse the response** (single command):
```bash
jq '{state: .data[0].attributes.processingState, id: .data[0].id, version: .data[0].attributes.version, encryption: .data[0].attributes.usesNonExemptEncryption}' /tmp/forager_build_response.json
```

Read the jq output for:
- `state` — look for `"VALID"`
- `id` — this is the BUILD_ID for subsequent steps
- If all null, the build hasn't propagated yet — wait and retry

**Save the BUILD_ID** once found (single command):
```bash
jq -r '.data[0].id' /tmp/forager_build_response.json > /tmp/forager_build_id.txt
```

If state is NOT `VALID`, wait 60 seconds then re-run the curl+jq calls:
```bash
sleep 60
```

**If the build is not found** (null values), the upload may still be propagating. Wait 2 minutes and try again.

**If processing fails** (state = `FAILED` or `INVALID`), stop and report. Do not proceed to steps 9-12.

**Only proceed to Step 9 if state = `VALID`.**

## Step 9: Export Compliance (Automatic)

Export compliance is handled automatically via `ITSAppUsesNonExemptEncryption = NO` in `forager/App/Info.plist`. The `encryption` field from Step 8's jq output confirms this — should be `false`.

If it shows `null`, verify with a direct build check:
```bash
curl -s -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" "https://api.appstoreconnect.apple.com/v1/builds/$(cat /tmp/forager_build_id.txt)" -o /tmp/forager_compliance.json
```
```bash
jq '.data.attributes.usesNonExemptEncryption' /tmp/forager_compliance.json
```

If it stays null after 30 seconds, set it via API:
```bash
curl -s -X PATCH -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" -H "Content-Type: application/json" -d "{\"data\":{\"id\":\"$(cat /tmp/forager_build_id.txt)\",\"type\":\"builds\",\"attributes\":{\"usesNonExemptEncryption\":false}}}" "https://api.appstoreconnect.apple.com/v1/builds/$(cat /tmp/forager_build_id.txt)"
```

## Step 10: Add Build to Beta Test Group

Default group: **Public Beta Testers** (`46d19222-23de-4578-954a-ed0457239949`).

Override with `--group "Group Name"` argument (see Arguments section).

If `--group` was passed, look up the ID first:
```bash
curl -s -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" "https://api.appstoreconnect.apple.com/v1/betaGroups?filter%5Bapp%5D=6756034827" -o /tmp/forager_groups.json
```
```bash
jq '.data[] | {id: .id, name: .attributes.name}' /tmp/forager_groups.json
```

**Add build to the group** (single command — substitute the actual BUILD_ID inline):
```bash
curl -s -X POST -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" -H "Content-Type: application/json" -d "{\"data\":[{\"id\":\"$(cat /tmp/forager_build_id.txt)\",\"type\":\"builds\"}]}" "https://api.appstoreconnect.apple.com/v1/betaGroups/46d19222-23de-4578-954a-ed0457239949/relationships/builds"
```
HTTP 204 (empty response) = success.

## Step 11: Set "What to Test" & Submit for Beta Review

Set the "What to Test" notes from the latest git commit message, then submit for beta app review (required for external groups). Run each as a separate call.

**Get the commit message:**
```bash
git log -1 --pretty=%B
```

**Get the localization ID** — save response, then parse:
```bash
curl -s -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" "https://api.appstoreconnect.apple.com/v1/builds/$(cat /tmp/forager_build_id.txt)/betaBuildLocalizations" -o /tmp/forager_localizations.json
```
```bash
jq '.data[0].id' /tmp/forager_localizations.json
```
Note the localization ID from the output (strip quotes).

**Update "What to Test"** — use the localization ID from above. Escape the commit message for JSON (replace newlines with `\\n`, escape quotes). If a localization exists, PATCH it:
```bash
curl -s -X PATCH -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" -H "Content-Type: application/json" -d '{"data":{"id":"LOCALIZATION_ID","type":"betaBuildLocalizations","attributes":{"whatsNew":"ESCAPED_COMMIT_MSG"}}}' "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations/LOCALIZATION_ID"
```

If no localization exists, POST to create one:
```bash
curl -s -X POST -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" -H "Content-Type: application/json" -d "{\"data\":{\"type\":\"betaBuildLocalizations\",\"attributes\":{\"whatsNew\":\"ESCAPED_COMMIT_MSG\",\"locale\":\"en-US\"},\"relationships\":{\"build\":{\"data\":{\"id\":\"$(cat /tmp/forager_build_id.txt)\",\"type\":\"builds\"}}}}}" "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations"
```

**Submit for beta app review** (required for external test groups):
```bash
curl -s -X POST -H "Authorization: Bearer $(cat /tmp/forager_jwt.txt)" -H "Content-Type: application/json" -d "{\"data\":{\"type\":\"betaAppReviewSubmissions\",\"relationships\":{\"build\":{\"data\":{\"id\":\"$(cat /tmp/forager_build_id.txt)\",\"type\":\"builds\"}}}}}" "https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions"
```
HTTP 201 = submitted. HTTP 422 with `INVALID_QC_STATE` = already approved (success, skip).

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
