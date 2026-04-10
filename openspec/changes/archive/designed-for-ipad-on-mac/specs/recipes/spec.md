## MODIFIED Requirements

### Requirement: Recipe import sources
The system SHALL offer recipe import via URL paste, text paste, in-app browser, and photo import. On Mac (`ProcessInfo.processInfo.isiOSAppOnMac == true`), the document scanner option SHALL be hidden since camera hardware is unavailable.

#### Scenario: Import menu on iOS
- **WHEN** a user opens the recipe import menu on iOS
- **THEN** all import options are available: Browse, Paste URL, Paste Text, Import from Photo (with scanner)

#### Scenario: Import menu on Mac
- **WHEN** a user opens the recipe import menu on Mac
- **THEN** Browse, Paste URL, Paste Text, and Import from Photo (library only) are available
- **THEN** document scanner is NOT shown

### Requirement: Recipe views use NavigationStack
All recipe-related views presenting navigation hierarchy in sheets SHALL use `NavigationStack` instead of deprecated `NavigationView`.

#### Scenario: Create recipe sheet
- **WHEN** the create recipe sheet is presented
- **THEN** it uses `NavigationStack` for its navigation hierarchy

#### Scenario: Edit recipe sheet
- **WHEN** the edit recipe sheet is presented
- **THEN** it uses `NavigationStack` for its navigation hierarchy
