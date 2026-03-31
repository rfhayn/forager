#!/usr/bin/env bash
# Hook: status-sync.sh
# Event: PostToolUse (async, matcher: Write)
# Purpose: Sync milestone status to orchestration DB when current-story.md changes

set -euo pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Graceful degradation: no orchestration = no-op
test -d "$PROJECT_DIR/orchestration" || exit 0

# Read hook input JSON from stdin
INPUT="$(cat)"

# Check if the written file is current-story.md
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Normalize to relative path and check if it's current-story.md
REL_PATH="$(realpath --relative-to="$PROJECT_DIR" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
case "$REL_PATH" in
  docs/current-story.md|current-story.md) ;;
  *) exit 0 ;;
esac

STORY_FILE="$PROJECT_DIR/docs/current-story.md"
test -f "$STORY_FILE" || exit 0

# Parse active milestones and their statuses from current-story.md
# Look for lines like: ### PREFIX-#.#: Title — STATUS
while IFS= read -r line; do
  # Match "### PREFIX-#.#: ... — STATUS" or "### PREFIX-#.#: ... -- STATUS"
  if echo "$line" | grep -qE '^###\s+[A-Z]+-[0-9]+(\.[0-9]+)?:.*\b(ACTIVE|COMPLETE|READY|PLANNED)\b'; then
    MILESTONE_ID="$(echo "$line" | grep -oE '[A-Z]+-[0-9]+(\.[0-9]+)?' | head -1)"
    STATUS="$(echo "$line" | grep -oE '\b(ACTIVE|COMPLETE|READY|PLANNED)\b' | tail -1)"

    # Map document status to DB status
    case "$STATUS" in
      ACTIVE)   DB_STATUS="active" ;;
      COMPLETE) DB_STATUS="complete" ;;
      READY|PLANNED) DB_STATUS="planned" ;;
      *) continue ;;
    esac

    clauductor milestone update --id "$MILESTONE_ID" --status "$DB_STATUS" 2>/dev/null || true
  fi
done < "$STORY_FILE"
