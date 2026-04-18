#!/bin/bash
# milestone-format.sh — detect and normalize forager milestone/change identifiers
#
# PURPOSE
#   Forward-only naming migration: historical work uses M#.#.# (legacy),
#   new work uses <verb>-<kebab-case> OpenSpec change-ids. The 6 workflow
#   skills (new-milestone, milestone-complete, commit, pr, session-start,
#   done) need to accept both formats without skill-level branching
#   in every call site. This utility detects the format and outputs a
#   normalized representation that downstream skill logic can consume
#   format-agnostically.
#
# USAGE
#   .claude/skills/_shared/milestone-format.sh <identifier>
#
# EXAMPLES
#   Legacy M-prefix (historical work):
#     $ milestone-format.sh M9.16
#     format=M  id=M9.16  original=M9.16
#
#     $ milestone-format.sh M18.1.3
#     format=M  id=M18.1.3  original=M18.1.3
#
#   New OpenSpec change-id (forward work):
#     $ milestone-format.sh architecture-compliance-sweep
#     format=kebab  id=architecture-compliance-sweep  original=architecture-compliance-sweep
#
#     $ milestone-format.sh fix-grocery-list-detail-scope
#     format=kebab  id=fix-grocery-list-detail-scope  original=fix-grocery-list-detail-scope
#
#   Unrecognized input — error:
#     $ milestone-format.sh random gibberish
#     ERROR: unrecognized identifier ...  (exit code 2)
#
# EXIT CODES
#   0  — format detected and normalized output written to stdout
#   1  — usage error (no argument provided)
#   2  — unrecognized identifier (does not match M#.#.# or kebab pattern)
#
# REGEX
#   M-format pattern:     ^M[0-9]+(\.[0-9]+){0,3}$   (e.g., M7, M7.2, M7.2.3, M7.2.3.4)
#   kebab-format pattern: ^[a-z][a-z0-9]*(-[a-z0-9]+)+$  (at least one hyphen; letters/digits only; lowercase)

set -euo pipefail

# Handle --test before arg validation (self-test mode runs test harness)
if [ "${1:-}" = "--test" ]; then
    PASS=0
    FAIL=0
    run_case() {
        local input="$1"
        local expected_format="$2"
        local expected_exit="$3"
        local output
        local exit_code
        output=$("$0" "$input" 2>/dev/null) && exit_code=0 || exit_code=$?
        if [ "$exit_code" = "$expected_exit" ]; then
            if [ "$expected_exit" = "0" ] && [[ "$output" == *"format=$expected_format"* ]]; then
                echo "  ✓ '$input' → $expected_format (exit 0)"
                PASS=$((PASS + 1))
            elif [ "$expected_exit" != "0" ]; then
                echo "  ✓ '$input' → error (exit $exit_code)"
                PASS=$((PASS + 1))
            else
                echo "  ✗ '$input' → output mismatch: $output"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "  ✗ '$input' → exit code $exit_code (expected $expected_exit)"
            FAIL=$((FAIL + 1))
        fi
    }
    echo "--- SELF-TEST ---"
    run_case "M9.16" "M" "0"
    run_case "M18.1.3" "M" "0"
    run_case "M9" "M" "0"
    run_case "architecture-compliance-sweep" "kebab" "0"
    run_case "fix-grocery-list-detail-scope" "kebab" "0"
    run_case "random-gibberish" "kebab" "0"
    run_case "random gibberish" "" "2"
    run_case "noHyphen" "" "2"
    echo "--- $PASS passed, $FAIL failed ---"
    [ "$FAIL" -eq 0 ] || exit 1
    exit 0
fi

if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "usage: milestone-format.sh <identifier>" >&2
    echo "example: milestone-format.sh M9.16" >&2
    echo "example: milestone-format.sh architecture-compliance-sweep" >&2
    echo "run tests: milestone-format.sh --test" >&2
    exit 1
fi

ID="$1"
FORMAT=""

if [[ "$ID" =~ ^M[0-9]+(\.[0-9]+){0,3}$ ]]; then
    FORMAT="M"
elif [[ "$ID" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)+$ ]]; then
    FORMAT="kebab"
else
    echo "ERROR: unrecognized identifier '$ID'" >&2
    echo "  expected M#.#.# (legacy, e.g. M9.16) or kebab-case change-id (e.g. architecture-compliance-sweep)" >&2
    exit 2
fi

echo "format=$FORMAT  id=$ID  original=$ID"
