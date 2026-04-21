# No Store Default Duplicates — Investigation and Plan

**Discovered**: 2026-04-21 (build 139, iOS device testing)
**Status**: Plan only — no code changes yet
**Suggested change-id**: `fix-no-store-default-duplicates`

---

## Problem

A single device accumulated **5 duplicate "No Store" default entities** after a household delete + reinstall cycle. `Settings → Manage Stores` shows 8 total stores: 3 real (Trader Joe's, Costco, Target) + 5 locked "No Store" entries. The locked UI is working — the user cannot delete them — so the protection added in M18.2 is actually trapping the duplicates in the list.

Log evidence (rich.log, 2026-04-21):

```
[2026-04-21 16:40:30] [DEBUG] [Household] Copied 8 Store(s) to household
```

That line is emitted by `HouseholdService.copyPersonalDataToHousehold` (`Services/HouseholdService.swift:1960`). The count of 8 already includes the 5 "No Store" rows that existed in the personal scope at the moment of household creation — they were blindly copied into the new household "My Kitchen".

Context:
- M18.2 shipped a protected "No Store" default (`isDefault == YES`) that is seeded by `DefaultSeeder.ensureNoStoreExists` and locked by the Manage Stores UI.
- The device went through build 138 → household delete → app reinstall → build 139 → new household creation.
- `CategoryDeduplicator` exists today (M7.2.3 Phase 3.8) and handles the analogous case for `Category`, but there is no equivalent for `Store`.

---

## Evidence

### Store creation sites (audit)

`Services/StoreService.swift:54` — factory-routed, legitimate user creation (ADR 014 compliant).

`Services/HouseholdService.swift:1239` — `migrateHouseholdDataToPersonal` (household → personal). Guards against duplicates via `existingStoreNames` (line 1229–1234). **Safe.**

`Services/HouseholdService.swift:1938` — `copyPersonalDataToHousehold` (personal → household on create). **Does NOT guard against duplicate names, does NOT exclude `isDefault == YES`.** Fetches every `householdKey == nil` store from the private store (line 1934) and copies each into the new household scope. This is the line that produced the `Copied 8 Store(s) to household` log entry.

`Services/Persistence/DefaultSeeder.swift:187` — `ensureNoStoreExists` for personal scope. `fetchLimit = 1`, raw `Store(context:)`.

`Services/Persistence/DefaultSeeder.swift:215` — `ensureNoStoreExists` for household scope. Same pattern, conditioned on a Household entity existing.

No other production creation sites. `grep "Store(context:"` across `foragerTests/` returns only test-harness usage (exempt per ADR 014).

### Seeder call sites

`Services/Persistence/PersistenceController.swift:462` — runs every app launch in `performOneTimeSetup`.
`Services/HouseholdService.swift:721` — runs after a clean household delete (no data migration) before re-seeding categories.

### The `ensureNoStoreExists` check (lines 180–230)

The personal-scope check is:

```swift
personalRequest.predicate = NSPredicate(format: "isDefault == YES AND householdKey == nil")
personalRequest.fetchLimit = 1
```

A single-row fetch against the view/background context. The function has no awareness of CloudKit import timing — if the import hasn't merged the prior device's "No Store" yet, the fetch returns nil and a second one is created. Next launch, the import might have landed; but the first row is also present, and nothing ever removes it.

---

## CategoryDeduplicator pattern summary

`Services/Persistence/CategoryDeduplicator.swift` is the existing reference implementation for "same logical entity, multiple physical rows after CloudKit sync". Shape:

1. **Fetch all** `Category` rows (`removeDuplicates`, line 58).
2. **Group by compound semantic key** — `"\(normalizedName)|\(householdKey ?? "personal")"` (line 70–74). This is the M7.3.3 fix that prevents cross-scope deletion (a personal category with the same name as a household category must not be treated as a duplicate).
3. **Pick the keeper** — oldest `dateCreated`, with groups of size > 1 (line 90–97). Ties on nil dates sort stable-false.
4. **Delete the rest** — `context.delete(duplicate)` for each non-keeper (line 105–111). **Relationships pointing at the deleted duplicate are not explicitly re-parented.** The deduplicator relies on Core Data's inverse relationship handling + the fact that `Category`'s inverse on `Ingredient.categoryEntity` has `Nullify` delete rule: referring objects end up with `categoryEntity = nil`, which is acceptable because every template has the "Uncategorized" fallback. This is a design choice; it is correct for Category but may not be correct for Store.
5. **Save + log** if anything was deleted (line 116–121).

**Idempotency / safety**: `removeDuplicates` is safe to call repeatedly — a second run finds a single row per group and is a no-op. It runs on a background context via `CloudKitSyncMonitor.runDeduplication` (`Services/CloudKitSyncMonitor.swift:239`), triggered from `handleRemoteChange` (line 135). Failures are caught and logged as `#if DEBUG print`; the sync event still succeeds. That "best-effort" stance is the pattern to mirror.

---

## Root cause analysis

**Primary cause (high confidence): `copyPersonalDataToHousehold` copies No Store blindly.**

The log line `Copied 8 Store(s) to household` is explained by: at the moment of household creation, the personal store already held N "No Store" rows plus 3 real stores. The fetch at `HouseholdService.swift:1933` is `householdKey == nil` with no `isDefault == NO` filter and no dedupe-by-name step (unlike the symmetrical `migrateHouseholdDataToPersonal` at line 1229–1238 which DOES dedupe by name). Every personal No Store is cloned into the household scope — and `ensureNoStoreExists` then runs later in the same flow and may add one more (household-scope check, line 210–228) if the copy didn't trigger the "already present" branch at the exact moment of the fetch.

**Secondary cause (medium confidence): the original 5 personal "No Store" rows existed _before_ household creation.**

How did the personal scope get 5 "No Store" rows in the first place? Hypothesized sequence:

1. Build 138 (pre-fix): user was in a household, personal scope had its original single No Store.
2. Household delete (no migration). `HouseholdService.leaveHousehold` calls `ensureNoStoreExists` at line 721 — fine, a single row.
3. App reinstall. CloudKit re-imports the owner's private-zone records asynchronously.
4. `PersistenceController.performOneTimeSetup` runs on launch and calls `ensureNoStoreExists` before the CloudKit import is complete. The single-shot `fetchLimit = 1` check returns nil → a new No Store is created locally. Moments later, the prior device's row imports → second row present in the store.
5. Previous household delete cycles (earlier in device history) plus re-seeding on each launch stacked additional copies through the same race.
6. Nothing ever reconciles them because no Store deduplicator exists.

Net: 5 personal-scope "No Store" rows → copied wholesale into the new household on creation.

**Supporting circumstantial evidence**: the bug is specific to a device with a reinstall history and multiple household cycles. A fresh install on a second device would show 1 No Store (seeder ran before any import happened), which matches the historical behaviour we never noticed.

---

## Fix options

| Option | Scope | Root cause vs symptom | Regression test | Risk |
|---|---|---|---|---|
| **A. StoreDeduplicator (new service) + dedupe-by-name guard in `copyPersonalDataToHousehold`** | 2 files: new `Services/Persistence/StoreDeduplicator.swift`, 1 predicate change + lookup-set in `HouseholdService.swift:1933–1949`, 1 call-site change in `CloudKitSyncMonitor.runDeduplication`. | Both. Dedup guard in copy = root cause of the 8-row log line. Deduplicator = root cause of the pre-existing 5 rows + defence against future sync races. | Unit test: seed 5 `isDefault=YES`, personal-scope `Store` rows → run deduplicator → assert 1 row, oldest kept. Plus: `copyPersonalDataToHousehold` with N personal stores including 3 `isDefault=YES` → assert household gets stores deduped by (name, isDefault). | Low. Store dedupe picks keeper by `dateCreated`; no referring relationships on `Store` except `IngredientTemplate.preferredStore` and `GroceryListItem.store`. Both are nullify-on-delete, and the UI already handles nil `preferredStore`. No impact on M18.1 store assignment (factory routing is unchanged) or M18.2 locked UI (locked flag is unchanged). |
| **B. Extend `CategoryDeduplicator` to a generic `DefaultEntityDeduplicator<Entity>` + `StoreDeduplicator` + copy-path dedupe** | 4 files: generics refactor, 2 concrete deduplicators, HouseholdService change. | Same as A, but more reusable for future default entities. | Same as A, plus existing `CategoryDeduplicatorTests` still pass unchanged. | Medium. Generic refactor touches a shipped, working service. Risk/reward is poor when we only need one more instance. |
| **C. Symptom-only: one-shot migration that purges extra `isDefault=YES` Stores on next launch, plus copy-path dedupe** | 1 file: migration block in `PersistenceController.performOneTimeSetup`, guarded by a UserDefaults flag. | Fixes the copy path (root cause of fresh occurrences) and remediates existing corruption in a single pass, but leaves no ongoing defence for CloudKit sync races that reintroduce duplicates. | Integration test: pre-populate 5 No Store rows → run setup → assert 1 row. | Medium-low. Migration flags are easy to get wrong on a reinstall (the flag re-fires and double-deletes). And if another CloudKit sync race reintroduces duplicates post-migration, we'd need a second one-shot migration later. |

---

## Recommendation

**Option A.** Create `Services/Persistence/StoreDeduplicator.swift` modelled line-for-line on `CategoryDeduplicator`, with:

- **Grouping key**: `"\(name|lowercased)|\(householdKey ?? "personal")|\(isDefault ? "default" : "user")"`. The extra `isDefault` dimension keeps a user-created "No Store" (unlikely but possible) separate from the protected default, which is semantically correct for Store in a way that the Category version doesn't need.
- **Keeper selection**: oldest `dateCreated`, identical to Category.
- **Relationship re-parenting**: before deletion, walk `ingredientTemplates` and `groceryListItems` off the duplicate and re-point them at the keeper. This is the one place I would *not* copy Category blindly — Category got away with nullify because Uncategorized is a safety net; Store has no equivalent, and silently nulling `preferredStore` on templates would be a user-visible regression.
- **Invocation**: add a `runStoreDeduplication()` call next to `runDeduplication()` in `CloudKitSyncMonitor.handleRemoteChange`, and invoke both from a new `runAllDeduplication()` wrapper so future deduplicators plug in cleanly.

Alongside the service, fix `HouseholdService.copyPersonalDataToHousehold` (line 1933–1949) to follow the same pattern as its sibling `migrateHouseholdDataToPersonal` (line 1229–1238): build a lookup set of existing household-scope store names before the loop, and skip personal rows whose name is already present in the household. That single change prevents the "Copied 8 Store(s) to household" log line from ever appearing again.

Why A over B: we have one concrete need (Store), a second instance doesn't yet justify generics, and the Category deduplicator is a shipped, load-bearing service I don't want to refactor under a bug fix. Why A over C: the CloudKit sync race is still live; a one-shot migration leaves us exposed to the same bug on any future reinstall.

### Related observation (not in scope)

`DefaultSeeder.ensureNoStoreExists` uses raw `Store(context:)` (lines 187, 215) rather than `ManagedObjectFactory.make`. The seeder is an ADR 014 exception for the personal path, but the household-scope creation on line 215 could arguably be factory-routed for consistency with M18.1. Flagged for a separate pass — not needed for this fix.

---

## Tasks skeleton (phases only)

1. **Investigation** — confirm hypothesis on device: capture personal-scope Store count on a device with the duplicates, verify the 5 rows are all `isDefault=YES` + `householdKey=nil`.
2. **Implementation** — `StoreDeduplicator` + `CloudKitSyncMonitor` wiring + `copyPersonalDataToHousehold` dedupe guard.
3. **Tests** — unit tests for the deduplicator (keeper selection, re-parenting of templates + grocery items, cross-scope safety). Integration test for the copy path.
4. **Remediation for existing corruption** — verify that the deduplicator, invoked on first CloudKit sync notification after app upgrade, cleans the 5 stranded "No Store" rows on the affected device. No separate one-shot migration should be needed; if testing shows otherwise, add a launch-time `runStoreDeduplication()` call in `performOneTimeSetup`.
5. **Ship** — `/opsx:propose fix-no-store-default-duplicates` → `/opsx:apply` → `/pr` → `/release-prep`.
