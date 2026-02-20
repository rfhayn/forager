# ADR 012: Grocery Items as Transactional Snapshots

**Status**: Accepted
**Date**: February 20, 2026
**Milestone**: M15 — Testing Bug Fixes
**Deciders**: Rich Hayn

---

## Context

During M15 testing, multiple bugs traced back to `GroceryListItem` storing flat string copies of `name` and `categoryName` independently of `IngredientTemplate`:

1. **Category not propagating**: Quick-add created a grocery item with default category before showing the template dialog. User's category choice was written to the template but never back to the item.
2. **Name drift**: Template names updated via normalization improvements (singular → plural, sanitization) but existing grocery items retained the old name.
3. **Display text loss**: After editing a recipe, ingredient display text wasn't repopulated because `EditRecipeView` didn't call `parseToStructured()`.

The natural reaction was: "Make `IngredientTemplate` the single source of truth — add an `ingredientTemplate` relationship on `GroceryListItem` so the item derives its name and category from the template."

This ADR documents why that approach is **wrong** and what the correct fix is.

---

## Decision

**Keep `GroceryListItem` as a point-in-time snapshot. Do NOT add an `ingredientTemplate` pointer.**

Fix category integrity separately via M9.12 (category string → `Category` entity relationship).

### Current Architecture (Preserved)

```
GroceryListItem
  - name: String          (full display text: "2 cups flour")
  - categoryName: String  (flat copy: "Produce")
  - displayText: String   (formatted quantity text)
  - numericValue: Double  (for aggregation/scaling)
  - standardUnit: String  (for unit conversion)
  - source: String        ("recipe" | "manual" | "staple")
  - weeklyList: WeeklyList (relationship)
  - sourceRecipes: NSSet<Recipe> (relationship)
```

### What Will Change (M9.12, Post-Launch)

```
GroceryListItem
  + categoryEntity: Category  (replaces categoryName string)
  - categoryName: String      (kept for CloudKit backward compat)

IngredientTemplate
  + categoryEntity: Category  (replaces category string)
  - category: String          (kept for CloudKit backward compat)
```

---

## Rationale

### Grocery lists are transactional records

A grocery list captures **what you intended to buy at a specific point in time**. This is fundamentally different from a recipe (which is a living document).

- If you rename a template from "flour" to "all-purpose flour," your past grocery lists should still say "flour" — that's what you actually bought.
- If you recategorize "oat milk" from Dairy to Beverages, last week's list that had it under Dairy was correct *at the time*.
- Financial ledgers use the same pattern: the line item records the product name at time of transaction, not a foreign key to a mutable product catalog.

### A template pointer creates wrong coupling

Adding `ingredientTemplate: IngredientTemplate` to `GroceryListItem` would mean:
- **Template deletion breaks grocery items**: Delete "saffron" from your ingredient library → all historical grocery list items referencing it lose their identity.
- **Name changes are retroactive**: Normalizing "strawberry" → "strawberries" would change text on completed, archived lists.
- **Not all items have templates**: Manually-added items that the user skips the "Add to Ingredients?" dialog for would have nil template — creating a two-path display system.

### The bugs had simpler root causes

| Bug | Root cause | Correct fix |
|-----|-----------|-------------|
| Category not propagating | Temporal ordering in quick-add (Step 1 defaults, Step 2 dialog never writes back) | `lastAddedItem` backfill pattern |
| Name drift | Template normalization doesn't update existing items | By design — snapshots don't update |
| Display text loss on edit | `EditRecipeView` missing `parseToStructured()` | Added the missing call |

None of these required an architectural change. They were creation-flow bugs.

### M9.12 is the right structural fix

M9.12 replaces `categoryName: String` with `categoryEntity: Category` — a relationship to the `Category` entity. This fixes:
- **Category renames propagate**: Renaming "Bread & Frozen" → "Bread & Bakery" updates everywhere.
- **Referential integrity**: No more string matching that can drift between `ForagerTheme`, `DefaultSeeder`, and user data.
- **The snapshot semantics are preserved**: The Category entity itself is organizational infrastructure, not transactional content. Renaming a category is correcting a label, not changing history.

---

## Alternatives Considered

### A. Add `ingredientTemplate` Relationship to GroceryListItem

Rejected. Creates wrong coupling between transactional records and mutable identity records. Template deletion, renaming, and recategorization all produce unintended side effects on historical data.

### B. Add `ingredientTemplate` Relationship + Keep Flat Fields as Cache

Considered. The template pointer would serve as an optional enhancement while flat fields remain the source of truth. Overly complex — two sources of truth with unclear precedence. If the flat field IS the source of truth, the pointer adds complexity without fixing anything.

### C. Status Quo (No Changes)

Partially accepted. The current flat-string architecture is correct for grocery items. However, `categoryName: String` should eventually become `categoryEntity: Category` (M9.12) for organizational integrity.

---

## Consequences

### Positive
- **Historical accuracy**: Past grocery lists always reflect what was planned at the time
- **Deletion safety**: Removing templates or categories never orphans grocery items
- **Simplicity**: No relationship traversal for basic display — `item.name` and `item.categoryName` are self-contained
- **CloudKit friendly**: Flat strings are the simplest data type for sync

### Negative
- **Template improvements don't backfill**: Normalizing "grape" → "grapes" won't update existing items (acceptable — they were correct when created)
- **Category string drift persists until M9.12**: String-based `categoryName` remains fragile until replaced with entity relationship
- **Duplicate data storage**: Template name and grocery item name store the same text (acceptable tradeoff for snapshot semantics)

### Neutral
- **M9.12 scope unchanged**: Category string → entity relationship remains planned post-launch
- **M9 overall scope reduced by ~3-4h**: M9.1's category utility extraction and `extractCleanIngredientName` centralization were completed during M15 bug fixes

---

## References

- M9 PRD: `docs/prds/m9-technical-debt-codebase-optimization.md` — M9.12 (lines 693-735)
- Insights Log: UX/TwoStepCreation, Parsing/ConfidenceSemantics, CoreData/GroceryItemName
- Bug fix commits: `a516a24` (category propagation), `c79a8fb` (plural normalization)
