## Context

ADR 014 established that all HouseholdScoped entity creation must go through `ManagedObjectFactory.make()`. However, the factory was implemented as an optional dependency (`ManagedObjectFactory?`) across services and repositories. This created a systemic pattern where every creation site has an `if let factory` / `else` branch — and the `else` branch silently creates entities in the wrong persistent store.

The three `Household*Repository` classes (`HouseholdCategoryRepository`, `HouseholdPlannedMealRepository`, `HouseholdIngredientTemplateRepository`) are always instantiated inline by their parent services **without** passing the factory — making their factory parameter dead code and every creation path a fallback.

Current factory injection happens in `foragerApp.swift:144` via `.configure(factory:)` calls on services. The configure pattern is the reason factory is optional — it's set after init.

## Goals / Non-Goals

**Goals:**
- Eliminate all production code paths that create top-level HouseholdScoped entities without the factory
- Make it impossible to forget factory injection (compile-time enforcement via non-optional types)
- Fix the 1 force-unwrap crash risk in HouseholdService
- Add test coverage for the factory itself (currently zero tests)

**Non-Goals:**
- Changing child entity creation patterns (Ingredient, GroceryListItem inherit store from parent — correct per ADR 014)
- Refactoring the factory to support child contexts (RecipeImportService exception — documented, acceptable)
- Adding test coverage for all 42 untested services (only factory/scope/dedup tests in scope)
- Changing the `@FetchRequest` client-side filtering pattern (deliberate architectural trade-off)

## Decisions

### D1: Make factory non-optional via init injection (not configure)

**Decision**: Change `factory: ManagedObjectFactory?` to `factory: ManagedObjectFactory` and inject via init, not `.configure()`.

**Why not keep configure()**: The configure pattern is why factory is optional in the first place. Services are created before the factory exists (in `foragerApp.swift`), then configured later. This temporal gap means there's a window where factory is nil.

**Alternative considered**: Keep configure() but add `precondition(factory != nil)` at creation sites. Rejected — still a runtime check, doesn't prevent the bug at compile time.

**Implementation**: Reorder initialization in `foragerApp.swift` so the factory is created first, then passed to service inits. Services that are `@StateObject` will need their init signatures updated.

### D2: Remove all fallback branches — propagate errors instead

**Decision**: When `factory.make()` throws, propagate the error to the caller. Never silently create an unscoped entity.

**Why**: The fallback pattern exists as a "safety net" but actually creates worse problems (invisible data, broken sync) than showing an error to the user would. A visible error is always better than silent data corruption.

**In views (CreateRecipeView)**: Show an error alert. The user can retry.

**In services**: Methods that create entities should throw. Callers handle the error.

### D3: Pass factory from parent service to inline repositories

**Decision**: When services create `Household*Repository` instances inline, pass `self.factory` to the repository init.

**Why**: The repositories already accept factory in their init — it's just never populated. This is a one-line fix at each call site.

**Sites**:
- `MealPlanService` → `HouseholdPlannedMealRepository(context:, factory:)`
- `IngredientTemplateService` → `HouseholdIngredientTemplateRepository(context:, factory:)`
- `Category+CoreDataClass` → `HouseholdCategoryRepository(context:, factory:)` — needs factory access, may need to accept factory as parameter
- `DefaultSeeder` → exempt (first-launch bootstrap, no household exists yet)

### D4: Route view saves through service layer

**Decision**: Replace `try? viewContext.save()` with service method calls in 4 production locations. Use existing service methods where available, add a `saveContext()` method where needed.

**Why**: `try?` silently swallows Core Data save errors. In a dual-store CloudKit architecture, save failures can indicate store conflicts or constraint violations. Services can log errors and provide recovery options.

### D5: Test strategy — factory behavior, not every service

**Decision**: Write tests for ManagedObjectFactory, HouseholdScopeProvider, and CategoryDeduplicator. Don't test every service in this change.

**Why**: The factory is the foundation. If it works correctly, all services that use it get correct behavior. Testing the factory validates the entire Phase 1 fix. CategoryDeduplicator has a force-unwrap that needs a safety test.

## Risks / Trade-offs

**[Risk] Init-order dependency in foragerApp.swift** → Factory must be created before services. SwiftUI `@StateObject` makes this tricky since property wrappers initialize before `init()` runs. Mitigation: may need to use `@State` + lazy initialization or a service container pattern. Investigate actual init order before committing to approach.

**[Risk] Category+CoreDataClass needs factory access** → This model extension creates `HouseholdCategoryRepository` inline but has no access to the factory. Mitigation: pass factory as a parameter to the method, or move the logic to a service.

**[Risk] Breaking test setup** → Tests that create services without a factory will fail to compile. Mitigation: tests use in-memory PersistenceController which provides a factory — update test setup to pass it.

**[Trade-off] DefaultSeeder exemption** → Seeder creates entities without factory during first launch (no household exists). This is acceptable and documented. Add a comment marking it as an intentional exemption.
