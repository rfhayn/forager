## Context

`MealPlanService` is a `@MainActor` singleton (`MealPlanService.shared`, `private init()`) that exposes `@Published var activeMealPlan: MealPlan?` for SwiftUI views to bind to. The service is responsible for loading the currently active meal plan by fetching `MealPlan` entities with `isActive == YES` AND the household-scope predicate.

The household-scope predicate is built from a `householdKeyProvider: (() -> String?)?` closure wired by the app entry point. When the closure is nil (default), the predicate falls back to `householdKey == nil`.

The singleton's `init()` calls `loadActiveMealPlan()` eagerly. Because `.shared` is accessed during `foragerApp.init()` before `householdKeyProvider` is wired, the init-time load runs with the nil-key predicate and returns an empty result for users in a household. `activeMealPlan` stays `nil`.

The fix: after wiring the provider, call `loadActiveMealPlan()` one more time so the fetch runs with the correct scope.

### Why this surfaced now

The Dashboard introduced a `mealPlanOverviewCard` that binds to `mealPlanService.activeMealPlan` (added in FUI-1.7). Prior to Dashboard, meal-plan state was only shown on the Meals tab, whose `.onAppear` reliably reloaded on every visit. Dashboard is now the landing tab, so users see a `nil` `activeMealPlan` before anything reloads it. The bug was always present in the service's load flow — the Dashboard exposed it.

### Why the grocery-list card doesn't have this bug

`WeeklyListsView` uses `@FetchRequest` + in-memory `.filter { $0.householdKey == currentKey }`. SwiftUI reactively re-renders the view when `householdService.currentHouseholdKey` changes (via `@EnvironmentObject` observation), and the filter re-applies. No imperative reload needed. Contrast with `MealPlanService.shared.activeMealPlan` which is set imperatively and cached.

## Goals / Non-Goals

**Goals**:
- Dashboard Meal Plan card renders the active plan on first render after cold start.
- No behavior change for warm-start, no-household, or post-switch household scenarios.
- One-statement fix — minimum reviewable surface.

**Non-Goals**:
- Refactoring `MealPlanService` away from singleton. Larger change; tracked elsewhere.
- Observing `householdService.currentHouseholdKey` changes inside the service to auto-reload. More powerful but more surface area; singleton-removal is the right long-term seam.
- Changing how Dashboard subscribes to meal-plan state.
- Addressing the other 6 newly-exposed assertion failures from PR #147 — those are a separate investigation (see `investigate-import-and-store-test-failures`).

## Decisions

### Decision 1 — Trigger reload at app-init wiring point, not from Dashboard `.onAppear`

**Chosen**: add `MealPlanService.shared.loadActiveMealPlan()` in `foragerApp.init()` immediately after the `householdKeyProvider` assignment.

**Alternatives**:
- Add `.onAppear { mealPlanService.loadActiveMealPlan() }` on the Dashboard's `mealPlanOverviewCard`. Rejected — puts the fix in the wrong place. The underlying bug is an init-order issue in the service wiring; fixing it at the Dashboard would be treating the symptom, and every new view that binds to `activeMealPlan` would need the same workaround.
- Change `MealPlanService.init()` to defer `loadActiveMealPlan()` until `householdKeyProvider` is set. Rejected — more machinery (state tracking, deferred invocation) for the same outcome. The wiring order in `foragerApp.init()` is deterministic; a plain re-invocation is simpler.
- Observe `householdKeyProvider` changes internally (KVO-style). Rejected — closures aren't observable; would require refactoring to a separate `@Published` key or a dedicated observer pattern. Out of scope.

**Rationale**: the app-init wiring point is where the dependency graph is assembled. Once the provider is set, re-invoking the load is the correct completion of the configuration. The change is local to the wiring code that already knows about the init-order.

### Decision 2 — Don't add a new method; reuse the public `loadActiveMealPlan()`

**Chosen**: invoke the existing public method by name.

**Alternatives**:
- Add a new `reconfigureActiveMealPlan()` method with more explicit semantics. Rejected — `loadActiveMealPlan()` is already the right verb. Renaming or adding an alias is noise.
- Add a parameter to `householdKeyProvider` setter to auto-trigger reload. Rejected — makes the setter non-trivial, couples the setter to the published state.

**Rationale**: `loadActiveMealPlan()` already does the right thing; the only missing piece is invoking it at the right time.

### Decision 3 — Ship as standalone change (not folded into `architecture-compliance-sweep`)

**Chosen**: separate change / branch / PR.

**Alternatives**:
- Fold into PR #146 (`architecture-compliance-sweep`). Rejected — PR #146 is already open, smoke-tested, waiting for merge. Adding unrelated fix churns review. Cleaner to ship this independently and cumulatively bump build 137 from main after both merge.
- Fold into a later "Dashboard polish" change. Rejected — this is a correctness bug, not polish. Ship now.

**Rationale**: the principle "one change = one branch = one PR = one squash commit" applies. This is one bug with one cause and one fix — its own PR.

## Risks / Trade-offs

- **Risk**: Re-invoking `loadActiveMealPlan()` does a second Core Data fetch at app init. → **Mitigation**: negligible. The fetch is a single `fetchLimit: 1` query with `fetchLimit: 1`. Measured performance target per the method doc: <0.1s. Running it twice (once with nil key, once with correct key) is sub-millisecond combined.

- **Risk**: If `householdKeyProvider` returns nil (e.g., user not in a household), the reload fetches `householdKey == nil` — which matches the init-time behavior. → **Accepted**: correct behavior for personal-scope users. No regression.

- **Risk**: If the fetch errors, `activeMealPlan` stays at whatever init-time set it to (nil). → **Accepted**: same behavior as today.

- **Trade-off**: Leaves the deeper singleton-coupling issue in place. → **Accepted**: this change fixes the user-visible symptom with minimal disruption. The long-term DI refactor is tracked in the `establish-test-planning-workflow` plan and can happen without blocking launch or polish cycles.

## Migration Plan

1. Single feature branch off main. One commit. One squash merge.
2. No data migration. No schema change.
3. After merge, Rich can bump build 137 (or whatever the next available build number is) and archive for TestFlight re-verification. The manual check: cold-launch the app from a killed state (not background), go to Dashboard, verify the Meal Plan card shows the active plan name immediately.

## Open Questions

None. The fix is deterministic.
