# ADR 013: Scope-Aware Fetch Pattern for Dual-Store Architecture

**Status**: ACCEPTED
**Date**: March 7, 2026
**Deciders**: Rich
**Related**: ADR 008 (Shared Zone Architecture), ADR 007 (Core Data Change Process)
**Triggered By**: M10.6 ghost duplicate bug — `DuplicateDetectionService` matched a recipe invisible to the user, causing silent data loss and CloudKit zone corruption (error 134060)

---

## Context

Forager uses a dual-store CloudKit architecture (ADR 008):
- **Private store** (`forager.sqlite`) — personal data
- **Shared store** (`forager_shared.sqlite`) — household shared data

Each entity with household support has a `householdKey` property. The UI filters recipes and other entities by checking `householdKey` against the current household. However, **Core Data fetch requests without a `householdKey` predicate return objects from ALL stores**, including ghost objects from previous households.

### The Bug

1. User left a household. Cleanup ran but a recipe survived (CloudKit re-sync, timing, or incomplete purge).
2. User imported the same recipe. `DuplicateDetectionService` found the ghost recipe (no scope filtering).
3. User chose "Replace Existing". The overwrite targeted the ghost recipe in the wrong store.
4. No data appeared (ghost recipe invisible in UI).
5. User created a new household. `container.share()` found Ingredient objects spanning multiple CloudKit zones → **error 134060: Object graph corruption**.

### Root Cause

Any service that does `Entity.fetchRequest()` without a `householdKey` predicate can "see" objects the user cannot. The UI's in-memory filtering creates a false sense of scope safety.

---

## Decision

**All service-layer fetch requests that return user-facing data MUST include a `householdKey` scope predicate.**

### The Pattern

```swift
// REQUIRED: Scope predicate for any fetch returning user-visible data
private func scopePredicate(householdKey: String?) -> NSPredicate {
    if let key = householdKey {
        return NSPredicate(format: "householdKey == %@", key)
    } else {
        return NSPredicate(format: "householdKey == nil")
    }
}

// Usage: combine with other predicates
let request = Recipe.fetchRequest()
request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
    NSPredicate(format: "sourceURL == %@", url),
    scopePredicate(householdKey: currentKey)
])
```

### Entities Requiring Scope

Any entity with `householdKey`:
- `Recipe`
- `WeeklyList`
- `GroceryListItem` (via WeeklyList)
- `MealPlan`
- `PlannedMeal` (via MealPlan)
- `Category`
- `IngredientTemplate`

### Entities Exempt

- `Ingredient` — scoped implicitly through Recipe relationship (no direct `householdKey`)
- `Household` / `HouseholdMember` — only one active household at a time
- `UserPreferences` — device-local, no household scoping

---

## Consequences

### Positive
- Prevents ghost object interactions (duplicate detection, search, cross-entity queries)
- Prevents CloudKit zone corruption from cross-zone object graphs
- Makes scope boundary explicit in code rather than relying on UI-level filtering
- Aligns service behavior with what users actually see

### Negative
- Every new service fetch needs to accept and apply `householdKey`
- Slightly more verbose fetch code
- Existing code must be audited for unscoped fetches

### Pre-Mutation Cleanup Rule

Before any operation that changes CloudKit zone membership (e.g., `container.share()`), run a **pre-flight orphan cleanup** to remove:
1. Objects with stale `householdKey` (pointing to non-existent households)
2. Orphaned `Ingredient` objects not linked to any `Recipe`
3. Remnant objects in the shared store

This is implemented in `HouseholdService.cleanOrphanedHouseholdData()`.

---

### M9.24 Extension: Scope-Aware Store Assignment

ADR 013 originally addressed **fetches** (read path). M9.24 extends the same principle to
**store assignment** (write path): never hardcode which persistent store objects are assigned to.

```swift
// ❌ WRONG — hardcoded store, breaks on member devices
viewContext.assign(obj, to: privateStore)

// ✅ CORRECT — scope-aware, works for owner AND member
let targetStore: NSPersistentStore
if case .household(_, let storeID) = scopeProvider.activeScope {
    targetStore = persistence.store(for: storeID)
} else {
    targetStore = persistence.privateStore
}
viewContext.assign(obj, to: targetStore)
```

**Why**: On the owner's phone, the private store is correct (zone routing via relationships).
On a member's phone, the shared store is correct (shared CloudKit database). The scope
provider already knows which device role we're on — use it.

---

## Compliance Checklist

When creating or modifying a service that fetches or creates household-scoped entities:

- [ ] Does every `fetchRequest()` include a `householdKey` predicate?
- [ ] Is `householdKey` passed in (not assumed from global state)?
- [ ] Does the `replaceExistingRecipe`-style overwrite validate store accessibility?
- [ ] Before `container.share()`, is `cleanOrphanedHouseholdData()` called?
- [ ] Are all household-scoped entity creations using `ManagedObjectFactory`? (ADR 014)
- [ ] Is store assignment resolved via `HouseholdScopeProvider`, not hardcoded? (M9.24)

Add this to the `/forager-core-data-audit` checklist for any entity with `householdKey`.

---

## Related Files

- `Services/Import/DuplicateDetectionService.swift` — scoped with `householdKey` parameter (M10.6 fix)
- `Services/Import/RecipeImportService.swift` — ghost recipe validation in `replaceExistingRecipe` (M10.6 fix)
- `Services/HouseholdService.swift` — `cleanOrphanedHouseholdData()` pre-creation cleanup (M10.6 fix)
- `forager/Views/Recipes/RecipeListView.swift` — UI in-memory filtering (existing pattern)
