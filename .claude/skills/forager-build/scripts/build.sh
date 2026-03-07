#!/bin/bash
# Forager build script — runs xcodebuild with correct config and filters output
set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"

xcodebuild \
  -project "$PROJECT_DIR/forager.xcodeproj" \
  -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "BUILD|error:|warning:" | head -30
