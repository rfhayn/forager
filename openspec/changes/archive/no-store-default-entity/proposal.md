## Why

Store assignment currently has no way to distinguish between "user hasn't assigned a store yet" and "user intentionally chose no specific store." Both states are `store = nil`. This means items like water or salt that a user deliberately leaves unassigned still trigger store-assignment nudges and show as "Unassigned" in grouping. Categories solved this with a protected "Uncategorized" entity: `categoryEntity = nil` means needs attention, `categoryEntity = Uncategorized` means settled. Stores need the same pattern.

## What Changes

- **Core Data schema v12**: Add `isDefault: Bool` attribute to Store entity (lightweight migration, append-only safe for CloudKit)
- **Store+CoreDataProperties.swift**: Add `isDefault` managed property
- **DefaultSeeder**: Seed a protected "No Store" entity (gray, sortOrder 999, isDefault true) alongside default categories
- **StoreService**: Protect default store from deletion and renaming. Add lookup method for the default store.
- **StoreAssignmentModal / StoreChangeModal**: "No Store" button assigns the "No Store" entity instead of setting `store = nil`
- **New item default**: Items without a store get the "No Store" entity (like items get "Uncategorized" category)
- **Store grouping**: "No Store" group uses the entity. `store = nil` means truly unassigned (shows indicator/nudge).
- **ManageStoresView**: "No Store" appears in list but cannot be deleted or renamed

## Capabilities

### New Capabilities
- `default-store`: Protected "No Store" entity with isDefault flag, mirroring the category "Uncategorized" pattern

### Modified Capabilities
- `store-aware-shopping`: Store assignment differentiates between "No Store" (settled) and nil (unassigned)
- `grocery-lists`: Store grouping uses "No Store" entity name instead of "Unassigned" string

## Impact

- **Core Data model**: Schema v11 → v12 (add isDefault to Store). Lightweight migration, no data transformation.
- **Models/Store+CoreDataProperties.swift**: Add `isDefault: Bool`
- **Services/Persistence/DefaultSeeder.swift**: Seed "No Store" entry
- **Services/StoreService.swift**: Protection logic, lookup method, default assignment
- **Views/Grocery/StoreAssignmentModal.swift**: Assign entity instead of nil
- **Views/Grocery/StoreChangeModal.swift**: Same
- **Views/Grocery/ManageStoresView.swift**: Protection from delete/rename
- **Services/GroceryListItemService.swift**: Default store assignment on new items
- **CloudKit**: Append-only boolean attribute, safe for Production schema
