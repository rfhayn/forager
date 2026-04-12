## MODIFIED Requirements

### Requirement: Store assignment distinguishes "No Store" from unassigned
When a user selects "No Store" in the assignment modal, the system SHALL assign the "No Store" entity (not nil). Items with `store = nil` are truly unassigned and MAY show assignment indicators.

#### Scenario: User explicitly chooses "No Store"
- **WHEN** the user taps "No Store" in StoreAssignmentModal or StoreChangeModal
- **THEN** the item's store is set to the "No Store" entity
- **THEN** the item is considered store-resolved (no assignment nudge)

#### Scenario: New item without store
- **WHEN** a new grocery list item is created without a specific store
- **THEN** the item's store is set to the "No Store" entity by default

#### Scenario: Truly unassigned item
- **WHEN** an item has `store = nil` (e.g., legacy data before migration)
- **THEN** the item appears in an "Unassigned" group in store grouping
