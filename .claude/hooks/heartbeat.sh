#!/usr/bin/env bash
# Hook: heartbeat.sh
# Event: PostToolUse (async, matcher: Bash|Edit|Write)
# Purpose: Keep worker alive in orchestration DB so supervisor can detect dead sessions

set -euo pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Graceful degradation: no orchestration = no-op
test -d "$PROJECT_DIR/orchestration" || exit 0

HEARTBEAT_FILE="$PROJECT_DIR/orchestration/.last-heartbeat"

# Throttle: only fire if last heartbeat was >60s ago
if [ -f "$HEARTBEAT_FILE" ]; then
  # Find files modified less than 1 minute ago — if found, skip
  if find "$HEARTBEAT_FILE" -mmin -1 2>/dev/null | grep -q .; then
    exit 0
  fi
fi

# Parse worker name from branch (same logic as session-register.sh)
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ] || [ "$BRANCH" = "HEAD" ]; then
  exit 0
fi

MILESTONE="$(echo "$BRANCH" | grep -oE '(feature/)?[A-Z]+-[0-9]+' | sed 's|^feature/||' || echo "")"
if [ -z "$MILESTONE" ]; then
  MILESTONE="$(echo "$BRANCH" | grep -oE '(feature/)?M[0-9]+\.[0-9]+' | sed 's|^feature/||' || echo "")"
fi

if [ -z "$MILESTONE" ]; then
  exit 0
fi

WORKER_NAME="${USER:-unknown}-${MILESTONE}-build"

# Update timestamp file (touch before CLI call for fast-path on next invocation)
touch "$HEARTBEAT_FILE"

# Send heartbeat
clauductor heartbeat --worker-id "$WORKER_NAME" 2>/dev/null || true
