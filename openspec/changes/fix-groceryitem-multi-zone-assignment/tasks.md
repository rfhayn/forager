## 1. Investigation (confirm hypothesis before coding)

- [ ] 1.1 Re-read ADR 014 lines 45-69 (Child HouseholdScoped pattern + M9.19 CRITICAL) to confirm the expected invariant
- [ ] 1.2 Grep verify the full list of `GroceryListItem(context:)` production sites (11 currently catalogued in proposal.md); record any additions
- [ ] 1.3 Grep for `Ingredient(context:)` production sites; catalog separately
- [ ] 1.4 Read `ManagedObjectFactory.make()` to confirm it uses `context.assign(object, to: targetStore)` — yes per factory source line ~210
- [ ] 1.5 Read `PersistenceController.store(for:)` to confirm StoreID → NSPersistentStore resolution
- [ ] 1.6 Confirm on the dev's device (via Xcode device logs or by re-triggering the error) that the conflicted object is indeed a GroceryListItem whose list is in a different store than itself
- [ ] 1.7 Check if any Ingredient sites are in recipe-import batch paths where the parent Recipe is not saved yet at Ingredient creation time — these may need factory routing, not parent inference

## 2. Fix — production code

- [ ] 2.1 `Services/GroceryListItemService.swift:130` — add `viewContext.assign(item, to: list.objectID.persistentStore ?? <fallback>)` immediately after `let item = GroceryListItem(context: viewContext)`; fallback to first coordinator store with a DiagnosticLogger warning
- [ ] 2.2 `Services/GroceryListItemService.swift:239` (addStaples) — same pattern
- [ ] 2.3 `Services/MealPlanService.swift:959` — same pattern, parent from the containing WeeklyList context
- [ ] 2.4 `Services/HouseholdService.swift:1357` — identify the parent context, apply assign
- [ ] 2.5 `Services/HouseholdService.swift:1972` — same
- [ ] 2.6 `Services/HouseholdService.swift:2167` — same
- [ ] 2.7 `Services/WeeklyListService.swift:93` — same
- [ ] 2.8 `Services/QuantityMergeService.swift:232` — consolidated item is a new GroceryListItem; parent is the containing list
- [ ] 2.9 `forager/Views/Grocery/WeeklyListsView.swift:222` — view-layer creation; assign to the list's store
- [ ] 2.10 `forager/Views/Grocery/AddIngredientsToListView.swift:519` — same
- [ ] 2.11 Audit `Ingredient(context:)` sites and apply the pattern where the parent Recipe is already in a known store

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
