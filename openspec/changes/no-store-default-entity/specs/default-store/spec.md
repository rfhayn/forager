## ADDED Requirements

### Requirement: Store entity has isDefault flag
The Store entity SHALL have an `isDefault: Bool` attribute that identifies the protected default store. Only one store per household SHALL have `isDefault = true`.

#### Scenario: Schema migration
- **WHEN** the app launches with schema v11 data
- **THEN** lightweight migration adds `isDefault` attribute with default value `false` to all existing stores

### Requirement: "No Store" entity seeded on first launch
The system SHALL seed a "No Store" Store entity on first launch with `isDefault = true`, gray color (#9E9E9E), sortOrder 999. This entity SHALL be created during the same seeding pass as default categories.

#### Scenario: Fresh install
- **WHEN** the app launches for the first time
- **THEN** a "No Store" entity is created alongside default categories

#### Scenario: Reinstall / new device
- **WHEN** the app launches and no default store exists locally
- **THEN** `ensureNoStoreExists()` creates the "No Store" entity before any store operations

### Requirement: Default store protected from deletion and renaming
The "No Store" entity SHALL NOT be deletable or renamable by the user. It SHALL always appear in the store management view.

#### Scenario: User attempts to delete default store
- **WHEN** the user tries to delete the "No Store" entry in ManageStoresView
- **THEN** the delete action is not available or is blocked

#### Scenario: User attempts to rename default store
- **WHEN** the user tries to rename the "No Store" entry
- **THEN** the rename action is not available or is blocked
