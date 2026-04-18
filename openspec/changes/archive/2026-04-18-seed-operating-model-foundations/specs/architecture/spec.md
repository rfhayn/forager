## ADDED Requirements

### Requirement: Scope-aware fetches for HouseholdScoped entities

All fetches on HouseholdScoped entities (Recipe, WeeklyList, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem, Store) SHALL include a `householdKey` predicate that binds to the active scope. This applies to NSFetchRequest instances in services, repositories, and SwiftUI `@FetchRequest` property wrappers. Source: ADR 013 (`docs/architecture/013-scope-aware-fetch-pattern.md`).

#### Scenario: Service-layer fetch on a HouseholdScoped entity includes householdKey
- **WHEN** a service or repository method constructs an NSFetchRequest for any HouseholdScoped entity
- **THEN** the predicate MUST include a clause constraining `householdKey` to `HouseholdScopeProvider.activeScope` or `currentHouseholdKey`

#### Scenario: SwiftUI view fetches a HouseholdScoped entity
- **WHEN** a SwiftUI view declares `@FetchRequest` or binds an NSFetchRequest for a HouseholdScoped entity
- **THEN** the predicate MUST include `householdKey == <current-household-key>` or an equivalent expression tied to the active scope

#### Scenario: Switching active household re-evaluates fetches
- **WHEN** the active household scope changes (e.g., owner toggles between households)
- **THEN** existing `@FetchRequest` instances MUST re-execute with the new predicate and display only entities belonging to the new scope

#### Scenario: Fetch without householdKey predicate is flagged by architecture-audit
- **WHEN** the `/architecture-audit` skill scans the codebase
- **THEN** any `@FetchRequest` or NSFetchRequest on a HouseholdScoped entity without a `householdKey` predicate SHALL be reported as a violation with file:line reference

### Requirement: Factory enforcement for HouseholdScoped entity creation

All instantiations of HouseholdScoped entities in production code SHALL route through `ManagedObjectFactory.make()` so that scope assignment and store routing are handled consistently. Direct `Entity(context:)` calls are prohibited except in tests, SwiftUI previews, Core Data seeders, and background-context migration utilities. Source: ADR 014 (`docs/architecture/014-managed-object-factory-enforcement.md`).

#### Scenario: Service creates a HouseholdScoped entity
- **WHEN** any service, repository, or import pipeline creates an instance of a HouseholdScoped entity
- **THEN** the instance MUST be obtained via `ManagedObjectFactory.make()` with the entity type and active scope

#### Scenario: Raw Entity(context:) call is flagged
- **WHEN** the `/architecture-audit` skill scans production code for HouseholdScoped entity instantiation
- **THEN** any raw `Entity(context:)` call outside the allowed exception list (tests, previews, seeders, background contexts) SHALL be reported as a violation

#### Scenario: Child entity inherits scope from parent
- **WHEN** a child entity (Ingredient, GroceryListItem) is created with its parent relationship set
- **THEN** the child MAY be created via `Entity(context:)` directly; factory is not required because the child inherits store placement from the parent via the Core Data relationship

### Requirement: Views do not call context.save() directly

SwiftUI views SHALL NOT call `context.save()`, `viewContext.save()`, or `.managedObjectContext.save()` directly. All Core Data write commits SHALL be performed by service-layer methods, repositories, or the persistence controller. Source: service-layer pattern (`docs/architecture/service-layer-pattern.md`).

#### Scenario: View mutates and persists a HouseholdScoped entity
- **WHEN** a SwiftUI view needs to persist changes to a HouseholdScoped entity (e.g., renaming a list, adding a category)
- **THEN** the view MUST delegate the write to a service method (e.g., `WeeklyListService.renameList(_:to:)`) which handles the save

#### Scenario: View-layer save call is flagged
- **WHEN** the `/architecture-audit` skill scans `forager/Views/**/*.swift` for save-call patterns
- **THEN** any occurrence of `context.save()`, `viewContext.save()`, or `.managedObjectContext.save()` SHALL be reported as a violation

### Requirement: Hybrid parser confidence routing thresholds

The hybrid ingredient parsing pipeline SHALL route between its three tiers (Regex → ML → NLP) based on fixed confidence thresholds: Regex results with confidence ≥ 0.9 are accepted directly; otherwise ML is consulted and results ≥ 0.8 are accepted; otherwise NLP is consulted and its confidence is capped at 0.75. Source: ADR 010 (`docs/architecture/010-hybrid-parser-confidence-routing.md`).

#### Scenario: High-confidence regex result bypasses ML and NLP
- **WHEN** `HybridIngredientParser.parse()` receives a regex result with confidence ≥ 0.9
- **THEN** that result is returned immediately without invoking ML or NLP parsers

#### Scenario: ML result is consulted when regex confidence is below threshold
- **WHEN** regex confidence is below 0.9
- **THEN** ML parsing is invoked; if ML confidence ≥ 0.8, the ML result is returned

#### Scenario: NLP fallback caps confidence at 0.75
- **WHEN** both regex and ML confidence fall below their thresholds
- **THEN** NLP parsing is invoked and its reported confidence is capped at 0.75 regardless of internal NLP score

### Requirement: GroceryListItem snapshot pattern

GroceryListItem entities SHALL contain snapshot copies of category and store metadata rather than live relationships to IngredientTemplate. This allows items to remain valid if their source template is later deleted or modified. Source: ADR 012 (`docs/architecture/012-grocery-item-snapshot-architecture.md`).

#### Scenario: GroceryListItem is created from a template
- **WHEN** a GroceryListItem is created during import, meal-plan generation, or manual add
- **THEN** the item MUST snapshot the template's category (via `categoryEntity` relationship) and store (via store snapshot fields) rather than storing a live reference to the template

#### Scenario: Source template is deleted after item creation
- **WHEN** a template that was the source of a GroceryListItem is deleted
- **THEN** the existing GroceryListItem MUST retain its category and store information intact (no cascading deletion, no broken references)

#### Scenario: GroceryListItem does not add ingredientTemplate relationship
- **WHEN** reviewing the GroceryListItem entity schema
- **THEN** no live `ingredientTemplate` relationship SHALL exist on GroceryListItem

### Requirement: Core Data change process for schema modifications

All Core Data schema changes (new entity, new attribute, new relationship, changed attribute type) SHALL follow the documented change process: create a new model version, perform impact analysis via the `/core-data-audit` skill, assess CloudKit production-schema compatibility (append-only), and update the migration plan. Destructive changes to the CloudKit Production schema are prohibited. Source: ADR 007 (`docs/architecture/007-core-data-change-process.md`).

#### Scenario: Developer proposes a new Core Data attribute
- **WHEN** a change proposal includes adding an attribute to an existing entity
- **THEN** the design MUST reference a new model version (e.g., v11 → v12), describe the lightweight migration strategy, and confirm the attribute is optional or has a default (CloudKit append-only compliance)

#### Scenario: Destructive CloudKit schema change is attempted
- **WHEN** a proposed change would remove an attribute, change an attribute type incompatibly, or delete an entity that has reached the CloudKit Production schema
- **THEN** the change MUST be rejected or restructured; destructive changes are prohibited

#### Scenario: Pre-implementation audit before schema change
- **WHEN** a developer prepares to implement a Core Data schema change
- **THEN** `/core-data-audit` SHALL be run to inventory usage of affected entities, relationships, codegen, and migration impact before any code is modified
