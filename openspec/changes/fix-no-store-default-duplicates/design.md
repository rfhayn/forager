## Context

The "No Store" default entity was introduced in M18.2 as a protected row (`isDefault == YES`, UI-locked) to represent "no preferred store" for ingredient templates and grocery items. `DefaultSeeder.ensureNoStoreExists` seeds it per scope on app launch; the Manage Stores UI hides the delete affordance on locked rows so users can't accidentally orphan templates.

Two observations on 2026-04-21 triggered this work:

1. Device inspection (build 139, post-reinstall) showed **5 "No Store" rows** in Manage Stores alongside 3 real stores. UI lock working as intended, but lock + duplicates = 5 un-deletable rows trapped in the list.
2. Log inspection of `rich.log` showed `Copied 8 Store(s) to household` during `My Kitchen` household creation — the 5 duplicates at personal scope were blindly cloned into the new household scope, preserving the bug across household cycles.

The investigation plan (`docs/bugs/investigation-plans/no-store-duplicates-plan.md`) catalogs all 4 Store creation sites and identifies the smoking-gun bug at `Services/HouseholdService.swift:1933-1949`. `CategoryDeduplicator` handles the analogous case for Category (M7.2.3 Phase 3.8) but there is no equivalent service for Store.

## Goals / Non-Goals

**Goals:**
- Fix the primary bug: `copyPersonalDataToHousehold` must not clone duplicates into the new household scope.
- Establish a deduplication safety net for Store, modelled on `CategoryDeduplicator` but with relationship re-parenting (Category's nullify+Uncategorized pattern doesn't translate to Store).
- Remediate existing corrupted devices: on first remote-change notification after upgrade, collapse duplicates to a single row per `(name, householdKey, isDefault)` group.
- Establish the pattern for future default-entity deduplicators (e.g., if another M18-style default entity ever comes along).

**Non-Goals:**
- Generalizing `CategoryDeduplicator` + `StoreDeduplicator` into a `DefaultEntityDeduplicator<E>` generic. Rationale: one more instance doesn't yet justify refactoring a shipped, load-bearing service. Revisit on the third instance.
- Routing `DefaultSeeder.ensureNoStoreExists` through `ManagedObjectFactory.make()`. The seeder is an ADR 014 exception; the hygiene concern is real but separate.
- Preventing CloudKit sync races in seeders by querying CloudKit before seeding. Too complex for the reliability gain — the deduplicator post-hoc cleanup is simpler and covers all race conditions (not just the seed-vs-import case).
- Removing the UI lock on "No Store". The lock is correct when there's exactly one No Store per scope; this change restores that invariant.
- Fixing the `DefaultSeeder.ensureNoStoreExists` CloudKit-import race at the source. Addressed downstream by the deduplicator instead.

## Decisions

### Decision 1: New `StoreDeduplicator`, not a generic refactor
**Choice**: Create `Services/Persistence/StoreDeduplicator.swift` mirroring `CategoryDeduplicator.swift` in shape but with Store-specific grouping key and mandatory relationship re-parenting.

**Rationale**: Generic refactor is tempting but costs more than it saves today. `CategoryDeduplicator` is shipped and stable. A second concrete class lets us diverge on the one semantic that differs (re-parenting vs nullify+safety-net) without breaking Category.

**Alternatives considered**:
- *Generic `DefaultEntityDeduplicator<E>`* — risky, touches shipped code, no clear reuse win beyond two instances. Revisit at three.
- *Bolt re-parenting onto `CategoryDeduplicator` and make it handle Store too* — conflates two semantically different entities and breaks CategoryDeduplicator's single-responsibility.

### Decision 2: Grouping key includes `isDefault`
**Choice**: Group by `"\(name|lowercased)|\(householdKey ?? "personal")|\(isDefault ? "default" : "user")"`.

**Rationale**: A hypothetical future user-created "No Store" (unlikely given the UI lock, but technically possible via edge cases like custom-store creation with that name) must remain semantically separate from the protected default. Category doesn't need this dimension because there's no `isDefault` distinction on Category.

**Alternatives considered**:
- *Just `(name, householdKey)`* — merges a user-created "No Store" with the protected default; incorrect.
- *Separate pass for isDefault=YES vs isDefault=NO* — more code, same result.

### Decision 3: Explicit relationship re-parenting before delete
**Choice**: Before deleting a duplicate Store, walk its `ingredientTemplates` and `groceryListItems` inverse relationships and re-point each at the keeper. Use `NSFetchRequest` with a `store == duplicate` predicate to find them (faster than iterating through the Core Data graph).

**Rationale**: `Store`'s inverse relationships on `IngredientTemplate.preferredStore` and `GroceryListItem.store` have `nullify` delete rule. Nullifying on dedup would silently drop template preferences — a user-visible regression (they'd need to re-assign preferred stores for affected templates). Category gets away with nullify because every template has the Uncategorized fallback; Store has no such safety net.

**Alternatives considered**:
- *Change the Core Data delete rule to cascade* — wrong semantics (user-initiated delete should still nullify); also a schema change.
- *Nullify on dedup + warn user* — degraded UX; the correct behavior is to preserve the association.

### Decision 4: Invocation via `runAllDeduplication` wrapper
**Choice**: Introduce a `CloudKitSyncMonitor.runAllDeduplication()` method that calls both `runDeduplication()` (the existing Category one) and a new `runStoreDeduplication()`. Rename `handleRemoteChange`'s call site accordingly.

**Rationale**: Single entry point for future deduplicators. Matches the "strategic registry" pattern over scattered observer wiring.

**Alternatives considered**:
- *Inline the Store call next to the Category call* — works today, awkward at three deduplicators.
- *Rename `runDeduplication()` to be Store-aware* — conflates responsibilities.

### Decision 5: No separate one-shot migration for existing corruption
**Choice**: Let the new deduplicator run on the next remote-change notification after upgrade. If device testing shows the remote-change path doesn't fire reliably for the stranded duplicates (e.g., because no remote change is arriving since the data is stale), fall back to invoking `runStoreDeduplication()` once from `performOneTimeSetup`.

**Rationale**: One-shot migrations are brittle (flag re-fires on reinstall; ordering with seeders matters). The deduplicator-on-remote-change pattern is the primary mechanism for Category corruption too, and it works. Test-driven decision: ship deduplicator, verify on the affected device, fall back to launch-time invocation only if necessary.

**Alternatives considered**:
- *Always invoke on launch* — overkill; the remote-change observer covers the common case.
- *One-shot migration with UserDefaults flag* — more code, more ways to get wrong.

### Decision 6: Name-dedupe guard in `copyPersonalDataToHousehold`, matching sibling
**Choice**: Before the `for old in oldStores` loop at `Services/HouseholdService.swift:1933-1949`, build a `Set<String>` of lowercased existing household-scope Store names. Skip personal-scope rows whose `name?.lowercased()` is already in the set. Matches the exact pattern used by `migrateHouseholdDataToPersonal` at line 1229-1238.

**Rationale**: Symmetry with the already-working sibling function. No new pattern; just extend the existing one. Prevents the "8 Stores copied" log line from recurring on fresh household creation even on devices that don't yet have the deduplicator in place.

**Alternatives considered**:
- *Rely solely on the deduplicator* — works but delays cleanup to the first sync event; guarding the copy path keeps the data clean from the moment of creation.

## Risks / Trade-offs

- **Risk**: Re-parenting `IngredientTemplate.preferredStore` touches Core Data relationships during a background context operation. If a concurrent user edit on the main context is in flight, there's a potential merge conflict. → **Mitigation**: `CategoryDeduplicator` already uses a background context with `automaticallyMergesChangesFromParent = true` and we inherit that; conflicts are resolved by the existing `NSMergeByPropertyObjectTrumpMergePolicy`. Add a save-error catch that logs and no-ops rather than crashing.
- **Risk**: The `isDefault` dimension in the grouping key causes a user-created "No Store" and the protected default to survive as two rows — which is intended — but the UI treats locked+unlocked rows identically in the list. Cosmetic, not functional. → **Mitigation**: Accept; follow-up UX pass if anyone actually hits it.
- **Risk**: Running the deduplicator on every remote-change event is expensive for users with many Stores. → **Mitigation**: Current grouping fetches all Stores and iterates in-memory; for real-world data sizes (dozens of stores) this is sub-millisecond. Same assumption `CategoryDeduplicator` makes. Revisit if profiling shows otherwise.
- **Risk**: Device remediation depends on remote-change notifications firing for the affected device. If the user's CloudKit is quiet for a long time after upgrade, the stranded duplicates persist. → **Mitigation**: This is the fallback path in Decision 5 — if testing shows it's an issue, add a launch-time invocation.
- **Trade-off**: The new service has meaningful code-shape overlap with `CategoryDeduplicator` (~60% of the skeleton is near-identical). → Accepted: one concrete new file over a generic refactor of a shipped service.
- **Trade-off**: We don't fix the root-cause CloudKit-import race in `DefaultSeeder`. → Accepted: deduplicator is the pragmatic downstream defense; the race exists for any seeder and would require a different architectural answer (CloudKit-first check before seed, which is expensive).

## Migration Plan

1. **Branch ready**: `feature/fix-no-store-default-duplicates` already branched from `main`. No coordination needed with `fix-groceryitem-multi-zone-assignment` (PR #150) since this change touches different files.
2. **Implement**:
   - Write `Services/Persistence/StoreDeduplicator.swift` with grouping, keeper selection, re-parenting, delete, save, logging (mirror of CategoryDeduplicator with divergences per Decisions 2-3).
   - Wire into `CloudKitSyncMonitor`: rename `runDeduplication` call to `runAllDeduplication`; new method calls both Category and Store deduplicators.
   - Add name-dedupe guard to `HouseholdService.copyPersonalDataToHousehold` Store loop.
3. **Test**:
   - New `foragerTests/Services/StoreDeduplicatorTests.swift` with 6 scenarios: no duplicates (no-op), two duplicates same scope (keeper oldest), three duplicates + relationships re-parented, cross-scope (personal + household, not deduped across scopes), isDefault vs user-created (not deduped across), idempotent second run.
   - Add regression test for `copyPersonalDataToHousehold` dedupe guard — either in `HouseholdServiceTests.swift` (if exists) or as a minimal new test.
   - Full test suite green; expect the 3 pre-existing flakes unrelated to this change to remain flaky.
4. **Device verification**: install build on the affected device (Rich's iPhone, which has 5 stranded "No Store" rows). Wait for next CloudKit remote-change event. Confirm Manage Stores shows exactly 1 "No Store" afterward. If not, add launch-time invocation per Decision 5.
5. **Ship**: `/pr`, merge, `/archive`, TestFlight distribute.

## Open Questions

- **Q1**: Does `CategoryDeduplicator`'s remote-change trigger fire reliably for devices that have NO recent CloudKit activity? (Relevant to whether Decision 5's fallback path is needed.) *Resolve via device testing.*
- **Q2**: Are there test-file architectural patterns for services that need a background-context setup? `CategoryDeduplicatorTests` uses in-memory stores; the re-parenting assertions may need extra setup. *Resolve while writing the test file.*
- **Q3**: Should `StoreDeduplicator` also dedupe across `CloudKitSyncMonitor` contexts (main + background)? `CategoryDeduplicator` operates on a dedicated background context. Probably same pattern. *Resolve during implementation.*
- **Q4**: The related-but-out-of-scope observation (`DefaultSeeder.ensureNoStoreExists` household-path uses raw `Store(context:)`) — should we queue that as a follow-up change (`harden-defaultseeder-factory-routing`) or leave it implicit on the app-health roadmap? *Decide at close-out.*
