#!/bin/bash
# architecture-guard.sh — ADR 014 factory bypass warning
# PreToolUse sync hook, matcher: Edit|Write
# Warns when HouseholdScoped entities are created directly instead of via ManagedObjectFactory.make()

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

# HouseholdScoped entities that MUST use ManagedObjectFactory.make()
ENTITIES="WeeklyList|Recipe|PlannedMeal|MealPlan|Category|IngredientTemplate|Ingredient|GroceryListItem"

if echo "$CONTENT" | grep -qE "($ENTITIES)\(context:" ; then
  echo "⚠️  Factory bypass detected — use ManagedObjectFactory.make() instead of direct init (ADR 014)"
  echo "   HouseholdScoped entities must be created via the factory for proper scope assignment."
fi

exit 0
