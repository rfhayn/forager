## ADDED Requirements

### Requirement: Auto-create meal plan and assign recipe from dashboard
MealPlanService SHALL provide a method to assign a recipe to today, auto-creating a meal plan if none exists covering today's date.

#### Scenario: No active meal plan
- **WHEN** `assignRecipeToToday(recipe:)` is called and no meal plan covers today
- **THEN** a new meal plan is created with standard naming convention, default duration from user settings, and the recipe is added as a PlannedMeal for today with default meal type dinner

#### Scenario: Active meal plan exists
- **WHEN** `assignRecipeToToday(recipe:)` is called and an active meal plan covers today
- **THEN** the recipe is added as a PlannedMeal for today in the existing plan

#### Scenario: Factory enforcement
- **WHEN** a PlannedMeal or MealPlan is created by this method
- **THEN** it uses `ManagedObjectFactory.make()` per ADR 014
