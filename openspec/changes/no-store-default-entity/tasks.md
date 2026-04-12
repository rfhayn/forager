## 1. Schema v12 Migration

- [x] 1.1 Create new Core Data model version (v12) from v11
- [x] 1.2 Add `isDefault` attribute to Store entity: Bool, default value false, non-optional
- [x] 1.3 Set v12 as current model version
- [x] 1.4 Update Store+CoreDataProperties.swift: add `@NSManaged public var isDefault: Bool`

## 2. Default Store Seeding

- [x] 2.1 Add "No Store" to DefaultSeeder: name "No Store", color "#9E9E9E", sortOrder 999, isDefault true
- [x] 2.2 Add `ensureNoStoreExists(in:)` method to DefaultSeeder (parallel to `ensureUncategorizedExists`)
- [x] 2.3 Call `ensureNoStoreExists` from PersistenceController and HouseholdService (same places that call ensureUncategorizedExists)

## 3. StoreService Updates

- [x] 3.1 Add `lookupDefaultStore()` method: fetch by `isDefault == true AND householdKey`
- [x] 3.2 Add deletion protection: prevent deleting stores where `isDefault == true`
- [x] 3.3 Add rename protection: ManageStoresView filters out isDefault stores from list

## 4. Store Assignment UI

- [x] 4.1 Update StoreAssignmentModal: "No Store" button assigns the default store entity instead of nil
- [x] 4.2 Update StoreChangeModal: same change for bulk assignment
- [x] 4.3 Update ManageStoresView: filter isDefault stores from management list

## 5. Default Store on New Items

- [x] 5.1 Update GroceryListItemService: resolveStore returns default "No Store" when no preferred store
- [x] 5.2 Add lookupDefaultStore helper to GroceryListItemService

## 6. Store Grouping Update

- [x] 6.1 Store grouping works naturally: "No Store" entity items group under entity name, nil items still group as "Unassigned"
- [x] 6.2 Ordering: specific stores by sortOrder, then "No Store" (sortOrder 999), then "Unassigned" at bottom

## 7. Build and Verify

- [x] 7.1 Build iOS target — confirm zero errors
- [ ] 7.2 Test fresh install: "No Store" entity seeded alongside categories
- [ ] 7.3 Test store assignment: "No Store" option assigns entity, not nil
- [ ] 7.4 Test store grouping: "No Store" group and "Unassigned" group appear separately
- [ ] 7.5 Test ManageStoresView: "No Store" cannot be deleted or renamed
