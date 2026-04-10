## MODIFIED Requirements

### Requirement: Grocery list refresh
The system SHALL support refreshing grocery list data via pull-to-refresh on iOS and via a toolbar refresh button on Mac.

#### Scenario: Pull-to-refresh on iOS
- **WHEN** a user pulls down on the grocery lists view on iOS
- **THEN** the list refreshes

#### Scenario: Toolbar refresh on Mac
- **WHEN** a user taps the refresh toolbar button on Mac
- **THEN** the grocery lists refresh with the same behavior as pull-to-refresh

### Requirement: Grocery list views use NavigationStack
All grocery-list-related views presenting navigation hierarchy in sheets SHALL use `NavigationStack` instead of deprecated `NavigationView`.

#### Scenario: Add item sheet
- **WHEN** the add list item sheet is presented
- **THEN** it uses `NavigationStack` for its navigation hierarchy
