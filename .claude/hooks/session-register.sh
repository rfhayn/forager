#!/usr/bin/env bash
# Hook: session-register.sh
# Event: SessionStart (async)
# Purpose: Auto-register worker in orchestration DB on session start/resume

set -euo pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Graceful degradation: no orchestration = no-op
test -d "$PROJECT_DIR/orchestration" || exit 0

# Parse branch name for milestone prefix
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [ -z "$BRANCH" ] || [ "$BRANCH" = "main" ] || [ "$BRANCH" = "HEAD" ]; then
  exit 0
fi

# Extract milestone from branch: feature/LIFE-1.1-desc → LIFE-1
# Supports PREFIX-#.# format and legacy M#.# format
MILESTONE="$(echo "$BRANCH" | grep -oE '(feature/)?[A-Z]+-[0-9]+' | sed 's|^feature/||' || echo "")"
if [ -z "$MILESTONE" ]; then
  # Try legacy M#.# format: feature/M1.2.3-desc → M1.2
  MILESTONE="$(echo "$BRANCH" | grep -oE '(feature/)?M[0-9]+\.[0-9]+' | sed 's|^feature/||' || echo "")"
fi

if [ -z "$MILESTONE" ]; then
  exit 0
fi

# Worker name: username-milestone-session type
WORKER_NAME="${USER:-unknown}-${MILESTONE}-build"

# Register or heartbeat if already registered
if clauductor register --name "$WORKER_NAME" --type build --milestone "$MILESTONE" --owner "${USER:-unknown}" 2>/dev/null; then
  :
else
  # Already registered — send heartbeat instead
  clauductor heartbeat --worker-id "$WORKER_NAME" 2>/dev/null || true
fi
