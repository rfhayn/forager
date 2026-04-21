#!/bin/bash
# architecture-guard.sh — ADR 014 factory / explicit-assign enforcement
# PreToolUse sync hook, matcher: Edit|Write
#
# Enforces ADR 014's two sanctioned creation paths for HouseholdScoped entities:
#   1. ManagedObjectFactory.make() — handles store assignment internally
#   2. Direct Entity(context:) FOLLOWED BY context.assign(object, to: targetStore)
#      within 10 lines — child-inheritance pattern from ADR 014 M9.15 / M9.19 CRITICAL
#
# Any direct Entity(context:) init WITHOUT an accompanying assign within 10 lines
# is flagged as a factory bypass. This catches the class of bug that caused
# CloudKit zone conflict error 134040 in April 2026
# (change: fix-groceryitem-multi-zone-assignment).
#
# History: originally blocked all direct Entity(context:) init. Updated in
# 2026-04-21 to recognize the child-inheritance + assign pattern per ADR 014's
# actual rules. Strict factory-only enforcement is tracked on the app-health
# roadmap as `harden-factory-enforcement-for-child-entities`.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

# Only check Swift files in forager/ (skip tests, previews, seeders)
case "$FILE_PATH" in
  */foragerTests/*|*/foragerUITests/*|*Preview*|*Seeder*|*ManagedObjectFactory*|*HouseholdService*) exit 0 ;;
esac
[[ "$FILE_PATH" == *.swift ]] || exit 0
[[ "$FILE_PATH" == *forager/* ]] || exit 0

# Extract the content being written/edited
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')
[ -z "$CONTENT" ] && exit 0

# HouseholdScoped entities subject to the creation rules
ENTITIES="WeeklyList|Recipe|PlannedMeal|MealPlan|Category|IngredientTemplate|Ingredient|GroceryListItem"

# For each line matching an entity-init, require a context.assign(...) call
# within the next 10 lines. awk passes ENTITIES via -v to keep regex correct.
VIOLATION=$(echo "$CONTENT" | awk -v entities="$ENTITIES" '
  {
    lines[NR] = $0
  }
  END {
    init_re = "(" entities ")\\(context:"
    assign_re = "\\.assign\\(.*to:"
    for (i = 1; i <= NR; i++) {
      if (lines[i] ~ init_re) {
        has_assign = 0
        end = i + 10
        if (end > NR) end = NR
        for (j = i; j <= end; j++) {
          if (lines[j] ~ assign_re) {
            has_assign = 1
            break
          }
        }
        if (!has_assign) {
          print "violation:" i
          exit 0
        }
      }
    }
  }
')

if [ -n "$VIOLATION" ]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "⚠️ Factory bypass detected — direct HouseholdScoped Entity(context:) init must be followed within 10 lines by either context.assign(object, to: targetStore) (ADR 014 child-inheritance pattern, M9.19 CRITICAL) or ManagedObjectFactory.make() (ADR 014 strict pattern). See fix-groceryitem-multi-zone-assignment for background."
    }
  }'
fi

exit 0
