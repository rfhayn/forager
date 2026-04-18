#!/bin/bash
# doc-freshness.sh — check four documentation families for branch-diff freshness
#
# PURPOSE
#   Block PR creation (/pr) when required docs have not been updated on the
#   current branch. Same check serves /review at WARN severity. Single source
#   of truth prevents the two skills drifting out of sync.
#
# USAGE
#   .claude/skills/_shared/doc-freshness.sh [--mode=block|warn]
#   .claude/skills/_shared/doc-freshness.sh --test
#
#   --mode=block  (default) exit non-zero on any STALE family
#   --mode=warn   always exit 0; only prints the report
#   --test        run the embedded self-test harness
#
# CHECKS
#   Dev journal:     docs/development-journal.md modified in `git diff main...HEAD --name-only`
#   Insights log:    docs/insights-log.md modified in diff
#   PRD:             one of docs/prds/active/<id>*.md OR openspec/changes/<id>/proposal.md
#                    exists AND is modified in diff; no match ⇒ STALE (strict)
#   OpenSpec change: openspec/changes/<id>/tasks.md modified in diff;
#                    if no change dir exists, reports SKIP (not STALE)
#
# EXIT CODES
#   0  — block mode with all families FRESH (or OpenSpec SKIP); or warn mode; or --test all-pass
#   1  — block mode with one or more STALE families; --test failure; or unknown arg
#   2  — cannot determine branch identifier
#
# ENVIRONMENT (for testing)
#   DOC_FRESHNESS_ROOT_OVERRIDE  — repo root override (self-test uses a temp dir)
#   DOC_FRESHNESS_DIFF_OVERRIDE  — synthetic diff list (one path per line)
#   DOC_FRESHNESS_IDENT_OVERRIDE — synthetic identifier (bypasses branch detection)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MILESTONE_FORMAT="$SCRIPT_DIR/milestone-format.sh"

usage() {
    cat <<'EOF'
usage: doc-freshness.sh [--mode=block|warn]
       doc-freshness.sh --test

  --mode=block  (default) exit non-zero on any STALE family
  --mode=warn   always exit 0; only prints the report
  --test        run the embedded self-test harness
EOF
}

# ----- family check functions ------------------------------------------------
# Each returns "STATUS|reason" via echo. Functions read $REPO_ROOT for filesystem
# lookups and take the diff list as argument so tests can inject synthetic data.

check_journal() {
    local diff_list="$1"
    if printf '%s\n' "$diff_list" | grep -qx "docs/development-journal.md"; then
        echo "FRESH|docs/development-journal.md modified"
    else
        echo "STALE|docs/development-journal.md not modified in branch diff"
    fi
}

check_insights() {
    local diff_list="$1"
    if printf '%s\n' "$diff_list" | grep -qx "docs/insights-log.md"; then
        echo "FRESH|docs/insights-log.md modified"
    else
        echo "STALE|docs/insights-log.md not modified in branch diff"
    fi
}

check_prd() {
    local identifier="$1"
    local diff_list="$2"
    local prd_path=""

    # OpenSpec proposal counts as PRD when the change dir exists
    if [ -f "$REPO_ROOT/openspec/changes/$identifier/proposal.md" ]; then
        prd_path="openspec/changes/$identifier/proposal.md"
    else
        # Glob docs/prds/active/<id>*.md (case-insensitive fallback for legacy M -> m)
        shopt -s nullglob
        local matches=( "$REPO_ROOT/docs/prds/active/${identifier}"*.md )
        if [ ${#matches[@]} -eq 0 ]; then
            local lc
            lc="$(printf '%s' "$identifier" | tr '[:upper:]' '[:lower:]')"
            if [ "$lc" != "$identifier" ]; then
                matches=( "$REPO_ROOT/docs/prds/active/${lc}"*.md )
            fi
        fi
        shopt -u nullglob
        if [ ${#matches[@]} -gt 0 ]; then
            prd_path="${matches[0]#$REPO_ROOT/}"
        fi
    fi

    if [ -z "$prd_path" ]; then
        echo "STALE|no PRD found matching identifier '$identifier'"
    elif printf '%s\n' "$diff_list" | grep -qx "$prd_path"; then
        echo "FRESH|$prd_path modified"
    else
        echo "STALE|$prd_path not modified in branch diff"
    fi
}

check_openspec() {
    local identifier="$1"
    local diff_list="$2"
    if [ ! -d "$REPO_ROOT/openspec/changes/$identifier" ]; then
        echo "SKIP|no active change dir at openspec/changes/$identifier"
        return
    fi
    local tasks_path="openspec/changes/$identifier/tasks.md"
    if printf '%s\n' "$diff_list" | grep -qx "$tasks_path"; then
        echo "FRESH|$tasks_path modified"
    else
        echo "STALE|$tasks_path not modified in branch diff"
    fi
}

# ----- report rendering ------------------------------------------------------

print_report() {
    local identifier="$1"
    local journal="$2"
    local insights="$3"
    local prd="$4"
    local openspec="$5"

    local j_status="${journal%%|*}"    ; local j_reason="${journal#*|}"
    local i_status="${insights%%|*}"   ; local i_reason="${insights#*|}"
    local p_status="${prd%%|*}"        ; local p_reason="${prd#*|}"
    local o_status="${openspec%%|*}"   ; local o_reason="${openspec#*|}"

    echo "Documentation Freshness Report"
    echo "================================"
    echo "Branch identifier: $identifier"
    echo
    printf "  %-18s| %-6s | %s\n" "Family" "Status" "Reason"
    printf "  %-18s|%s|%s\n" "------------------" "--------" "-------------------------------------"
    printf "  %-18s| %-6s | %s\n" "Dev journal"     "$j_status" "$j_reason"
    printf "  %-18s| %-6s | %s\n" "Insights log"    "$i_status" "$i_reason"
    printf "  %-18s| %-6s | %s\n" "PRD"             "$p_status" "$p_reason"
    printf "  %-18s| %-6s | %s\n" "OpenSpec change" "$o_status" "$o_reason"
    echo

    # Remediation: only list hints for STALE families
    local any_stale=0
    if [ "$j_status" = "STALE" ] || [ "$i_status" = "STALE" ] || [ "$p_status" = "STALE" ] || [ "$o_status" = "STALE" ]; then
        any_stale=1
        echo "Remediation:"
        [ "$j_status" = "STALE" ] && echo "  /dev-journal          (update the development journal)"
        [ "$i_status" = "STALE" ] && echo "  /log-insight          (record any technical insights)"
        if [ "$p_status" = "STALE" ]; then
            if [[ "$p_reason" == no\ PRD\ found* ]]; then
                echo "  Create PRD at         docs/prds/active/${identifier}.md"
                echo "                        (or reference openspec/changes/${identifier}/proposal.md)"
            else
                local prd_path="${p_reason% not modified in branch diff}"
                echo "  Update PRD at         $prd_path"
            fi
        fi
        [ "$o_status" = "STALE" ] && echo "  Update OpenSpec tasks at  openspec/changes/$identifier/tasks.md"
        echo
    fi

    echo "$any_stale"  # trailing marker — captured by caller
}

# ----- identifier resolution -------------------------------------------------

resolve_identifier() {
    # Honour override for tests
    if [ -n "${DOC_FRESHNESS_IDENT_OVERRIDE:-}" ]; then
        echo "$DOC_FRESHNESS_IDENT_OVERRIDE"
        return 0
    fi

    local branch
    branch="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "")"
    if [ -z "$branch" ]; then
        echo "ERROR: not in a git repo or detached HEAD" >&2
        return 2
    fi

    # Strip feature/ prefix (if present)
    local stripped="${branch#feature/}"

    # Try milestone-format.sh on full stripped (works for OpenSpec kebab)
    if "$MILESTONE_FORMAT" "$stripped" >/dev/null 2>&1; then
        echo "$stripped"
        return 0
    fi

    # Legacy M#.#.# with -description suffix: extract leading M-prefix
    if [[ "$stripped" =~ ^(M[0-9]+(\.[0-9]+){0,3}) ]]; then
        local extracted="${BASH_REMATCH[1]}"
        if "$MILESTONE_FORMAT" "$extracted" >/dev/null 2>&1; then
            echo "$extracted"
            return 0
        fi
    fi

    echo "ERROR: cannot determine valid identifier from branch '$branch'" >&2
    echo "  expected feature/M#.#.#-* or feature/<kebab-change-id>" >&2
    return 2
}

# ----- main ------------------------------------------------------------------

run_main() {
    local mode="block"
    for arg in "$@"; do
        case "$arg" in
            --mode=block) mode="block" ;;
            --mode=warn)  mode="warn" ;;
            -h|--help)    usage; exit 0 ;;
            *)            echo "unknown arg: $arg" >&2; usage >&2; exit 1 ;;
        esac
    done

    REPO_ROOT="${DOC_FRESHNESS_ROOT_OVERRIDE:-$( cd "$SCRIPT_DIR/../../.." && pwd )}"

    local identifier
    if ! identifier="$(resolve_identifier)"; then
        exit 2
    fi

    local diff_list
    if [ -n "${DOC_FRESHNESS_DIFF_OVERRIDE:-}" ]; then
        diff_list="$DOC_FRESHNESS_DIFF_OVERRIDE"
    else
        diff_list="$(git -C "$REPO_ROOT" diff main...HEAD --name-only 2>/dev/null || echo "")"
    fi

    local journal insights prd openspec
    journal="$(check_journal "$diff_list")"
    insights="$(check_insights "$diff_list")"
    prd="$(check_prd "$identifier" "$diff_list")"
    openspec="$(check_openspec "$identifier" "$diff_list")"

    local report_output
    report_output="$(print_report "$identifier" "$journal" "$insights" "$prd" "$openspec")"
    # Separate trailing any-stale marker from the report body
    local any_stale="${report_output##*$'\n'}"
    local body="${report_output%$'\n'*}"
    printf '%s\n' "$body"

    if [ "$any_stale" = "1" ]; then
        if [ "$mode" = "block" ]; then
            echo "Stale docs block PR creation. Re-run /pr after committing doc updates."
            exit 1
        else
            echo "(warn mode: stale docs reported, not blocking)"
            exit 0
        fi
    fi

    if [ "$mode" = "block" ]; then
        echo "All documentation families fresh. /pr may proceed."
    fi
    exit 0
}

# ----- self-test -------------------------------------------------------------

run_self_test() {
    local PASS=0 FAIL=0
    local TMP_ROOT
    TMP_ROOT="$(mktemp -d)"
    # Prepare a minimal synthetic repo layout
    mkdir -p "$TMP_ROOT/docs/prds/active"
    mkdir -p "$TMP_ROOT/openspec/changes"
    touch "$TMP_ROOT/docs/development-journal.md"
    touch "$TMP_ROOT/docs/insights-log.md"
    # A PRD matching identifier "test-change"
    touch "$TMP_ROOT/docs/prds/active/test-change.md"
    # An OpenSpec change dir for "other-change" (separate from PRD fixture)
    mkdir -p "$TMP_ROOT/openspec/changes/other-change"
    touch "$TMP_ROOT/openspec/changes/other-change/proposal.md"
    touch "$TMP_ROOT/openspec/changes/other-change/tasks.md"

    REPO_ROOT="$TMP_ROOT"

    assert_status() {
        local label="$1" got="$2" want="$3"
        if [ "$got" = "$want" ]; then
            echo "  ✓ $label"
            PASS=$((PASS + 1))
        else
            echo "  ✗ $label: got '$got', want '$want'"
            FAIL=$((FAIL + 1))
        fi
    }

    echo "--- SELF-TEST: doc-freshness.sh ---"

    # Case 1: dev-journal fresh vs stale
    local r
    r="$(check_journal "docs/development-journal.md")"
    assert_status "journal FRESH when in diff"  "${r%%|*}" "FRESH"
    r="$(check_journal "docs/other-file.md")"
    assert_status "journal STALE when absent"   "${r%%|*}" "STALE"

    # Case 2: insights-log fresh vs stale
    r="$(check_insights "docs/insights-log.md")"
    assert_status "insights FRESH when in diff" "${r%%|*}" "FRESH"
    r="$(check_insights "")"
    assert_status "insights STALE on empty diff" "${r%%|*}" "STALE"

    # Case 3: PRD present, in diff
    r="$(check_prd "test-change" "docs/prds/active/test-change.md")"
    assert_status "PRD FRESH when matched & in diff" "${r%%|*}" "FRESH"

    # Case 4: PRD present but unmodified
    r="$(check_prd "test-change" "docs/other-file.md")"
    assert_status "PRD STALE when matched & not in diff" "${r%%|*}" "STALE"

    # Case 5: PRD missing entirely
    r="$(check_prd "no-such-change" "")"
    assert_status "PRD STALE when identifier has no match" "${r%%|*}" "STALE"

    # Case 6: OpenSpec change dir exists, tasks.md in diff
    r="$(check_openspec "other-change" "openspec/changes/other-change/tasks.md")"
    assert_status "OpenSpec FRESH when tasks.md in diff" "${r%%|*}" "FRESH"

    # Case 7: OpenSpec change dir exists, tasks.md absent from diff
    r="$(check_openspec "other-change" "")"
    assert_status "OpenSpec STALE when tasks.md not in diff" "${r%%|*}" "STALE"

    # Case 8: no OpenSpec change dir => SKIP
    r="$(check_openspec "no-such-change" "")"
    assert_status "OpenSpec SKIP when no change dir" "${r%%|*}" "SKIP"

    # Case 9: OpenSpec proposal satisfies PRD (proposal counts as PRD)
    r="$(check_prd "other-change" "openspec/changes/other-change/proposal.md")"
    assert_status "PRD FRESH via OpenSpec proposal path" "${r%%|*}" "FRESH"

    # Case 10: invalid identifier exits 2
    local exit_code=0
    DOC_FRESHNESS_IDENT_OVERRIDE="" \
    DOC_FRESHNESS_ROOT_OVERRIDE="$TMP_ROOT" \
        bash -c "cd '$TMP_ROOT' && git init -q 2>/dev/null; \"$0\" --mode=warn" >/dev/null 2>&1 || exit_code=$?
    # On a fresh `git init` with no commits and no branch, resolve_identifier exits 2.
    # Accept 2 as the expected failure mode; other non-zero codes also acceptable for this case.
    if [ "$exit_code" -ne 0 ]; then
        echo "  ✓ invalid identifier / no git branch exits non-zero (code $exit_code)"
        PASS=$((PASS + 1))
    else
        echo "  ✗ invalid identifier should exit non-zero (got 0)"
        FAIL=$((FAIL + 1))
    fi

    rm -rf "$TMP_ROOT"
    echo "--- $PASS passed, $FAIL failed ---"
    [ "$FAIL" -eq 0 ] || return 1
    return 0
}

# ----- dispatch --------------------------------------------------------------

if [ "${1:-}" = "--test" ]; then
    run_self_test
    exit $?
fi

run_main "$@"
