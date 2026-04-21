## Why

CoreData error 134040 ("Object graph corruption detected — objects related to GroceryListItem/p20 are assigned to multiple zones") was observed on a production device on 2026-04-21, causing `NSPersistentCloudKitContainer`'s mirroring delegate to abort initialization. When that happens, **no CloudKit sync functions at all** — the household-sharing feature we lead with in the App Store 4.3(a) repositioning appeal (`reposition-app-store-listing`) is functionally broken until the user reinstalls or clears local state. Evidence preserved at `docs/bugs/investigation-assets/2026-04-21-groceryitem-multi-zone-error.png` and `...-rich.log`.

Initial investigation shows 11 production sites create `GroceryListItem(context:)` directly, relying on Core Data to infer store membership from the subsequently-set parent relationships. ADR 014's "Child HouseholdScoped Entities" pattern (lines 45-54) documents this as expected, but ADR 014's own M9.19 CRITICAL note (lines 56-69) warns that direct creation is safe **only** when the parent's store is guaranteed to match the child's store, which Core Data does not guarantee without an explicit `context.assign(object, to: targetStore)` call. The 11 production sites omit this assign — relying on heuristic store inference that has always been fragile and that now fails deterministically in CloudKit shared-zone contexts.

This must ship in a new binary before the App Store submission can be approved, independent of the 4.3(a) positioning work. The repositioning change stays metadata-only; this change ships alongside it as the "new build" Apple's reviewer will evaluate.

## What Changes

- **Fix the creation pattern** at all 11 production `GroceryListItem(context:)` sites: add explicit `context.assign(item, to: parentStore)` before the first save. Parent store resolved from `list.objectID.persistentStore` (or equivalent parent).
- **Apply the same audit** to the sibling HouseholdScoped child `Ingredient` — same risk, same fix.
- **Clarify ADR 014** to make the "parent store inference is not automatic" rule explicit with an example of the correct pattern.
- **Architecture audit skill** tightened to detect direct `GroceryListItem(context:)` / `Ingredient(context:)` calls that lack a subsequent `context.assign()` call.
- **Runtime remediation**: add a launch-time detection path that checks whether the mirroring delegate failed to initialize for zone-assignment reasons, logs diagnostics, and surfaces a repair action (delete the corrupted object so CloudKit can re-sync a clean copy). Deferred details live in design.md.
- **Regression test** added to `foragerTests/Services/GroceryListItemServiceTests.swift`: create a shared-store-scoped WeeklyList, add an item through the service, assert the item's `objectID.persistentStore` matches the list's store.
- **Ship a new binary** to ASC. Update `docs/app-store-rejection-43a-response.md` reply letter to mention the crash fix as an incidental improvement alongside the metadata repositioning.

**Not in scope**:
- A broader sweep to route all HouseholdScoped creation through `ManagedObjectFactory.make()` — that's a separate architectural harden (future `harden-factory-enforcement-for-child-entities`).
- Removing the child-inherits-from-parent pattern entirely.
- Schema v12 changes.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `architecture`: tighten the child HouseholdScoped entity creation requirement so the "explicit store assignment" obligation is part of the spec, not just an ADR footnote. Add scenario covering cross-store safety validation.
- `grocery-lists`: add scenario requiring items created in a household-scoped list land in the same persistent store as the list.

## Impact

- **Code changes** at 11 production sites (Services/GroceryListItemService.swift, Services/MealPlanService.swift, Services/HouseholdService.swift three sites, Services/WeeklyListService.swift, Services/QuantityMergeService.swift, forager/Views/Grocery/WeeklyListsView.swift, forager/Views/Grocery/AddIngredientsToListView.swift). Ingredient creation sites to be audited separately; include any found.
- **Test coverage**: new regression tests under `foragerTests/Services/` for shared-store scenario.
- **Binary change**: new build must ship. Coordinate with `reposition-app-store-listing` — both changes land in the same ASC submission.
- **ADR 014 update**: clarify Child HouseholdScoped Entities pattern with explicit `context.assign()` requirement and example.
- **Architecture audit skill update**: new check for direct `GroceryListItem(context:)` or `Ingredient(context:)` without subsequent `context.assign()`.
- **No Core Data schema change**. No CloudKit production schema change.
- **Existing corrupted data on the user's device**: remediation path to be designed (see design.md § Remediation). May require a one-time cleanup on launch.
- **Related OpenSpec change**: `reposition-app-store-listing` is paused on its `feature/reposition-app-store-listing` branch; resumes once this change ships and the new binary is uploaded.
