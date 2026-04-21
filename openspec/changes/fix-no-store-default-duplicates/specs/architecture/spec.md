## ADDED Requirements

### Requirement: Default-entity deduplication pattern
When a Core Data entity supports a scope-based protected "default" row (e.g., `Store` with `isDefault == YES`, `Category` "Uncategorized") and that default is seeded on app launch, the system SHALL provide a deduplicator service that collapses duplicate rows to a single keeper per semantic group. The deduplicator SHALL run on `NSPersistentStoreRemoteChange` notifications (handled by `CloudKitSyncMonitor`) to reconcile duplicates created by CloudKit sync races between app instances.

The pattern exists today for `Category` (`CategoryDeduplicator`, M7.2.3 Phase 3.8). This requirement formalizes the pattern and extends it to `Store`.

#### Scenario: Duplicate rows are collapsed to the oldest keeper
- **WHEN** a deduplicator runs and finds 2+ rows matching the same semantic group (by grouping key)
- **THEN** the row with the oldest `dateCreated` is retained as the keeper, and the remaining rows are deleted

#### Scenario: Deduplication is idempotent
- **WHEN** a deduplicator runs against a data set with no duplicates (or runs a second time after a successful first run)
- **THEN** no rows are deleted and no errors are raised

#### Scenario: Remote-change trigger fires deduplication
- **WHEN** `CloudKitSyncMonitor` receives an `NSPersistentStoreRemoteChange` notification
- **THEN** all registered deduplicators run on a background context in sequence via `runAllDeduplication()`

### Requirement: Deduplication preserves child relationships without a safety net
When a deduplicator deletes a duplicate row whose child entities depend on the relationship (i.e., no Uncategorized-style safety-net default exists), the deduplicator SHALL re-parent those children to the keeper before deleting the duplicate. Pure `nullify` delete rules MUST NOT be relied on for entities without a safety-net default, because nullifying silently drops user-assigned preferences.

`Category`'s deduplicator CAN rely on `nullify` because every `IngredientTemplate` has "Uncategorized" as a safety-net fallback. `Store`'s deduplicator CANNOT rely on `nullify` because no equivalent safety net exists; a null `preferredStore` or `store` would be a user-visible regression.

#### Scenario: Store duplicate deletion re-parents templates and grocery items
- **WHEN** `StoreDeduplicator` deletes a duplicate `Store`
- **THEN** every `IngredientTemplate` with `preferredStore == duplicate` is updated so `preferredStore == keeper` before the duplicate is deleted
- **AND** every `GroceryListItem` with `store == duplicate` is updated so `store == keeper` before the duplicate is deleted

#### Scenario: Category duplicate deletion does NOT need explicit re-parenting
- **WHEN** `CategoryDeduplicator` deletes a duplicate `Category`
- **THEN** Core Data's nullify delete rule nulls the reference, and `IngredientTemplate` falls through to `Uncategorized` for display — which is the designed safety-net behavior

### Requirement: Deduplicator grouping key includes scope-distinguishing dimensions
A deduplicator's grouping key SHALL include every dimension on which two rows are semantically distinct, not just the display name. Two rows with the same name but different `householdKey` (personal vs household) or different `isDefault` flag (user-created vs protected default) MUST survive as separate rows.

#### Scenario: Personal-scope and household-scope rows are not deduped together
- **WHEN** the data set contains a personal-scope `Category` "Meat" (`householdKey == nil`) and a household-scope `Category` "Meat" (`householdKey == <uuid>`)
- **THEN** both rows survive; the deduplicator treats them as different groups via the `householdKey` component of the grouping key

#### Scenario: Protected default and user-created row with same name are not deduped together
- **WHEN** the data set contains a protected `Store` named "No Store" (`isDefault == YES`) and a user-created `Store` named "No Store" (`isDefault == NO`) at the same scope
- **THEN** both rows survive; `StoreDeduplicator`'s grouping key includes the `isDefault` component
