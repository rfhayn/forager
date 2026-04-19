## Why

A full `xcodebuild test` run on 2026-04-19 (during `architecture-compliance-sweep` verification) surfaced that the forager test suite takes ~25 minutes instead of a few minutes, and reports `TEST FAILED` even when no new bugs exist. Investigation by a background agent found two distinct issues:

1. **4 test files crash-loop on setUp** — 51 xctest relaunches in one run, ~15 minutes of CI time wasted on simulator re-spinups. Tests never reach their assertions; the "failures" are fatal errors in service setup. Root causes:
   - `RecipeServiceTests`, `WeeklyListServiceTests` — crash on implicit-unwrap of `factory!` because `configure(factory:)` is never called in setUp. The factory injection pattern (ADR 014) was added after these tests were written.
   - `StoreServiceTests` — `StoreService.swift:73` explicitly `assertionFailure`s with *"StoreService.createStore called without factory — configure(factory:) must be called at app startup"*. Same root cause.
   - `RecipeImportServiceLLMTests` — crashes at `PersistenceController.swift:57` *"Private store not found. Expected forager.sqlite"*. Root cause: the test uses a raw `NSPersistentContainer(name: "forager")` with one in-memory store, but `RecipeImportService.persistAndFinish` reaches through `PersistenceController.shared.privateStore` — a separate production singleton that has no stores in a test process.

2. **2 stale assertion failures** — tests whose expectations were not updated when the code underneath them changed:
   - `HybridParserRoutingTests.testParsersReceiveCorrectInput` expects parsers to receive `"½ cup butter"` but `IngredientPreprocessor` now normalizes the fraction to `"1/2 cup butter"` before dispatch.
   - `IngredientTemplateNormalizationTests.testLargeEggsSingularizes` expects `"large egg"` but the normalizer now treats "large" as a size descriptor and strips it, yielding `"egg"`.

These are pre-existing drift from the `architecture-compliance-sweep` baseline. Fixing them separately keeps that PR focused and makes this change's blast-radius small.

## What Changes

**Test-harness fixes** (4 files, setUp only):

- `foragerTests/Services/RecipeServiceTests.swift`: create a `ManagedObjectFactory` in setUp and call `service.configure(factory:)` + `templateService.configure(factory:)`.
- `foragerTests/Services/WeeklyListServiceTests.swift`: same pattern.
- `foragerTests/Services/StoreServiceTests.swift`: same pattern (single service, single configure call).
- `foragerTests/Services/RecipeImportServiceLLMTests.swift`: replace the raw `NSPersistentContainer` with `PersistenceController(inMemory: true)` so the dual-store architecture is present; **also** temporarily swap `PersistenceController.shared` to the test's instance for the duration of the test, so the service's internal `.shared.privateStore` lookup resolves to the in-memory private store. Restore the prior `.shared` in tearDown.

**Small production changes** (2 files, both enabling the test fixes):

- `Services/Persistence/PersistenceController.swift`: change `static let shared` → `static var shared` so the test can swap it. Production code never mutates this; the default stays in effect. One-line change + comment explaining why.
- `Services/Persistence/PersistenceController.swift`: change the in-memory URLs from `/dev/null` + `/dev/null-shared` to `/dev/null/forager.sqlite` + `/dev/null/forager_shared.sqlite` so the `privateStore`/`sharedStore` getters (which look up by `url.lastPathComponent`) resolve the in-memory stores the same way production resolves real files.

**Stale-assertion fixes** (2 files, one assertion each):

- `foragerTests/Services/Parsing/HybridParserRoutingTests.swift::testParsersReceiveCorrectInput`: change the input from `"½ cup butter"` to `"1 cup butter"` (ASCII-only). The test's purpose is to verify all three parsers receive the SAME input, not to validate `IngredientPreprocessor` — so avoid coupling to its exact normalization rules. Add a comment documenting why.
- `foragerTests/Services/IngredientTemplateNormalizationTests.swift::testLargeEggsSingularizes`: update the expected result from `"large egg"` to `"egg"` and document why (`large` is a size descriptor, stripped; `baby` in adjacent tests is an identity qualifier, preserved).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `developer-tooling`: MODIFIED — the test-harness setup is now correctly aligned with ADR 014's factory-enforcement pattern. Four service test files now call `configure(factory:)` in setUp; `PersistenceController(inMemory: true)` resolves its in-memory stores via the same `.lastPathComponent` lookup production uses; `PersistenceController.shared` is swappable for tests that exercise code paths reaching through the singleton. No change to the `/architecture-audit` skill or other developer-tooling surfaces.

## Impact

**Before** (2026-04-19 full-suite run):
- Runtime: ~25 minutes (1495s elapsed)
- Crash-loops: 51 simulator relaunches from the 4 broken setUp methods
- Visible failures: 2 stale assertions
- Hidden failures: unknown (tests in the 4 crashing files never reach their assertions)

**After** (this change):
- Runtime: **under 5 seconds for the 6 previously-broken test files** (measured: 2.8s for 78 tests). Full-suite runtime should drop from ~25min to ~3-5min.
- Crash-loops: **zero** for the 4 fixed files.
- Stale assertions: **fixed**.
- Newly-exposed failures (were hidden by crashes before): 6 real assertion mismatches in `RecipeImportServiceLLMTests` (4) and `StoreServiceTests` (2). These are pre-existing bugs or behavior drifts, not regressions from this change. They are **out of scope** for this change and are captured as follow-up work. See "Deferred follow-ups" below.

**Affected code**:
- 2 production files (`PersistenceController.swift`): two small, reviewable changes with explanatory comments.
- 6 test files (4 setUp fixes + 2 assertion fixes).
- 1 OpenSpec change directory.

**No changes to**: business logic, view code, schemas, CloudKit configuration, factory, scope provider, or any of the services whose tests are being fixed.

**Deferred follow-ups** (out of scope here, captured so they don't disappear):

- The 6 remaining test failures revealed by running the previously-crashing tests: `RecipeImportServiceLLMTests.testSaveImportUsesPipelineWhenLLMDisabled/testPipelineFallbackCreatesIngredientsWithTemplates/testSaveResultIncludesUncategorizedTemplates/testReplaceExistingRecipeUpdatesFields/testEmptyIngredientsStillSavesRecipe` and `StoreServiceTests.testFetchStoresScopedByHouseholdKey` (+ 1 other). These are real behavior questions requiring investigation — either the tests are stale (behavior changed legitimately) or the code has a bug. Propose under change `investigate-import-and-store-test-failures` after `architecture-compliance-sweep` ships.
- `PersistenceController.shared` as mutable singleton is a code smell. The `establish-test-planning-workflow` change (currently planned at `~/.claude/plans/test-first-thinking-exploration.md`) should consider a proper DI refactor for services that currently reach through `.shared`. That's a larger change, not blocked by this one.
