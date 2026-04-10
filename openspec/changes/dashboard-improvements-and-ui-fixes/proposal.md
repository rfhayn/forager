## Why

The dashboard feels empty when users don't have all three data types (meals, grocery lists, meal plans) because cards hide entirely when there's no data. Users don't discover the dashboard's value until they've already built up content elsewhere. Additionally, a full UI audit found dark mode contrast failures and inconsistent use of theme tokens across several views. These need to be fixed before App Store submission.

## What Changes

### Dashboard Content
- Always show 3 cards (Tonight's Meal, Shopping List, Meal Plan Overview) with "ghost card" pattern when empty: dashed outline, no background fill, actionable tap text
- Tonight's Meal ghost tap opens RecipeListView in a sheet; selecting a recipe auto-creates a meal plan if needed and assigns the recipe to today
- Shopping List ghost tap opens the existing create list dialog (From Staples / From Meal Plan / Empty List)
- Meal Plan ghost tap opens CreateMealPlanSheet
- Add 4th card (Tomorrow's Meal) that only appears when tomorrow has a meal in the active plan (no ghost state)
- Center the quick action buttons (currently left-justified)

### Dashboard Background
- Change DashboardView background from `backgroundPrimary` to `backgroundCanvas` to match all other tabs

### UI Consistency Fixes
- Replace `.white` with `ForagerTheme.buttonPrimaryText` on accent backgrounds (3 locations) to fix dark mode contrast failure
- Replace system colors (`Color(.systemGray6)`, `Color(.systemBackground)`, `Color(.systemGray4)`) with theme tokens in SelectListSheet (3 locations)
- Replace hardcoded fonts with ForagerTheme tokens (4 locations across MealPlanDetailView and SelectListSheet)
- Fix DashboardView hardcoded font size

## Capabilities

### New Capabilities
- `dashboard-ghost-cards`: Ghost card UI pattern, recipe quick-assign from dashboard (auto-create meal plan + assign recipe to today), always-visible dashboard tiles

### Modified Capabilities
- `meal-planning`: Dashboard can auto-create a meal plan and assign a recipe to today without navigating to the Meal Plans tab
- `grocery-lists`: Dashboard ghost card triggers the existing create list flow

## Impact

- **DashboardView.swift**: Major rework (ghost cards, new card states, tomorrow card, centered quick actions, background fix, font fix)
- **MealPlanService.swift**: New method to auto-create a meal plan and assign a recipe to a specific date
- **MealPlanDetailView.swift**: Dark mode contrast fixes (3 lines), font fix (1 line)
- **MealPlanListView.swift**: Dark mode contrast fix (1 line)
- **SelectListSheet.swift**: System colors replaced with theme tokens (3 lines), font fixes (2 lines)
- **ForagerTheme or new modifier**: Ghost card style (dashed border, no fill, themed text)
- **No Core Data changes, no schema changes**
