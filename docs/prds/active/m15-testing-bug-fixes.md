# M15 Testing Bug Fixes PRD

**Status**: ACTIVE
**Created**: February 20, 2026
**Branch**: `feature/M15-ux-design-system`
**Context**: User testing on M15.5b build revealed 12 issues across parsing, display, data propagation, and styling

---

## Issues Found

### P0 — Data Loss

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | Editing recipe loses structured quantity fields (displayText blank after save) | `EditRecipeView.completeSave()` creates Ingredient entities but never calls `parseToStructured()` — unlike `CreateRecipeView` which does | Add structured field population matching CreateRecipeView pattern |

### P1 — Display Bugs

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 2 | Redundant right-aligned quantity on grocery items | `GroceryListDetailView` shows separate displayText column, but item.name already contains full text | Remove right-aligned displayText block |
| 3 | Redundant quantity+unit on recipe ingredient rows | `RecipeListView.ingredientRow()` shows separate qty Text + ingredient name Text | Remove separate qty Text; show full name at 1x, construct text from scaled qty at other factors |
| 4 | Quick option (Takeout/etc) text not struck through when completed | `MealPlanDetailView.plannedDayContent()` applies strikethrough to recipe text but not quick option text | Add `.strikethrough(meal.isCompleted)` to icon and text |
| 5 | Settings pure black background in dark mode | SettingsView missing `scrollContentBackground(.hidden)` + canvas background | Add pattern used by all other screens |
| 6 | Template name "/ black pepper" | `extractCleanIngredientName()` regex strips "1" and "4 tsp" separately from "1/4 tsp", leaving "/" | Fix regex to handle fraction patterns like `1/4` |
| 7 | Template name "cloves garlic" | Unit word "cloves" not in `extractCleanIngredientName()` measurement pattern | Add missing count units to regex |
| 8 | Template name "pound chicken breast" | Same issue — "pound" not in measurement pattern | Covered by same regex fix |
| 9 | Category chips stale after recategorization | `@FetchRequest` observes direct attribute changes on `GroceryListItem`, not relationship changes through `ingredientTemplate?.category` | Force refresh on appear |

### P1 — Data Integrity

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 13 | Duplicate ingredient templates created (e.g., two "carrot" entries) | `migrateExistingTemplates()` normalizes names but doesn't deduplicate collisions; `findOrCreateTemplate()` error fallback creates templates without checking pending context objects | Three-layer fix: (1) migration now groups by canonical name and merges collisions, (2) fallback path checks context pending objects, (3) new UI duplicate detection banner + guided merge sheet on Ingredients tab |
| 14 | Grocery items show warning badges and no quantities after adding from recipe | `GroceryListItem.name` stored template name ("garlic") not full text ("2 cloves garlic"); structured fields copied as zero when ingredient lacked them | Re-parse via `IngredientParsingService` when structured data missing; store full ingredient text in `listItem.name` |

### P2 — Not Changing (Documented Decisions)

| # | Issue | Decision |
|---|-------|----------|
| 10 | "Large title" left-aligned | iOS platform convention — not a bug |
| 11 | Template rename doesn't propagate to existing grocery items | `GroceryListItem.name` is a point-in-time snapshot; retroactive propagation requires migration. Documented as known limitation |
| 12 | Stale template names in existing items | Same as #11 — future consideration |

---

## Implementation Plan

### Commit 1: Fix EditRecipeView structured quantity loss (P0)
- **File**: `forager/EditRecipeView.swift`
- Add `parseToStructured()` call in `completeSave()` after line 618
- Populate: displayText, numericValue, standardUnit, isParseable, parseConfidence
- Pattern matches `CreateRecipeView.swift` lines 626-640

### Commit 2: Remove redundant quantity displays (P1)
- **File**: `forager/GroceryListDetailView.swift` — remove right-aligned displayText block
- **File**: `forager/RecipeListView.swift` — remove separate qty Text, show full `ingredient.name` at 1x scale, construct display from scaled data at other factors

### Commit 3: Fix takeout strikethrough + SettingsView dark mode (P1)
- **File**: `forager/MealPlanDetailView.swift` — add `.strikethrough(meal.isCompleted)` to quick option icon and text
- **File**: `forager/SettingsView.swift` — add `.scrollContentBackground(.hidden)` and `.background(ForagerTheme.backgroundCanvas.ignoresSafeArea())`

### Commit 4: Template name sanitization (P1)
- **File**: `Services/IngredientTemplateService.swift` — add Phase 0 sanitization (strip leading punctuation + residual unit words)
- **File**: `forager/MealPlanDetailView.swift` — fix `extractCleanIngredientName()` regex for fractions
- **File**: `forager/AddIngredientsToListView.swift` — add missing count units to regex
- **File**: `Services/Persistence/PersistenceController.swift` — wire up `migrateExistingTemplates()` in `performOneTimeSetup()`

### Commit 5: Fix category chip refresh + documentation (P1)
- **File**: `forager/WeeklyListsView.swift` — force `viewContext.refreshAllObjects()` on appear
- Documentation updates to current-story.md, insights-log.md

### Commit 6: Fix grocery items missing quantities and warnings (P1)
- **File**: `forager/AddIngredientsToListView.swift` — re-parse ingredients lacking structured data; store full text in `listItem.name`

### Commit 7: Fix duplicate template creation + add deduplication (P1)
- **File**: `Services/IngredientTemplateService.swift` — `migrateExistingTemplates()` now deduplicates; fallback path checks pending context objects; added `findDuplicateTemplates()` method

### Commit 8: Duplicate detection UI on Ingredients tab (P1)
- **File**: `forager/IngredientsView.swift` — duplicate banner matching review banner pattern, "Dupes (N)" filter pill, guided `DuplicateReviewSheet` with merge flow

---

## Acceptance Criteria

1. Edit a recipe → ingredients retain quantity display after save
2. Grocery list items show no redundant right-side quantity
3. Recipe detail at 1x and 2x shows clean single-line ingredients
4. Marking takeout as done → strikethrough appears on icon and text
5. Settings in dark mode → warm canvas background (not pure black)
6. Adding "3 cloves garlic" → template name is "garlic"
7. Adding "1/4 tsp black pepper" via meal plan → template name is "black pepper"
8. Recategorize items → return to list overview → category chips update
9. Add ingredients from recipe to grocery list → items show full text with quantities (not just template names)
10. If duplicate templates exist → yellow "Duplicates" banner appears on Ingredients tab
11. Tap "Review Now" on duplicate banner → guided merge sheet shows each group with keeper recommendation
12. Tap "Merge" → duplicates consolidated (relationships transferred, usage count summed, duplicate deleted)

---

## Known Limitations (Documented)

- **Template → grocery item name propagation**: `GroceryListItem.name` is set at creation time. Template renames cannot retroactively update existing items without a data migration. This is by design — grocery items are point-in-time snapshots.
- **Title alignment**: Large navigation titles are left-aligned per iOS platform convention.
