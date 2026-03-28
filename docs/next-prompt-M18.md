# Next Implementation Prompt

**Last Updated**: March 28, 2026
**For Milestone**: M18 — Store-Aware Shopping
**Status**: **M18 ACTIVE** (Phase 1)

**Branch**: `feature/M18-store-aware-shopping`

---

## M18 — Store-Aware Shopping

**PRD**: `docs/prds/active/m18-store-aware-shopping.md`
**Origin**: Beta tester feedback (Joe) — categories map to *what* you buy, stores map to *where* you buy it.

**What**: Add a Store entity so users can tag ingredient templates with a preferred store and view their grocery list grouped by store. Organic learning — users assign stores as they shop, not in a setup wizard. Feature is invisible until the first store is created.

**Why**: Users shop at multiple stores and mentally partition their grocery list. This is the #1 beta tester feature request.

---

## Phase 1: Store Preferences on Templates (M18.1)

### M18.1.1: Store Entity + Schema v11 (1-1.5h)

**IMPORTANT**: Run `/forager-core-data-audit` before starting schema changes.

New Core Data entity `Store`:
- `id` (UUID), `name` (String), `color` (String/hex), `sortOrder` (Int16)
- `householdKey` (String?), `household` (Household?), `dateCreated` (Date), `updatedAt` (Date)
- HouseholdScoped → must use `ManagedObjectFactory.make()` (ADR 014)

New relationships:
- `IngredientTemplate.preferredStore: Store?` (optional to-one)
- `GroceryListItem.store: Store?` (optional to-one, snapshot pattern like category)
- Inverses: `Store.ingredientTemplates`, `Store.groceryListItems`

Schema version: v11 (lightweight migration, new entity + optional relationships, CloudKit-safe)

**Key files to modify**:
- `forager.xcdatamodeld` — new entity, relationships, version bump
- `Models/` — new Store+CoreDataClass.swift, Store+CoreDataProperties.swift
- `Models/ManagedObjectFactory.swift` — add `makeStore()` factory method
- `Models/IngredientTemplate+CoreDataProperties.swift` — add preferredStore
- `Models/GroceryListItem+CoreDataProperties.swift` — add store

### M18.1.2: StoreService (1h)

Run `/forager-service-check` before creating.

```swift
class StoreService {
    static func createStore(name:color:in:) -> Store
    static func deleteStore(_:reassignTo:in:)
    static func reorderStores(_:in:)
    static func fetchStores(in:) -> [Store]
    static func assignStore(_:to template:in:)
    static func assignStore(_:to groceryItem:in:)
}
```

Follow established service layer pattern (see `Services/GroceryListItemService.swift` as reference).

### M18.1.3: Store Management UI (1.5-2h)

**Settings > Stores** (new section, below Categories):
- List with color dot + name, drag to reorder
- Swipe to delete (reassignment dialog if templates assigned)
- Add store: name + color picker
- Empty state: `ContentUnavailableView`
- Suggested store chips on first use (Costco, Walmart, Target, Kroger, Whole Foods, Aldi, Trader Joe's)

Follow `ManageCategoriesView` pattern.

### M18.1.4: Store Assignment UX (1.5-2h)

- Long-press grocery list item → "Buy at..." → store picker
- Sets store on IngredientTemplate (learning) + current GroceryListItem
- Small color dot indicator on grocery list items (only when store assigned)

### M18.1.5: "Group by Store" View Mode (1.5-2h)

- Toggle in GroceryListDetailView toolbar: Category (default) | Store
- Store sections: color dot + name + completion count
- "Unassigned" section at bottom for items without store
- Sub-sort by category within each store section
- Persistence: `UserDefaults` key `groceryListGroupMode`
- Stretch: filter chips for single-store "shopping trip mode"

---

## Key Architecture Notes

- Store is HouseholdScoped → factory enforcement (ADR 014)
- All fetches must include `householdKey` predicate (ADR 013)
- GroceryListItem.store is a snapshot (like category) — set at add-time from template
- CloudKit: new entity + optional relationships = safe lightweight migration
- No destructive schema changes (append-only for CloudKit Production)

---

## Phase 2 (M18.2) — Deferred

Multi-store per template, shopping trip mode, smart suggestions, store-aware staples. Only if Phase 1 resonates with users.
