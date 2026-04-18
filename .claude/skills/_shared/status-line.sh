#!/bin/bash
# status-line.sh — write the branch-keyed status file read by .claude/statusline.sh
#
# PURPOSE
#   The status line (`.claude/statusline.sh`) is polled by Claude Code every
#   ~300ms. It reads `~/.claude/forager-status-<branch-slug>.txt`. Branch
#   switches auto-update via the branch-keyed filename; focus changes
#   *within* a branch require an explicit write.
#
#   This helper centralizes that write. All workflow skills that represent
#   a focus transition (/session-start, /new-milestone, /milestone-complete,
#   /commit, /opsx:apply, /opsx:archive, /done) should call `write_status`
#   with a short label instead of hand-rolling the echo > path boilerplate.
#
# USAGE (subcommand form — recommended)
#   bash .claude/skills/_shared/status-line.sh write "<label>"
#   bash .claude/skills/_shared/status-line.sh write "<label>" <branch>
#   bash .claude/skills/_shared/status-line.sh path
#   bash .claude/skills/_shared/status-line.sh path <branch>
#
# USAGE (sourced — when callers want the function directly)
#   source .claude/skills/_shared/status-line.sh
#   write_status "<label>"
#   write_status "<label>" "<branch-override>"
#
# LABEL CONVENTIONS
#   Legacy M-format:     [M7.7] app-store-submission
#                        [M16.9] ml-model-retraining .3 full-retrain
#   OpenSpec change-id:  [architecture-compliance-sweep] phase 1
#                        [architecture-compliance-sweep] phase 2 — views 1–15
#   Idle / post-ship:    [main] post-Cluster B — next: scope architecture-compliance-sweep
#
# EXIT CODES
#   0 — status written (write) or path printed (path)
#   1 — usage error

set -euo pipefail

_status_file_for_branch() {
    local branch="${1:-}"
    if [ -z "$branch" ]; then
        branch=$(git --no-optional-locks branch --show-current 2>/dev/null || echo "")
    fi
    if [ -z "$branch" ]; then
        echo "ERROR: cannot determine current branch" >&2
        return 1
    fi
    local slug
    slug=$(echo "$branch" | tr '/' '-')
    echo "$HOME/.claude/forager-status-${slug}.txt"
}

write_status() {
    local label="${1:-}"
    local branch_override="${2:-}"
    if [ -z "$label" ]; then
        echo "usage: write_status <label> [branch]" >&2
        return 1
    fi
    local file
    file=$(_status_file_for_branch "$branch_override") || return 1
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$label" > "$file"
    echo "status: $label  (wrote $file)"
}

# Subcommand dispatch when executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ $# -lt 1 ]; then
        echo "usage: status-line.sh write <label> [branch]" >&2
        echo "       status-line.sh path [branch]" >&2
        exit 1
    fi
    cmd="$1"
    shift
    case "$cmd" in
        write)
            write_status "$@"
            ;;
        path)
            _status_file_for_branch "${1:-}"
            ;;
        --test)
            echo "--- SELF-TEST ---"
            tmp_home=$(mktemp -d)
            HOME="$tmp_home" write_status "[test-branch] sanity" "test-branch" >/dev/null
            expected="$tmp_home/.claude/forager-status-test-branch.txt"
            mkdir -p "$(dirname "$expected")"
            HOME="$tmp_home" write_status "[test-branch] sanity" "test-branch" >/dev/null
            if [ -f "$expected" ] && grep -q "sanity" "$expected"; then
                echo "  ✓ write_status wrote expected file"
            else
                echo "  ✗ write_status did not produce expected file"
                rm -rf "$tmp_home"
                exit 1
            fi
            HOME="$tmp_home" write_status "[feature/slash] ok" "feature/slash" >/dev/null
            slashed="$tmp_home/.claude/forager-status-feature-slash.txt"
            if [ -f "$slashed" ]; then
                echo "  ✓ branch slashes converted to hyphens in slug"
            else
                echo "  ✗ slash→hyphen conversion failed"
                rm -rf "$tmp_home"
                exit 1
            fi
            rm -rf "$tmp_home"
            echo "--- all passed ---"
            ;;
        *)
            echo "ERROR: unknown subcommand '$cmd'" >&2
            echo "usage: status-line.sh {write|path} ..." >&2
            exit 1
            ;;
    esac
fi
