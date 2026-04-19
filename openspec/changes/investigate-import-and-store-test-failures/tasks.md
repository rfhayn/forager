# investigate-import-and-store-test-failures — Tasks

## Phase 1 — Investigation (done in background agent)

- [x] Run the 2 affected test files on PR #147 branch; collect actual failure output via xcresulttool
- [x] Classify each failure: REAL BUG / TEST-HARNESS ARTIFACT / STALE TEST
- [x] Trace Failure #1 root cause to `persistAndFinish` refresh loop + M9.23 commit `e058ef7`
- [x] Trace Failure #2 to cross-test state leakage (alphabetical test order + PersistenceController(inMemory:) URL caching)
- [x] Trace Failure #3 to factory's `.personal` branch overriding `service.householdKey`
- [x] Confirm 3 other tests previously thought failing actually pass — PR #147 description over-counted
- [x] Agent plan at `~/.claude/plans/investigate-import-and-store-test-failures.md`

## Phase 2 — Service fix (Failure #1)

- [x] Add `preserveUpdated: Set<NSManagedObject> = []` parameter to `RecipeImportService.persistAndFinish`
- [x] Implement objectID-based filter in the refresh loop (child-context vs viewContext instances share objectID but not identity)
- [x] `replaceExistingRecipe` passes `preserveUpdated: [recipe]`
- [x] `saveImport` continues to use the default empty set (no change in behavior)
- [x] Build clean

## Phase 3 — Test fixes (Failures #2, #3)

### 3a. RecipeImportServiceLLMTests (Failure #2)

- [x] Add `baselineRecipeCount` / `baselineIngredientCount` captured in setUp
- [x] Add `recipesAddedByThisTest()` / `ingredientsAddedByThisTest()` / `currentRecipeCount()` / `currentIngredientCount()` helpers
- [x] `testSaveImportUsesPipelineWhenLLMDisabled` — delta-count assertions + UUID-suffixed title + predicate fetch (decouples from existingObject's faulted-instance issue)
- [x] `testPipelineFallbackCreatesIngredientsWithTemplates` — delta-count + all-ingredients template check (no reliance on recipe.ingredients relationship cache)
- [x] `testEmptyIngredientsStillSavesRecipe` — delta-count assertions

### 3b. StoreServiceTests (Failure #3)

- [x] Add `TestStubScopeProvider` class conforming to `ScopeProvider` at top of file
- [x] Rewrite `testFetchStoresScopedByHouseholdKey` to create a real Household, reconfigure the service with a factory using `TestStubScopeProvider(.household(...))`, verify `costco.householdKey == household.id?.uuidString`

## Phase 4 — Verification

- [x] Build clean: `xcodebuild build` → 0 errors
- [x] 19 of 19 tests in the 2 affected files pass in 0.83 seconds (was: 3 real failures + 51 crash-loops pre-PR-#147 + ~25min total suite time)
- [ ] Full `xcodebuild test` run post-merge (deferred — targeted run is sufficient signal that both suites are now green)

## Phase 5 — Ship

- [ ] Update `docs/current-story.md` with the change entry
- [ ] `/dev-journal` — Session 123 entry
- [ ] `/log-insight` — capture: (a) the child-context-vs-viewContext objectID-vs-identity trap in Core Data refresh loops, (b) NSPersistentCloudKitContainer in-memory state-leakage discovery, (c) predicate-fetch over existingObject for freshly-saved entities, (d) TestStubScopeProvider as a reusable pattern
- [ ] `/commit`
- [ ] `/pr`
- [ ] After merge: `/opsx:archive investigate-import-and-store-test-failures`
- [ ] Post-merge smoke test: verify `replaceExistingRecipe` actually works in production via Import Preview "Replace existing" flow

## Deferred (follow-ups)

- **NSPersistentCloudKitContainer state-leakage root cause**: investigate whether URL caching, store coordinator retention, or CloudKit mirroring is the source. Eventually either a unique-URL-per-test approach or a cleaner test container option in PersistenceController. Non-urgent — delta assertions work around it.
- **Reusable TestStubScopeProvider**: extract to `foragerTests/TestSupport/` when a second service test needs it.
- **Singleton DI refactor**: `MealPlanService.shared`, `PersistenceController.shared`, etc. reaching through singletons forces test-scoped workarounds. Properly tracked in `establish-test-planning-workflow` plan.
