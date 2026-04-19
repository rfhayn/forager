# Spec: Meal Planning

## Overview

Calendar-based weekly meal planning that bridges recipe discovery and grocery list generation. Users assign recipes to dates within configurable planning periods, track meal completion, and generate grocery lists from meal plans with automatic ingredient aggregation and consolidation. The meal planning system is fully optional -- users can create grocery lists with or without it.

## Requirements

- REQ-001: The system MUST support creating meal plans with user-defined date ranges (configurable 3-14 day duration, default 7 days starting Sunday).
  - Scenario: Given the user taps "New Meal Plan", When they accept the default 7-day range starting next Sunday, Then a MealPlan entity is created with startDate and endDate spanning 7 days.

- REQ-002: The system MUST display a calendar view showing one week at a time with clear date headers and recipe assignments per day.
  - Scenario: Given a meal plan for Sept 16-22 with "Tacos" on Monday, When the user views the calendar, Then Monday shows "Tacos" and unassigned days show an add button, all rendering within 0.5 seconds.

- REQ-003: The system MUST support assigning recipes to dates via a RecipePickerSheet with search and servings adjustment.
  - Scenario: Given the user taps the add button on Wednesday, When RecipePickerSheet opens and they search "pasta" and select "Carbonara" with 4 servings, Then a PlannedMeal is created linking Carbonara to Wednesday.

- REQ-004: The system MUST support removing and moving recipe assignments within a meal plan.
  - Scenario: Given "Tacos" is assigned to Monday, When the user long-presses and selects "Move to Thursday", Then the PlannedMeal date updates and Monday shows empty.

- REQ-005: The system MUST generate a grocery list from a meal plan by aggregating all planned recipe ingredients with smart consolidation.
  - Scenario: Given a 7-day meal plan with 5 recipes totaling 30 ingredients, When the user taps "Generate Shopping List", Then a WeeklyList is created with consolidated items (duplicates merged), recipe source tags preserved, and progress overlay shown during generation.

- REQ-006: The system MUST support meal completion tracking by marking planned meals as completed with a completedDate.
  - Scenario: Given "Tacos" is planned for Monday, When the user marks it complete on Monday evening, Then PlannedMeal.completedDate is set and the calendar shows a completion indicator.

- REQ-007: The system MUST track recipe usage when recipes are assigned to meal plans, incrementing usageCount and updating lastUsed on the Recipe entity.
  - Scenario: Given "Carbonara" has usageCount=3, When it is assigned to a new meal plan, Then usageCount becomes 4 and lastUsed updates to the assignment date.

- REQ-008: The system MUST support scaled recipe quantities when generating grocery lists from meal plans, preserving the servings adjustment chosen during assignment.
  - Scenario: Given "Tacos (serves 4)" is planned with a 2x scaling (8 servings), When the grocery list generates, Then all Taco ingredients appear at 2x quantities with scale indicators.

- REQ-009: The system SHOULD auto-create the next meal plan when an active plan exists, with the start date set to the day after the previous plan ends.
  - Scenario: Given a completed meal plan ending Saturday Sept 22, When the user opens Meal Planning, Then the system suggests creating a new plan starting Sunday Sept 23.

- REQ-010: The system MUST support configurable meal planning preferences in Settings: default duration (3-14 days), start day (any day of week), auto-naming behavior, and recipe source display toggle.
  - Scenario: Given the user changes default start day to Monday in Settings, When they create a new meal plan, Then the default date range starts on the next Monday.

- REQ-011: The app entry point MUST invoke `MealPlanService.shared.loadActiveMealPlan()` immediately after wiring the service's `householdKeyProvider` closure. Without this invocation the service's eager init-time load runs with the default nil-key predicate and fails to populate `activeMealPlan` for users in a household; UI that binds to `activeMealPlan` (notably the Dashboard Meal Plan card) then displays a ghost/empty state until some other event triggers a reload. Source: `fix-dashboard-meal-plan-cold-start` (2026-04-19).
  - Scenario: Given the user is in a household with an active meal plan, When the app is cold-launched, Then `foragerApp.init()` wires `MealPlanService.shared.householdKeyProvider` AND immediately calls `loadActiveMealPlan()` AND the Dashboard Meal Plan card renders the active plan's name on first render (not the ghost state).
  - Scenario: Given no active meal plan exists for the current scope, When the app is cold-launched, Then `activeMealPlan` is nil after the reload AND the Dashboard shows the ghost state ("No meal plan this week. Tap to create one.").
  - Scenario: Given the user is not in any household (`householdKeyProvider` returns nil), When the app is cold-launched, Then the reload fetches meal plans with `householdKey == nil` predicate AND populates `activeMealPlan` with the active personal-scope plan if any exists.

## Implementation Notes

- Core entities: MealPlan (date range + name), PlannedMeal (date + recipe link + completedDate)
- MealPlan has an optional one-to-one relationship with WeeklyList for generated grocery lists
- PlannedMeal has a many-to-one relationship with Recipe
- Grocery list generation uses the same consolidation pipeline as manual recipe-to-list (QuantityMergeService)
- User preferences stored in UserPreferences Core Data entity (defaultMealPlanDuration, defaultStartDay, autoNameMealPlans, showRecipeSourceTags)
- MealPlan and PlannedMeal are HouseholdScoped and use ManagedObjectFactory.make() per ADR 014
