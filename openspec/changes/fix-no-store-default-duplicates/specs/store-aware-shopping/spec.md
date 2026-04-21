## ADDED Requirements

### Requirement: Protected "No Store" default exists as exactly one row per scope
At any given time, a user's personal scope (`householdKey == nil`) SHALL contain exactly one `Store` entity matching the protected-default predicate (`isDefault == YES AND name == "No Store"`). The same invariant SHALL hold for each household scope (`householdKey == <uuid>`) the user participates in.

Duplicates can arise from CloudKit sync races between app instances or from household create/leave cycles that clone store data. A deduplication safety net (`StoreDeduplicator`) SHALL collapse duplicates on remote-change notifications so the invariant is restored without user intervention.

#### Scenario: Fresh install on a device with existing CloudKit data
- **WHEN** the app is installed on a device whose iCloud account already has `Store` data from a prior install
- **THEN** after the first remote-change sync event, exactly one row matching `(isDefault == YES, name == "No Store", householdKey == nil)` exists

#### Scenario: Household creation does not duplicate existing "No Store" into the household
- **WHEN** a user with personal-scope "No Store" creates a new household via the "create empty then copy" flow
- **THEN** the copied household-scope "No Store" set contains exactly one row, regardless of how many personal-scope "No Store" rows existed at the moment of creation
- **AND** `HouseholdService.copyPersonalDataToHousehold` applies a name-dedupe guard on Store (matching `migrateHouseholdDataToPersonal`'s existing guard) before cloning personal-scope Stores into the household

#### Scenario: Existing duplicates on an upgraded device are cleaned
- **WHEN** a device has multiple existing `isDefault == YES, name == "No Store"` rows at the same scope (from pre-change corruption)
- **THEN** after upgrading to the build containing `StoreDeduplicator` and triggering a remote-change event (or launching the app if launch-time invocation is enabled as a fallback), the device's Store list shows exactly one "No Store" row at that scope
- **AND** every `IngredientTemplate` or `GroceryListItem` that pointed at a deleted duplicate now points at the keeper (no nulled `preferredStore` or `store`)

### Requirement: Manage Stores UI lock remains correct under deduplication
The UI lock on protected default rows (`isDefault == YES`) SHALL continue to prevent user-initiated deletion, AND SHALL continue to prevent user-initiated name edits that would violate the protected-default name invariant. Deduplication is a system-level safety net, not a user-facing delete mechanism.

#### Scenario: Locked row remains locked after deduplication
- **WHEN** the deduplicator collapses duplicates down to the keeper
- **THEN** the surviving keeper row retains `isDefault == YES` and remains locked in the Manage Stores UI (no UI-visible change to the user; the list simply shows fewer "No Store" rows)
