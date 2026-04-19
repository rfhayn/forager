## Why

On cold app start, the Dashboard's **Meal Plan Overview card renders blank** (ghost state: "No meal plan this week. Tap to create one.") even when an active meal plan exists. The card populates only after the user navigates to the **Meals** tab once — at which point `MealPlansListView.onAppear` calls `updateActivePlanStatus()`, which triggers `loadActiveMealPlan()` internally, and the published `activeMealPlan` property finally updates.

This is a visible correctness bug observed during TestFlight validation of build 136 on 2026-04-19.

**Root cause — init-order race in the `MealPlanService.shared` singleton**:

1. `MealPlanService.shared` lazy-initializes on first access. Its `private init()` runs `loadActiveMealPlan()` immediately.
2. At that moment, `householdKeyProvider` is still `nil` (the default). The service's internal `householdKeyPredicate()` falls back to `NSPredicate(format: "householdKey == nil")`.
3. The user's actual meal plan has a non-nil `householdKey`, so the fetch returns `[]` and `activeMealPlan` is set to `nil`.
4. `foragerApp.init()` then wires the `householdKeyProvider` closure (at `foragerApp.swift:135`) and configures the factory (`:160`) — but nothing triggers a re-fetch, so `activeMealPlan` stays `nil`.
5. Dashboard renders; the card binds to `mealPlanService.activeMealPlan` which is `nil`; the ghost state shows.
6. When the user visits the Meals tab, `MealPlansListView.onAppear` calls `updateActivePlanStatus()` → `loadActiveMealPlan()`, which now runs with the correct household key and populates `activeMealPlan`. Subsequent Dashboard renders show the card.

`WeeklyListsView`'s Dashboard grocery-list card does NOT have this problem because it uses SwiftUI's `@FetchRequest` + in-memory `.filter` pattern — SwiftUI reactively re-renders when `householdService.currentHouseholdKey` changes, and the filter re-applies without any imperative reload. `MealPlanService.shared` is imperatively-cached, so it needs an explicit reload when the household key becomes available.

## What Changes

**Single-line fix in `forager/App/foragerApp.swift`** immediately after the `MealPlanService.shared.householdKeyProvider = ...` assignment (line ~135-137):

```swift
MealPlanService.shared.householdKeyProvider = { [weak household] in
    household?.currentHouseholdKey
}

// fix-dashboard-meal-plan-cold-start: reload active plan now that the
// household key is wired. Without this, init-time loadActiveMealPlan()
// ran with nil key and set activeMealPlan = nil; nothing triggered a
// re-fetch, so the Dashboard Meal Plan card stayed blank until the
// user visited the Meals tab.
MealPlanService.shared.loadActiveMealPlan()
```

One statement. Runs synchronously on the main actor during app init, after the provider closure is set. The re-fetch uses the correct scope predicate and populates `@Published activeMealPlan` before the Dashboard renders.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `meal-planning`: MODIFIED REQ — meal-plan-service active-plan load must use the configured household scope. Specifically: `MealPlanService` SHALL expose a public `loadActiveMealPlan()` method that can be called after `householdKeyProvider` is configured to re-fetch using the correct scope. The app entry point SHALL invoke this method after wiring the provider so that the first render of any UI binding to `activeMealPlan` observes the correct value.

## Impact

**Affected code** (1 file, 1 statement):
- `forager/App/foragerApp.swift` — one added line + multi-line comment, immediately after the `householdKeyProvider` assignment.

**No changes to**:
- `MealPlanService.swift` — the public `loadActiveMealPlan()` method already exists (called by `MealPlansListView.onAppear` via `updateActivePlanStatus()` and elsewhere). We're just invoking it one additional time at the right point.
- Schema, CloudKit config, factory, scope provider, any view code, Dashboard layout, meal plan logic.

**Behavior change**:
- Cold-start: Dashboard Meal Plan card shows the active plan immediately (correct), instead of showing the ghost state until Meals tab is visited.
- Warm-start / resume: no change — `activeMealPlan` is already populated from previous load.
- No household: no change — `loadActiveMealPlan()` with nil key returns nil-keyed plans (matches current behavior).

**Scope / non-goals**:
- Not refactoring `MealPlanService` away from singleton/imperative-cache pattern (the init-order coupling is a symptom of the singleton — proper fix is DI, tracked separately under `establish-test-planning-workflow` / future singleton-removal change).
- Not changing how `MealPlanListView` or `DashboardView` subscribe — `@Published activeMealPlan` on the shared service is the binding surface and continues to work as-is. The fix is strictly: "wire the provider, then reload once."

**Risk**: Near-zero. The fix invokes an existing method immediately after wiring its dependency. If the reload were to fail (e.g., Core Data fetch error), `activeMealPlan` would stay at whatever the init-time load set it to (nil) — which is the current behavior. No new failure modes introduced.

**Verification**:
- Build clean.
- Cold-start on TestFlight build 137: Dashboard Meal Plan card shows plan name on first render (not ghost state).
- No regression on warm-start or no-household-active paths.
