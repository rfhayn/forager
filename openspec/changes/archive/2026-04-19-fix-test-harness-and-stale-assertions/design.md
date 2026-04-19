## Context

The forager test harness has two classes of pre-existing problems that surfaced together during a full-suite run on 2026-04-19:

1. **Four test files crash-loop on setUp** because they were written before factory enforcement (ADR 014) added the requirement that services have a configured factory before they can create `HouseholdScoped` entities. The tests call `PersistenceController(inMemory: true)` and construct the service, but never call `service.configure(factory:)`. When a test method invokes e.g. `service.createRecipe(...)`, the service's `factory.make(...)` hits the implicit-unwrapped `factory!` (declared `private(set) var factory: ManagedObjectFactory!`) and fatalErrors.

2. **`RecipeImportServiceLLMTests` uses a raw `NSPersistentContainer`** instead of a `PersistenceController`, and the service under test internally calls `PersistenceController.shared.privateStore`. `.shared` lazy-initializes the default (production) controller, which has no loaded stores in a test process — the `privateStore` getter's force-unwrap crashes with *"Private store not found. Expected forager.sqlite"*.

3. **Two assertion failures** are independent drift: `IngredientPreprocessor` now normalizes Unicode fractions before parser dispatch (so mocks that received `½` now receive `1/2`), and `IngredientTemplateService.normalize` now strips the `large` size descriptor (so `"Large Eggs"` normalizes to `"egg"`, not `"large egg"`).

The agent report that uncovered all this also noted that the crash-loops inflate CI time by ~15 minutes per run because each crashing test method triggers a full simulator relaunch. Fixing the harness is therefore high-leverage even if the 6 residual assertion failures can't all be resolved at the same time.

## Goals / Non-Goals

**Goals:**
- Eliminate the 51 crash-loops entirely. Every test method in the 4 affected files should run to completion (even if it fails an assertion).
- Fix the 2 stale assertion drifts with minimal disruption — prefer test updates over code updates because the code behavior is correct.
- Do this with the smallest possible production-code change (two lines in `PersistenceController.swift` with explanatory comments).
- Leave the test suite in a state where the remaining failures (6) are honest, visible, and actionable — not hidden by crashes.

**Non-Goals:**
- Fixing the 6 newly-exposed assertion failures in `RecipeImportServiceLLMTests` and `StoreServiceTests`. Those are separate investigations.
- Refactoring services to accept `PersistenceController` via DI instead of using `.shared`. Proper fix but larger scope; captured as follow-up.
- Un-gating of any test currently behind `#if DEBUG`.
- Any change to the production path's `PersistenceController.shared` behavior — the default continues to be set to `PersistenceController()` on first access.

## Decisions

### Decision 1 — Add `configure(factory:)` calls in setUp rather than make factory optional in services

**Chosen**: four test setUps call `ManagedObjectFactory(context:, scopeProvider: nil, persistence:)` and pass the factory to `service.configure(factory:)` (and to `templateService.configure(factory:)` where a template service is in play).

**Alternatives**:
- Change `factory: ManagedObjectFactory!` to `factory: ManagedObjectFactory?` in services and add `guard let` everywhere. Rejected — violates ADR 014 (factory must be configured at app startup; optional would weaken that contract in production). The implicit-unwrap is an *intentional* crash-at-wrong-startup check.
- Make `configure(factory:)` callable implicitly by having services lazy-create a default factory from their context. Rejected — same ADR 014 concern, plus would need to thread `scopeProvider` somewhere.

**Rationale**: tests should set up services the way production sets them up. The fix is two lines of setUp boilerplate per test file, not a production-code weakening.

### Decision 2 — Change in-memory store URLs to include canonical filenames

**Chosen**: in-memory paths become `/dev/null/forager.sqlite` and `/dev/null/forager_shared.sqlite` (up from bare `/dev/null` / `/dev/null-shared`).

**Alternatives**:
- Relax the `privateStore`/`sharedStore` getters to match any store with `scope == .private` using a different lookup mechanism. Rejected — would require querying NSPersistentStoreDescription's `cloudKitContainerOptions.databaseScope` or similar, which is brittle and not the current match key. The filename match is simple.
- Add a separate in-memory-aware lookup path in `privateStore`/`sharedStore`. Rejected — adds conditional complexity for a problem that's better solved by aligning the URLs.
- Use actual temp-directory files for in-memory mode. Rejected — defeats the "in-memory" label and may slow tests.

**Rationale**: Core Data treats the URL as an opaque identifier for in-memory stores; the filesystem path doesn't need to be real. Using the canonical filenames means the getter logic stays identical in production and test.

### Decision 3 — Make `PersistenceController.shared` a `var` for test-only swapping

**Chosen**: `static var shared = PersistenceController()` instead of `static let shared`. `RecipeImportServiceLLMTests.setUp` captures the prior value, swaps in an in-memory controller, and restores the prior value in tearDown.

**Alternatives**:
- Refactor `RecipeImportService.persistAndFinish` (and any other site hitting `.shared`) to accept a `PersistenceController` via init. Correct long-term fix but large — `RecipeImportService` is used from many call sites. Rejected for this change's scope.
- Leave `RecipeImportServiceLLMTests` crashing. Rejected — 5 tests worth of coverage lost for no reason.
- Add a DI seam just for PersistenceController access inside the service. Rejected — invents a new pattern for one test file.

**Rationale**: `var` is a small, reversible change that unblocks the test. Production code never sets `.shared`, so behavior is unchanged for the app. The swap is explicit in the test and restored in tearDown — not a hidden mutation. The long-term DI refactor can still happen later without touching this.

### Decision 4 — Update stale assertions rather than roll back the underlying behavior

**Chosen**: both stale assertions update their expectations; neither underlying service behavior is reverted.

**Alternatives**:
- Revert `IngredientPreprocessor`'s `½ → 1/2` normalization. Rejected — the normalization is a real preprocessing improvement and matches how the parsers are tuned.
- Revert the "large" qualifier stripping in `IngredientTemplateService.normalize`. Rejected — size descriptors (small/medium/large) *should* strip (same product, different grade), while identity descriptors (baby, fresh) are already preserved. The current behavior is correct.

**Rationale**: tests exist to verify intended behavior. When the intended behavior changes, tests update.

### Decision 5 — For the parser-routing test, use ASCII input rather than keep the fraction

**Chosen**: change `"½ cup butter"` → `"1 cup butter"` in `testParsersReceiveCorrectInput`.

**Alternatives**:
- Keep `½` but assert parsers receive `"1/2 cup butter"`. Rejected — this test is about parser-dispatch routing, not about preprocessor normalization. Coupling the test to the preprocessor's exact normalization rules creates a second failure point if preprocessor rules evolve.

**Rationale**: test the thing the test is about. Parser routing is unchanged by the choice of input; use the simplest input that exercises the routing.

## Risks / Trade-offs

- **Risk**: Making `.shared` a `var` introduces a temptation for someone to mutate it elsewhere in tests, creating harder-to-debug test-order dependencies. → **Mitigation**: comment on the declaration explicitly says "Production code NEVER sets this — the default stays in effect"; the single caller (`RecipeImportServiceLLMTests`) restores the prior value in tearDown. If this pattern grows, the `establish-test-planning-workflow` change should introduce a cleaner DI seam.

- **Risk**: Changing in-memory URLs from `/dev/null` to `/dev/null/forager.sqlite` might surprise someone reading the test code expecting the sentinel path. → **Mitigation**: comment on the change documents why and notes that the URL is opaque for in-memory stores. Very low risk.

- **Trade-off**: This change does NOT fix the 6 remaining assertion failures. Reviewers should not expect a green `TEST SUCCEEDED` from this change alone — only "no more crash-loops + 2 stale assertions resolved." The remaining 6 are called out explicitly as deferred.

- **Risk**: The `testReplaceExistingRecipeUpdatesFields` failure may be a real import-replacement bug, not a stale test. Leaving it unfixed means the bug (if real) stays in production. → **Mitigation**: captured as follow-up. Is not blocking `architecture-compliance-sweep`. Separate investigation change will triage.

## Migration Plan

1. Single branch `feature/fix-test-harness-and-stale-assertions`, one squash commit to main.
2. No data migration. No schema change.
3. Run the 4 affected test files locally to verify zero crash-loops. Confirmed: 78 tests in 2.8 seconds, down from ~15 minutes of relaunches.
4. After merge, trigger a full-suite run to confirm total CI time drops from ~25min to ~3-5min.

## Open Questions

- None that block this change. The 6 remaining failures are legitimate work but out of scope.
