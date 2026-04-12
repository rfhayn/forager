## MODIFIED Requirements

### Requirement: Grocery list section headers render inside cards
Section headers (category names and store names) SHALL render as the first row inside each insetGrouped section card, on the card surface background. Headers SHALL NOT float on the canvas background between cards.

#### Scenario: Expanded section in light mode
- **WHEN** a category section is expanded in light mode
- **THEN** the header row and item rows appear in one unified card
- **THEN** a thin divider separates the header from the items
- **THEN** the header text is readable on the card surface

#### Scenario: Collapsed section
- **WHEN** a category section is collapsed
- **THEN** only the header row appears as a single-row card (chevron + title + count badge)

#### Scenario: Store grouping mode
- **WHEN** store grouping is enabled
- **THEN** store headers and category headers both render inside their respective section cards
