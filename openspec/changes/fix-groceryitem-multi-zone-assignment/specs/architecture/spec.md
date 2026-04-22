## ADDED Requirements

### Requirement: Child HouseholdScoped entities explicitly assigned to parent store
When creating a child HouseholdScoped entity (`GroceryListItem`, `Ingredient`) that inherits its household relationship from a parent entity (`WeeklyList`, `Recipe`), the creation site SHALL explicitly assign the new object to the parent's persistent store via `context.assign(object, to: parentStore)` before the first save. Relying on Core Data's implicit store inference from subsequently-set relationships is insufficient under CloudKit dual-store mirroring and MAY cause zone-conflict crashes (error 134040 "Object graph corruption detected").

The child-inheritance pattern documented in ADR 014 remains valid; this requirement makes the store-assignment step that pattern implicitly assumed into an explicit code obligation.

#### Scenario: GroceryListItem creation in shared-store scope
- **WHEN** code creates a `GroceryListItem` as a child of a `WeeklyList` whose `objectID.persistentStore` is the shared store
- **THEN** the site calls `context.assign(item, to: list.objectID.persistentStore)` before setting any relationship or calling `context.save()`, and the resulting item's `objectID.persistentStore` matches the list's store after save

#### Scenario: Ingredient creation in shared-store recipe
- **WHEN** code creates an `Ingredient` as a child of a `Recipe` whose `objectID.persistentStore` is the shared store
- **THEN** the site calls `context.assign(ingredient, to: recipe.objectID.persistentStore)` before the first save, and the resulting ingredient lands in the same store as the recipe

#### Scenario: Fallback when parent has no store
- **WHEN** code creates a child entity whose parent has no persistent store (e.g., unsaved in-memory parent)
- **THEN** the site falls back to assigning the child to the persistent store coordinator's first store (matching Core Data's default behavior) AND logs the fallback via DiagnosticLogger so the pattern can be audited

#### Scenario: Test and preview contexts exempt
- **WHEN** the context is an in-memory test context or preview context with only one persistent store
- **THEN** the `context.assign()` call is still made but is effectively a no-op; tests do not need to mock multi-store behavior

### Requirement: Architecture audit detects direct child creation without assign
The `/architecture-audit` skill SHALL flag any production-code call to `GroceryListItem(context:)` or `Ingredient(context:)` that is not followed (within 10 lines) by a `context.assign(` call on the newly-created object, or routed through `ManagedObjectFactory.make()`.

#### Scenario: Audit flags missing assign
- **WHEN** the audit runs against a production file containing `let item = GroceryListItem(context: viewContext)` followed by property configuration and `list.addToItems(item)` with no `viewContext.assign(item, ...)` call
- **THEN** the audit reports the site as a rule violation with file and line reference

#### Scenario: Audit skips test files
- **WHEN** the audit runs against files under `foragerTests/` or `foragerUITests/`
- **THEN** direct `GroceryListItem(context:)` / `Ingredient(context:)` calls are exempt from the rule

#### Scenario: Audit skips factory route
- **WHEN** a production site uses `factory.make(GroceryListItem.self, in: scope) { ... }`
- **THEN** the audit considers the site compliant regardless of the absence of an explicit `assign` call (the factory performs the assignment internally)
