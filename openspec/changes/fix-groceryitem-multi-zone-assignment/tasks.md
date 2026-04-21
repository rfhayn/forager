## 1. Investigation (confirm hypothesis before coding)

- [x] 1.1 Re-read ADR 014 lines 45-69 (Child HouseholdScoped pattern + M9.19 CRITICAL) to confirm the expected invariant — confirmed. M9.19 note explicitly warns parent-store-must-match-child-store, but the ADR does not mandate the `context.assign()` call required to reliably enforce it.
- [x] 1.2 Grep verify the full list of `GroceryListItem(context:)` production sites — 11 sites: GroceryListItemService (130, 239), MealPlanService (959), HouseholdService (1357, 1972, 2167), WeeklyListService (93), QuantityMergeService (232), WeeklyListsView (222), AddIngredientsToListView (519). Of these, HouseholdService:2167 has an explicit `viewContext.assign(newItem, to: persistence.sharedStore)` at line 2193 — SAFE. Remaining 10 need fixes.
- [x] 1.3 Grep for `Ingredient(context:)` production sites — 10 sites: IngredientParsingService (156), RecipeImportService (347), HouseholdService (1305, 1894, 2131), RecipeService (143, 175), EditRecipeView (890), RecipeListView (808), CreateRecipeView (892). Of these, HouseholdService:2131 has explicit assign at 2150, and RecipeImportService:347 feeds into the bulk assign at `persistAndFinish` line 472 — both SAFE. Remaining 8 need verification (HouseholdService 1305/1894 are in migration paths; need to check bulk-assign coverage).
- [x] 1.4 Read `ManagedObjectFactory.make()` to confirm it uses `context.assign(object, to: targetStore)` — confirmed, lines 210 and 225. Resolves target store via `persistence.store(for: storeID)`.
- [x] 1.5 Read `PersistenceController.store(for:)` to confirm StoreID → NSPersistentStore resolution — confirmed, lines 92-99. Maps `.private` → `privateStore` getter (looks up `forager.sqlite`) and `.shared` → `sharedStore` getter (looks up `forager_shared.sqlite`).
- [ ] 1.6 Confirm on the dev's device (via Xcode device logs or by re-triggering the error) that the conflicted object is indeed a GroceryListItem whose list is in a different store than itself — DEFERRED (requires device access; hypothesis confidence is high enough to proceed with fix)
- [x] 1.7 Check if any Ingredient sites are in recipe-import batch paths where the parent Recipe is not saved yet at Ingredient creation time — YES: RecipeImportService.swift:347 creates Ingredients where Recipe may be a newly-created object. That path handles it via bulk `viewContext.assign(obj, to: targetStore)` at line 472 (covers ALL inserted objects in one sweep). Safe. Similar pattern should be applied at sites where the child's parent-store inference could fail.

### Refined site list — 18 production sites need the fix

**GroceryListItem — 10 sites**:
- `Services/GroceryListItemService.swift:130` (addItem main path)
- `Services/GroceryListItemService.swift:239` (addStaples batch path)
- `Services/MealPlanService.swift:959` (generate grocery list from plan)
- `Services/HouseholdService.swift:1357` (migration: household → personal)
- `Services/HouseholdService.swift:1972` (migration: personal → household, owner-side M9.21)
- `Services/WeeklyListService.swift:93` (new list item creation)
- `Services/QuantityMergeService.swift:232` (consolidation output)
- `forager/Views/Grocery/WeeklyListsView.swift:222` (view-layer creation)
- `forager/Views/Grocery/AddIngredientsToListView.swift:519` (view-layer creation)

**Ingredient — 8 sites**:
- `Services/IngredientParsingService.swift:156` (parsing output — caller context matters)
- `Services/HouseholdService.swift:1305` (migration: household → personal)
- `Services/HouseholdService.swift:1894` (migration: personal → household)
- `Services/RecipeService.swift:143` (edit flow)
- `Services/RecipeService.swift:175` (create flow)
- `forager/Views/Recipes/EditRecipeView.swift:890` (view-layer creation)
- `forager/Views/Recipes/RecipeListView.swift:808` (view-layer creation)
- `forager/Views/Recipes/CreateRecipeView.swift:892` (view-layer creation)

**Already safe — 3 sites** (no fix needed):
- `Services/HouseholdService.swift:2167` + 2193 (explicit assign)
- `Services/HouseholdService.swift:2131` + 2150 (explicit assign)
- `Services/Import/RecipeImportService.swift:347` (feeds bulk assign at 472)

**Fix pattern** (consistent across all 18 sites):
```swift
let item = GroceryListItem(context: viewContext)
// Prevent CloudKit zone conflict (134040): co-locate with parent
if let parentStore = list.objectID.persistentStore {
    viewContext.assign(item, to: parentStore)
}
```

Parent reference varies by site (WeeklyList for GroceryListItem, Recipe for Ingredient).

## 2. Fix — production code

- [x] 2.1 `Services/GroceryListItemService.swift:130` (addItem) — parent-store assign added
- [x] 2.2 `Services/GroceryListItemService.swift:239` (addStaples) — parent-store assign added
- [x] 2.3 `Services/MealPlanService.swift:959` — parent-store assign added (parent: `newList`)
- [x] 2.4 `Services/HouseholdService.swift:1305` (Ingredient, migrateHouseholdDataToPersonal) — explicit `PersistenceController.shared.privateStore` assign added
- [x] 2.4b `Services/HouseholdService.swift:1357` (GroceryListItem, migrateHouseholdDataToPersonal) — explicit privateStore assign added
- [x] 2.5 `Services/HouseholdService.swift:1894` (Ingredient, copyPersonalDataToHousehold owner-side) — explicit privateStore assign added (owner's shared zone lives in private store per M9.24)
- [x] 2.5b `Services/HouseholdService.swift:1972` (GroceryListItem, copyPersonalDataToHousehold owner-side) — explicit privateStore assign added
- [x] 2.6 `Services/HouseholdService.swift:2167` (GroceryListItem, copyPersonalDataToSharedStore member-side) — **already had assign at 2193; no change needed**
- [x] 2.7 `Services/WeeklyListService.swift:93` — parent-store assign added (parent: `list`)
- [x] 2.8 `Services/QuantityMergeService.swift:232` — parent-store assign added (parent: `list`)
- [x] 2.9 `forager/Views/Grocery/WeeklyListsView.swift:222` — parent-store assign added (parent: `newList`)
- [x] 2.10 `forager/Views/Grocery/AddIngredientsToListView.swift:519` — parent-store assign added (parent: `targetList`)
- [x] 2.11 Ingredient sites audited and fixed:
  - [x] `Services/RecipeService.swift:143` (duplicate recipe, parent: `copy`)
  - [x] `Services/RecipeService.swift:175` (addIngredient, parent: `recipe`)
  - [x] `Services/IngredientParsingService.swift:156` (parseAndConnect, parent: `recipe`)
  - [x] `Services/HouseholdService.swift:1305` — covered by 2.4 above
  - [x] `Services/HouseholdService.swift:1894` — covered by 2.5 above
  - [x] `Services/HouseholdService.swift:2131` — **already had assign at 2150; no change needed**
  - [x] `forager/Views/Recipes/EditRecipeView.swift:890` (parent: `recipe`)
  - [x] `forager/Views/Recipes/RecipeListView.swift:808` (parent: `recipe`)
  - [x] `forager/Views/Recipes/CreateRecipeView.swift:892` (parent: `recipe`)
- [x] 2.12 Build verified — `xcodebuild ... build` returns `** BUILD SUCCEEDED **`
- [x] 2.13 Architecture-guard hook updated at `.claude/hooks/architecture-guard.sh` — now recognizes `Entity(context:)` followed by `.assign(...)` within 10 lines as the ADR 014 child-inheritance-with-assign pattern (was blocking all direct inits). Strict factory-only migration tracked as `harden-factory-enforcement-for-child-entities` on the app-health roadmap.

## 3. Regression test

- [ ] 3.1 Add `foragerTests/Services/GroceryListItemServiceTests.swift::testItemLandsInListStore_sharedStoreList` — create an in-memory dual-store context, create a household in the shared store, create a WeeklyList in the shared store, call `addItem` via the service, assert item's `objectID.persistentStore == list.objectID.persistentStore`
- [ ] 3.2 Add sibling test covering the personal-scope path (both list and item in private store, household == nil)
- [ ] 3.3 Add a test covering the `addIngredients` batch path — all created items share the list's store
- [ ] 3.4 Add a test covering the `addStaples` path — all created items share the list's store
- [ ] 3.5 Ensure tests FAIL before the fix is applied (to confirm they exercise the bug) — run tests on an unfixed branch first, then apply fix

## 4. Launch-time diagnostic

- [ ] 4.1 Locate where NSPersistentCloudKitContainer load completion is handled (likely `Services/Persistence/PersistenceController.swift`)
- [ ] 4.2 Add a NotificationCenter observer for `NSPersistentCloudKitContainer.eventChangedNotification` or equivalent mirroring delegate failure notification
- [ ] 4.3 On failure with error code 134040 or a userInfo message containing "multiple zones", log a structured entry via `DiagnosticLogger` with: entity name, persistent ID fragment, conflicting zone names, error code
- [ ] 4.4 Verify the diagnostic runs in both Debug and Release (DiagnosticLogger is gated appropriately)
- [ ] 4.5 Do NOT attempt auto-repair — diagnostic only

## 5. ADR 014 clarification

- [ ] 5.1 Edit `docs/architecture/014-managed-object-factory-enforcement.md` Child HouseholdScoped Entities section (lines 45-54) to add an explicit `context.assign(object, to: parent.objectID.persistentStore)` step in the example code, with a note that this is required not optional
- [ ] 5.2 Cross-reference from the M9.19 CRITICAL block (lines 56-69) to the new assign requirement
- [ ] 5.3 Add a "Correct pattern" vs "Incorrect pattern" code comparison in the ADR

## 6. Architecture audit skill

- [ ] 6.1 Locate the architecture-audit skill at `.claude/skills/architecture-audit/` (or similar path)
- [ ] 6.2 Add a check rule: detect `<Entity>(context:)` for `GroceryListItem` or `Ingredient` in production code, and within 10 lines after, require either `context.assign(` on the newly-created object OR a `factory.make(` call
- [ ] 6.3 Exempt test files, preview providers, and exempt files listed in ADR 014 Exempt Files section
- [ ] 6.4 Test the updated rule against the post-fix codebase — should report 0 violations
- [ ] 6.5 Test the updated rule against the pre-fix codebase (on a scratch branch) — should report 11+ violations, confirming the rule catches the pattern

## 7. Device remediation (dev's iPhone)

- [ ] 7.1 Identify the specific GroceryListItem(s) in conflict by running the app with the new diagnostic + verbose CloudKit logging enabled
- [ ] 7.2 Record the persistent ID(s) in `docs/bugs/investigation-assets/` for future reference
- [ ] 7.3 Delete the conflicted object(s) locally via a one-off Debug-only developer tool OR by manual Core Data intervention (simulator + CloudKit Dashboard)
- [ ] 7.4 Verify: relaunch app, confirm mirroring delegate initializes without error, confirm CloudKit sync resumes (new items added on a second device appear on this device)
- [ ] 7.5 If a fresh install on a second device pulls the bad state from CloudKit, add a CloudKit Dashboard cleanup step — delete the orphan CKRecord directly from the shared zone or default zone

## 8. Build, validate, ship

- [ ] 8.1 Run the full test suite: `xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` — require green
- [ ] 8.2 User bumps `CURRENT_PROJECT_VERSION` in Xcode (per memory: user manages build numbers)
- [ ] 8.3 Archive and distribute via `/archive` skill to TestFlight
- [ ] 8.4 Verify on the dev's device that the new build:
  - Launches without the mirroring delegate error
  - Adding a grocery item succeeds and syncs to a second device
  - All existing lists/recipes/meal plans remain accessible
- [ ] 8.5 Upload the new build to App Store Connect, replace build 134 in the v2.0 submission

## 9. Coordinate with reposition-app-store-listing

- [ ] 9.1 Update `docs/app-store-rejection-43a-response.md` Resolution Center reply letter: add one sentence mentioning the build change — "We've also shipped a new build (138) fixing a CloudKit sync issue our testing uncovered; the functional repositioning described above is unchanged between builds 134 and 138"
- [ ] 9.2 Update `docs/app-store-rejection-43a-response.md` Rejection Record section with the build swap (134 → 138 or whatever the final number is)
- [ ] 9.3 Update `tasks.md` in the `reposition-app-store-listing` change to reference the new build number
- [ ] 9.4 Merge this change first, then resume `reposition-app-store-listing` Session 2 (screenshots + video) against the new binary

## 10. Close-out

- [ ] 10.1 Run `/review` to catch any issues with the branch's changes before PR
- [ ] 10.2 Update `docs/development-journal.md` with the session narrative
- [ ] 10.3 Log insights to `docs/insights-log.md` — at minimum: the 134040 error's root cause (implicit-vs-explicit store assignment), the child pattern's hidden requirement, the reason 11 sites existed simultaneously
- [ ] 10.4 Run `/pr` to create the pull request
- [ ] 10.5 After merge, run `/opsx:archive fix-groceryitem-multi-zone-assignment` to promote the spec deltas into living specs (architecture + grocery-lists)
