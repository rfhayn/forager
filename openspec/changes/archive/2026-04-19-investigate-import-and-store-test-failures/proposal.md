## Why

PR #147 (`fix-test-harness-and-stale-assertions`) eliminated 51 test setUp crash-loops but surfaced 3 real assertion failures that had been hidden underneath the crashes. A background investigation agent ran the previously-crashing files and determined:

- **Actual failure count is 3, not 6** (earlier count was over-reported before PR #147's tests could actually execute).
- **1 is a REAL service bug** in `RecipeImportService.persistAndFinish` that affects `replaceExistingRecipe` — worth fixing urgently because it may affect production.
- **1 is a test-harness state-leakage artifact** from `PersistenceController(inMemory:)` — counts leak across tests in the same file.
- **1 is a stale test assumption** pre-dating ADR 014's factory enforcement — test expected `service.householdKey` to propagate into factory-made entities, but the factory's `.personal` scope explicitly nils `householdKey`.

Agent's full plan: `~/.claude/plans/investigate-import-and-store-test-failures.md`.

## What Changes

**Service fix (1 file, ~10 lines in `Services/Import/RecipeImportService.swift`)**:

The `persistAndFinish` method runs a `refresh(mergeChanges: false)` loop over `viewContext.updatedObjects` before save to prevent 134040 cross-store validation errors (M9.23 commit `e058ef7`). That broadening is correct for `saveImport` (the recipe is INSERTED, so `!obj.isInserted` excludes it) but **incorrect for `replaceExistingRecipe`** — the recipe is UPDATED in place, so the refresh discards its new title/instructions/etc., reverting the recipe to its pre-edit state. Production impact unknown but possible; the user may not have noticed because UI refresh-fetch could paper over the stale write.

Fix: add `preserveUpdated: Set<NSManagedObject> = []` parameter to `persistAndFinish`. The refresh loop excludes objects whose objectID is in `preserveUpdated`. `replaceExistingRecipe` passes `preserveUpdated: [recipe]`. `saveImport` doesn't pass anything — default `[]` preserves existing behavior. Uses objectID comparison (not identity) because child-context and viewContext instances of the same recipe are different objects.

**Test fixes (2 files)**:

- `foragerTests/Services/RecipeImportServiceLLMTests.swift`: setUp captures baseline Recipe / Ingredient counts; assertions use `recipesAddedByThisTest()` / `ingredientsAddedByThisTest()` deltas instead of absolute counts. The `testSaveImportUsesPipelineWhenLLMDisabled` test uses a UUID-suffixed title and fetches by predicate (avoids the "existingObject returns faulted instance with nil attributes" issue on freshly-saved recipes). The `testPipelineFallbackCreatesIngredientsWithTemplates` test loops all ingredients to verify template connectivity (no reliance on `recipe.ingredients` relationship cache).
- `foragerTests/Services/StoreServiceTests.swift`: adds a `TestStubScopeProvider` conforming to `ScopeProvider`; `testFetchStoresScopedByHouseholdKey` creates a real `Household` entity, then reconfigures `StoreService` with a factory using a `TestStubScopeProvider` returning `.household(id: household.objectID, storeID: .private)`. The factory's `.household` branch sets `store.householdKey = household.id?.uuidString`, which is what the test's fetch-scope assertion needs.

**No changes to**: production view code, schemas, CloudKit configuration, factory, scope provider implementation, or any of the services whose tests are being fixed (beyond the one `persistAndFinish` signature addition).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `architecture`: MODIFIED REQ — `persistAndFinish`'s refresh-updated-objects loop gains a `preserveUpdated` escape hatch so updated-in-place entities (notably the recipe being replaced in `replaceExistingRecipe`) don't have their pending edits discarded. The M9.23 fix for 134040 cross-store validation errors continues to apply to all OTHER updated objects — only the explicitly-preserved ones are excluded.

## Impact

**Affected code** (1 production file + 2 test files):
- `Services/Import/RecipeImportService.swift`: `persistAndFinish` signature gains `preserveUpdated: Set<NSManagedObject> = []`; refresh loop filters by objectID membership in that set. `replaceExistingRecipe` passes `preserveUpdated: [recipe]`. ~10 lines of change with explanatory comments.
- `foragerTests/Services/RecipeImportServiceLLMTests.swift`: setUp captures baselines; 3 tests updated to delta + predicate-fetch patterns.
- `foragerTests/Services/StoreServiceTests.swift`: `TestStubScopeProvider` helper class added at file top; `testFetchStoresScopedByHouseholdKey` rewritten.

**Verification**: **19 / 19 tests pass in 0.83 seconds.** (Was: 3 failures + 6 leaked-state false alarms pre-fix.)

**Production behavior change**: `replaceExistingRecipe` now actually persists the user's edits to title/instructions/etc. as intended. If production was previously broken (replace-existing was a UI-only update silently reverted at save), this fixes a real bug. Worth verifying on-device post-merge.

**No behavior change for**: `saveImport` (new recipes) — default `preserveUpdated: []` matches pre-fix behavior.

**Scope / non-goals**:
- NOT refactoring `MealPlanService`/`StoreService`/etc. away from singleton-through-PersistenceController.shared patterns. Bigger change; tracked under `establish-test-planning-workflow`.
- NOT fixing the underlying `NSPersistentCloudKitContainer` in-memory URL caching that causes state leakage. The delta-assertion approach works around it at the test level; a cleaner fix (per-test unique URL, or using NSPersistentContainer for tests that don't need dual-store) is deferred.
- NOT adding regression tests beyond what already exists — the existing tests, now passing, are the regression coverage.

**Deferred follow-ups** (captured so they don't disappear):
- Verify `replaceExistingRecipe` actually works in production post-merge via the "Replace existing" UI flow in the import preview. If it was broken, this fix repairs it; if it wasn't broken (e.g., some other save path compensates), the fix is still correct as defense-in-depth.
- The state-leakage root cause (NSPersistentCloudKitContainer cache, NSPersistentStoreCoordinator, or URL-handling) deserves its own investigation before adopting a unique-URL approach, but delta assertions make it non-urgent.
- Reusable `TestStubScopeProvider` could live in `foragerTests/TestSupport/` (if that folder gets created) for sharing across future service tests. Currently inlined in `StoreServiceTests.swift`.
