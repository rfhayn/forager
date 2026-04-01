#!/bin/bash
# core-data-guard.sh — ADR 007 schema change warning
# PreToolUse sync hook, matcher: Edit|Write
# Warns before Core Data schema changes without audit

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

# Check if path is a Core Data model file
if [[ "$FILE_PATH" == *.xcdatamodeld* ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "⚠️ Core Data schema change detected. Run /core-data-audit before proceeding (ADR 007). CloudKit Production schema is append-only — no destructive changes allowed."
    }
  }'
fi

exit 0
