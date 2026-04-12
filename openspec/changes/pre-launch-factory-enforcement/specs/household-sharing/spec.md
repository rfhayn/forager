## MODIFIED Requirements

### Requirement: REQ-010
The system MUST use the ManagedObjectFactory for all HouseholdScoped entity creation to ensure correct store assignment (ADR 014). The factory MUST be a non-optional dependency in all services and repositories that create HouseholdScoped entities. Fallback creation via `Entity(context:)` is FORBIDDEN in production code paths. If factory creation fails, the error MUST be propagated to the caller — never silently creating an unscoped entity.

#### Scenario: Factory is non-optional in services
- **WHEN** a service or repository that creates HouseholdScoped entities is initialized
- **THEN** the factory parameter MUST be non-optional (`ManagedObjectFactory`, not `ManagedObjectFactory?`)

#### Scenario: Factory error propagation
- **WHEN** `factory.make()` throws an error during entity creation
- **THEN** the error MUST be propagated to the caller (service method throws or returns nil with logged error), and no entity SHALL be created via direct `Entity(context:)` fallback

#### Scenario: Household repository factory injection
- **WHEN** a service instantiates a `Household*Repository` (HouseholdCategoryRepository, HouseholdPlannedMealRepository, HouseholdIngredientTemplateRepository) inline
- **THEN** the service MUST pass its own factory instance to the repository init

#### Scenario: View-level entity creation
- **WHEN** a SwiftUI view needs to create a top-level HouseholdScoped entity
- **THEN** it MUST delegate to a service method or use the factory via environment — never calling `Entity(context:)` directly

#### Scenario: Exempt contexts
- **WHEN** entity creation occurs in tests, SwiftUI previews, DefaultSeeder (first-launch bootstrap), or HouseholdService migration methods
- **THEN** direct `Entity(context:)` is acceptable as these are documented exceptions per ADR 014
