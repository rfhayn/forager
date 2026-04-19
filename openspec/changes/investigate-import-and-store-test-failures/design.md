## Context

With PR #147 eliminating the 51 setUp crash-loops, the underlying assertion failures became visible. A background investigation agent ran the two affected files (`RecipeImportServiceLLMTests`, `StoreServiceTests`) and produced a triage plan at `~/.claude/plans/investigate-import-and-store-test-failures.md`. Key finding: only 3 real failures, not 6. The other 3 tests mentioned in PR #147's description actually pass — the PR description over-counted before the tests could run.

Each of the 3 real failures is a different class of problem, each deserving a different fix:

- **#1 (real bug)** `RecipeImportServiceLLMTests.testReplaceExistingRecipeUpdatesFields` — `persistAndFinish`'s refresh loop discards the target recipe's pending edits. **Service fix.**
- **#2 (test-harness artifact)** `testSaveImportUsesPipelineWhenLLMDisabled` — state leaks across tests in the file. **Test fix (delta assertions + predicate-fetch).**
- **#3 (stale test)** `StoreServiceTests.testFetchStoresScopedByHouseholdKey` — test expected `service.householdKey` to propagate into factory-made entities, but ADR 014's factory takes scope from ScopeProvider, not service. **Test fix (stub ScopeProvider).**

## Goals / Non-Goals

**Goals:**
- All 19 tests in the two affected suites pass.
- No change to `saveImport` behavior (cross-store refresh safety net for 134040 errors still applies).
- `replaceExistingRecipe` actually persists user-initiated field edits (fixes possible production bug).
- Test fixes use patterns already present in the codebase (delta assertions match `StoreServiceTests.testFetchStoresReturnsOrderedBySort`; stub ScopeProvider is simple).

**Non-Goals:**
- Refactoring service-to-singleton coupling. Tracked in `establish-test-planning-workflow`.
- Fixing the underlying NSPersistentCloudKitContainer in-memory state-leakage root cause. Tracked as deferred.
- Adding a reusable TestSupport folder. Inline the stub in StoreServiceTests for now; extract later if re-used.

## Decisions

### Decision 1 — Option A for service fix: `preserveUpdated` parameter on `persistAndFinish`

**Chosen**: add `preserveUpdated: Set<NSManagedObject> = []` parameter. Refresh loop excludes objects whose objectID is in that set. `replaceExistingRecipe` passes `[recipe]`; `saveImport` uses the default `[]`.

**Alternatives**:
- Narrow the refresh criterion (restore M9.23's original "cross-store only" scope). Rejected — risky without device-level verification that 134040 errors are still covered by the narrower check.
- Capture pending changes before refresh, restore after. Rejected — brittle, tightly coupled to Core Data internals.
- Refactor `replaceExistingRecipe` to not go through `persistAndFinish`. Rejected — duplicates the cross-store resolution logic.

**Rationale**: minimal, additive change. Default parameter preserves existing `saveImport` behavior. The escape hatch is explicit and self-documenting — the call site names what it's preserving.

### Decision 2 — Compare preserveUpdated by objectID, not object identity

**Chosen**: `let preserveIDs = Set(preserveUpdated.map { $0.objectID })` then `!preserveIDs.contains(obj.objectID)`.

**Alternatives**:
- Compare by `===` (identity). Rejected — the caller passes a child-context `recipe` instance, but the refresh loop iterates viewContext's updatedObjects. Those are DIFFERENT NSManagedObject instances sharing the same ObjectID after child→parent propagation. Identity comparison would always miss, defeating the fix.
- Use `NSManagedObject`'s `isEqual` (which compares by objectID). Rejected — would work, but explicit objectID comparison is self-documenting.

**Rationale**: NSManagedObject instances are per-context. ObjectID is the cross-context identifier.

### Decision 3 — Delta assertions for state leakage (test fix #2), not unique in-memory URLs

**Chosen**: capture baseline counts in setUp; assertions use `recipesAddedByThisTest()` / `ingredientsAddedByThisTest()`.

**Alternatives**:
- Unique in-memory URL per test (requires `PersistenceController.init` signature change). Rejected for now — matches test-support pattern already used by `testFetchStoresReturnsOrderedBySort`; zero production-code impact.
- `DELETE FROM *` sweep in tearDown. Rejected — risk of masking real bugs if cleanup misses objects.

**Rationale**: delta pattern is already present in the codebase, zero production impact. The leakage root cause (suspected `NSPersistentCloudKitContainer` URL-keyed cache) is worth investigating later but doesn't block this fix.

### Decision 4 — Fetch-by-unique-title for testSaveImportUsesPipelineWhenLLMDisabled

**Chosen**: generate a UUID-suffixed title in the draft, then fetch recipes matching that title to verify the save.

**Alternatives**:
- `context.existingObject(with: result.recipeObjectID)` + read attributes. Rejected — on the dual-store in-memory container, freshly-saved objects come back as faulted with nil attributes. Refreshing via `mergeChanges: true` sometimes works, but is fragile.
- `context.refreshAllObjects()` before reading. Rejected — blunt instrument; other tests in the suite might depend on NOT having all objects re-faulted.
- Skip the title assertion entirely (rely on delta count only). Rejected — loses coverage of the "save actually wrote the draft's values" property.

**Rationale**: fetch-by-predicate is robust against cache states AND against state leakage from other tests. A UUID-suffixed title guarantees uniqueness.

### Decision 5 — Inline TestStubScopeProvider in StoreServiceTests, don't create TestSupport folder

**Chosen**: put `TestStubScopeProvider` as a `@MainActor final class` at the top of `StoreServiceTests.swift`.

**Alternatives**:
- Create `foragerTests/TestSupport/TestStubScopeProvider.swift` (new folder). Rejected — we only use it in one file today; create the folder when a second file needs it.

**Rationale**: YAGNI. One file = one inline helper. When a second service test needs a stub ScopeProvider, extract then.

## Risks / Trade-offs

- **Risk**: the service fix may expose previously-hidden behavior. If `replaceExistingRecipe` was silently reverting edits in production and users had become accustomed to manually re-editing, the new (correct) behavior may surprise them. → **Mitigation**: this is the "fix a real bug" path, not a behavior regression. Smoke-test post-merge via Import Preview "Replace existing" flow.

- **Risk**: the objectID-comparison in the refresh loop adds a small allocation (`Set(preserveUpdated.map { $0.objectID })`) on every `persistAndFinish` call. → **Accepted**: negligible (single element set for `replaceExistingRecipe`; empty set for `saveImport`).

- **Trade-off**: delta assertions mask the underlying state-leakage issue. → **Accepted**: the leakage is real but non-critical. Documenting it in the test file comments + deferring the root-cause investigation is honest.

- **Trade-off**: the `TestStubScopeProvider` is inlined rather than reusable. → **Accepted**: will extract when the 2nd consumer materializes.

## Migration Plan

1. Single feature branch `feature/investigate-import-and-store-test-failures` off `feature/fix-test-harness-and-stale-assertions` (PR #147). Note: depends on PR #147 merging first, OR this PR can rebase onto main after #147 merges.
2. No data migration. No schema change.
3. After merge: verify full-suite runtime is now ~3-5min (target from PR #147) AND zero failures.

## Open Questions

- The state-leakage root cause (NSPersistentCloudKitContainer URL-keyed cache? NSPersistentStoreCoordinator retention?) — out of scope here, but worth a future investigation.
- Does `replaceExistingRecipe` actually work in production? Post-merge smoke test via Import Preview's "Replace existing" flow will confirm. If broken and this fix repairs it, note it in the journal; if it was working, the fix is still correct as defense.
