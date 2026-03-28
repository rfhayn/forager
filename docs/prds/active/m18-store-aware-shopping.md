# M18: Store-Aware Shopping + Recipe Attribution

**Status**: ACTIVE
**Estimated**: 7-10 hours (6 sub-milestones)
**Priority**: Pre-launch feature
**Last Updated**: March 28, 2026
**Branch**: `feature/M18-store-aware-shopping`
**Origin**: Beta tester feedback (Joe) — categories map to *what* you buy, but shopping decisions are about *where* you buy it.

---

## Problem Statement

Users shop at multiple stores (Costco, Heinen's, Target) and mentally track which items to buy where. The current category system organizes by food type (Produce, Dairy, Pantry) but cannot express store preference. This forces users to:

1. Mentally partition the grocery list by store while shopping
2. Miss items because they didn't think of "Costco items" while at Costco
3. Lose the efficiency of batching a store trip around the right items

**Joe's insight**: "Perhaps a shopping preference tab that allows me to pre-populate where I buy most stuff. Then it creates either separate lists or lists that identify a store — like a color or something that tells you where you should be buying what."

Additionally, the import pipeline already extracts `imageURL` and `author` from recipes but drops them at save time. These need persisting for legal attribution and future image display.

## Solution: Combined Schema v11 Migration

Both features require Core Data schema changes. We batch them into a single lightweight migration (v10 → v11) to avoid multiple version bumps.

### Design Principles

- **Additive, not disruptive** — store preferences layer on top of existing categories, never replace them
- **Organic learning** — users assign store preferences as they shop, not in a bulk setup wizard
- **Household-shared** — store preferences travel with the household (a family shares where they shop)
- **Optional** — users who shop at one store never see store features
- **Invisible by default** — zero stores = zero store UI. Feature has no footprint until first store created.

---

## Core Data Impact Analysis (ADR 007)

### Schema Changes Summary (v10 → v11)

- **Entities Added**: Store (1)
- **Entities Modified**: Recipe, IngredientTemplate, GroceryListItem, Household (4)
- **Properties Added**: 8 attributes on Store, 2 attributes on Recipe, 3 new relationships, 1 inverse on Household
- **Properties Removed**: None
- **Destructive Changes**: None

### Migration Safety

- **Type**: Lightweight (automatic). No mapping model needed.
- **CloudKit safety**: All changes are append-only. New entity + optional relationships + optional attributes. No renames, deletions, or type changes.
- **Existing data**: Zero stores post-migration. Recipe.imageURL and Recipe.author are nil for all existing recipes.

### New Entity: `Store`

| Property | Type | Notes |
|----------|------|-------|
| `id` | UUID? | Primary key |
| `name` | String? | "Costco", "Heinen's", "Target" |
| `color` | String? | Hex color code for visual indicator |
| `sortOrder` | Int16 | User-defined display order (default 0) |
| `householdKey` | String? | Household scoping (ADR 008/013) |
| `household` | Household? | Relationship for zone routing |
| `dateCreated` | Date? | |
| `updatedAt` | Date? | Conflict resolution |
| `ingredientTemplates` | NSSet? | Inverse of IngredientTemplate.preferredStore |
| `groceryListItems` | NSSet? | Inverse of GroceryListItem.store |

**HouseholdScoped** → must use `ManagedObjectFactory.make()` (ADR 014).
**Fetch index**: `byStoreSortOrder` on `(sortOrder ASC, name ASC)`.

### Modified Entity: `IngredientTemplate`

- Add `preferredStore: Store?` — optional to-one relationship (inverse: `Store.ingredientTemplates`)

### Modified Entity: `GroceryListItem`

- Add `store: Store?` — optional to-one relationship, snapshot at add-time (inverse: `Store.groceryListItems`)

### Modified Entity: `Recipe`

- Add `imageURL: String?` — optional String (source recipe hero image URL)
- Add `author: String?` — optional String (recipe creator name for attribution)

### Modified Entity: `Household`

- Add `stores: NSSet?` — to-many relationship (inverse: `Store.household`, nullify)

### Comprehensive Search Results

```
".preferredStore"  → 0 results (new property)
".store" on GroceryListItem → 0 results (new property; "store" is common word, filtered to entity context)
"imageURL" → ImportDraftRecipe.swift:70, SchemaRecipeMapper.swift, extraction code — no Recipe entity references
"author" → ImportDraftRecipe.swift:71, SchemaRecipeMapper.swift — no Recipe entity references
"Store.fetchRequest" → 0 results (new entity)
```

### Affected Files Checklist

#### Core Data Layer
- [ ] `forager.xcdatamodeld/forager 11.xcdatamodel/contents` — CREATE new model version
- [ ] `forager.xcdatamodeld/.xccurrentversion` — MODIFY to point to v11
- [ ] `Models/Store+CoreDataClass.swift` — CREATE
- [ ] `Models/Store+CoreDataProperties.swift` — CREATE (properties + generated accessors)
- [ ] `Models/Store+Extensions.swift` — CREATE (displayName, displayColor computed properties)
- [ ] `Models/Recipe+CoreDataProperties.swift` — MODIFY: add `@NSManaged public var imageURL: String?` and `@NSManaged public var author: String?`
- [ ] `Models/IngredientTemplate+CoreDataProperties.swift` — MODIFY: add `@NSManaged public var preferredStore: Store?`
- [ ] `Models/GroceryListItem+CoreDataProperties.swift` — MODIFY: add `@NSManaged public var store: Store?`
- [ ] `Models/Household+CoreDataProperties.swift` — MODIFY: add `@NSManaged public var stores: NSSet?` + generated accessors
- [ ] `Services/Persistence/DataScope.swift` — MODIFY: add `extension Store: HouseholdScoped {}`

#### Service Layer
- [ ] `Services/StoreService.swift` — CREATE: CRUD, assignment, query, resolveStore
- [ ] `Services/GroceryListItemService.swift` — MODIFY: snapshot store in addItem (~line 133), addStaples, addIngredients
- [ ] `Services/WeeklyListService.swift` — MODIFY: add optional store param to addItem
- [ ] `Services/Import/RecipeImportService.swift` — MODIFY: persist imageURL + author at ~line 182
- [ ] `Services/RecipeService.swift` — MODIFY: add optional imageURL + author params to createRecipe
- [ ] `Services/RecipeFormModels.swift` — MODIFY: add imageURL + author to RecipeFormData

#### UI Layer
- [ ] `forager/Views/Grocery/ManageStoresView.swift` — CREATE (replicate ManageCategoriesView pattern)
- [ ] `forager/Views/Grocery/AddStoreView.swift` — CREATE (name + color picker + suggested store chips)
- [ ] `forager/Views/Settings/SettingsView.swift` — MODIFY: add Stores row in Data Management section
- [ ] `forager/Views/Grocery/GroceryListDetailView.swift` — MODIFY: store grouping, context menu, toolbar toggle, color dots
- [ ] `forager/Theme/ForagerSectionHeader.swift` — MODIFY: optional colorDot parameter
- [ ] `forager/Theme/ForagerTheme+StoreColors.swift` — CREATE: hex→Color helper + default palette

#### Tests
- [ ] `foragerTests/Services/StoreServiceTests.swift` — CREATE
- [ ] `foragerTests/Services/WeeklyListServiceTests.swift` — MODIFY: store snapshot test

#### Docs
- [ ] `CLAUDE.md` — Update entity count (12), model version (v11), add Store to HouseholdScoped list

### Update Strategy (Dependency Order)

1. Core Data schema + model files (v11)
2. DataScope.swift (HouseholdScoped conformance)
3. StoreService (service layer)
4. GroceryListItemService + WeeklyListService (snapshot wiring)
5. RecipeImportService + RecipeService (attribution wiring)
6. UI views (ManageStoresView, GroceryListDetailView, SettingsView)
7. Tests

### Time Estimate (ADR 007 Formula)

- Schema + model files (10 files): 70min
- Service layer (6 files × 15min): 90min
- UI layer (6 files × 10min): 60min
- Tests (2 files × 15min): 30min
- Subtotal: 250min
- Buffer (30%): 75min
- **Total: 325min (~5.4h)** — conservative; actual estimate 7-10h including iteration

### Risk Assessment

- **High Risk**: `GroceryListDetailView.swift` — most complex changes (grouping logic, context menus, toolbar toggle). Existing category grouping must remain default and unchanged.
- **Medium Risk**: `GroceryListItemService.swift` — store snapshot must not break existing 3 creation paths (addItem, addIngredients batch, addStaples).
- **Low Risk**: Recipe attribution — purely additive optional fields, no behavioral changes.

---

## Sub-Milestones

### M18.1.0: Schema v11 + Model Files (1.2h)

Create `forager 11.xcdatamodel` with all changes from both features in one shot.

**Files**: See Core Data Layer checklist above.

**Verification**: Build project. All existing tests pass. No runtime behavior changes (zero stores exist).

### M18.1.1: StoreService + Factory Support (1.1h)

New service following established service layer pattern.

```swift
class StoreService {
    static func createStore(name:color:in:) -> Store
    static func deleteStore(_:reassignTo:in:)
    static func reorderStores(_:in:)
    static func fetchStores(in:) -> [Store]
    static func assignStore(_:toTemplate:in:)
    static func assignStore(_:toGroceryItem:in:)
    static func resolveStore(for:targetList:) -> Store?  // cross-store safe
}
```

Run `/forager-service-check` before implementation.

**Key design**: `resolveStore(for:targetList:)` mirrors `GroceryListItemService.resolveCategory()` for cross-store CloudKit safety.

### M18.1.2: Store Snapshot Wiring (0.6h)

When a `GroceryListItem` is created, snapshot the template's `preferredStore` onto the item.

**Files**: `GroceryListItemService.swift` (3 creation paths), `WeeklyListService.swift`

**Critical invariant**: `GroceryListItem.store` is a snapshot set at creation time, exactly like `categoryEntity`. Does NOT auto-update if template preference changes later.

### M18.1.3: Store Management UI (1.75h)

**Settings > Stores** (new section, below Categories in Data Management)

- List with color dot + name, drag to reorder
- Swipe to delete (reassignment dialog if templates assigned)
- Add store: name + color picker
- Empty state: `ContentUnavailableView`
- Suggested store chips on first use (Costco, Walmart, Target, Kroger, Whole Foods, Aldi, Trader Joe's)

Follow `ManageCategoriesView` pattern exactly.

### M18.1.4: Store Assignment UX + Color Dots + Grouping (1.75h)

**Assignment**:
- Long-press grocery list item → "Buy at..." → store picker
- Sets store on IngredientTemplate (learning) + current GroceryListItem
- Color dot indicator on items (only when store assigned, visible in both group modes)

**Grouping**:
- Toolbar toggle: "Group by Category" (default) | "Group by Store"
- Store sections: color dot + name + completion count in ForagerSectionHeader
- "Unassigned" section at bottom for items without store
- Sub-sort by category within each store section
- Persistence: `UserDefaults` key `groceryListGroupMode`

**Invisibility rule**: If `stores.isEmpty`, toolbar toggle hidden, grouping defaults to category.

### M10.4.0: Recipe Attribution Wiring (0.75h)

Persist `imageURL` and `author` from import extraction into Recipe entity.

**Wiring points**:
- `RecipeImportService.saveImport()` at ~line 182: add `recipe.imageURL = draft.imageURL.value` and `recipe.author = draft.author.value`
- `RecipeService.createRecipe()`: add optional `imageURL` and `author` parameters
- `RecipeFormModels.RecipeFormData`: add fields, update `toRecipeFormData()` mapping

**Note**: `imageURL` is stored but NOT rendered as an image in this milestone. Image rendering deferred to future milestone. The URL is persisted so it's available when that ships.

---

## Phase 2: Multi-Store + Shopping Trips (M18.2) — Deferred

**Status**: PLANNED (only if Phase 1 resonates with users)
**Estimated**: 6-10 hours

- M18.2.1: Multi-store per template (StorePreference join entity)
- M18.2.2: Shopping trip mode (single-store filtered view)
- M18.2.3: Smart store suggestions based on category patterns
- M18.2.4: Store-aware staple items
- M18.2.5: Price tracking (stretch)

---

## Architecture Considerations

### CloudKit Compatibility
- New entity with optional relationships = safe lightweight migration
- Store is HouseholdScoped → routes through household zone
- No destructive schema changes — append-only safe for CloudKit Production

### Household Sharing
- Stores are household-scoped: when a family member adds "Costco", all members see it
- Store assignments on templates are shared — "we buy milk at Costco" is a household fact

### Category vs. Store (they coexist)
- **Category** = what it is + aisle position within a store (Produce, Dairy, Pantry)
- **Store** = where you buy it (Costco, Heinen's, Target)
- Orthogonal dimensions — "Chicken breast" is always "Deli & Meat" category, but might be "Costco" store
- "Group by Store" mode uses category as a sub-sort within each store section

---

## Design Decisions

1. **No `isDefault` on Store** — Unlike Category ("Uncategorized" is protected), Store has no equivalent. Deletion protection is runtime: show reassignment dialog when `store.ingredientTemplates.count > 0`.
2. **Store color dots visible in both group modes** — Useful context regardless of active grouping.
3. **Filter chips deferred to Phase 2** — Section grouping sufficient for v1.
4. **imageURL stored but not rendered** — Persisted for future image display milestone.
5. **`GroceryListItem.store` is a snapshot** — Mirrors `categoryEntity` pattern exactly.

---

## Acceptance Criteria

### M18.1 (Store-Aware Shopping Phase 1)
- [ ] `forager 11.xcdatamodel` exists with Store entity and all new relationships
- [ ] App launches and migrates from v10 without data loss
- [ ] Store conforms to `HouseholdScoped` in DataScope.swift
- [ ] User can create/edit/delete/reorder stores in Settings > Stores
- [ ] User can assign a preferred store to any grocery list item via long-press
- [ ] Store assignment persists to IngredientTemplate.preferredStore for future lists
- [ ] New GroceryListItem snapshots preferredStore from template at creation time
- [ ] Grocery list has "Group by Store" / "Group by Category" toggle
- [ ] Store sections show color dot, store name, and completion count
- [ ] Items without a store appear in "Unassigned" section
- [ ] Stores are household-scoped and created via ManagedObjectFactory (ADR 014)
- [ ] All fetches include householdKey predicate (ADR 013)
- [ ] Feature invisible to users with no stores (no toggle, no dots)
- [ ] Existing category grouping unchanged and remains default
- [ ] Store deletion offers reassignment dialog
- [ ] Cross-store safety: resolveStore handles dual-store CloudKit correctly

### M10.4.0 (Recipe Attribution)
- [ ] Recipe entity has imageURL and author attributes
- [ ] RecipeImportService.saveImport() persists imageURL and author from draft
- [ ] RecipeService.createRecipe() accepts optional imageURL and author
- [ ] Existing recipes unaffected (nil values)

---

## Future Considerations

- **Recipe description, cuisine, category** on Recipe entity — deferred to future milestone. Import pipeline extracts these but they are not persisted yet.
- **Image rendering** from imageURL — deferred to future milestone (M11.1 Recipe Images)
- **Author display** in recipe views — can be added incrementally
- **M10.4 remaining scope** (import history, telemetry dashboard) — deferred, not needed for launch
