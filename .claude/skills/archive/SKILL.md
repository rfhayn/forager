---
name: archive
description: Archive and distribute forager to TestFlight. Auto-increments build number, archives for Release, and uploads to App Store Connect.
---

# Archive & Distribute

Archive forager for TestFlight/App Store distribution. Handles version management, archiving, and upload.

## Current State

- Marketing version: !`grep 'MARKETING_VERSION = ' forager.xcodeproj/project.pbxproj | head -1 | tr -d '[:space:];'`
- Build number: !`grep 'CURRENT_PROJECT_VERSION = ' forager.xcodeproj/project.pbxproj | head -1 | tr -d '[:space:];'`
- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`

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

```bash
git add forager.xcodeproj/project.pbxproj
git commit -m "M7.7: Bump build number to $NEW_BUILD"
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

## Step 6: Export for App Store Connect

```bash
# Create ExportOptions.plist if it doesn't exist
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
  2>&1 | tail -10
```

## Step 7: Upload to TestFlight

The export with `destination: upload` should auto-upload. If manual upload is needed:

```bash
xcrun altool --upload-app \
  -f ~/Desktop/forager-export/forager.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID \
  2>&1
```

**Note**: API key authentication requires an App Store Connect API key. If not set up, the user can upload the .ipa via Transporter.app or Xcode Organizer as a fallback.

## Step 8: Report

```
✅ Archive & Upload Complete
Version: 1.2 (build 24)
Archive: ~/Desktop/forager-1.2-24.xcarchive
Status: Uploaded to App Store Connect
Next: Check TestFlight in App Store Connect for processing status
```

## Arguments

- No arguments: auto-increment build, archive, export, upload
- `--version X.Y`: also bump marketing version (e.g., `/archive --version 1.3`)
- `--no-upload`: archive and export only, skip TestFlight upload
- `--dry-run`: show what would happen without making changes

## Configuration

- **Team ID**: 93FT2PT9NM
- **Bundle ID**: com.richhayn.forager
- **Signing**: Automatic (Apple Development → Distribution managed by Xcode)
- **CloudKit**: Enabled in Release, disabled in Debug

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `No signing certificate` | Open Xcode → Signing & Capabilities → resolve. Or: `security find-identity -v -p codesigning` |
| `Provisioning profile` | Xcode auto-manages. Try: Xcode → Preferences → Accounts → Download Manual Profiles |
| `Export failed` | Try `xcodebuild -exportArchive` with `-allowProvisioningUpdates` flag |
| `Upload rejected` | Check build number isn't reused. App Store Connect rejects duplicate build numbers per version |
