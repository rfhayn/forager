## Context

Categories have a protected "Uncategorized" entity with `isDefault = true` (Category+CoreDataProperties). It's seeded by DefaultSeeder, protected from deletion in ManageCategoriesView, and used as the fallback when no category is assigned. The `lookupUncategorizedCategory()` method in IngredientTemplateService finds it by name + householdKey. DefaultSeeder creates it with sortOrder 999 and gray color (#9E9E9E).

Stores currently have no equivalent. The Store entity has: id, name, color, sortOrder, householdKey, household, dateCreated, updatedAt, plus relationships to ingredientTemplates and groceryListItems. No `isDefault` flag exists — this requires a schema migration.

The app is on Core Data schema v11. CloudKit Production schema is append-only (no destructive changes). Adding a boolean attribute with a default value is a safe lightweight migration.

## Goals / Non-Goals

**Goals:**
- Add `isDefault: Bool` to Store entity (schema v12)
- Seed a "No Store" entity on first launch and household creation
- Protect "No Store" from deletion and renaming
- Make "No Store" assignment an entity reference, not nil
- Make `store = nil` mean "truly unassigned, needs attention"
- Match the category Uncategorized pattern exactly

**Non-Goals:**
- Changing how categories work
- Adding store assignment indicators/nudges (that's a separate change)
- Changing the store management UI beyond protecting the default
- Auto-migrating existing nil-store items to "No Store" (users should decide)

## Decisions

### 1. Schema v12: single attribute addition

Add `isDefault: Bool` (default value: `false`, optional: no) to the Store entity. This is the same pattern as Category's `isDefault`. Lightweight migration handles this automatically. CloudKit Production schema accepts append-only attributes.

Follow ADR 007 process: create new model version, add attribute, update codegen files.

### 2. Seed alongside categories in DefaultSeeder

Add "No Store" to DefaultSeeder, seeded in the same pass as default categories. Properties: name "No Store", color "#9E9E9E" (gray, same as Uncategorized), sortOrder 999, isDefault true. Uses the factory pattern via `performScopedWrite` for correct CloudKit store assignment.

Add a `ensureNoStoreExists()` method parallel to `ensureUncategorizedExists()` for resilience on reinstall.

### 3. Lookup by isDefault flag, not by name

Create `StoreService.lookupDefaultStore()` that fetches by `isDefault == true AND householdKey == currentKey`. This is more robust than name matching since `isDefault` is a protected flag the user cannot change.

**Alternative considered**: Lookup by name convention (`name == "No Store"`). Rejected because it's fragile if the name ever needs localization.

### 4. StoreAssignmentModal: assign entity instead of nil

The "No Store" button currently calls `assignStore(nil)`. Change to `assignStore(defaultStore)` where defaultStore is the "No Store" entity. The visual presentation stays the same: a "No Store" option at the top of the list.

### 5. Do NOT auto-migrate existing nil items

Existing items with `store = nil` stay as nil after migration. Users can assign them to "No Store" explicitly. This avoids surprising data changes and respects the user's current state.

## Risks / Trade-offs

- **[Risk] CloudKit sync timing on new device** → Default store might not exist yet on a fresh install before CloudKit syncs. Mitigation: `ensureNoStoreExists()` creates it locally before store operations.
- **[Risk] Multiple "No Store" entities from multi-device seeding** → Same deduplication approach as categories: let each device seed, CloudKit syncs, deduplicator cleans up. Check if a StoreDeduplicator is needed (parallel to CategoryDeduplicator).
- **[Trade-off] Existing nil items not auto-migrated** → Users may need to manually assign items. This is acceptable: the "No Store" option appears in the assignment modal, and items with nil still show in the "Unassigned" group until the user addresses them.
