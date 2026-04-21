## Why

A single device accumulated **5 duplicate "No Store" default entities** (`isDefault == YES`) after a household delete + reinstall cycle on 2026-04-21. The UI lock added in M18.2 prevents the user from deleting them — so the protection intended to keep the default safe is actively trapping the duplicates in the Manage Stores list. Screenshot + log evidence preserved at `docs/bugs/investigation-assets/` and investigation plan at `docs/bugs/investigation-plans/no-store-duplicates-plan.md`.

Audit (the agent's grep + line-level read) found two causes that compound:

1. **Primary — `HouseholdService.copyPersonalDataToHousehold` (line 1933-1949) copies Stores blindly.** Its fetch is `householdKey == nil` with no name-dedupe and no `isDefault == NO` filter. Every personal-scope Store (including every duplicate No Store) is cloned into the new household scope. The log line `Copied 8 Store(s) to household` is this bug firing. Its sibling `migrateHouseholdDataToPersonal` (line 1229-1238) already has the name-dedupe guard — the two directions are inconsistent.
2. **Secondary — `DefaultSeeder.ensureNoStoreExists` has a CloudKit-import race.** Single-shot `fetchLimit = 1` check with no awareness of import timing. On reinstall the local fetch returns nil before the owner's prior-device row imports → new row gets created → moments later the prior row imports → two rows. Compounds across reinstall + household cycles.

There is no deduplication safety net for Store today. `CategoryDeduplicator` exists for the equivalent Category case and runs on remote-change notifications via `CloudKitSyncMonitor.runDeduplication`. Store has no equivalent, so duplicates accumulate silently.

Not urgent for the v2.0 App Store submission (the 5 duplicates are cosmetic, don't block functionality) but worth shipping before user data volume grows. Pre-existing bug — not caused by the zone-conflict fix in `fix-groceryitem-multi-zone-assignment` (that change's validation session surfaced it).

## What Changes

- **New service**: `Services/Persistence/StoreDeduplicator.swift` modelled on `CategoryDeduplicator.swift` with one critical divergence — explicit relationship re-parenting for `IngredientTemplate.preferredStore` and `GroceryListItem.store` before deleting a duplicate. Category got away with `nullify` delete rule because Uncategorized was the safety net; Store has no equivalent safety net, and silently nulling `preferredStore` on templates would be a user-visible regression.
- **Grouping key**: `"\(name|lowercased)|\(householdKey ?? "personal")|\(isDefault ? "default" : "user")"`. The extra `isDefault` dimension keeps a user-created "No Store" (unlikely but possible) semantically separate from the protected default. Category's version doesn't need this dimension.
- **Keeper selection**: oldest `dateCreated`, identical to Category.
- **Invocation**: add `runStoreDeduplication()` next to `runDeduplication()` in `CloudKitSyncMonitor.handleRemoteChange`. Introduce a `runAllDeduplication()` wrapper so future deduplicators plug in cleanly.
- **Fix the buggy copy path**: `HouseholdService.copyPersonalDataToHousehold` (line 1933-1949) gains a name-dedupe guard in the Store loop, matching the pattern already used by `migrateHouseholdDataToPersonal` (line 1229-1238). This prevents the "Copied 8 Store(s) to household" log line from ever reappearing on fresh household creation.
- **Regression tests**:
  - Unit: seed 5 `isDefault == YES` personal-scope Stores → run `StoreDeduplicator.removeDuplicates()` → assert exactly 1 survives (oldest `dateCreated`), and that templates + grocery items that pointed at the deleted rows now point at the keeper.
  - Unit: `copyPersonalDataToHousehold` with N personal Stores (including duplicates) → assert household gets Stores deduped by `(name|householdKey|isDefault)`.
  - Integration: existing `CategoryDeduplicatorTests` continue to pass unchanged.
- **Remediation for existing corruption**: no separate one-shot migration. The new deduplicator runs on the next remote-change notification after app upgrade and cleans any stranded duplicates in place. If testing on the affected device shows the remote-change path doesn't fire reliably enough, fall back to invoking `runStoreDeduplication()` once from `performOneTimeSetup`.

**Not in scope** (intentionally deferred):
- Converting `DefaultSeeder.ensureNoStoreExists` to route through `ManagedObjectFactory.make()`. The seeder is an ADR 014 exception on the personal path; the household path at line 215 could arguably be factory-routed for M18.1 consistency but it's a separate hygiene concern.
- Generalizing `CategoryDeduplicator` + `StoreDeduplicator` into a `DefaultEntityDeduplicator<E>` generic. One more instance doesn't yet justify refactoring a shipped, load-bearing service. Revisit when a third entity needs deduplication.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `architecture`: codify the deduplication pattern as a cross-cutting rule. New requirement covers (a) when deduplication is warranted, (b) mandatory relationship-re-parenting when child entities lack a safety-net default, (c) invocation on remote-change notifications.
- `store-aware-shopping`: add scenario requiring that the protected "No Store" default exists as exactly one row per scope (personal, household) at all times.

## Impact

- **Code changes**: 1 new file (`Services/Persistence/StoreDeduplicator.swift` ~150 lines), 2 modified files (`Services/CloudKitSyncMonitor.swift` — add observer wiring, introduce `runAllDeduplication` wrapper; `Services/HouseholdService.swift` — add dedupe guard to `copyPersonalDataToHousehold` ~5 lines).
- **No schema change, no Core Data migration, no CloudKit schema change.** Pure logic correction + new service.
- **Test coverage**: new `foragerTests/Services/StoreDeduplicatorTests.swift` (~200 lines, ~6 tests) + 1-2 regression tests in `HouseholdServiceTests` (if that file exists; else a small new test file for the copy-path dedupe guard).
- **Binary change required**: yes. Ships alongside the next TestFlight build.
- **Remediation**: devices with existing duplicates get cleaned on first remote-change notification after upgrade. No manual user action required.
- **Related change coordination**: `fix-groceryitem-multi-zone-assignment` (PR #150) is the current in-flight change. This change branches from main and is independent — no merge dependencies. Ship whenever convenient after PR #150 merges.
- **Roadmap alignment**: listed as future work on `docs/roadmaps/app-health-roadmap.md`; this change takes it from backlog to active.
