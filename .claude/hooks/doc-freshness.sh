#!/usr/bin/env bash
# Hook: doc-freshness.sh
# Event: PreToolUse (sync, matcher: Bash, if: Bash(git commit *))
# Purpose: Warn about stale or missing core docs before commits
# Exit 0 always (warn only, never block)

set -euo pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCS="$PROJECT_DIR/docs"
WARNINGS=""

# Parse milestone from branch name
# Supports: feature/AUTH-1.3-description → AUTH-1
#           feature/M18.1-description   → M18
#           feature/LIFE-1-description  → LIFE-1
BRANCH="$(git branch --show-current 2>/dev/null || echo "")"
MILESTONE=""
if [[ "$BRANCH" =~ ^feature/([A-Z][A-Za-z]*-[0-9]+) ]]; then
  MILESTONE="${BASH_REMATCH[1]}"
elif [[ "$BRANCH" =~ ^feature/(M[0-9]+) ]]; then
  MILESTONE="${BASH_REMATCH[1]}"
fi

warn() {
  WARNINGS="${WARNINGS}  ⚠ $1\n"
}

# --- Core doc existence checks ---

if [ ! -f "$DOCS/current-story.md" ]; then
  warn "docs/current-story.md missing"
fi

if [ ! -f "$DOCS/development-journal.md" ]; then
  warn "docs/development-journal.md missing"
fi

if [ ! -f "$DOCS/insights-log.md" ]; then
  warn "docs/insights-log.md missing"
fi

if [ ! -f "$DOCS/next-prompt.md" ]; then
  warn "docs/next-prompt.md missing"
fi

if [ ! -f "$DOCS/requirements.md" ]; then
  warn "docs/requirements.md missing"
fi

# --- Milestone-specific checks (only if we detected a milestone) ---

if [ -n "$MILESTONE" ]; then
  # Check current-story.md mentions the milestone as ACTIVE
  if [ -f "$DOCS/current-story.md" ]; then
    if ! grep -q "$MILESTONE" "$DOCS/current-story.md" 2>/dev/null; then
      warn "current-story.md does not reference milestone $MILESTONE"
    fi
  fi

  # Check next-prompt.md has a pointer for this milestone
  if [ -f "$DOCS/next-prompt.md" ]; then
    if ! grep -q "$MILESTONE" "$DOCS/next-prompt.md" 2>/dev/null; then
      warn "next-prompt.md has no pointer for milestone $MILESTONE"
    fi
  fi

  # Check next-prompt-MILESTONE.md exists (try major milestone ID)
  # For AUTH-1.3, look for next-prompt-AUTH-1.md or next-prompt-AUTH-1.3.md
  MAJOR="${MILESTONE%%.*}"
  FOUND_NP=false
  [ -f "$DOCS/next-prompt-${MILESTONE}.md" ] && FOUND_NP=true
  [ -f "$DOCS/next-prompt-${MAJOR}.md" ] && FOUND_NP=true
  if [ "$FOUND_NP" = false ]; then
    warn "No next-prompt file for milestone $MILESTONE (expected next-prompt-${MILESTONE}.md or next-prompt-${MAJOR}.md)"
  fi

  # Check requirements.md has a section for this milestone
  if [ -f "$DOCS/requirements.md" ]; then
    if ! grep -q "$MILESTONE\|$MAJOR" "$DOCS/requirements.md" 2>/dev/null; then
      warn "requirements.md has no section for milestone $MILESTONE"
    fi
  fi
fi

# --- Journal freshness check ---

if [ -f "$DOCS/development-journal.md" ]; then
  TODAY="$(date +%Y-%m-%d)"
  if ! head -20 "$DOCS/development-journal.md" | grep -q "$TODAY" 2>/dev/null; then
    warn "development-journal.md hasn't been updated today ($TODAY)"
  fi
fi

# --- Output warnings ---

if [ -n "$WARNINGS" ]; then
  echo "Doc freshness check before commit:"
  echo -e "$WARNINGS"
  echo "Run /commit to auto-fix, or update docs manually."
fi

exit 0
