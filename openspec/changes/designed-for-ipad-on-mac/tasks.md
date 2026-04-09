## 1. Enable Mac Distribution

- [x] 1.1 Flip `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES` in project.pbxproj (Debug + Release configurations)
- [x] 1.2 Archive foragerMac App Store Connect record (ID 6761905908) to avoid conflict with iOS listing

## 2. Camera Feature Gating

- [x] 2.1 Hide "Scan Document" button in PhotoImportView when `ProcessInfo.processInfo.isiOSAppOnMac == true`
- [x] 2.2 Hide document scanner option from recipe import menu in RecipeListView on Mac
- [x] 2.3 Verify photo library picker (PhotosPicker) still works on Mac

## 3. Device Name Extraction

- [x] 3.1 Add Mac device types ("Mac", "MacBook", "iMac", "Mac mini", "Mac Pro", "Mac Studio") to DashboardView device name parsing (~line 217)
- [x] 3.2 Add same Mac device types to HouseholdService device name extraction (~line 3105)
- [x] 3.3 Add fallback in DiagnosticLogger for Mac device name (~line 77, 90)

## 4. Font Size Fixes

- [x] 4.1 Bump 8pt font to 11pt in IngredientMatchRow.swift:209
- [x] 4.2 Bump 10pt font to 11pt in DashboardView.swift:428
- [x] 4.3 Bump 8pt font to 11pt in RecipeListView.swift:2175

## 5. Pull-to-Refresh Alternative

- [x] 5.1 Add toolbar refresh button to WeeklyListsView for Mac (alongside existing .refreshable)
- [x] 5.2 Add toolbar refresh button to MealPlanListView for Mac (alongside existing .refreshable)

## 6. Sheet Dismiss Behavior

- [x] 6.1 Make .interactiveDismissDisabled conditional on Mac in RecipeImportSheet.swift:118 (allow dismiss — no unsaved edits)
- [x] 6.2 Make .interactiveDismissDisabled conditional on Mac in AddIngredientsToListView.swift:232 (allow dismiss — no unsaved edits)
- [x] 6.3 Make .interactiveDismissDisabled conditional on Mac in MealPlanIngredientSelectionView.swift:60 (allow dismiss when not adding)
- [x] 6.4 Keep .interactiveDismissDisabled on CreateRecipeView.swift:193 and EditRecipeView.swift:186 (has unsaved edits — protect on all platforms)

## 7. NavigationView → NavigationStack Migration

- [x] 7.1 Migrate NavigationView → NavigationStack in Recipe views: AddIngredientView, CreateRecipeView, EditRecipeView, IngredientsView
- [x] 7.2 Migrate NavigationView → NavigationStack in Grocery views: StoreChangeModal, CategoryChangeModal, AddCategoryView, AddStoreView, AddIngredientsToListView, AddListItemView, ManageStoresView, ManageCategoriesView, WeeklyListsView, EditStapleView, AddStapleView, GroceryListDetailView
- [x] 7.3 Migrate NavigationView → NavigationStack in MealPlanning views: MealPlanIngredientSelectionView, CreateMealPlanSheet, MealPlanListView, SelectMealPlanSheet
- [x] 7.4 Migrate NavigationView → NavigationStack in Components: SelectListSheet

## 8. Adaptive Grid Layouts

- [x] 8.1 Change fixed 5-column grid to adaptive in AddCategoryView.swift:44
- [x] 8.2 Change fixed 5-column grid to adaptive in AddStoreView.swift:52

## 9. Sheet Presentation Detents

- [x] 9.1 Use larger detent for DuplicateResolutionSheet.swift:92 on Mac
- [x] 9.2 Use larger detent for RecipeListView.swift:1316/1734 on Mac
- [x] 9.3 Use larger detent for GroceryListDetailView.swift:158 on Mac

## 10. Build and Verify

- [x] 10.1 Build iOS target — confirm zero regressions from NavigationStack migration and platform guards
- [ ] 10.2 Archive and upload to TestFlight — verify Mac build installs via TestFlight
- [ ] 10.3 Manual QA on Mac: test all import flows, dashboard greeting, grocery lists, meal plans, recipe views
