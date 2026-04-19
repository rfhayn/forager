## ADDED Requirements

### Requirement: Active meal plan reloads after household scope is configured

The app entry point SHALL invoke `MealPlanService.shared.loadActiveMealPlan()` immediately after wiring the service's `householdKeyProvider` closure. Without this invocation the service's eager init-time load runs with the default nil-key predicate and fails to populate `activeMealPlan` for users in a household; subsequent UI that binds to `activeMealPlan` (notably the Dashboard Meal Plan card) displays the ghost/empty state until some other event triggers a reload (e.g., `MealPlansListView.onAppear`).

#### Scenario: Cold-start with an active meal plan

- **WHEN** the app is cold-launched and the user is in a household with an active meal plan
- **THEN** `foragerApp.init()` wires `MealPlanService.shared.householdKeyProvider` AND immediately calls `MealPlanService.shared.loadActiveMealPlan()` AND the Dashboard Meal Plan card renders the active plan's name on first render (not the ghost state)

#### Scenario: Cold-start with no active meal plan

- **WHEN** the app is cold-launched and no active meal plan exists for the current scope
- **THEN** `activeMealPlan` is nil after the reload AND the Dashboard shows the ghost state ("No meal plan this week. Tap to create one.")

#### Scenario: Cold-start with no household

- **WHEN** the app is cold-launched and the user is not in any household (`householdKeyProvider` returns nil)
- **THEN** the reload fetches meal plans with `householdKey == nil` predicate AND populates `activeMealPlan` with the active personal-scope plan if any exists

#### Scenario: Warm-start (app resume)

- **WHEN** the app returns from background to foreground
- **THEN** no new invocation of `loadActiveMealPlan()` is required (the state is already populated from the previous load); existing on-resume refresh paths (e.g., `MealPlansListView.onAppear` when the user navigates to the Meals tab) continue to apply
