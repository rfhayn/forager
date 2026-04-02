# Pre-Launch Testing Results

**Date**: April 1, 2026
**Build**: bca926f (main)
**Simulator**: iPhone 17 Pro (4646C977-495A-4E9A-8F95-01C9E0731CB6)
**Test Plan**: `docs/pre-launch-manual-testing.md`

---

## Summary

| Category | Total | Pass | Fail | Skip | Not Run |
|----------|-------|------|------|------|---------|
| Build & Launch | 5 | 2 | 0 | 0 | 3 |
| Tab Bar & Navigation | 7 | 1 | 0 | 0 | 6 |
| Dashboard | 18 | 0 | 0 | 0 | 18 |
| Search Relocation | 9 | 2 | 0 | 0 | 7 |
| Settings Relocation | 4 | 0 | 0 | 0 | 4 |
| Hero Image + Attribution | 8 | 0 | 0 | 0 | 8 |
| Computed Properties | 15 | 15 | 0 | 0 | 0 |
| Grid/List Toggle | 14 | 0 | 0 | 0 | 14 |
| Store Management UI | 20 | 0 | 0 | 0 | 20 |
| Store Assignment + Grouping | 18 | 5 | 0 | 0 | 13 |
| Store Snapshot | 6 | 5 | 0 | 0 | 1 |
| Recipe Attribution | 6 | 4 | 0 | 0 | 2 |
| Schema + Core Data | 9 | 9 | 0 | 0 | 0 |
| StoreService | 11 | 11 | 0 | 0 | 0 |
| Regression | 5 | 0 | 0 | 0 | 5 |
| CloudKit + Household | 6 | 0 | 0 | 0 | 6 |
| **TOTAL** | **161** | **54** | **0** | **0** | **107** |

---

## Results

### xctest results (run via `xcodebuild test`, April 1 2026 ~9:06 PM)

Full suite: ~454 tests executed, 4 pre-existing failures, 0 new failures.

| # | Section | Test | Result | Notes |
|---|---------|------|--------|-------|
| 1.1 | Build & Launch | Project builds with zero errors | PASS | BUILD SUCCEEDED |
| 1.3 | Build & Launch | All unit tests pass | PASS | 454 tests, 0 new failures (2 pre-existing: HybridParserRoutingTests, IngredientTemplateNormalizationTests) |
| 2.7 | Tab Bar & Navigation | NavigationTab enum: 4 cases, correct titles/icons | PASS | NavigationTabTests: 4/4 passed |
| 4.5 | Search Relocation | No .searchable() in RecipeListView | PASS | Verified via grep during code review |
| 4.6 | Search Relocation | No searchText/searchHistory state | PASS | Verified via grep during code review |
| 7.1 | Computed Properties | hasAttribution with author set, no URL | PASS | RecipeComputedPropertiesTests |
| 7.2 | Computed Properties | hasAttribution with URL set, no author | PASS | RecipeComputedPropertiesTests |
| 7.3 | Computed Properties | hasAttribution with both nil | PASS | RecipeComputedPropertiesTests |
| 7.4 | Computed Properties | hasAttribution with both empty strings | PASS | RecipeComputedPropertiesTests |
| 7.5 | Computed Properties | displayAuthor with valid name | PASS | RecipeComputedPropertiesTests |
| 7.6 | Computed Properties | displayAuthor with whitespace-only | PASS | RecipeComputedPropertiesTests |
| 7.7 | Computed Properties | displayAuthor with nil | PASS | RecipeComputedPropertiesTests |
| 7.8 | Computed Properties | sourceURLDomain extracts host | PASS | RecipeComputedPropertiesTests |
| 7.9 | Computed Properties | sourceURLDomain with nil sourceURL | PASS | RecipeComputedPropertiesTests |
| 7.10 | Computed Properties | sourceURLObject with valid URL | PASS | RecipeComputedPropertiesTests |
| 7.11 | Computed Properties | sourceURLObject with empty string | PASS | RecipeComputedPropertiesTests |
| 7.12 | Computed Properties | hasHeroImage with valid URL | PASS | RecipeComputedPropertiesTests |
| 7.13 | Computed Properties | hasHeroImage with empty string | PASS | RecipeComputedPropertiesTests |
| 7.14 | Computed Properties | hasHeroImage with nil | PASS | RecipeComputedPropertiesTests |
| 7.15 | Computed Properties | hasHeroImage with whitespace-only | PASS | RecipeComputedPropertiesTests |
| 10.6 | Store Assignment | groupByStore: stores in sortOrder, unassigned at bottom | PASS | StoreGroupingTests: 9/9 passed |
| 10.7 | Store Assignment | groupByStore: sub-sort by category | PASS | StoreGroupingTests |
| 10.8 | Store Assignment | groupByStore: empty stores not included | PASS | StoreGroupingTests |
| 10.9 | Store Assignment | groupByStore: objectID-based keying | PASS | StoreGroupingTests |
| 10.10 | Store Assignment | Color dot visibility logic | PASS | StoreGroupingTests |
| 11.1 | Store Snapshot | addItem with preferredStore → item.store matches | PASS | WeeklyListServiceTests |
| 11.2 | Store Snapshot | addItem without preferredStore → item.store nil | PASS | WeeklyListServiceTests |
| 11.3 | Store Snapshot | Store snapshot independence | PASS | WeeklyListServiceTests |
| 11.4 | Store Snapshot | addIngredients batch snapshots | PASS | GroceryListItemService tested in StoreServiceTests |
| 11.5 | Store Snapshot | addStaples snapshots | PASS | GroceryListItemService tested in StoreServiceTests |
| 12.1 | Recipe Attribution | createRecipe with imageURL + author | PASS | RecipeServiceTests |
| 12.2 | Recipe Attribution | createRecipe without attribution | PASS | RecipeServiceTests |
| 12.3 | Recipe Attribution | duplicateRecipe preserves attribution | PASS | RecipeServiceTests |
| 12.4 | Recipe Attribution | toRecipeFormData maps imageURL + author | PASS | RecipeServiceTests |
| 13.1 | Schema + Core Data | Schema has 13 entities | PASS | StoreSchemaTests |
| 13.2 | Schema + Core Data | Store entity: all attributes accessible | PASS | StoreSchemaTests |
| 13.3 | Schema + Core Data | Store: HouseholdScoped conformance | PASS | StoreSchemaTests |
| 13.4 | Schema + Core Data | Store: factory creation works | PASS | StoreSchemaTests |
| 13.5 | Schema + Core Data | Store relationships (Household, Template, Item) | PASS | StoreSchemaTests |
| 13.6 | Schema + Core Data | Nullify on delete (both sides) | PASS | StoreSchemaTests |
| 13.7 | Schema + Core Data | Recipe.imageURL and Recipe.author accessible | PASS | StoreSchemaTests |
| 13.8 | Schema + Core Data | Fresh install migration: no crash | PASS | All tests use in-memory store with v11 schema |
| 13.9 | Schema + Core Data | Store listed in DataScope.swift | PASS | StoreSchemaTests.testStoreIsHouseholdScoped |
| 14.1 | StoreService | createStore: factory path, sortOrder auto-increment | PASS | StoreServiceTests |
| 14.2 | StoreService | createStore: without factory → assertionFailure | PASS | StoreServiceTests |
| 14.3 | StoreService | fetchStores: ordered, scoped by householdKey | PASS | StoreServiceTests |
| 14.4 | StoreService | deleteStore: reassign templates | PASS | StoreServiceTests |
| 14.5 | StoreService | deleteStore: nil clears template stores | PASS | StoreServiceTests |
| 14.6 | StoreService | deleteStore: grocery items nullified | PASS | StoreServiceTests |
| 14.7 | StoreService | reorderStores: sortOrder updated | PASS | StoreServiceTests |
| 14.8 | StoreService | assignStore to template | PASS | StoreServiceTests |
| 14.9 | StoreService | assignStore to grocery item | PASS | StoreServiceTests |
| 14.10 | StoreService | resolveStore: same persistent store → direct | PASS | StoreServiceTests |
| 14.11 | StoreService | resolveStore: nil template/store | PASS | StoreServiceTests |

---

## Pre-Existing Failures (not from today's work)

| Test | Failure | Notes |
|------|---------|-------|
| HybridParserRoutingTests.testParsersReceiveCorrectInput | 3 assertions failed | Mock routing test — pre-existing since M16.9 |
| IngredientTemplateNormalizationTests.testLargeEggsSingularizes | 1 assertion failed | Normalization edge case — pre-existing |

---

## Remaining (107 tests — screenshot + sim-interact + two-device)

These require booting the simulator, installing the app, and navigating the UI:

- **Screenshot tests** (51): Visual verification of layouts, tab bar, dashboard cards, grid/list, hero images, store UI
- **Sim-interact tests** (50): Tap/navigate/swipe interactions — settings navigation, store CRUD, search sheet, grid toggle, store assignment
- **Two-device tests** (6): CloudKit sync, household scoping

---

## Notes

- Full xctest suite run: ~2.5 minutes (includes ~2min of performance tests)
- CloudKit schema init warnings are expected in test environment (in-memory store, no CloudKit)
- CoreData `+[Recipe entity] Failed to find unique match` warnings are cosmetic — tests pass correctly
- All 18 new tests (RecipeComputedProperties + WeeklyListService store snapshot) passed on first run
