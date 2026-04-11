## Context

The DashboardView (FUI-1.7/1.8) currently has three conditional cards (Next Meal, Grocery Run, Meal Plan Overview) that hide when no data exists, plus a welcome card shown only when ALL three are empty. The result: users with partial data (e.g., a shopping list but no meal plan) see a sparse dashboard that doesn't communicate the app's full value. A UI audit also revealed dark mode contrast failures and system color usage that breaks theme consistency.

Current DashboardView structure: ScrollView > VStack with conditional card rendering. Cards use `surfacePrimary` background with `ForagerTheme.Radius.lg` corners. Quick action buttons are in an HStack with `.leading` alignment inherited from the parent VStack.

## Goals / Non-Goals

**Goals:**
- Dashboard always shows 3 cards (Tonight's Meal, Shopping List, Meal Plan) with ghost/solid states
- Ghost cards invite action with contextual tap targets
- Recipe quick-assign from dashboard (pick recipe, auto-create/find meal plan, assign to today)
- Optional 4th card (Tomorrow's Meal) when data exists
- Centered quick action buttons
- Consistent background color across all tabs
- Fix all dark mode contrast and theme token issues found in audit

**Non-Goals:**
- Recipe Spotlight / discovery card (deferred, was cut from FUI-1.7)
- Drag-to-reorder cards
- Customizable dashboard layout
- New Core Data entities or schema changes
- Animations between ghost and solid states (nice-to-have, not required)

## Decisions

### 1. Ghost card style: dashed border with `borderSubtle` color, no background fill

Use `RoundedRectangle` with `.stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))` in `ForagerTheme.borderSubtle` color. No background fill (transparent, showing `backgroundCanvas` through). Content uses `textTertiary` for the message and `accentPrimary` for the action text. Same corner radius and padding as solid cards for height consistency.

**Alternative considered**: Lighter solid fill with dashed border. Rejected because the transparency makes the "empty" state visually distinct from filled cards at a glance.

### 2. Recipe quick-assign: new MealPlanService method, not a new service

Add `assignRecipeToToday(recipe:)` to `MealPlanService`. This method:
1. Checks for an active meal plan covering today
2. If none, creates one using the standard naming convention and user's preferred duration/start day from settings
3. Adds the recipe as a PlannedMeal for today (default meal type: dinner, since it's the most common use case)
4. Returns the created/updated meal plan

Uses existing `ManagedObjectFactory.make()` for PlannedMeal creation (ADR 014). The method runs through `PersistenceController.performScopedWrite()` for correct store assignment.

**Alternative considered**: Creating a separate `DashboardActionService`. Rejected because the logic is purely meal plan manipulation, which belongs in MealPlanService.

### 3. Recipe picker: present full RecipeListView in a sheet

Present `RecipeListView` in a `.sheet` with a selection callback. The existing view already has grid/list toggle, import menu, and search. Add an optional `onSelect: ((Recipe) -> Void)?` parameter; when non-nil, tapping a recipe calls the callback and dismisses instead of navigating to detail.

**Alternative considered**: Simplified picker with just a list. Rejected because the user explicitly wants the full RecipeListView (option B), and it allows importing a new recipe on the spot.

### 4. Shopping list ghost card: reuse existing create dialog

The ghost card tap sets `showingCreateOptions = true` on DashboardView, which presents the same `confirmationDialog` used in WeeklyListsView: "From Staples", "From Meal Plan", "Empty List". The actual list creation logic is already in WeeklyListsView/WeeklyListService. DashboardView navigates to the Lists tab after creation.

### 5. Tomorrow's Meal card: completely hidden when no data

No ghost state for tomorrow. It appears below the Meal Plan Overview card only when the active meal plan has a PlannedMeal for tomorrow's date. Same solid card style as Tonight's Meal but with "Tomorrow" header.

### 6. UI fixes: mechanical token replacements

All UI audit fixes are direct token swaps:
- `.white` → `ForagerTheme.buttonPrimaryText` (adapts: white in light, dark in dark)
- `Color(.systemGray6)` → `ForagerTheme.backgroundSecondary`
- `Color(.systemBackground)` → `ForagerTheme.surfacePrimary`
- `Color(.systemGray4)` → `ForagerTheme.borderSubtle`
- Hardcoded fonts → `ForagerTheme.captionFont`, `.bodyFont`, `.secondaryFont`

## Risks / Trade-offs

- **[Risk] RecipeListView in selection mode might have import side effects** → The import flow saves a recipe; if the user imports + selects, the recipe is saved AND assigned to today. This is actually fine and expected behavior.
- **[Risk] Auto-created meal plan might conflict with existing plan** → `assignRecipeToToday` checks for an active plan first. Only creates if none covers today.
- **[Risk] Ghost cards add height, might require scrolling on small screens** → Ghost cards use same height as solid cards. Three cards + quick actions fit on iPad/Mac screens. On iPhone SE, minor scrolling is acceptable.
- **[Trade-off] Quick action buttons still useful after ghost cards** → Ghost cards provide direct entry points, but quick actions serve a different purpose (tab navigation shortcuts). Keep both.
