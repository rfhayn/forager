## ADDED Requirements

### Requirement: Service unit tests configure the managed object factory in setUp

Service-layer unit tests that exercise creation paths using `ManagedObjectFactory.make()` (ADR 014) SHALL call `service.configure(factory:)` in their setUp method with a `ManagedObjectFactory` constructed from the test's in-memory `PersistenceController`. This applies to any test that calls service methods which internally invoke `factory.make(...)`. Without this configuration the service's implicit-unwrapped factory crashes on first use, producing the crash-loop behavior fixed by `fix-test-harness-and-stale-assertions`.

#### Scenario: RecipeServiceTests setUp configures the factory

- **WHEN** `RecipeServiceTests.setUp` runs
- **THEN** a `ManagedObjectFactory` is instantiated with the test's in-memory `PersistenceController` and passed to `service.configure(factory:)` AND to `templateService.configure(factory:)`

#### Scenario: WeeklyListServiceTests setUp configures the factory

- **WHEN** `WeeklyListServiceTests.setUp` runs
- **THEN** the factory is configured on both `service` and `templateService` for parity with production setup

#### Scenario: StoreServiceTests setUp configures the factory

- **WHEN** `StoreServiceTests.setUp` runs
- **THEN** the factory is configured on `service` so that `service.createStore(...)` exercises the production creation path instead of the assertionFailure guard at `StoreService.swift:73`

### Requirement: In-memory PersistenceController resolves its stores by canonical filename

`PersistenceController(inMemory: true)` SHALL configure its in-memory store URLs so that the `privateStore` and `sharedStore` property getters (which match on `url.lastPathComponent`) find the stores the same way they do in production. The in-memory paths SHALL use `forager.sqlite` and `forager_shared.sqlite` as their last path components (nested under any opaque parent such as `/dev/null/`). Core Data treats these URLs as opaque identifiers for in-memory stores — the filesystem path does not need to be valid.

#### Scenario: In-memory privateStore getter resolves

- **WHEN** `PersistenceController(inMemory: true).privateStore` is accessed
- **THEN** the getter returns the in-memory `.private` store (no fatalError)

#### Scenario: In-memory sharedStore getter resolves

- **WHEN** `PersistenceController(inMemory: true).sharedStore` is accessed
- **THEN** the getter returns the in-memory `.shared` store (no fatalError)

### Requirement: Tests that reach through `PersistenceController.shared` may swap it

For test files whose services internally reach through `PersistenceController.shared` (e.g. `RecipeImportService.persistAndFinish` accessing `.shared.privateStore`), the test's setUp MAY swap `PersistenceController.shared` with the test's in-memory controller and restore the prior value in tearDown. `PersistenceController.shared` SHALL be declared as `static var` (not `let`) to support this swap. Production code SHALL NOT mutate `PersistenceController.shared` — the mutable declaration exists solely to enable test isolation pending a future DI refactor.

#### Scenario: RecipeImportServiceLLMTests swaps the shared controller in setUp

- **WHEN** `RecipeImportServiceLLMTests.setUp` runs
- **THEN** the prior `PersistenceController.shared` is captured, an in-memory controller is assigned to `PersistenceController.shared`, and the service's internal `.shared.privateStore` lookup now resolves to the in-memory private store

#### Scenario: tearDown restores the prior shared controller

- **WHEN** `RecipeImportServiceLLMTests.tearDown` runs after any test method
- **THEN** `PersistenceController.shared` is reassigned to the prior value captured in setUp so subsequent tests are not coupled to this file's controller

#### Scenario: Production code does not mutate shared

- **WHEN** any file outside `foragerTests/` is scanned for assignments to `PersistenceController.shared`
- **THEN** zero matches SHALL be found; the `static var` declaration exists for test swapping only
