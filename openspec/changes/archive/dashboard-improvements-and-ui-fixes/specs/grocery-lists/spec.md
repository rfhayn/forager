## MODIFIED Requirements

### Requirement: Create grocery list from dashboard
The dashboard Shopping List ghost card SHALL trigger the same create list flow as WeeklyListsView, presenting options: "From Staples", "From Meal Plan", "Empty List".

#### Scenario: Create from dashboard
- **WHEN** the user taps the Shopping List ghost card on the dashboard
- **THEN** the create list confirmation dialog appears with "From Staples", "From Meal Plan", and "Empty List" options

#### Scenario: List created successfully
- **WHEN** the user completes list creation from the dashboard
- **THEN** the Shopping List card transitions from ghost to solid showing the new list
