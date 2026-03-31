#!/usr/bin/env bash
# Hook: lock-guard.sh
# Event: PreToolUse (sync, matcher: Edit|Write)
# Purpose: Warn before editing a file locked by another worker

set -euo pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Graceful degradation: no orchestration = no-op
test -d "$PROJECT_DIR/orchestration" || exit 0

# Read hook input JSON from stdin
INPUT="$(cat)"

# Extract file path from tool_input
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Make path relative to project root for consistent lock matching
FILE_PATH="$(realpath --relative-to="$PROJECT_DIR" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"

# Check lock status via CLI
LOCK_RESULT="$(clauductor check-lock --file "$FILE_PATH" 2>/dev/null || echo '{"locked":false}')"

LOCKED="$(echo "$LOCK_RESULT" | jq -r '.locked' 2>/dev/null)"
if [ "$LOCKED" != "true" ]; then
  exit 0
fi

# File is locked — check if it's locked by the current worker
LOCK_WORKER="$(echo "$LOCK_RESULT" | jq -r '.worker_id' 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
MILESTONE="$(echo "$BRANCH" | grep -oE '(feature/)?[A-Z]+-[0-9]+' | sed 's|^feature/||' || echo "")"
if [ -z "$MILESTONE" ]; then
  MILESTONE="$(echo "$BRANCH" | grep -oE '(feature/)?M[0-9]+\.[0-9]+' | sed 's|^feature/||' || echo "")"
fi
CURRENT_WORKER="${USER:-unknown}-${MILESTONE}-build"

# Locked by current worker — allow silently
if [ "$LOCK_WORKER" = "$CURRENT_WORKER" ]; then
  exit 0
fi

# Locked by another worker — warn but allow (exit 0)
LOCK_MILESTONE="$(echo "$LOCK_RESULT" | jq -r '.milestone' 2>/dev/null)"
cat <<WARN
WARNING: File '$FILE_PATH' is locked by worker '$LOCK_WORKER' (milestone: $LOCK_MILESTONE).
Consider coordinating before editing. To enforce blocking, change this hook to exit 2.
WARN

exit 0
