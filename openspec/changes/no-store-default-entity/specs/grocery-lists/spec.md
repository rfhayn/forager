## MODIFIED Requirements

### Requirement: Store grouping uses "No Store" entity
When store grouping is enabled, items assigned to the "No Store" entity SHALL appear in a "No Store" group (using the entity name). Items with `store = nil` SHALL appear in a separate "Unassigned" group.

#### Scenario: Items with "No Store" entity
- **WHEN** store grouping is on and items are assigned to the "No Store" entity
- **THEN** they appear in a "No Store" group with gray color indicator

#### Scenario: Mix of assigned, No Store, and nil
- **WHEN** store grouping is on and items have a mix of specific stores, "No Store" entity, and nil
- **THEN** groups appear in order: specific stores (by sortOrder), then "No Store", then "Unassigned"
