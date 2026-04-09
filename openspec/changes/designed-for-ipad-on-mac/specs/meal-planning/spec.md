## MODIFIED Requirements

### Requirement: Meal plan refresh
The system SHALL support refreshing meal plan data via pull-to-refresh on iOS and via a toolbar refresh button on Mac.

#### Scenario: Pull-to-refresh on iOS
- **WHEN** a user pulls down on the meal plans view on iOS
- **THEN** the list refreshes

#### Scenario: Toolbar refresh on Mac
- **WHEN** a user taps the refresh toolbar button on Mac
- **THEN** the meal plans refresh with the same behavior as pull-to-refresh

### Requirement: Meal planning views use NavigationStack
All meal-planning-related views presenting navigation hierarchy in sheets SHALL use `NavigationStack` instead of deprecated `NavigationView`.

#### Scenario: Create meal plan sheet
- **WHEN** the create meal plan sheet is presented
- **THEN** it uses `NavigationStack` for its navigation hierarchy
