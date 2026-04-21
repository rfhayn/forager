## ADDED Requirements

### Requirement: Items added to a household-scoped list land in the same persistent store
When a user adds an item to a `WeeklyList` that belongs to a household (i.e., the list's `householdKey` is non-nil and its `objectID.persistentStore` resolves to a specific store), the newly-created `GroceryListItem` SHALL be assigned to the same persistent store as the list. A cross-store relationship between item and list (item in store A, list in store B) is a bug and MUST NOT occur in production.

This requirement codifies the invariant that the CloudKit mirroring delegate requires to route records correctly between the private-default zone and the CKShare-backed custom zone without triggering "Object graph corruption detected" (error 134040).

#### Scenario: Adding item to shared-store list
- **WHEN** a user on an owner or member device adds a grocery item to a `WeeklyList` whose `objectID.persistentStore` is the shared store
- **THEN** after save, the new item's `objectID.persistentStore` is also the shared store, AND the CloudKit mirroring delegate exports the item's CKRecord to the same zone as the list's CKRecord

#### Scenario: Adding item to personal-scope list
- **WHEN** a user adds a grocery item to a `WeeklyList` whose `householdKey` is nil (personal scope)
- **THEN** after save, the new item's `objectID.persistentStore` is the private store, AND `item.household` is nil, AND `item.householdKey` is nil

#### Scenario: Batch add from recipe preserves store alignment
- **WHEN** a user adds multiple ingredients from a recipe to a household-scoped grocery list in one operation
- **THEN** every created `GroceryListItem` lands in the list's persistent store, none land in a different store

#### Scenario: Staples batch add preserves store alignment
- **WHEN** a user adds one or more staple ingredient templates to a household-scoped grocery list
- **THEN** every created `GroceryListItem` lands in the list's persistent store

### Requirement: Launch-time diagnostic for CloudKit mirroring delegate failures
On app launch, if the CloudKit mirroring delegate fails to initialize with a "zone-assignment" class error (CoreData error 134040 or related "multiple zones" message), the app SHALL log a structured diagnostic entry via `DiagnosticLogger` naming the entity type, persistent ID fragment, and zone names in conflict. The diagnostic runs in both Debug and Release builds (Release logging gated through the production-appropriate path). No automatic remediation is performed; the diagnostic is intended to surface the state for manual triage.

#### Scenario: Mirroring delegate fails on launch
- **WHEN** `NSPersistentCloudKitContainer`'s mirroring delegate posts a failure notification with error 134040 during app launch
- **THEN** `DiagnosticLogger` records a structured entry (entity name, persistent ID, conflicting zone names, error code) AND the app does not crash

#### Scenario: Successful launch no-op
- **WHEN** the mirroring delegate initializes successfully
- **THEN** no diagnostic entry is written (the diagnostic path is silent on the happy path)
