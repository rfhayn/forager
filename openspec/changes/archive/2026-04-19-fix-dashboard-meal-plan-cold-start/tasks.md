# fix-dashboard-meal-plan-cold-start — Tasks

## Phase 1 — Apply fix

- [x] Read `forager/App/foragerApp.swift` lines 130-140 to confirm the `MealPlanService.shared.householdKeyProvider = ...` assignment location
- [x] Add one line immediately after the closure assignment: `MealPlanService.shared.loadActiveMealPlan()`
- [x] Add a multi-line comment explaining the init-order race and why the reload is needed

## Phase 2 — Verification

- [x] `xcodebuild build` — succeeds with 0 errors, 0 new warnings
- [x] Manual smoke (simulator or TestFlight build 137): cold-launch app with an active meal plan, confirm Dashboard Meal Plan card shows the plan name on first render (not ghost state)
- [x] Verify no regression on Meals tab (should still load/refresh on its own)
- [x] Verify no regression on cold-start with no active meal plan (should show ghost state)

## Phase 3 — Ship

- [x] Update `docs/current-story.md` with `fix-dashboard-meal-plan-cold-start` ACTIVE entry
- [x] `/dev-journal` — Session 122 entry
- [x] `/log-insight` — singleton init-order races with Combine publishers; Dashboard surfaces the gap because it's the landing tab
- [x] `/commit` — doc-freshness gate should pass (proposal, tasks, journal, insights all modified in the branch)
- [x] `/pr`
- [x] After merge: `/opsx:archive fix-dashboard-meal-plan-cold-start`
- [x] Bump build number + archive to TestFlight for cold-start verification (can pair with the next cumulative build after PR #146/#147 merge)
