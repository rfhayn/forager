# fix-dashboard-meal-plan-cold-start — Tasks

## Phase 1 — Apply fix

- [ ] Read `forager/App/foragerApp.swift` lines 130-140 to confirm the `MealPlanService.shared.householdKeyProvider = ...` assignment location
- [ ] Add one line immediately after the closure assignment: `MealPlanService.shared.loadActiveMealPlan()`
- [ ] Add a multi-line comment explaining the init-order race and why the reload is needed

## Phase 2 — Verification

- [ ] `xcodebuild build` — succeeds with 0 errors, 0 new warnings
- [ ] Manual smoke (simulator or TestFlight build 137): cold-launch app with an active meal plan, confirm Dashboard Meal Plan card shows the plan name on first render (not ghost state)
- [ ] Verify no regression on Meals tab (should still load/refresh on its own)
- [ ] Verify no regression on cold-start with no active meal plan (should show ghost state)

## Phase 3 — Ship

- [ ] Update `docs/current-story.md` with `fix-dashboard-meal-plan-cold-start` ACTIVE entry
- [ ] `/dev-journal` — Session 122 entry
- [ ] `/log-insight` — singleton init-order races with Combine publishers; Dashboard surfaces the gap because it's the landing tab
- [ ] `/commit` — doc-freshness gate should pass (proposal, tasks, journal, insights all modified in the branch)
- [ ] `/pr`
- [ ] After merge: `/opsx:archive fix-dashboard-meal-plan-cold-start`
- [ ] Bump build number + archive to TestFlight for cold-start verification (can pair with the next cumulative build after PR #146/#147 merge)
