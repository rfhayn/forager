# Learning Note 44: The CloudKit Dual-Store Journey

**Date**: March 14, 2026
**Milestones**: M7 → M7.6 → M9.12 → M9.13 → M9.14 → M9.15 → M9.15.3 → M9.18 → M9.19
**Status**: Living document — updated as CloudKit lessons continue

---

## The Story

Before M7, Forager was a simple app. One SQLite database on the device. Recipes, grocery lists, meal plans — all local, all personal. Core Data queries were straightforward. You created an object, saved it, fetched it. Nothing could go wrong with store assignment because there was only one store.

Then came the household feature.

---

### Act 1: The Foundation (M7.1, December 2025)

Swapping `NSPersistentContainer` for `NSPersistentCloudKitContainer` was almost too easy — API-compatible, no view changes needed. CloudKit auto-generated the schema. History tracking and remote change notifications plugged in cleanly. A 1.5-hour estimate landed at exactly 1.5 hours.

The confidence was dangerous.

---

### Act 2: The Wrong Architecture (M7.1.3 + M7.2.1, December 2025)

Two failures in quick succession.

**M7.1.3**: Five hours building multi-device sync coordination without reading the PRD first. The code became a tangle of workarounds masking symptoms. Scrapped entirely.

**M7.2.1**: Three and a half hours building beautiful, technically correct CKShare-based individual item sharing. Share buttons on recipes. Per-item permissions. Granular access control. Architecturally perfect for the wrong problem.

The actual requirement was a shared household database — not "share this recipe with a friend," but "my partner and I see the same grocery list." That's a fundamentally different architecture: shared zone, not CKShare. One-time setup, not per-item sharing. Everything shared automatically, not selectively.

**Lesson**: Weeks of coding can save you hours of planning.

---

### Act 3: The Dual-Store Architecture (M7.2.3, December 2025 - January 2026)

The correct architecture emerged: two persistent stores.

- `forager.sqlite` — private store, personal data
- `forager_shared.sqlite` — shared store, household data

Every household-scoped entity (Recipe, WeeklyList, Category, IngredientTemplate, MealPlan, PlannedMeal, and later Ingredient and GroceryListItem) gets a `household` relationship and a `householdKey` string attribute. The "attach-then-share" pattern: create household, stamp existing data with the household reference, call `container.share()` to move everything to the shared zone.

External AI validation (ChatGPT and Gemini reviewing the architecture document) caught four production-breaking bugs before a single line shipped:
- Wrong share API call (would fail at runtime)
- Delete rules too aggressive (would lose user data)
- Stale object reference after sharing (would crash)
- Brittle DataScope coupling

These would have cost 20+ hours to debug in production. The 4-hour review investment was the best ROI of the entire project.

---

### Act 4: iOS Fights Back (M7.6.8, January - February 2026)

`UICloudSharingController` — Apple's built-in UI for managing CloudKit shares — is broken on iOS 18.x. Blank screens. LaunchServices Error -54. XPC connection failures. Three hours of debugging on real devices before accepting it wasn't fixable from app code.

The workaround (ADR 009): public link sharing with `UIActivityViewController`. Anyone with the URL can join. Less granular than Apple's controller, but it actually works. Similar trust model to Google Docs or Notion.

Then, seven more gotchas surfaced during TestFlight preparation:
1. Schema only pushes for entities that have instances (must force-push before Production deploy)
2. The `cloudkit.share` record type doesn't exist until the first share is created
3. `container.share()` fails on fresh installs because records haven't synced to the server yet
4. `container.share()` only migrates the root record — children stay in the private store
5. iOS 16+ strips the owner's name from CKShare participants
6. CloudKit schema is append-only in Production — fields can never be deleted or renamed
7. The default CloudKit environment is Production — one accidental Release build pushes unfinished schema permanently

**Original estimate for M7**: 27-37 hours. **Actual**: 60+ hours. The 2x overrun was split roughly evenly between wasted work (~12h on wrong approaches), unexpected complexity (~15h on dual-store edge cases), and valuable investment (~8h on external validation and documentation).

---

### Act 5: The Silent Failures Begin (M9.12 - M9.13, March 2026)

Months passed. Features were built on top of the dual-store foundation. The grocery list, recipe import, meal planning — all working. Then a user tested the app while in a household, and items they added to a grocery list just... didn't appear.

No crash. No error. No warning.

The root cause: **cross-store relationships**. When a user is in a household, their grocery list is in the shared store but the ingredient template was created in the private store (because `Entity(context:)` defaults to the first/private store). Setting `listItem.ingredientTemplate = privateStoreTemplate` creates a cross-store relationship. Core Data accepts it. `viewContext.save()` silently rolls back. The item doesn't exist.

Investigation revealed a systemic problem: `ManagedObjectFactory` — the component designed to assign objects to the correct store — had been established in M7.2.3 as the mandatory creation path. But **zero production code actually used it**. All 43+ entity creation sites used direct `Entity(context:)`. It worked through M7 because the views that would break hadn't been built yet.

This was the first warning that the single-store assumptions baked into the pre-M7 codebase were time bombs.

---

### Act 6: Zone Immutability (M9.15, March 2026)

Household creation had been "working" in development but failing 100% with real user data. Error 134060: "objects assigned to multiple zones."

The attach-then-share pattern — the foundation of the entire household architecture — was broken.

Here's why: when you call `viewContext.save()`, NSPersistentCloudKitContainer's mirroring delegate creates CKRecord objects in CloudKit's private zone. These zone assignments are **permanent**. When you later call `container.share([household])`, CloudKit tries to move those records to the shared zone and refuses. You can't move a CKRecord between zones. Ever.

The fix required rewriting the entire household creation flow: **create-empty-then-copy**. Share an empty Household first (no data = no CKRecords to conflict), then copy all personal data as brand-new objects with fresh UUIDs. The copies get fresh CKRecords in the shared zone. Delete the originals from the private zone.

This also required promoting Ingredient and GroceryListItem to HouseholdScoped entities (schema v9), adding `household` and `householdKey` to both. The model version went from v8 to v9.

---

### Act 7: Scope vs. Store (M9.15.3, March 2026)

Three TestFlight builds in one day (37, 38, 39), each fixing a variation of the same conceptual error.

After `container.share()`, the Household entity doesn't immediately move to the shared store. CloudKit migrates records server-side, and that can take 60+ seconds. The code was checking "is the Household in the shared store?" to determine scope. During those 60 seconds, the answer was "no" — so every new entity was created without a `householdKey`, making it invisible to household-scoped queries.

**Build 37**: Replaced "wait for shared store" with "stamp in place" — set `householdKey` on existing private-store objects and let CloudKit handle migration asynchronously.

**Build 38**: Fixed `HouseholdService.currentScope` — it was checking store location instead of entity existence.

**Build 39**: The identical bug existed in `HouseholdScopeProvider.activeScope`, a completely separate code path used by `ManagedObjectFactory`.

**The lesson**: Scope means "does a Household exist?" not "is the Household in the shared store?"

---

### Act 8: Ghosts (M9.15.3 + M9.18, March 2026)

A failed `createHouseholdAndShare()` leaves a Household entity in the private store. It syncs to CloudKit. On reinstall, CloudKit re-downloads it. The app's `loadCurrentHousehold()` finds it, checks for a CKShare, finds none, and marks it as a "ghost" — a leftover from a household the user left.

But some "ghosts" were real. Build 48 deleted a user's valid household because it was in the private store (normal during CloudKit migration) and had no CKShare yet (because migration was still in progress). The user's data vanished.

**The fix**: Check which store the Household is in before treating it as a ghost. Private-store Households are normal during migration. Only shared-store Households without a CKShare are genuine ghosts.

---

### Act 9: The Silent Data Loss (M9.19, March 2026)

Build 49 fixed the ghost detection. Force-quit worked fine — data persisted. But after deleting the app and reinstalling, the Household came back and all the data was gone. 28 copied objects — recipes, categories, templates, grocery lists — permanently lost.

The user waited. The data never came back.

This was the deepest bug. The `copyPersonalDataToHousehold()` function — the one that stamps personal data with the household's key — also set `new.household = household` on every copied entity. A Core Data relationship. Harmless in a single-store world.

But after `container.share()`, the Household is in the **shared store**. The copies are in the **private store**. Every `new.household = household` created a **cross-store relationship**. And NSPersistentCloudKitContainer's mirroring delegate silently refuses to export records with cross-store relationships.

No crash. No error. No console warning. No callback. The records exist locally. They save to SQLite. Force-quit and relaunch, they're there. But they never upload to CloudKit. Delete the app, and they're gone forever.

The fix was removing ten lines of code: every `new.household = household` in the copy function. The `householdKey` string attribute — a simple string, not a Core Data relationship — is immune to store boundaries. It's what all fetch predicates use anyway (ADR 013). The relationship was redundant and dangerous.

---

## The Pattern

Every CloudKit bug in Forager follows the same pattern: **a single-store assumption surviving into a dual-store world**.

- `Entity(context:)` creates in the private store → wrong store for household entities
- `entity.household = household` → cross-store relationship when stores differ
- "Is it in the shared store?" → wrong question when migration is asynchronous
- "No CKShare found" → doesn't mean ghost when the entity hasn't migrated yet
- `viewContext.save()` after cross-store assignment → silent rollback, no error

The pre-M7 codebase had none of these problems because there was only one store. M7 introduced the dual-store architecture but couldn't retroactively make every line of code store-aware. Each subsequent milestone exposed another assumption.

---

## The Rules (Hard-Won)

1. **Zone assignments are permanent.** Once a CKRecord exists in a zone, it cannot move. Never try to "attach-then-share" objects with existing records.

2. **Cross-store relationships fail silently.** No crash, no error, no warning. Data saves locally but never exports to CloudKit. The only symptom is data loss after reinstall.

3. **`householdKey` (String) is strictly more reliable than `household` (relationship).** Strings are store-independent. Relationships create cross-store links when stores diverge.

4. **Scope is entity existence, not store location.** After `container.share()`, the Household may stay in the private store for 60+ seconds. Scope shouldn't depend on where it lives.

5. **Private-store Households are normal during migration.** Only shared-store Households without a CKShare are genuine ghosts.

6. **The mirroring delegate is a black box.** It logs to OSLog (inaccessible to TestFlight users). It fails silently on cross-store relationships. It dies permanently if the store file is removed. Build your own diagnostic logging.

7. **Test with delete+reinstall, not just force-quit.** Local persistence masks CloudKit export failures. The only way to verify data actually uploaded is to destroy the local copy and see if it comes back.

---

## The Numbers

| Metric | Value |
|--------|-------|
| Original M7 estimate | 27-37 hours |
| Actual M7 time | 60+ hours |
| Time wasted on wrong approaches | ~12 hours |
| CloudKit-related bugfix milestones after M7 | 7 (M9.12, M9.13, M9.14, M9.15, M9.15.3, M9.18, M9.19) |
| TestFlight builds for M9.15.3 alone | 5 (builds 37-41) |
| Lines of code that caused permanent data loss | 10 (`new.household = household` × 10 entity types) |
| Time to find root cause of data loss (M9.19) | ~3 hours across 2 sessions |
| ADRs created for CloudKit decisions | 4 (008, 009, 013, 014) |
| Schema versions for CloudKit changes | 4 (v6, v7, v8, v9) |

---

## Related Documents

- **ADR 008**: Shared Zone Architecture (the dual-store decision)
- **ADR 009**: Public Link Sharing (iOS 18.x UICloudSharingController workaround)
- **ADR 013**: Scope-Aware Fetch Pattern (mandatory `householdKey` predicates)
- **ADR 014**: ManagedObjectFactory Enforcement (correct store assignment)
- **Learning Note 25**: Architecture Pivot — CKShare vs Shared Zone
- **Learning Note 29**: CloudKit & Household Sharing Journey (M7 retrospective)
- **Learning Note 34**: CloudKit Sharing & Sync Gotchas (seven non-obvious behaviors)
- **PRD M9.15**: Household Creation Architecture Fix
- **Insights Log**: 35+ CloudKit-related entries
