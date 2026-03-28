# Next Implementation Prompt

**Last Updated**: March 28, 2026
**For Milestone**: M18 — Store-Aware Shopping + Recipe Attribution
**Status**: **M18 ACTIVE**

**Branch**: `feature/M18-store-aware-shopping`

---

## M18 — Store-Aware Shopping + Recipe Attribution

**PRD**: `docs/prds/active/m18-store-aware-shopping.md`
**Origin**: Beta tester feedback (Joe) + recipe import attribution gap.

**What**: Combined milestone batching two features into a single Core Data v11 migration:
1. Store entity + preferences + grouped grocery list views
2. Recipe.imageURL + Recipe.author (persisting what import already extracts)

**Why**: Users shop at multiple stores and mentally partition their list. Import pipeline extracts attribution data but drops it. Both need schema changes — one migration is better than two.

---

## Sub-Milestones (Execution Order)

### M18.1.0: Schema v11 + Model Files (1.2h)

**IMPORTANT**: Core Data audit COMPLETE — see PRD for full impact analysis.

Create `forager 11.xcdatamodel` with ALL changes:

**New entity `Store`**:
- `id` (UUID?), `name` (String?), `color` (String?/hex), `sortOrder` (Int16)
- `householdKey` (String?), `household` (Household?), `dateCreated` (Date?), `updatedAt` (Date?)
- HouseholdScoped → `ManagedObjectFactory.make()` (ADR 014)
- Fetch index: `byStoreSortOrder` on `(sortOrder, name)`

**New relationships**:
- `IngredientTemplate.preferredStore: Store?` (to-one, optional)
- `GroceryListItem.store: Store?` (to-one, optional, snapshot pattern)
- `Household.stores: NSSet?` (to-many, nullify)
- All inverses configured

**New attributes on Recipe**:
- `imageURL: String?` (optional)
- `author: String?` (optional)

**Files to create/modify**:
- `forager.xcdatamodeld/forager 11.xcdatamodel/contents` — CREATE
- `forager.xcdatamodeld/.xccurrentversion` — MODIFY
- `Models/Store+CoreDataClass.swift` — CREATE
- `Models/Store+CoreDataProperties.swift` — CREATE
- `Models/Store+Extensions.swift` — CREATE
- `Models/Recipe+CoreDataProperties.swift` — MODIFY (add imageURL, author)
- `Models/IngredientTemplate+CoreDataProperties.swift` — MODIFY (add preferredStore)
- `Models/GroceryListItem+CoreDataProperties.swift` — MODIFY (add store)
- `Models/Household+CoreDataProperties.swift` — MODIFY (add stores + accessors)
- `Services/Persistence/DataScope.swift` — MODIFY (add Store: HouseholdScoped)
- `CLAUDE.md` — Update entity count to 12, model to v11

### M18.1.1: StoreService (1.1h)

Run `/forager-service-check` before creating.

```swift
class StoreService {
    static func createStore(name:color:in:) -> Store
    static func deleteStore(_:reassignTo:in:)
    static func reorderStores(_:in:)
    static func fetchStores(in:) -> [Store]
    static func assignStore(_:toTemplate:in:)
    static func assignStore(_:toGroceryItem:in:)
    static func resolveStore(for:targetList:) -> Store?
}
```

`resolveStore` mirrors `GroceryListItemService.resolveCategory()` for cross-store CloudKit safety.

### M18.1.2: Store Snapshot Wiring (0.6h)

In `GroceryListItemService`: snapshot `template.preferredStore` onto new items in all 3 creation paths (addItem, addIngredients, addStaples). Same pattern as `categoryEntity` snapshot.

### M18.1.3: Store Management UI (1.75h)

**Settings > Stores** (below Categories in Data Management):
- List with color dot + name, drag to reorder
- Swipe to delete (reassignment dialog if templates assigned)
- Add store: name + color picker + suggested store chips
- Empty state: `ContentUnavailableView`
- Replicate `ManageCategoriesView` pattern

### M18.1.4: Store Assignment UX + Color Dots + Grouping (1.75h)

**Assignment**: Long-press grocery item → "Buy at..." → store picker. Sets template + current item.
**Color dots**: Small dot on items with assigned store (visible in both group modes).
**Grouping toggle**: Category (default) | Store in toolbar. Store sections with color dot + name + count.
**Unassigned section**: Items without store at bottom.
**Invisibility**: No toggle/dots if no stores created.
**Persistence**: `UserDefaults` key `groceryListGroupMode`

### M10.4.0: Recipe Attribution Wiring (0.75h)

- `RecipeImportService.saveImport()` ~line 182: add `recipe.imageURL = draft.imageURL.value` and `recipe.author = draft.author.value`
- `RecipeService.createRecipe()`: add optional imageURL + author params
- `RecipeFormModels.RecipeFormData`: add fields, update `toRecipeFormData()` mapping
- imageURL stored but NOT rendered as image (deferred to future milestone)

---

## Key Design Decisions

1. **No `isDefault` on Store** — Deletion protection is runtime (check template count), not a schema flag
2. **Store color dots in both group modes** — Useful context regardless of grouping
3. **Filter chips deferred to Phase 2** — Section grouping sufficient for v1
4. **imageURL stored not rendered** — Persisted for future image display
5. **GroceryListItem.store is a snapshot** — Mirrors categoryEntity pattern exactly

---

## Architecture Notes

- Store is HouseholdScoped → factory enforcement (ADR 014)
- All fetches must include `householdKey` predicate (ADR 013)
- CloudKit: new entity + optional relationships = safe lightweight migration
- No destructive schema changes (append-only for CloudKit Production)
- Category and Store are orthogonal — coexist, never compete
