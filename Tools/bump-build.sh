#!/bin/bash
# Bump CURRENT_PROJECT_VERSION in project.pbxproj (first two occurrences = Debug + Release)
# Usage: Tools/bump-build.sh <old> <new>

set -euo pipefail

OLD="${1:?Usage: bump-build.sh <old> <new>}"
NEW="${2:?Usage: bump-build.sh <old> <new>}"
PBXPROJ="forager.xcodeproj/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
    echo "❌ $PBXPROJ not found — run from project root" >&2
    exit 1
fi

awk -v old="$OLD" -v new="$NEW" \
    '/CURRENT_PROJECT_VERSION = / && count < 2 { sub("CURRENT_PROJECT_VERSION = " old, "CURRENT_PROJECT_VERSION = " new); count++ } { print }' \
    "$PBXPROJ" > /tmp/pbxproj_tmp

mv /tmp/pbxproj_tmp "$PBXPROJ"

echo "✅ Build number bumped: $OLD → $NEW"
