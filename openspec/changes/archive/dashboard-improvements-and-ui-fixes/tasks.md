## 1. UI Consistency Fixes (audit findings)

- [x] 1.1 Replace `.white` with `ForagerTheme.buttonPrimaryText` in MealPlanDetailView:214 (TODAY circle text)
- [x] 1.2 Replace `.white` with `ForagerTheme.buttonPrimaryText` in MealPlanDetailView:504 (Add to Grocery List button)
- [x] 1.3 Replace `.white` with `ForagerTheme.buttonPrimaryText` in MealPlanListView:377 (day dots)
- [x] 1.4 Replace `Color(.systemGray6)` with `ForagerTheme.backgroundSecondary` in SelectListSheet:103
- [x] 1.5 Replace `Color(.systemBackground)` with `ForagerTheme.surfacePrimary` in SelectListSheet:184
- [x] 1.6 Replace `Color(.systemGray4)` with `ForagerTheme.borderSubtle` in SelectListSheet:188
- [x] 1.7 Replace hardcoded `.caption2` with `ForagerTheme.captionFont` in MealPlanDetailView:482
- [x] 1.8 Replace `.body` and `.subheadline` with theme fonts in SelectListSheet:127-138
- [x] 1.9 Replace hardcoded font `size: 11` with `ForagerTheme.captionFont` in DashboardView:428

## 2. Dashboard Background Fix

- [x] 2.1 Change DashboardView background from `ForagerTheme.backgroundPrimary` to `ForagerTheme.backgroundCanvas`

## 3. Ghost Card Style

- [x] 3.1 Create ghost card ViewModifier or helper view: dashed RoundedRectangle border (borderSubtle), no fill, same padding/radius as solid cards, textTertiary message, accentPrimary action text

## 4. Dashboard Card Refactor — Always Visible

- [x] 4.1 Refactor Tonight's Meal card to always show: solid when meal exists, ghost with "No recipe for today. Tap to pick one." when empty
- [x] 4.2 Refactor Shopping List card to always show: solid when list exists, ghost with "No shopping list. Tap to create one." when empty
- [x] 4.3 Refactor Meal Plan Overview card to always show: solid when plan exists, ghost with "No meal plan this week. Tap to create one." when empty
- [x] 4.4 Remove the welcome card (no longer needed since ghost cards always show)
- [x] 4.5 Remove `hasContent` conditional — cards always render

## 5. Tomorrow's Meal Card

- [x] 5.1 Add Tomorrow's Meal card below Meal Plan Overview — only renders when active plan has a PlannedMeal for tomorrow, no ghost state. Shows recipe name, servings, cook time with "Tomorrow" header.

## 6. Tonight's Meal — Recipe Quick-Assign

- [x] 6.1 Add `assignRecipeToToday(recipe:)` method to MealPlanService: finds active plan covering today or creates new one (standard naming, default duration/start day), adds recipe as PlannedMeal for today (default meal type: dinner), uses factory per ADR 014
- [x] 6.2 Add RecipeListView selection mode: optional `onSelect: ((Recipe) -> Void)?` parameter. When non-nil, tapping a recipe calls the callback and dismisses instead of navigating to detail.
- [x] 6.3 Wire ghost card tap: present RecipeListView in sheet with onSelect callback → call assignRecipeToToday → dismiss sheet

## 7. Shopping List Ghost Card Action

- [x] 7.1 Wire Shopping List ghost card tap to show create list confirmation dialog (From Staples / From Meal Plan / Empty List) — reuse same logic as WeeklyListsView

## 8. Meal Plan Ghost Card Action

- [x] 8.1 Wire Meal Plan ghost card tap to present CreateMealPlanSheet

## 9. Quick Actions Centering

- [x] 9.1 Center the quick action buttons HStack (remove inherited leading alignment)

## 10. Build and Verify

- [x] 10.1 Build iOS target — confirm zero errors
- [x] 10.2 Visual check: light mode dashboard with ghost cards, solid cards, mixed states
- [x] 10.3 Visual check: dark mode — verify contrast on all accent buttons and ghost card borders
