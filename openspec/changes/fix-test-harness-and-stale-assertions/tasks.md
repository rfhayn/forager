# fix-test-harness-and-stale-assertions — Tasks

## Phase 1 — Test-harness setUp fixes

- [x] `foragerTests/Services/RecipeServiceTests.swift` — instantiate `ManagedObjectFactory(context:, scopeProvider: nil, persistence:)` in setUp, call `service.configure(factory:)` + `templateService.configure(factory:)`
- [x] `foragerTests/Services/WeeklyListServiceTests.swift` — same pattern
- [x] `foragerTests/Services/StoreServiceTests.swift` — same pattern (single service, single configure call)
- [x] Verify all three files compile; run tests to confirm no more crash-loops

## Phase 2 — PersistenceController test-harness fixes

- [x] `Services/Persistence/PersistenceController.swift` — change in-memory URLs to `/dev/null/forager.sqlite` + `/dev/null/forager_shared.sqlite` so `privateStore`/`sharedStore` getters resolve. Add comment explaining why.
- [x] `Services/Persistence/PersistenceController.swift` — change `static let shared` → `static var shared` so tests can swap. Add comment: *"Production code NEVER sets this — the default stays in effect."*

## Phase 3 — RecipeImportServiceLLMTests refactor

- [x] Replace raw `NSPersistentContainer(name: "forager")` with `PersistenceController(inMemory: true)`
- [x] Capture prior `PersistenceController.shared` in a `previousShared` var
- [x] Assign the in-memory controller to `PersistenceController.shared` for the duration of the test
- [x] Restore the prior value in tearDown

## Phase 4 — Stale assertion fixes

- [x] `foragerTests/Services/Parsing/HybridParserRoutingTests.swift::testParsersReceiveCorrectInput` — change input `"½ cup butter"` to `"1 cup butter"` (ASCII-only). Add comment documenting why this test avoids coupling to `IngredientPreprocessor` normalization.
- [x] `foragerTests/Services/IngredientTemplateNormalizationTests.swift::testLargeEggsSingularizes` — update expected result `"large egg"` → `"egg"`. Add comment documenting that `large` is a size descriptor (stripped) while `baby` in adjacent tests is an identity qualifier (preserved).

## Phase 5 — Verification

- [x] `xcodebuild build` — succeeds with 0 errors, 0 new warnings
- [x] Targeted test run for the 6 affected files: 78 tests executed in 2.8s (previously: 51 crash-loops, ~15 minutes)
- [x] Zero crash-loops in the 4 previously-broken files
- [x] Both stale assertions now pass
- [ ] Full `xcodebuild test` run on a clean simulator to confirm total runtime drops from ~25min → ~3-5min (deferred — requires a clean restart; local confirmation on the affected files is sufficient signal)

## Phase 6 — Document remaining failures

- [x] Proposal.md "Deferred follow-ups" section enumerates the 6 newly-exposed assertion failures: 5 in `RecipeImportServiceLLMTests` (`testSaveImportUsesPipelineWhenLLMDisabled`, `testPipelineFallbackCreatesIngredientsWithTemplates`, `testSaveResultIncludesUncategorizedTemplates`, `testReplaceExistingRecipeUpdatesFields`, `testEmptyIngredientsStillSavesRecipe`) and 1 in `StoreServiceTests` (`testFetchStoresScopedByHouseholdKey`). These are real behavior/expectation mismatches requiring investigation — proposed as a follow-up change `investigate-import-and-store-test-failures`.

## Phase 7 — Ship

- [ ] `/dev-journal` — Session 121 entry
- [ ] `/log-insight` — capture insights about grep-existence-vs-grep-contents (services already-compliant), crash-loops-hide-real-failures, mutable-shared-is-a-test-seam-smell, preview-false-positives
- [ ] `/commit`
- [ ] `/pr`
- [ ] After merge: `/opsx:archive fix-test-harness-and-stale-assertions`
