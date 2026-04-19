## MODIFIED Requirements

### Requirement: Scope-aware fetches for HouseholdScoped entities

All fetches on HouseholdScoped entities (Recipe, WeeklyList, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem, Store) performed by service-layer or repository-layer code SHALL include a `householdKey` predicate that binds to the active scope. This applies to `NSFetchRequest` instances in `Services/*.swift` and `forager/Repositories/*.swift`. Source: ADR 013 (`docs/architecture/013-scope-aware-fetch-pattern.md`).

View-layer scope handling for SwiftUI `@FetchRequest` is under architectural review and is NOT governed by this requirement. The current in-memory filter pattern in views is emergent (first appeared Jan 18, 2026 in `f263730`; spread by copy-paste; not formalized by any ADR) and will be addressed by a future change (`decide-view-layer-scope-architecture`). Unscoped `@FetchRequest` in views SHALL NOT be treated as violations of this requirement until that future change lands and defines the normative view-layer pattern.

#### Scenario: Service-layer fetch on a HouseholdScoped entity includes householdKey

- **WHEN** a service or repository method constructs an `NSFetchRequest` for any HouseholdScoped entity
- **THEN** the predicate MUST include a clause constraining `householdKey` to `HouseholdScopeProvider.activeScope` or `currentHouseholdKey` (matching on string key when set, `householdKey == nil` otherwise)

#### Scenario: Fetch without householdKey predicate in services or repositories is flagged by architecture-audit

- **WHEN** the `/architecture-audit` skill scans `Services/` and `forager/Repositories/`
- **THEN** any `NSFetchRequest` on a HouseholdScoped entity whose predicate does not reference `householdKey` SHALL be reported as a violation with file:line reference

#### Scenario: View-layer @FetchRequest is out of scope for this requirement

- **WHEN** a SwiftUI view declares `@FetchRequest` on a HouseholdScoped entity without a `householdKey` predicate
- **THEN** this does NOT constitute a violation of this requirement, pending the outcome of the future `decide-view-layer-scope-architecture` change

#### Scenario: Switching active household re-evaluates service-layer fetches

- **WHEN** the active household scope changes (e.g., owner toggles between households) and a service method subsequently fetches a HouseholdScoped entity
- **THEN** the new fetch MUST use the updated scope in its predicate and return only entities belonging to the new scope

### Requirement: Views do not call context.save() directly

SwiftUI view production code SHALL NOT call `context.save()`, `viewContext.save()`, or `.managedObjectContext.save()` directly. All Core Data write commits SHALL be performed by service-layer methods, repositories, or the persistence controller. SwiftUI preview code (`#Preview { }` blocks, `PreviewProvider` extensions, files named `*Preview*.swift`) is exempt — previews are a legitimate standalone environment that may call `context.save()` to stage preview data. Source: service-layer pattern (`docs/architecture/service-layer-pattern.md`).

#### Scenario: View mutates and persists a HouseholdScoped entity

- **WHEN** a SwiftUI view needs to persist changes to a HouseholdScoped entity (e.g., renaming a list, renaming a plan, creating a custom category)
- **THEN** the view MUST delegate the write to a service method (e.g., `WeeklyListService.renameList(_:name:)`, `MealPlanService.renamePlan(_:name:)`, `CategoryService.createCustomCategory(displayName:color:)`) which handles the save

#### Scenario: Production view-layer save call is flagged

- **WHEN** the `/architecture-audit` skill scans `forager/Views/**/*.swift` for save-call patterns, excluding files matching `*Preview*` and excluding matches inside `#Preview { }` blocks and `PreviewProvider` extensions
- **THEN** any remaining occurrence of `context.save()`, `viewContext.save()`, or `.managedObjectContext.save()` SHALL be reported as a violation

#### Scenario: Preview save call is NOT flagged

- **WHEN** the `/architecture-audit` skill encounters a `context.save()` call inside a `#Preview { }` block, `PreviewProvider` extension, or file named `*Preview*.swift`
- **THEN** this does NOT constitute a violation — previews are an exempt environment
