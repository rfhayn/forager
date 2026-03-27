# M18: Store-Aware Shopping

**Status**: PLANNED
**Estimated**: 12-18 hours (2 phases)
**Priority**: Post-launch feature
**Depends On**: M7.7 (App Store submission)
**Last Updated**: March 25, 2026
**Origin**: Beta tester feedback (Joe) — categories map to *what* you buy, but shopping decisions are about *where* you buy it.

---

## Problem Statement

Users shop at multiple stores (Costco, Heinen's, Target) and mentally track which items to buy where. The current category system organizes by food type (Produce, Dairy, Pantry) but cannot express store preference. This forces users to:

1. Mentally partition the grocery list by store while shopping
2. Miss items because they didn't think of "Costco items" while at Costco
3. Lose the efficiency of batching a store trip around the right items

**Joe's insight**: "Perhaps a shopping preference tab that allows me to pre-populate where I buy most stuff. Then it creates either separate lists or lists that identify a store — like a color or something that tells you where you should be buying what."

## Solution: Phased Store Preferences

### Design Principles

- **Additive, not disruptive** — store preferences layer on top of existing categories, never replace them
- **Organic learning** — users assign store preferences as they shop, not in a bulk setup wizard
- **Household-shared** — store preferences travel with the household (a family shares where they shop)
- **Optional** — users who shop at one store never see store features

---

## Phase 1: Store Preferences on Templates (M18.1)

**Estimated**: 6-8 hours (5 sub-phases)
**Goal**: Users can tag ingredient templates with a preferred store and view their grocery list grouped by store.

### M18.1.1: Store Entity + Schema (1-1.5h)

**New Core Data entity: `Store`**

| Property | Type | Notes |
|----------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | "Costco", "Heinen's", "Target" |
| `color` | String | Hex color code for visual indicator |
| `sortOrder` | Int16 | User-defined display order |
| `isDefault` | Bool | Protected flag (prevent deletion if in use) |
| `householdKey` | String? | Household scoping (ADR 008/013) |
| `household` | Household? | Relationship for zone routing |
| `dateCreated` | Date | |
| `updatedAt` | Date | Conflict resolution |

**New relationship on IngredientTemplate:**
- `preferredStore: Store?` — optional to-one relationship
- Inverse: `Store.ingredientTemplates: NSSet`

**New relationship on GroceryListItem:**
- `store: Store?` — snapshot from template at list-add time (like category snapshot pattern from M9.12)
- Inverse: `Store.groceryListItems: NSSet`

**Schema version**: v11 (lightweight migration — new entity + optional relationships)

**ADR 007 compliance**: New entity, new optional relationships, no destructive changes. CloudKit-safe.

**Factory enforcement**: Store is HouseholdScoped → must use `ManagedObjectFactory.make()` (ADR 014).

### M18.1.2: StoreService (1h)

New service following established service layer pattern:

```swift
class StoreService {
    // CRUD
    static func createStore(name:color:in:) -> Store
    static func deleteStore(_:reassignTo:in:) // reassign templates to another store or nil
    static func reorderStores(_:in:)

    // Query
    static func fetchStores(in:) -> [Store]
    static func storeForTemplate(_:) -> Store?

    // Assignment
    static func assignStore(_:to template:in:)
    static func assignStore(_:to groceryItem:in:)
    static func bulkAssignStore(_:to templates:[IngredientTemplate]:in:)
}
```

Run `/forager-service-check` before implementation to verify no overlap.

### M18.1.3: Store Management UI (1.5-2h)

**Settings > Stores** (new section, below Categories)

- List of stores with color dot + name
- Drag to reorder (same pattern as ManageCategoriesView)
- Swipe to delete (with reassignment dialog if templates are assigned)
- Add store: name + color picker (same hex color pattern as Category)
- Tap to edit name/color

**Empty state**: `ContentUnavailableView` — "Add stores you shop at to organize your grocery list by where you buy things."

**Suggested stores on first use**: Offer common store names (Costco, Walmart, Target, Kroger, Whole Foods, Aldi, Trader Joe's) as quick-add chips. User taps to add, can rename.

### M18.1.4: Store Assignment UX (1.5-2h)

**How users assign stores to ingredients:**

1. **Long-press on grocery list item** → context menu includes "Buy at…" → store picker
   - This sets the store on the underlying IngredientTemplate (learning for next time)
   - Also tags the current GroceryListItem

2. **Template detail** (if/when we add one) → store picker field

3. **Bulk assign on import** — after parsing, before save, user can tag items with a store
   - Low priority for Phase 1 — can defer to Phase 2

**Visual indicator on grocery list items:**
- Small color dot (matching store color) to the left of the item name
- Subtle, doesn't compete with category section headers
- Only shown when item has a store assigned

### M18.1.5: "Group by Store" View Mode (1.5-2h)

**New toggle in GroceryListDetailView toolbar:**

Current: items grouped by Category (default, unchanged)
New: items grouped by Store

**"By Store" mode:**
- Section headers show store name + store color dot + completion count
- Items without a store go in an "Unassigned" section at the bottom
- Within each store section, items are sub-sorted by category sortOrder (maintains aisle logic within a store)
- Collapsible sections (same pattern as category sections)

**Toggle persistence**: UserDefaults key `groceryListGroupMode` — values: `"category"` (default), `"store"`

**Filter chips** (stretch goal for Phase 1):
- Horizontal scroll row at top: "All | Costco | Heinen's | Target"
- Tap to filter list to one store — "shopping trip mode"
- Active chip highlighted with store color

---

## Phase 2: Multi-Store + Shopping Trips (M18.2)

**Estimated**: 6-10 hours
**Goal**: Power features for multi-store households.
**Status**: PLANNED (only if Phase 1 resonates with users)

### M18.2.1: Multi-Store per Template

- Change `preferredStore` from to-one to to-many via join entity `StorePreference`
- `StorePreference`: IngredientTemplate ↔ Store + `priority: Int16` + `notes: String?`
- Example: "Chicken breast" → Costco (primary, bulk), Heinen's (secondary, quick trip)
- UI: store picker allows multiple selection with drag-to-prioritize

### M18.2.2: Shopping Trip Mode

- Dedicated "Start Trip" action: select a store → filtered list with only that store's items
- Check-off experience optimized for single-store context
- Trip history: when did you last shop at each store? (lightweight tracking)
- "You're missing 3 Costco items that are on your list" nudge

### M18.2.3: Smart Store Suggestions

- After N items are manually assigned to a store, suggest the store for similar items
- Leverage category as a signal: "You buy most Produce at Heinen's — assign this too?"
- Optional, behind a toggle

### M18.2.4: Staple Items per Store

- Extend `isStaple` on IngredientTemplate to be store-aware
- "Costco staples" vs "Weekly Heinen's staples"
- Auto-populate list sections when starting a new weekly list

### M18.2.5: Price Tracking (Stretch)

- Optional price field on StorePreference
- "You usually pay $X at Costco vs $Y at Heinen's"
- Way out of scope for initial release — note for future ideation only

---

## Data Model Summary

### Phase 1 (M18.1)

```
Store (NEW)
├── id: UUID
├── name: String
├── color: String (hex)
├── sortOrder: Int16
├── householdKey: String?
├── household: Household?
├── ingredientTemplates: [IngredientTemplate] (inverse of preferredStore)
└── groceryListItems: [GroceryListItem] (inverse of store)

IngredientTemplate (MODIFIED)
└── + preferredStore: Store? (to-one, optional)

GroceryListItem (MODIFIED)
└── + store: Store? (to-one, optional, snapshot at add-time)
```

### Phase 2 (M18.2)

```
StorePreference (NEW — replaces direct relationship)
├── id: UUID
├── priority: Int16
├── notes: String?
├── ingredientTemplate: IngredientTemplate
└── store: Store
```

---

## Architecture Considerations

### CloudKit Compatibility
- New entity with optional relationships = safe lightweight migration
- Store is HouseholdScoped → routes through household zone
- No destructive schema changes — append-only safe for CloudKit Production

### Household Sharing
- Stores are household-scoped: when a family member adds "Costco", all members see it
- Store assignments on templates are shared — "we buy milk at Costco" is a household fact
- Individual shopping trips could be per-user in Phase 2

### Migration Path
- Existing users get zero stores, zero store assignments — feature is invisible until they add a store
- No data migration needed beyond schema version bump
- Categories continue to work exactly as before

### Category vs. Store (they coexist)
- **Category** = what it is + aisle position within a store (Produce, Dairy, Pantry)
- **Store** = where you buy it (Costco, Heinen's, Target)
- These are orthogonal dimensions — "Chicken breast" is always "Deli & Meat" category, but might be "Costco" store
- "Group by Store" mode uses category as a sub-sort within each store section

---

## Acceptance Criteria

### Phase 1
- [ ] User can create/edit/delete/reorder stores in Settings
- [ ] User can assign a preferred store to any grocery list item via long-press
- [ ] Store assignment persists to the IngredientTemplate for future lists
- [ ] Grocery list has a "Group by Store" toggle
- [ ] Store sections show color dot, store name, and completion count
- [ ] Items without a store appear in "Unassigned" section
- [ ] Stores are household-scoped and sync via CloudKit
- [ ] Feature is invisible to users who haven't created any stores
- [ ] Existing category grouping is unchanged and remains the default

### Phase 2
- [ ] Multi-store per template with priority ordering
- [ ] Shopping trip mode (single-store filtered view)
- [ ] Smart store suggestions based on category patterns
- [ ] Store-aware staple items

---

## Open Questions

1. **Should store color dots appear in "Group by Category" mode too?** Leaning yes — it's useful context even when not actively grouping by store.
2. **Filter chips in Phase 1 or Phase 2?** Could be a quick win in Phase 1 if the section grouping alone feels incomplete.
3. **Store suggestions on first launch?** Pre-populated list of common chains, or start empty? Leaning toward suggested chips that the user taps to add.
4. **Price tracking scope** — Joe didn't mention price, but "where should I buy this" often implies "where is it cheapest." Park for now.
5. **Aisle numbers within a store?** "Aisle 3 at Costco" — useful but significant scope creep. Category sort order already approximates this. Defer.
