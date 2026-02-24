# M10 PRD Feedback for Claude

Date: February 24, 2026  
Target PRD: `docs/prds/active/m10-recipe-import.md`  
Reviewer: Codex

## Scope Reviewed
- PRD: `docs/prds/active/m10-recipe-import.md`
- Project context docs: `README.md`, `docs/current-story.md`, `docs/project-index.md`, `docs/requirements.md`, `docs/roadmap.md`, `docs/next-prompt.md`
- Supporting research: `docs/import-research/acceptance-criteria.md`, `docs/import-research/test-site-matrix.md`, `docs/import-research/architecture-review-codex.md`, `docs/import-research/prd-preparation-spike.md`
- Relevant code validation: `Services/RecipeService.swift`, `Services/IngredientParsingService.swift`, `Services/RecipeFormModels.swift`, `Services/ParsingTelemetryService.swift`, `forager/foragerApp.swift`, `forager/CreateRecipeView.swift`, `forager/RecipeListView.swift`, `Services/Persistence/ManagedObjectFactory.swift`, `Services/Persistence/DataScope.swift`

## Findings (Ordered by Severity)

### High

1. `ImportJobState` likely does not compile as declared.
- PRD declares `ImportJobState: Equatable` with `case saved(Recipe)`.
- `Recipe` is an `NSManagedObject` and there is no `Recipe: Equatable` conformance in the codebase.
- PRD refs: `docs/prds/active/m10-recipe-import.md:273`, `:280`.
- Recommended fix: use `saved(NSManagedObjectID)` or add a custom equality implementation that compares object IDs.

2. Household scoping behavior is under-specified and partly inaccurate in supporting docs.
- Plan says imported recipes auto-get `householdKey` using the same pattern as `CreateRecipeView.completeSave()`.
- Current `CreateRecipeView.completeSave()` does not set `household`/`householdKey`.
- Recipe visibility filters by `householdKey` in `RecipeListView`.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:704`
  - `docs/requirements.md:669`
  - `forager/CreateRecipeView.swift:646`
  - `forager/RecipeListView.swift:61`
  - `Services/Persistence/ManagedObjectFactory.swift:43`
  - `Services/Persistence/DataScope.swift:95`
- Recommended fix: explicitly define one import-save path:
  - use `ManagedObjectFactory` for scope-safe creation, or
  - explicitly assign `household` + `householdKey` before save.

3. "Import allows partial data" conflicts with current form validation contract.
- PRD says import validation differs from manual creation.
- Current `RecipeFormData.validate()` requires name, ingredients, and instructions.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:132`
  - `docs/prds/active/m10-recipe-import.md:474`
  - `Services/RecipeFormModels.swift:124`
- Recommended fix: document exact save gate for import (minimum required fields) and whether `RecipeFormData` validation is bypassed/adapted.

### Medium

4. Targets are inconsistent across docs.
- Heuristic accuracy differs (`>=70%` in PRD vs `>=85%` in acceptance criteria).
- Regression baseline differs (`282` vs `267` tests).
- Roadmap still has stale M10 estimate in one section.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:550`
  - `docs/import-research/acceptance-criteria.md:113`
  - `docs/prds/active/m10-recipe-import.md:468`
  - `docs/import-research/acceptance-criteria.md:139`
  - `docs/roadmap.md:226`
  - `docs/roadmap.md:1039`
- Recommended fix: normalize all targets in one source and reconcile downstream docs.

5. Telemetry/storage architecture is internally inconsistent.
- PRD says UserDefaults pattern is "same as ParsingTelemetryService."
- Current `ParsingTelemetryService` stores JSON in Documents directory.
- PRD proposes both extending `ParsingTelemetryService` and adding separate `ImportTelemetryService` (overlap risk).
- Refs:
  - `docs/prds/active/m10-recipe-import.md:164`
  - `docs/prds/active/m10-recipe-import.md:801`
  - `Services/ParsingTelemetryService.swift:167`
- Recommended fix: choose one telemetry owner and one storage strategy.

6. URL fallback policy for microdata-only pages is unclear for M10.1.
- Domain policy points to M10.2 heuristic fallback, but M10.2 is text-paste flow, not URL flow.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:763`
  - `docs/prds/active/m10-recipe-import.md:472`
- Recommended fix: define URL-flow fallback sequence explicitly (including what happens when JSON-LD and WKWebView both fail).

7. Share extension handoff contract needs tighter definition.
- Key read/clear semantics and duplicate consumption behavior are not explicit.
- PRD references an `.onOpenURL` change, but app currently has no `.onOpenURL` handling in `foragerApp`.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:393`
  - `docs/prds/active/m10-recipe-import.md:444`
  - `forager/foragerApp.swift:106`
- Recommended fix: define deterministic handoff lifecycle:
  - where URL is written,
  - when main app consumes it,
  - when key is cleared,
  - idempotency behavior across cold start/foreground.

## Positives

1. Phase ordering is strong (M10.1 URL first, then text, then photo).
2. PRD is data-backed with concrete spike metrics and edge-case frequencies.
3. Draft-first and atomic-save direction directly addresses persistence pollution risk.
4. Reuse of `IngredientParsingService.parseAndConnectIngredients()` is the right convergence point.
5. Risk register, assumptions, and open-question sections are unusually complete.

## Recommended PRD Edits Before Implementation Starts

1. Fix `ImportJobState` saved payload/equality design.
2. Add explicit household-scoping contract for import saves (factory vs manual assignment).
3. Define import-specific save validation gate in writing.
4. Reconcile all M10 targets across PRD, acceptance criteria, requirements, roadmap, next-prompt.
5. Collapse telemetry ownership to one service and one storage strategy.
6. Clarify URL-flow fallback behavior for non-JSON-LD and microdata-only pages.
7. Specify share extension handoff lifecycle and idempotency rules.

## Bottom Line

The M10 PRD is close to implementation-ready and strategically strong. The main remaining work is tightening a few contracts (state model, household scope, validation, telemetry ownership, and fallback semantics) so execution is predictable and low-risk.

---

## Full Audit Pass (Post-Update)

Date: February 24, 2026  
Scope: Full re-audit of updated PRD plus consistency checks across active planning docs and current code contracts.

### Findings (Ordered by Severity)

### High

1. `ImportJobState` can still fail Equatable synthesis.
- PRD now correctly changed `saved` to `NSManagedObjectID`, but `ImportJobState` still has `case needsReview(ImportDraftRecipe)` and the shown `ImportDraftRecipe` model does not declare `Equatable`.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:281`
  - `docs/prds/active/m10-recipe-import.md:286`
  - `docs/prds/active/m10-recipe-import.md:226`
- Fix options:
  - make `ImportDraftRecipe`/`ImportField<T>` Equatable (with constraints),
  - implement custom `==` for `ImportJobState`,
  - or drop Equatable if not required.

2. Import metadata persistence contract is still incomplete.
- PRD says v1 "stores imageURL" and models include `author`, `description`, `cuisine`, but `Recipe` has no fields for these and `RecipeFormData` also does not.
- Current mapping path (`ImportDraftRecipe -> RecipeFormData -> Recipe`) therefore drops metadata unless a sidecar persistence design is added.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:129`
  - `docs/prds/active/m10-recipe-import.md:147`
  - `docs/prds/active/m10-recipe-import.md:135`
  - `forager/forager.xcdatamodeld/forager 6.xcdatamodel/contents:168`
  - `Services/RecipeFormModels.swift:98`
- Fix: explicitly define v1 persistence behavior for each metadata field (persisted vs preview-only vs deferred).

3. Factory API naming in PRD does not match current code.
- PRD references `ManagedObjectFactory.createRecipe()`, but current factory API is `make(_:in:configure:)`.
- `RecipeService` currently has no factory dependency, so implementation path is still ambiguous.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:143`
  - `docs/prds/active/m10-recipe-import.md:726`
  - `Services/Persistence/ManagedObjectFactory.swift:180`
  - `Services/RecipeService.swift:20`
- Fix: update PRD to either:
  - call `factory.make(Recipe.self, in: ...)`, or
  - define a new helper API and the DI changes needed in `RecipeService`.

### Medium

4. Telemetry schema migration is not yet specified.
- PRD adds import telemetry methods to `ParsingTelemetryService`, but existing `ParsingTelemetryData` model currently stores only parsing + correction arrays.
- Import events imply schema/version updates and migration behavior for existing telemetry files.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:170`
  - `docs/prds/active/m10-recipe-import.md:825`
  - `Services/ParsingTelemetryService.swift:120`
  - `Services/ParsingTelemetryService.swift:125`
- Fix: add explicit schema change + migration plan for telemetry data.

5. Import parsing source attribution is likely to be wrong without a service change.
- PRD relies on `.import_` source availability, but current `parseAndConnectIngredients()` path logs with default `.recipeIngredient`.
- Without parameterization, imported ingredient parses will be misattributed in telemetry.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:99`
  - `Services/IngredientParsingService.swift:117`
  - `Services/IngredientParsingService.swift:149`
- Fix: add `source:` parameter through import save pipeline and pass `.import_`.

6. Share extension open-path is risky as written.
- PRD specifies opening the app via `UIApplication` responder chain from extension. This is fragile for extension-safe behavior/review.
- Ref: `docs/prds/active/m10-recipe-import.md:450`
- Fix: prefer `NSExtensionContext.open(_:completionHandler:)` contract and document failure path.

7. New app view files likely need manual pbxproj entries, but PRD only calls this out for tests.
- `Services/` is file-system synchronized, but `forager/` is a regular `PBXGroup`.
- Refs:
  - `forager.xcodeproj/project.pbxproj:280`
  - `forager.xcodeproj/project.pbxproj:334`
  - `docs/prds/active/m10-recipe-import.md:416`
  - `docs/prds/active/m10-recipe-import.md:467`
- Fix: add explicit note that new `forager/*.swift` files require project inclusion (or convert group strategy).

8. "Replace Existing" duplicate flow still lacks data-integrity semantics.
- PRD defines user choice but not replacement behavior for relationships (meal plans, grocery references, CloudKit object identity).
- Refs:
  - `docs/prds/active/m10-recipe-import.md:215`
  - `docs/prds/active/m10-recipe-import.md:432`
- Fix: define replacement semantics (in-place update vs delete+recreate) and relationship retention rules.

### Low

9. `robots.txt` stance remains contradictory.
- Risk table says "respect robots.txt"; Open Questions still asks if Forager should respect it.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:930`
  - `docs/prds/active/m10-recipe-import.md:941`
- Fix: keep as open question in both places or mark as decided in both.

10. One roadmap section still has stale M10 estimate.
- Ref: `docs/roadmap.md:226`
- Fix: update stale historical estimate block to avoid planning confusion.

### What Was Fixed Well Since Prior Pass

1. `saved(NSManagedObjectID)` replaced `saved(Recipe)` in state model.
2. Save validation gate is now explicit and aligned with current form rules.
3. Telemetry ownership split is clearer (`PTS` raw events, `ImportTelemetryService` aggregation, `ImportHistoryService` UX log).
4. Share extension handoff lifecycle is now documented (write/read/clear/idempotency).
5. URL microdata fallback behavior is now explicit for M10.1.

### Updated Bottom Line

The PRD is substantially stronger and very close to execution-ready. Remaining blockers are mainly contract-level: Equatable synthesis, metadata persistence semantics, factory API/DI accuracy, and a few operational clarifications (telemetry schema, import source attribution, extension-safe open path, duplicate replacement semantics).

---

## Deep Dive Audit Pass (Latest PRD Update)

Date: February 24, 2026  
Scope: Full re-audit of latest `m10-recipe-import.md` plus cross-checks against implementation docs and current code contracts.

### Findings (Ordered by Severity)

### High

1. `Recipe` field names are still wrong in persistence/replace semantics.
- PRD persists to `Recipe.prepTimeMinutes` and `Recipe.cookTimeMinutes`, but model fields are `prepTime` and `cookTime`.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:157`
  - `docs/prds/active/m10-recipe-import.md:158`
  - `docs/prds/active/m10-recipe-import.md:236`
  - `Recipe+CoreDataProperties.swift:21`
  - `Recipe+CoreDataProperties.swift:27`
- Fix: update PRD persistence mapping + replace semantics to `prepTime` / `cookTime` everywhere.

2. Tags persistence contract is incorrect.
- PRD says `tags` is preview-only because Recipe has no tags property, and defers adding tags to future schema.
- Current model already has `Recipe.tags`.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:166`
  - `docs/prds/active/m10-recipe-import.md:168`
  - `Recipe+CoreDataProperties.swift:30`
- Fix: mark tags as persisted in v1 (or explicitly justify not persisting despite existing field).

### Medium

3. Cross-doc household factory API references are still stale outside the PRD.
- `current-story` and `requirements` still reference nonexistent `ManagedObjectFactory.createRecipe()`.
- Actual API is `factory.make(_:in:configure:)`.
- Refs:
  - `docs/current-story.md:33`
  - `docs/requirements.md:669`
  - `Services/Persistence/ManagedObjectFactory.swift:180`
- Fix: update both docs to `factory.make(Recipe.self, in: scope) { ... }` and align wording with PRD Decision 2.

4. URL fallback policy is still inconsistent between docs.
- Acceptance criteria still says URL import falls through to heuristic after WKWebView.
- Latest PRD says M10.1 ends with graceful error after JSON-LD + WKWebView; microdata/heuristic URL fallback is deferred.
- Refs:
  - `docs/import-research/acceptance-criteria.md:74`
  - `docs/prds/active/m10-recipe-import.md:811`
- Fix: align acceptance criteria with PRD M10.1 scope boundary.

### Low

5. Mapping timing language is internally inconsistent.
- Decision text says `ImportDraftRecipe` maps into `RecipeFormData` at preview time, then says mapping is at save time.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:127`
  - `docs/prds/active/m10-recipe-import.md:136`
- Fix: pick one timing model and use it consistently (save-time mapping appears to be intended).

6. Share-extension fallback lifecycle names a host hook that is not defined in plan-level app changes.
- PRD fallback says consume pending URL on next launch via `sceneDidBecomeActive`, but modified files section only specifies `.onOpenURL` changes.
- Current app also has no scene-active handling yet.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:475`
  - `docs/prds/active/m10-recipe-import.md:487`
  - `forager/foragerApp.swift:106`
- Fix: explicitly add scene-phase recheck contract (e.g., `.onChange(of: scenePhase)` calling `checkForPendingImport()`).

7. One assumption appears stale relative to chosen minimal extension architecture.
- PRD still lists “Foundation Models in share extension” as an assumption to validate.
- Current architecture states extension only passes URL to host app.
- Refs:
  - `docs/prds/active/m10-recipe-import.md:455`
  - `docs/prds/active/m10-recipe-import.md:605`
- Fix: remove or re-scope that assumption to avoid implementation ambiguity.

### Positives in Latest Revision

1. Telemetry source-attribution gap is explicitly called out (`parseAndConnectIngredients` source parameter).
2. Duplicate replace behavior is now clearly in-place update (relationship-safe direction).
3. Share extension handoff is much clearer and now uses extension-safe `extensionContext.open`.
4. Telemetry schema migration note (v3 → v4 optional import events) is documented.
5. Xcode group realities (Services auto-sync vs forager manual PBXGroup) are explicitly captured.

### Updated Bottom Line

This PRD is close to execution-ready. The remaining blockers are mostly correctness and consistency edits: recipe field-name fixes, tags persistence correction, and cross-doc alignment (`current-story`, `requirements`, acceptance criteria). Once those are reconciled, the implementation plan is materially solid.
