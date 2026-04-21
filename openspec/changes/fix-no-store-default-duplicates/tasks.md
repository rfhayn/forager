## 1. Investigation (confirm before coding)

- [ ] 1.1 Read `Services/Persistence/CategoryDeduplicator.swift` end-to-end. Note the grouping key, keeper-selection heuristic, delete pattern, save pattern, log pattern. Flag divergences planned for `StoreDeduplicator`.
- [ ] 1.2 Read `Services/Persistence/DefaultSeeder.swift` — specifically `ensureNoStoreExists()` (personal + household paths). Confirm the single-shot `fetchLimit = 1` pattern and the lack of CloudKit-import awareness. Document in an inline comment that Decision 5 (post-hoc dedupe) is the chosen downstream defense.
- [ ] 1.3 Read `Services/CloudKitSyncMonitor.swift` around `handleRemoteChange` + `runDeduplication`. Identify the exact insertion point for `runStoreDeduplication()` and the shape of `runAllDeduplication()`.
- [ ] 1.4 Read `Services/HouseholdService.swift:1933-1949` (the buggy `copyPersonalDataToHousehold` Store loop) and `Services/HouseholdService.swift:1229-1238` (the correctly-guarded `migrateHouseholdDataToPersonal` sibling). Note the exact pattern to replicate.
- [ ] 1.5 Grep `Store(context:` in production code to confirm only 4 creation sites exist (StoreService, 2× HouseholdService, DefaultSeeder). If new sites appeared since the investigation plan was written, audit them.
- [ ] 1.6 Inspect inverse relationships on `Store` via the `.xcdatamodeld` file or `Store+CoreDataProperties.swift`: confirm `IngredientTemplate.preferredStore` and `GroceryListItem.store` are the only inbound relationships and have `nullify` delete rules.

## 2. StoreDeduplicator implementation

- [ ] 2.1 Create `Services/Persistence/StoreDeduplicator.swift`. Public API: `init(context: NSManagedObjectContext)`, `func removeDuplicates() throws -> Int`. Mirror `CategoryDeduplicator.swift` for overall shape.
- [ ] 2.2 Grouping key: compute `"\(nameLowercased)|\(householdKey ?? "personal")|\(isDefault ? "default" : "user")"`. Use `name?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""`. Consistent with the CategoryDeduplicator normalization pattern.
- [ ] 2.3 Fetch all `Store` rows in the deduplicator's context. Group into a dictionary keyed by the grouping key from 2.2.
- [ ] 2.4 For each group with size > 1: sort by `dateCreated` ascending (nil last), keep the first row as keeper, mark the rest for deletion.
- [ ] 2.5 For each row marked for deletion: before `context.delete(duplicate)`, fetch `IngredientTemplate` with `preferredStore == duplicate` and update each to `preferredStore = keeper`. Then fetch `GroceryListItem` with `store == duplicate` and update each to `store = keeper`. Use `NSFetchRequest` + predicate for both — faster than walking `duplicate.ingredientTemplates` inverse set.
- [ ] 2.6 After all deletions and re-parentings, call `context.save()` once. Wrap in do/catch; on error, log via DiagnosticLogger at `.error` level and return 0 (best-effort semantics matching CategoryDeduplicator).
- [ ] 2.7 Return the count of deleted rows. Log `🧹 StoreDeduplicator: removed \(count) duplicate Store(s)` via DiagnosticLogger at `.info` level if count > 0 (silent on 0).

## 3. CloudKitSyncMonitor wiring

- [ ] 3.1 Rename the existing `runDeduplication()` method to `runCategoryDeduplication()` for clarity. Search + replace internal call sites.
- [ ] 3.2 Add a new `runStoreDeduplication()` method modelled on the Category one (background queue, background context, `context.performAndWait`, instantiate `StoreDeduplicator`, call `removeDuplicates()`, log result, catch and log on error).
- [ ] 3.3 Add a new `runAllDeduplication()` method that calls `runCategoryDeduplication()` then `runStoreDeduplication()`. Does not parallelize — Category first by convention (oldest service).
- [ ] 3.4 Update `handleRemoteChange` to call `runAllDeduplication()` in place of the current `runDeduplication()` call.

## 4. HouseholdService copy-path fix

- [ ] 4.1 `Services/HouseholdService.swift:1933-1949` — before the `for old in oldStores` loop, build `let existingStoreNames: Set<String> = Set(newHouseholdStores.compactMap { $0.name?.lowercased() })` where `newHouseholdStores` is the already-created household-scope Store set at that point in the function (verify the name of this collection from surrounding context).
- [ ] 4.2 Inside the loop, skip personal rows whose `old.name?.lowercased()` is already in `existingStoreNames`. Mirror the skip pattern from `migrateHouseholdDataToPersonal` at line 1229-1238.
- [ ] 4.3 Log skipped count via DiagnosticLogger at `.debug` level: `Skipped N personal Stores already present in household`.
- [ ] 4.4 Verify that the `Copied 8 Store(s) to household` log line now shows the correct lower count (4 in the affected device's case: 3 real stores + 1 "No Store").

## 5. Tests

- [ ] 5.1 Create `foragerTests/Services/StoreDeduplicatorTests.swift`. Use `PersistenceController(inMemory: true)` setup pattern matching `CategoryDeduplicatorTests.swift`.
- [ ] 5.2 Test `testNoDuplicates_isNoop` — seed 1 default Store + 2 user Stores → run → assert 0 deletions.
- [ ] 5.3 Test `testFiveDefaultDuplicates_collapsedToOneOldest` — seed 5 `isDefault=YES, name="No Store"` rows with distinct `dateCreated` → run → assert 4 deletions and the keeper has the oldest `dateCreated`.
- [ ] 5.4 Test `testReParentsTemplates` — seed 2 duplicate Stores (A keeper, B duplicate), 3 `IngredientTemplate` with `preferredStore == B` → run → assert all 3 templates now have `preferredStore == A` AND B is deleted.
- [ ] 5.5 Test `testReParentsGroceryListItems` — similar to 5.4 but for `GroceryListItem.store`.
- [ ] 5.6 Test `testCrossScopeNotDeduped` — seed personal "No Store" and household "No Store" with different `householdKey` → run → assert both survive.
- [ ] 5.7 Test `testDefaultAndUserSameNameNotDeduped` — seed `isDefault=YES, name="No Store"` and `isDefault=NO, name="No Store"` at same scope → run → assert both survive.
- [ ] 5.8 Test `testIdempotentSecondRun` — run twice in succession → second run returns 0 deletions and no errors.
- [ ] 5.9 Add a regression test for the `copyPersonalDataToHousehold` dedupe guard (test file TBD — likely a new `foragerTests/Services/HouseholdServiceCopyPathTests.swift` if `HouseholdServiceTests` doesn't exist). Setup: personal scope with 5 duplicate "No Store" + 2 real stores, existing empty household with 1 "No Store" pre-seeded → copy runs → assert household ends with 1 "No Store" + 2 real stores (no duplicates copied over).
- [ ] 5.10 Run full suite: `xcodebuild ... test`. Green with the pre-existing 3 flakes unchanged.

## 6. Device verification

- [ ] 6.1 Archive + TestFlight-distribute a build containing the deduplicator + copy-path fix.
- [ ] 6.2 Install on Rich's iPhone (the device with 5 stranded "No Store" rows from the 2026-04-21 investigation).
- [ ] 6.3 Enable DiagnosticLogger in Settings → Diagnostics.
- [ ] 6.4 Wait for the next CloudKit remote-change event (or trigger one by adding a recipe on a second device).
- [ ] 6.5 Confirm Manage Stores now shows exactly 1 "No Store" at the personal scope AND 1 "No Store" at the household scope (if a household is active).
- [ ] 6.6 Confirm `IngredientTemplate` and `GroceryListItem` rows that previously pointed at the deleted duplicates now point at the keepers (smoke-check via UI: open a few recipes and grocery items, check their store shows correctly).
- [ ] 6.7 If remote-change doesn't fire reliably on the affected device within 5 minutes of active use, implement the fallback from Decision 5: invoke `runStoreDeduplication()` once from `PersistenceController.performOneTimeSetup` behind a launch-time condition.

## 7. ADR / docs

- [ ] 7.1 Determine whether this warrants a new ADR or an amendment to existing docs. Likely: extend `docs/architecture/service-layer-pattern.md` with a "Deduplication Services" subsection (short), OR add ADR 016 if the pattern is complex enough to warrant its own document. Consult during implementation.
- [ ] 7.2 Update `docs/architecture/service-layer-pattern.md` with the deduplicator pattern if chosen over ADR 016.
- [ ] 7.3 Update `docs/roadmaps/app-health-roadmap.md` — move `fix-no-store-default-duplicates` from backlog to "active" status, update the Bucket line counts if needed.

## 8. Doc freshness + PR

- [ ] 8.1 Update `docs/development-journal.md` with a Session N entry narrating the deduplicator design, the re-parenting divergence from Category, and device verification results.
- [ ] 8.2 Log 1-2 insights to `docs/insights-log.md` — at minimum the "Store dedup needs re-parenting, Category doesn't" insight.
- [ ] 8.3 Run doc-freshness gate: `bash .claude/skills/_shared/doc-freshness.sh --mode=block` — all families fresh.
- [ ] 8.4 Commit all changes with an appropriate prefix. Use `/commit` skill.
- [ ] 8.5 Push + `/pr`. Title: `fix-no-store-default-duplicates: StoreDeduplicator + copyPersonalDataToHousehold dedupe guard`.
- [ ] 8.6 `/archive` from main after PR merges (unless we ship from feature branch for device-verification reasons per Decision 5 fallback).

## 9. Close-out

- [ ] 9.1 Run `/review` before PR finalization.
- [ ] 9.2 After merge: `/opsx:archive fix-no-store-default-duplicates` to promote the spec deltas (`architecture` capability + `store-aware-shopping` capability) into the living specs.
- [ ] 9.3 Verify the affected device has exactly 1 "No Store" per scope post-ship.
- [ ] 9.4 If the related observation (`DefaultSeeder` household-path using raw `Store(context:)`) felt worth addressing: open a tiny follow-up change `harden-defaultseeder-factory-routing` and add to the app-health roadmap. Otherwise let it sit on the roadmap as-is.
