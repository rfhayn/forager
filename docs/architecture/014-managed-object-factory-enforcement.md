# ADR 014: ManagedObjectFactory Enforcement

**Status**: Accepted
**Date**: 2026-03-11
**Context**: M9.13 ManagedObjectFactory Enforcement & Cross-Store Crash Fix

## Decision

All creation of HouseholdScoped entities (`WeeklyList`, `Recipe`, `PlannedMeal`, `MealPlan`, `Category`, `IngredientTemplate`, `Ingredient`, `GroceryListItem`) MUST go through `ManagedObjectFactory.make()` or set `household`/`householdKey` by inheriting from their parent entity. Direct `Entity(context:)` without household binding for these types is **forbidden** in production code.

## Context

A TestFlight crash (`CoreData -[NSManagedObjectContext assignObject:toPersistentStore:]`) occurred when tapping "Add to Grocery List" from a recipe after leaving a household. The root cause was ad-hoc `viewContext.assign()` calls in view code that attempted to reassign objects between stores — illegal when the recipe still references a defunct shared store.

Investigation revealed a **systemic architectural violation**: M7.2.3 established `ManagedObjectFactory` as the ONLY creation path for HouseholdScoped entities (documented in `DataScope.swift`), but **zero production code actually used it**. All 43+ creation sites used direct `Entity(context:)`, which defaults to the private store regardless of household scope.

This worked through M7 because the views that crash (`AddIngredientsToListView`, `MealPlanDetailView`) didn't exist yet, and categories were flat strings (no cross-store relationships). Post-M7 milestones added these views and entity relationships without routing through the factory.

## Consequences

### Positive
- Cross-store crashes eliminated — objects always land in the correct store
- `householdKey` automatically set by factory — no manual assignment needed
- Store cleanup paths (`deleteHouseholdLinkedData`, `purgeAllSharedStoreObjects`) work reliably
- Compile-time protocol (`HouseholdScoped`) makes scope requirements explicit

### Negative
- Factory adds indirection to entity creation
- Services need factory injection (added `factory` property pattern)
- Background contexts can't use factory with scope provider (must use `performScopedWrite` or set householdKey manually)

## Enforcement

### Automated
- `/forager-architecture-audit` skill checks for direct `Entity(context:)` in non-exempt files
- Pre-development analysis includes factory compliance check

### Exempt Files
- **Test files** — in-memory contexts, no CloudKit
- **Preview providers** — in-memory contexts
- **`DefaultSeeder` / `SampleDataSeeder`** — first-launch seeding, no household
- **`HouseholdService.migrateDataFromHousehold()`** — intentional personal-scope copy
- **Background contexts** (`performWrite`) where householdKey is set manually

## Child HouseholdScoped Entities (M9.15)

`Ingredient` and `GroceryListItem` were promoted to HouseholdScoped in M9.15 to eliminate cross-store relationships. They inherit `household`/`householdKey` from their parent entity (Recipe/WeeklyList) rather than going through `ManagedObjectFactory.make()` directly. The **correct** pattern requires an explicit `context.assign(...)` call to co-locate the child with the parent's persistent store:

```swift
// ✅ CORRECT — explicit assign co-locates child with parent's store
let ingredient = Ingredient(context: viewContext)
if let parentStore = recipe.objectID.persistentStore {
    viewContext.assign(ingredient, to: parentStore)   // ← REQUIRED
}
ingredient.recipe = recipe
ingredient.household = recipe.household      // Safe — ingredient is in recipe's store
ingredient.householdKey = recipe.householdKey
```

```swift
// ❌ INCORRECT — relies on Core Data's implicit store inference from relationships
let ingredient = Ingredient(context: viewContext)
ingredient.recipe = recipe
ingredient.household = recipe.household      // Core Data MAY route to wrong store
ingredient.householdKey = recipe.householdKey
```

> **⚠️ 2026-04-21 CRITICAL — Explicit `context.assign()` is REQUIRED**
>
> Core Data's implicit relationship-based store inference runs at save time and does
> NOT reliably co-locate the child with the parent under CloudKit dual-store mirroring.
> The incorrect pattern above caused `fix-groceryitem-multi-zone-assignment` (CoreData
> error 134040 "Object graph corruption detected — objects assigned to multiple zones"):
> the child was placed in the default first store (usually private), the parent was in
> the shared store, and the CloudKit mirroring delegate refused to initialize.
>
> The architecture-guard hook at `.claude/hooks/architecture-guard.sh` enforces this:
> a direct `GroceryListItem(context:)` / `Ingredient(context:)` init that is not
> followed within 10 lines by a `context.assign(...)` call (or routed through
> `ManagedObjectFactory.make()`) is rejected at edit time.

> **⚠️ M9.19 — Cross-Store Relationship Rule (subsumed by the 2026-04-21 rule above)**:
> The `household` relationship is safe in the child pattern only because
> `recipe.household` is guaranteed to be in the same store as the recipe (and therefore
> the ingredient, via the explicit assign). **NEVER set `entity.household = household`
> when the Household object may be in a different store than the entity being created.**
>
> After `container.share()`, the Household moves to the **shared store**. Any
> private-store entity with a `household` relationship to it creates a cross-store link
> that the CloudKit mirroring delegate **silently refuses to export** — data saves locally
> but never uploads to CloudKit, causing permanent data loss on reinstall.
>
> **Rule**: When creating entities where the Household's store is uncertain (e.g., during
> `copyPersonalDataToHousehold`), use `householdKey` (String) only. The `household`
> relationship is redundant — all fetch predicates use `householdKey` per ADR 013.

## Non-HouseholdScoped Entities (Safe for Direct Creation)
- `Household`, `HouseholdMember` — manage their own store placement
- `UserPreferences` — personal-only, no household scope

## Related ADRs
- ADR 007: Core Data Change Process
- ADR 008: Shared Zone Architecture
- ADR 013: Scope-Aware Fetch Pattern
- Service Layer Pattern (docs/architecture/service-layer-pattern.md)
