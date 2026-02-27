# M10: Recipe Import — Implementation Blueprint

**Status**: READY
**Priority**: Next major feature (post-M8.4)
**Estimated Effort**: 70-95 hours (4 phases)
**Prerequisites**: M8.4 ✅ (ML parsing), M15 ✅ (design system)
**Last Updated**: February 24, 2026
**Spike Validation**: JSON-LD extraction spike (28 sites, 4 tiers) + OCR image extraction spike — see `docs/import-research/`
**Implementation Plan**: Reviewed and approved — this PRD serves as the implementation blueprint for all 4 phases

---

## 1. Problem Statement

Forager has no recipe import capability. Every recipe must be manually typed — title, ingredients (one by one), instructions, servings, prep/cook times. Users who discover recipes on the web, in cookbooks, or on social media must transcribe them by hand.

This is the #1 competitive gap. Every major recipe app (Mela, Paprika, Pestle, AnyList, Crouton) offers some form of import. Recipe import is table stakes for user acquisition and a prerequisite for household recipe sharing workflows.

### User Pain Point

A typical web recipe import takes 5-10 minutes of manual typing. A URL import takes < 4 taps and < 3 seconds. For cookbook recipes, manual typing takes 10-15 minutes vs. < 30 seconds with OCR + review.

---

## 2. Spike Findings (Data-Backed)

A structured spike validated assumptions before this PRD was written. All targets below derive from measured data, not estimates.

### 2.1 URL Import Spike (28 Sites)

| Metric | Result | Notes |
|--------|--------|-------|
| Sites tested | 28 | 4 tiers: major (9), blogs (9), challenging (6), international (4) |
| JSON-LD present (any form) | 19/28 (68%) | Standard ld+json + embedded + __NEXT_DATA__ |
| Recipe extractable (URLSession) | 12/28 (43%) | Server-rendered HTML only |
| Full extraction (title + ingredients + instructions) | 12/28 (43%) | All 12 successful extractions have the 3 core fields |
| Partial extraction (1-2 core fields missing) | 0/28 (0%) | Strict classification: full requires title + ingredients + instructions |
| No extraction possible | 16/28 (57%) | 9 no JSON-LD + 7 JSON-LD without Recipe @type |
| — of which: client-rendered (WKWebView recoverable) | ~8/28 (29%) | WordPress WPRM/Tasty plugins inject Recipe via JS |
| — of which: truly unrecoverable | ~3/28 (11%) | Pinterest (aggregator), GitHub (markdown), plain blog without recipe plugin |
| Median extraction time | 343ms | Fetch + parse combined |
| P95 extraction time | 1.7s | Slowest successful extractions |

**Key finding — why 43% ≠ 90%**: The research doc's claim that "~90%+ of major recipe sites have JSON-LD" is accurate — sites DO embed JSON-LD for Google Rich Results. However, ~30% render it via client-side JavaScript (WordPress recipe plugins inject `<script type="application/ld+json">` after page load). `URLSession` only gets server-rendered HTML.

**Implication**: Phase 1 requires a `WKWebView` fallback path. Estimated extraction rate with WKWebView: 75-80%.

### 2.2 Edge Cases Discovered

| Edge Case | Frequency | Handling Required |
|-----------|-----------|-------------------|
| `@graph` wrapper nesting | 18% (5/28) | Recursive search through @graph arrays |
| Array `@type` (e.g., `["Recipe", "CreativeWork"]`) | 11% (3/28) | Check array contains "Recipe" |
| HowToStep structured instructions | 39% (11/28) | Map to numbered step text |
| HowToSection nested instructions | 4% (1/28) | Flatten with section headers |
| HTML entities in JSON-LD | 25% (7/28) | Full entity decoding before parse |
| Unusual recipeYield formats | 14% (4/28) | Parse "6-8 servings", "Makes 12", etc. |
| __NEXT_DATA__ SSR payloads | 7% (2/28) | Recursive key search in Next.js JSON; tightened to require recipeIngredient |
| Inline script JSON-LD (not ld+json type) | 7% (2/28) | Regex scan for Recipe JSON in script blocks |

### 2.3 Photo/OCR Spike

| Metric | Result | Notes |
|--------|--------|-------|
| OCR confidence (clean printed text) | 100% | VNRecognizeTextRequest `.accurate` mode |
| Lines recognized | 22/22 | All text from test recipe image extracted |
| Section classification accuracy | ~90%+ | With section-aware context boosting |
| Title detection | Correct | First Title Case line near top |
| Ingredient detection | 8/8 correct | Number + unit heuristics + section context |
| Instruction detection | 6/8 initially, 8/8 with context | Section headers set default type for subsequent lines |
| Processing time | < 500ms | OCR + classify + assemble |

**Key finding**: Line-by-line heuristics alone achieve ~80% classification accuracy. Adding section-aware context (tracking which section header preceded each line) raises accuracy to ~90%+. Foundation Models would handle the remaining ambiguous cases.

### 2.4 Per-Field Extraction Rates (12 Successful Sites)

| Field | Extraction Rate | Notes |
|-------|----------------|-------|
| Title | 100% (12/12) | Always present in Recipe JSON-LD |
| Ingredients | 100% (12/12) | recipeIngredient is the core field |
| Instructions | 100% (12/12) | Always present when Recipe @type is found |
| Prep time | 83% (10/12) | ISO 8601 parsing; missing on paywall sites (NYT, Cook's Illustrated) |
| Cook time | 75% (9/12) | Missing on Serious Eats + paywall sites |
| Servings | 100% (12/12) | Various formats handled by yield parser |
| Image URL | 100% (12/12) | Always present |
| Author | 83% (10/12) | Missing on Budget Bytes, RecipeTin Eats |

---

## 3. Existing Infrastructure (Zero-Work Starting Points)

**Core Data impact: NONE.** No schema changes. No model version bump. No migration. No CloudKit Production schema update.

| Asset | Location | Impact |
|-------|----------|--------|
| `Recipe.sourceURL: String?` | `Recipe+CoreDataProperties.swift` | Already exists — no schema change |
| `RecipeService.createRecipe(sourceURL:)` | `Services/RecipeService.swift` | Already accepts sourceURL |
| `IngredientParsingService.parseAndConnectIngredients()` | `Services/IngredientParsingService.swift` | Import convergence point |
| `ParsingTelemetryService` with `.import_` | `Services/ParsingTelemetryService.swift` | Source enum ready |
| `ForagerTheme` status tokens | `forager/ForagerTheme.swift` | statusSuccessFG/Warning/Danger |
| `RecipeFormData` + `IngredientInput` | `Services/RecipeFormModels.swift` | Form model with validation |
| `HybridIngredientParser` strategy pattern | `Services/Parsing/HybridIngredientParser.swift` | Architecture model to mirror |
| Services/ auto-detected by Xcode | `PBXFileSystemSynchronizedRootGroup` | Just create files on disk |
| forager/ manual PBXGroup | Regular `PBXGroup` in pbxproj | Must manually add view files (PBXFileReference + PBXBuildFile + group children) |
| foragerTests/ manual PBXGroup | Build phase: `9B731C392E535C3300CE26F0` | Must manually add test files |

---

## 4. Architecture

### 4.1 Core Design Principles

1. **Draft-first workflow** — Never persist `Recipe` entities during extraction or preview. Use `ImportDraftRecipe` (pure in-memory struct) for all extraction and editing. Persist only on user "Save" tap via a new atomic `RecipeService.importRecipe()` method. **Persistence contract invariant**: No `Recipe` entity exists in the view context before the user taps "Save". Integration test required: URL → preview → cancel → assert zero `Recipe` rows.

2. **Strategy pattern extractors** — `RecipeExtractor` protocol with multiple implementations. Mirrors `HybridIngredientParser`'s proven architecture. Extractors return `nil` when they can't extract (same pattern as `MLIngredientParser.init?()` graceful nil). Router picks best result or falls through. Never fails silently.

3. **Existing service convergence** — All imported ingredient strings flow through `IngredientParsingService.parseAndConnectIngredients()` → template matching → structured quantities. No new parsing infrastructure needed. **Source attribution**: `parseAndConnectIngredients()` currently hardcodes `.recipeIngredient` as the telemetry source. Add a `source: ParsingSource = .recipeIngredient` parameter so the import path can pass `.import_` for correct telemetry attribution.

4. **Confidence-forward UX** — Every extracted field carries a confidence indicator via `ImportField<T>`. Users see what was auto-populated vs. what needs review.

5. **Zero silent failures** — Every extraction failure produces a user-visible message explaining what happened and what the user can do. See §8 Domain Policy Table.

### 4.2 Architecture Decisions

#### Decision 1: ImportDraftRecipe vs RecipeFormData (Codex Finding #3 — REVISED)

**Decision**: Separate `ImportDraftRecipe` struct that maps INTO `RecipeFormData` at save time.

**Rationale**:
- `RecipeFormData` lacks fields import needs (author, imageURL, description, cuisine)
- Field-level confidence tracking would bloat RecipeFormData for non-import flows
- Clean separation of concerns; import-specific provenance stays in import layer

**Trade-off**: Adds a new model type. Alternative was extending RecipeFormData with optional confidence properties. Separate model chosen because import has additional fields and confidence tracking that don't belong in the manual creation flow.

**Mapping**: `ImportDraftRecipe.toRecipeFormData()` → `RecipeFormData` at save time.

**Save validation gate**: Import uses the same `RecipeFormData.validate()` as manual creation. Full rules: title ≥ 3 characters (note: short titles like "Roux" or "Dal" pass; "Pie" passes), servings 1-99, prep/cook times 0-1440 min, at least 1 non-empty ingredient (max 50), instructions non-empty (max 5000 chars). The preview UI shows all extracted fields including missing ones, and the Save button remains disabled until validation passes. "Partial extraction" means the *extractor* returned incomplete data that the user must fill in — it does NOT mean partial data gets saved. `RecipeFormData.validate()` is not bypassed.

#### Decision 2: Atomic Save via RecipeService

**Problem**: Current `RecipeService.createRecipe()` calls `context.save()` immediately (line 44), while `parseAndConnectIngredients()` creates Ingredient entities without saving. These are two separate commits, not one atomic transaction.

**Solution**: New `RecipeService.importRecipe(from:ingredientTexts:sourceURL:)` method that: (a) creates the Recipe entity via `factory.make(Recipe.self, in: scope) { ... }` for scope-safe household assignment, (b) calls `parseAndConnectIngredients()`, (c) saves once via a single `context.save()`. Keeps existing `createRecipe()` API unchanged for manual recipe creation.

**Atomicity assumption to verify**: `parseAndConnectIngredients()` calls `templateService.findOrCreateTemplate()` and `templateService.incrementUsage()`. These must create/modify entities in the context WITHOUT calling `context.save()` internally — otherwise the single-save atomicity breaks. Verify during M10.1.3 implementation; if template service saves internally, either: (a) add a `skipSave` parameter, or (b) wrap the entire import in a child context.

**DI change required**: `RecipeService` currently has no `ManagedObjectFactory` dependency. Current init: `init(context:, parsingService:)`. The import method requires adding `ManagedObjectFactory` + `PersistenceController` + `ScopeProvider?` to the init signature (or accepting a pre-resolved `DataScope` parameter). This is a breaking init change — all call sites that create `RecipeService` must be updated (at minimum: `foragerApp.swift` and test files). Follow existing DI pattern from services that already use the factory.

#### Decision 3: Import Metadata Persistence (v1 Limitation)

`ImportDraftRecipe` carries metadata fields that enrich the preview experience but have no corresponding properties on the `Recipe` Core Data entity. v1 persistence behavior for each field:

| Field | v1 Behavior | Rationale |
|-------|-------------|-----------|
| `title` | **Persisted** → `Recipe.title` | Core field |
| `ingredients` | **Persisted** → via `parseAndConnectIngredients()` | Core field |
| `instructions` | **Persisted** → `Recipe.instructions` | Core field |
| `prepTimeMinutes` | **Persisted** → `Recipe.prepTime` (Int16) | Existing property; draft uses `Int?`, narrowed to `Int16` at save |
| `cookTimeMinutes` | **Persisted** → `Recipe.cookTime` (Int16) | Existing property; draft uses `Int?`, narrowed to `Int16` at save |
| `servings` | **Persisted** → `Recipe.servings` | Existing property |
| `sourceURL` | **Persisted** → `Recipe.sourceURL` | Existing property |
| `imageURL` | **Preview-only** — shown via AsyncImage during review, not persisted | Recipe entity has no image property; avoids schema change |
| `author` | **Preview-only** — shown for context during review, not persisted | Recipe entity has no author property |
| `description` | **Preview-only** — shown for context during review, not persisted | Recipe entity has no description property |
| `cuisine` | **Preview-only** — not persisted | Recipe entity has no cuisine property |
| `category` | **Preview-only** — not persisted | Recipe entity has no category property |
| `tags` | **Persisted** → `Recipe.tags` | Existing property (`String?`); extracted tags joined as comma-separated string |

**Future milestone**: Add `imageURL`, `author`, `cuisine`, `category` properties to `Recipe` entity (Core Data schema v7 + CloudKit migration). This is explicitly deferred to avoid schema changes in M10.

#### Decision 4: Flat Ingredient Groups (Codex Finding #4)

Multi-component recipes ("For the sauce:", "For the filling:") are flattened with label lines. Structured `RecipeSection` entity is future milestone. Preview communicates this clearly.

#### Decision 5: Foundation Models Fallback Strategy

- iPhone 15 Pro+, iPad M1+: Foundation Models available (~60% of iOS 26 users)
- Older devices: heuristic fallback (spike validated at ≥70% quality)
- User NEVER told "AI unavailable" — they just see heuristic results with lower confidence dots

#### Decision 6: Import History in UserDefaults, Not Core Data

Import history is diagnostic/ephemeral data, not user content requiring CloudKit sync. UserDefaults JSON array with 100-entry retention.

#### Decision 7: Telemetry Ownership

Three distinct responsibilities, cleanly separated:
- **`ParsingTelemetryService`** (M10.1) — Owns raw import event logging. Extended with `importAttempted/Succeeded/Failed/Cancelled` methods. Stores to Documents directory JSON file (same storage strategy PTS already uses — NOT UserDefaults).
- **`ImportTelemetryService`** (M10.4) — Read-only aggregation layer. Queries PTS event data to compute KPIs (success rate, median latency, correction rate, failure reasons by domain). Does NOT store its own data.
- **`ImportHistoryService`** (M10.4) — User-facing import log. Stores to UserDefaults (small, ephemeral, 100-entry cap). Separate from telemetry.

### 4.3 Strategy Pattern Extractors

```
RecipeExtractor protocol
    ├── RecipeJSONLDExtractor       (M10.1: ld+json, inline scripts, __NEXT_DATA__)
    ├── WKWebViewRecipeExtractor    (M10.1: JS-rendered fallback)
    ├── FoundationModelsExtractor   (M10.2: @Generable structured extraction)
    ├── HeuristicTextExtractor      (M10.2: line scoring fallback)
    └── ImageRecipeExtractor        (M10.3: OCR → classify → assemble)
```

### 4.4 Import Job State Machine

```
idle → received(URL) → fetching → extracting(method) → needsReview(draft) → saving → saved(NSManagedObjectID)
                          ↓              ↓                    ↓
                       failed          failed              failed
```

### 4.5 Import Orchestration Flow

```
URL/Text/Photo → extract → ImportDraftRecipe (in-memory)
    → preview UI → user edits → on Save: single context.save()
    → on Cancel: discard everything, zero persisted entities
```

### 4.6 Addressing Codex Review Findings

| # | Finding | Resolution |
|---|---------|------------|
| 1 | Preview flow creates persistent entities too early | **Draft-first workflow**: `ImportDraftRecipe` in-memory staging, persist only on confirm |
| 2 | Share Extension + Foundation Models constraint overstated | **Treat as unverified runtime assumption**: keep minimal extension as product-safe default, add M10.2 spike to validate on target hardware |
| 3 | `RecipeFormData` reuse over-assumed | **Separate ImportDraftRecipe**: RecipeFormData lacks import-specific fields (author, imageURL, cuisine) and adding confidence tracking would bloat it. ImportDraftRecipe maps into RecipeFormData at save time |
| 4 | No structured multi-component recipe support | **v1 flattens groups**: Prepend section headers as label lines. Preview communicates this. Structured `RecipeSection` scoped as future milestone |
| 5 | Legal section too absolute | **Add legal review gates**: Source attribution policy, paywall handling policy, caching/retention policy as explicit pre-launch checkpoints |

### 4.7 Duplicate Detection Strategy

1. **Exact URL match** — `sourceURL` comparison via Core Data fetch predicate (fastest, catches re-imports)
2. **Fuzzy title match** — Levenshtein distance < 3 on normalized titles
3. **User resolution** — "Import as New" / "Replace Existing" / "Cancel"

Returns `DuplicateResult?`: `.exactURL(Recipe)` or `.fuzzyTitle(Recipe, distance: Int)`

**"Replace Existing" semantics**: In-place update of the existing Recipe entity (NOT delete+recreate). This preserves all relationship references — PlannedMeal references remain valid, CloudKit object identity is preserved. GroceryListItems are unaffected because they use flat string snapshots (ADR 012), not Ingredient relationships. Fields overwritten: `title`, `instructions`, `prepTime` (Int16), `cookTime` (Int16), `servings` (Int16), `sourceURL`, `tags`. Ingredients are replaced: delete existing Ingredient entities, create new ones via `parseAndConnectIngredients()`. Single `context.save()` for atomicity.

---

## 5. Data Models

### 5.1 ImportDraftRecipe

```swift
struct ImportDraftRecipe: Equatable {
    var title: ImportField<String>
    var ingredients: ImportField<[String]>     // Raw text strings
    var instructions: ImportField<String>
    var prepTimeMinutes: ImportField<Int?>
    var cookTimeMinutes: ImportField<Int?>
    var servings: ImportField<Int>
    var imageURL: ImportField<String?>
    var author: ImportField<String?>
    var sourceURL: String?
    var description: String?
    var cuisine: String?
    var category: String?
    var tags: String?

    var extractionMethod: String               // "ld+json", "wkwebview", etc.
    var extractionTimeMs: Int

    var successLevel: ExtractionSuccessLevel   // .full / .partial / .failure
    var fieldsMissing: [String]
    func toRecipeFormData() -> RecipeFormData

    /// Factory for extractors to start from — pre-populated with safe defaults
    static func empty() -> ImportDraftRecipe  // All fields .missing confidence, sensible defaults (servings: 4, times: nil)
}
```

### 5.2 ImportField Generic Wrapper

```swift
struct ImportField<T: Equatable>: Equatable {
    var value: T
    var confidence: ImportConfidence
    var source: ImportFieldSource
    var wasEdited: Bool = false
}

enum ImportConfidence: Comparable {
    case high      // Green dot — structured data source
    case medium    // Amber dot — less reliable source
    case low       // Red dot — inferred or defaulted
    case missing   // User must provide
}

enum ImportFieldSource: String, Equatable {
    case jsonLD, wkWebView, nextData, heuristic, foundationModels, ocr, manual
}

enum ExtractionSuccessLevel: Equatable {
    case full      // All core fields present
    case partial   // Some fields missing
    case failure   // No usable data
}
```

### 5.3 ImportJobState

```swift
enum ImportJobState: Equatable {
    case idle
    case received(URL)
    case fetching
    case extracting(method: String)
    case needsReview(ImportDraftRecipe)
    case saving
    case saved(NSManagedObjectID)   // Not Recipe — NSManagedObject equality is reference-based
    case failed(ImportError)

    var isLoading: Bool   // fetching, extracting, saving
    var isReviewing: Bool // needsReview — used to hide parent sheet's Cancel toolbar
}
```

### 5.4 ImportError (Complete Taxonomy)

```swift
enum ImportError: LocalizedError, Equatable {
    // Network (M10.1)
    case networkError(String)           // "Unable to reach site."
    case timeout                        // "Request timed out."
    // Extraction (M10.1-M10.3)
    case noRecipeFound                  // "No recipe found on this page."
    case paywallDetected                // "Recipe may be behind a paywall."
    case malformedData(String)          // "Recipe data found but couldn't be read."
    case unsupportedSource(String)      // "Social media video import not yet supported."
    // Duplicate (M10.1)
    case duplicateFound(existingTitle: String)
    // Save (all phases)
    case saveError(String)
    // OCR (M10.3)
    case ocrFailed(String)
    case cameraPermissionDenied
    case noTextDetected
    // AI (M10.2-M10.3) — silent fallback, not shown to user
    case aiExtractionFailed
    case aiUnavailable

    var userMessage: String { ... }     // Maps to domain policy table (§8)
    var isRetryable: Bool { ... }
    var errorTitle: String { ... }      // Wireframe screen 5: "Recipe Behind a Paywall", "No Recipe Found", etc.
    var errorIcon: String { ... }       // Wireframe screen 5: SF Symbol name ("lock.fill", "magnifyingglass", etc.)
}
```

### 5.5 RecipeExtractor Protocol

```swift
protocol RecipeExtractor {
    var extractorName: String { get }
    func extract(from input: RecipeExtractionInput) async throws -> ImportDraftRecipe?
}

enum RecipeExtractionInput {
    case html(String, url: URL)
    case text(String)
    case image(Data)
}
```

**Return contract**:
- Return `nil` = "this input isn't my format, try the next extractor" (equivalent to `MLIngredientParser.init?()` returning nil). Example: JSON-LD extractor returns `nil` for HTML with no `ld+json` script tags.
- Throw `ImportError` = "I recognized this input as mine but extraction failed" (paywall detected, malformed JSON-LD, etc.). These errors propagate to the orchestrator for user-facing messages.
- The orchestrator tries extractors in priority order, collects thrown errors, and shows "No recipe found" only if ALL extractors return `nil` (none claimed the input). If any extractor throws, that error's `userMessage` is shown instead.

### 5.6 ExtractionContext

```swift
struct ExtractionContext {
    var usedGraphWrapper: Bool = false
    var usedArrayType: Bool = false
    var hadHTMLEntities: Bool = false
    var usedNextData: Bool = false
    var usedInlineScript: Bool = false
}
```

Tracks which edge case paths were exercised during extraction. Logged to telemetry for debugging and extraction rate analysis.

---

## 6. Phase Breakdown

### M10.1: URL Import — 24-32h

**Objective**: Paste a recipe URL → extract structured data via JSON-LD → preview with confidence indicators → save to Core Data. Includes WKWebView fallback, share extension, and duplicate detection.

**Why first**: Highest value, lowest complexity. Covers the most common use case. Leverages existing services heavily.

#### Sub-phases

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.1.1 | Import models + extraction infrastructure | 4-5h | — |
| M10.1.2 | JSON-LD extractor + schema mapper (port spike) | 5-6h | M10.1.1 |
| M10.1.3 | Import orchestrator + service | 4-5h | M10.1.2 |
| M10.1.4 | Import preview UI | 5-6h | M10.1.3 |
| M10.1.5 | WKWebView fallback | 3-4h | M10.1.2 |
| M10.1.6 | Duplicate detection | 2-3h | M10.1.3 |
| M10.1.7 | Share extension + App Group | 3-4h | M10.1.4 | ✅ IMPLEMENTED |
| M10.1.8 | Error handling + edge cases | 2-3h | M10.1.4, M10.1.6 | ✅ IMPLEMENTED |

#### New Files — Services/Import/ (auto-detected by Xcode)

**`RecipeExtractor.swift`** (~60 lines)
- `RecipeExtractor` protocol + `RecipeExtractionInput` enum
- `ExtractionContext` struct (tracks edge case flags: usedGraphWrapper, usedArrayType, hadHTMLEntities, etc.)

**`ImportDraftRecipe.swift`** (~200 lines)
- `ImportDraftRecipe`, `ImportField<T>`, `ImportConfidence`, `ImportFieldSource` enums
- `ImportJobState` enum, `ImportError` enum
- `ExtractionSuccessLevel` enum (.full/.partial/.failure)
- `toRecipeFormData()` mapping method

**`RecipeJSONLDExtractor.swift`** (~350 lines)
- Port from `Tools/import-spike/Sources/ImportSpike/RecipeJSONLDExtractor.swift` (385 lines)
- 3-tier strategy: standard ld+json → inline script blocks → __NEXT_DATA__
- Key methods: `extract(from html:)`, `extractBalancedJSON()`, `findObjectWithRecipeKeys()`, `isRecipeType()`
- Edge cases handled: @graph wrappers (18%), array @type (11%), __NEXT_DATA__ with recipeIngredient guard (7%)

**`SchemaRecipeMapper.swift`** (~320 lines)
- Port from spike (346 lines). Maps schema.org `[String: Any]` → `ImportDraftRecipe`
- Handles 5 instruction formats (string, string array, HowToStep, HowToSection, mixed)
- Handles 4 ingredient formats (string array, single string, PropertyValue, with header filtering)
- Handles 4 image formats (URL string, ImageObject, arrays of both)
- Handles 4 author formats (string, Person/Organization, array of authors)

**`ISO8601DurationParser.swift`** (~110 lines)
- Direct port from spike. Parses PT30M, PT1H30M, P0DT2H15M, bare numbers → minutes
- Includes `RecipeYieldParser`: parses "4 servings", "Makes 12", "6-8" → Int

**`HTMLEntityDecoder.swift`** (~60 lines)
- Extracted from spike extractor. 16 named entities + numeric (&#123;) + hex (&#xBD;)
- Applied before JSON parsing to prevent parse failures

**`RecipeImportService.swift`** (~400 lines) — ✅ IMPLEMENTED (M10.1.3+)
- `@MainActor class RecipeImportService: ObservableObject`
- Published: `state: ImportJobState`
- Dependencies: `IngredientParsingService`, `NSManagedObjectContext`
- Key methods:
  - `importFromURL(_ url: URL) async` — pre-flight unsupported source check → fetch HTML → try extractors in priority order → populate draft
  - `saveImport(from draft: ImportDraftRecipe) -> NSManagedObjectID?` — atomic save via child context
  - `replaceExistingRecipe(objectID:with:) -> NSManagedObjectID?` — in-place update of existing Recipe (deletes old ingredients, updates fields, creates new ingredients). Uses child context for atomicity. Preserves PlannedMeal references and CloudKit identity.
  - `checkDuplicate(for draft:) -> DuplicateResult?` — duplicate detection before save
  - `checkUnsupportedSource(_ url: URL) -> ImportError?` — fail-fast detection of Pinterest, TikTok, Instagram, Facebook Reel URLs before network fetch (M10.1.8)
  - `cancelImport()` — reset to idle
  - `checkForPendingImport()` — check App Group UserDefaults for share extension URL
- Telemetry: logs importAttempted/Succeeded/Failed/Cancelled to ParsingTelemetryService

**`WKWebViewExtractor.swift`** (~180 lines)
- `@MainActor class` with headless WKWebView (zero frame)
- Loads URL, waits for DOMContentLoaded + 2s settle via WKNavigationDelegate
- Extracts rendered HTML via `evaluateJavaScript("document.documentElement.outerHTML")`
- Pipes HTML through `RecipeJSONLDExtractor`
- Configurable timeout (default 8s), `CheckedContinuation` for async/await bridge
- **Assumption to validate**: headless WKWebView renders JS without being in a view hierarchy (§16.1)

**`DuplicateDetectionService.swift`** (~100 lines)
- Two strategies: (1) exact `sourceURL` match via Core Data fetch predicate, (2) fuzzy title match using Levenshtein distance < 3 on normalized titles
- Returns `DuplicateResult?`: `.exactURL(Recipe)` or `.fuzzyTitle(Recipe, distance: Int)`

#### New Files — Views (forager/)

> **Design alignment**: All import views follow M15 design system patterns (ForagerTheme tokens, SF Pro Rounded chrome, section headers, card patterns) and match wireframes in `docs/import-research/import-wireframes.html`. See wireframe screens 1-5.

**`RecipeImportSheet.swift`** (~300 lines) — ✅ IMPLEMENTED
- Entry point sheet from RecipeListView toolbar
- Nav bar: Cancel (leading, hidden when in `.needsReview` state), "Import Recipe" title (center, inline)
- URL input field, state-driven content (loading, preview, error)
- Tab/segment for "URL" mode (expanded in M10.2/M10.3 for "Text"/"Photo")
- Wires up `replaceExistingWithDraft()` → `importService.replaceExistingRecipe()` for duplicate resolution
- Uses `@Environment(\.openURL)` for paywall "Open in Safari" action
- Error states (wireframe screen 5) — ✅ IMPLEMENTED (M10.1.8): Four type-specific presentations via `errorView(_:)` switch dispatch + shared `errorLayout()` generic template:
  - **Paywall** (`paywallErrorView`): `lock.fill` icon in `surfaceWarning` circle, "Recipe Behind a Paywall", "Open in Safari" button (opens `urlText` in Safari)
  - **No Recipe Found** (`noRecipeErrorView`): `magnifyingglass` icon in `surfaceAccent` circle, "No Recipe Found", "Try Different URL" (M10.2: add "Try pasting text" link)
  - **Network Error** (`networkErrorView`): `wifi.slash` icon in `surfaceDanger` circle, "Unable to Reach This Site", "Try Again" button
  - **Generic** (`genericErrorView`): Error-specific icon in `surfaceWarning` circle, `errorTitle`/`userMessage`, conditional "Retry" (if retryable) + "Try Different URL"

**`RecipeImportPreviewView.swift`** (~350 lines) — ✅ IMPLEMENTED

Layout follows wireframe screen 1 (happy path) and screen 3 (partial extraction), using M15 design patterns:

**Nav bar**: Cancel (`.cancellationAction`), "Import Recipe" (center, from parent sheet), "Save Recipe" (`.confirmationAction`). Both managed via `.toolbar` on the preview view. Disabled when `successLevel == .failure`.

**Content area (top to bottom)**:
1. **Source attribution**: "From [host]" link in `text.link` color, `font-sm` (matches wireframe `source-link` class)
2. **Recipe title**: Large bold (`font-xl`, rounded), inline editable `TextField`. Confidence dot beside title.
3. **Compact metadata row**: Single row with dot separators — "N servings · N min prep · N min cook" (matches wireframe `meta-row` class). Follows M15's compact timing row pattern from RecipeDetailView. Each value shows confidence dot. Missing values show "—".
4. **Section divider**: Hairline (`border.subtle`)
5. **Ingredients section**: Section header "Ingredients" (12pt bold uppercase, rounded) with edit pencil icon (`pencil` SF Symbol) on trailing edge. Pencil taps into edit mode for the section.
   - **Per-ingredient rows** (wireframe `ingredient-row` class): Bordered card rows (`surface.primary` background, `border.subtle` border, `radius.sm`). Each row: `[confidence dot 8px] [qty in text.secondary, .monospacedDigit()] [name in text.primary]`. Follows M15's inline ingredient pattern (§6.2).
   - **Low-confidence ingredients**: Row uses `surface.warning` background, `warning.fg` border. Name shows "(verify)" or "(type?)" annotation in `warning.fg`.
   - **Missing ingredients**: Dashed border row, `surface.warning` background, placeholder text in `text.disabled` italic.
6. **Section divider**
7. **Instructions section**: Section header "Instructions" with edit pencil icon (trailing).
   - **Instruction steps**: Numbered step circles (24px, `accent.tint` background, `accent.primary` text, 12pt bold) + step text in `font-base`. Matches M15's instruction step pattern.
   - **"Show all N steps" collapse**: First 3 steps visible by default. "Show all N steps" link in `text.link` color below. Tap expands to show all. Follows wireframe `show-more` class.
8. **Image preview** (if available): AsyncImage from `imageURL`, max height 200pt, rounded corners.
9. **Metadata section** (if author/cuisine/category available): Compact rows with SF Symbol icons.

**Partial extraction state** (wireframe screen 3):
- **Warning banner**: `surface.warning` background with `warning.fg` border, triangle icon + "Some fields couldn't be extracted. Please review highlighted items."
- **Meta field cards**: Side-by-side cards for Prep time, Cook time, Servings. Empty fields: dashed border, `surface.warning` background, placeholder text ("Add prep time"). Uncertain values shown with `?` suffix in `warning.fg` (e.g., "4?"). Each card has confidence dot on trailing edge.

**`DuplicateResolutionSheet.swift`** (~100 lines) — ✅ IMPLEMENTED

Follows wireframe screen 4 — half-sheet modal:
- **Duplicate icon**: 48px `doc.on.doc.fill` in `statusWarningFG`
- **Title**: "Similar Recipe Found" (`cardTitle` font)
- **Message**: "You already have '[title]' in your collection." (body, `textSecondary`)
- **Three action buttons** (stacked vertically, all `.bordered` style with `accentPrimary` tint):
  1. "Import as New Recipe" → `onImportAsNew` callback
  2. "Replace Existing" → `onReplaceExisting` callback — in-place update of existing Recipe entity preserving PlannedMeal references and CloudKit identity (see §4.7)
  3. "Cancel" → `onCancel` callback (`.borderless`, `textSecondary`)
- Uses `.presentationDetents([.medium])` as half-sheet with drag indicator

#### New Files — Share Extension (new Xcode target)

**`ForagerShareExtension/ShareViewController.swift`** (~100 lines)
- Minimal UIViewController. Extracts URL from extensionContext.inputItems
- Writes URL to `UserDefaults(suiteName: "group.com.richhayn.forager")["pendingImportURL"]` (App Group shared container)
- Opens main app via `extensionContext.open(URL(string: "forager://import")!)` — uses registered URL scheme, NOT UIApplication responder chain (extension-safe, App Store review-safe)
- Calls `extensionContext.completeRequest(returningItems: nil)` after open

**`ForagerShareExtension/Info.plist`** — NSExtensionPointIdentifier, activation rules (URLs only)

**`ForagerShareExtension/ForagerShareExtension.entitlements`** — App Group

#### Share Extension Handoff Lifecycle

Deterministic contract for URL handoff between share extension and main app:

1. **Write**: Extension extracts URL from `extensionContext.inputItems` and writes to `UserDefaults(suiteName: "group.com.richhayn.forager")["pendingImportURL"]`
2. **Open**: Extension calls `extensionContext.open(URL(string: "forager://import")!)` to launch/foreground main app via registered URL scheme, then calls `completeRequest(returningItems: nil)`
3. **Read**: Main app's `.onOpenURL { url in ... }` modifier in `foragerApp.swift` fires on the `forager://import` URL. Handler reads `pendingImportURL` from App Group UserDefaults.
4. **Clear**: Main app removes the `pendingImportURL` key **immediately after reading**, before processing begins. This prevents duplicate consumption.
5. **Idempotency**: If `pendingImportURL` is nil (already cleared), do nothing. If the same URL is shared twice, each write is a new import attempt — duplicate detection (§4.7) handles re-imports of the same recipe.
6. **Race condition**: If user shares a second URL before the first is consumed, the second write overwrites the first. This is acceptable for v1 — single-URL queue.
7. **Failure path**: If `extensionContext.open()` fails (rare), extension shows "Please open Forager manually" message. The pending URL remains in App Group UserDefaults and is consumed on next app launch via `checkForPendingImport()` in `sceneDidBecomeActive`.

**Xcode config**: Register `forager` URL scheme in Info.plist under `CFBundleURLTypes`.

#### Modified Files

| File | Change | Lines |
|------|--------|-------|
| `Services/RecipeService.swift` | Add `importRecipe(from:ingredientTexts:sourceURL:)` — atomic save; inject `ManagedObjectFactory` dependency | +50 |
| `Services/IngredientParsingService.swift` | Add `source: ParsingSource = .recipeIngredient` param to `parseAndConnectIngredients()` and pass through to `parseUnified()` (which already has the param) | +5 |
| `Services/RecipeFormModels.swift` | Add `init(from: ImportDraftRecipe)` convenience initializer | +15 |
| `Services/ParsingTelemetryService.swift` | Add import-specific telemetry methods; bump schema v3→v4 | +60 |
| `forager/foragerApp.swift` | Add RecipeImportService @StateObject + environmentObject, .onOpenURL handler, `.onChange(of: scenePhase)` calling `checkForPendingImport()` for share extension fallback path | +30 |
| `forager/RecipeListView.swift` | Add toolbar import button, .sheet for RecipeImportSheet | +15 |
| `forager/forager.entitlements` | Add App Group `group.com.richhayn.forager` | +5 |

#### Test Files (manual pbxproj entries required)

| File | Tests | Coverage |
|------|-------|----------|
| `RecipeJSONLDExtractorTests.swift` | ~20 | ld+json, @graph, array @type, inline scripts, __NEXT_DATA__, HTML entities, malformed |
| `SchemaRecipeMapperTests.swift` | ~15 | All field types, HowToStep/Section, durations, yields, author variants |
| `ISO8601DurationParserTests.swift` | ~10 | PT30M, PT1H30M, bare numbers, edge cases |
| `RecipeImportServiceTests.swift` | ~15 | State transitions, duplicate check, atomic save, cancel-no-persist invariant |
| `DuplicateDetectionServiceTests.swift` | ~8 | URL match, fuzzy title, no false positives |
| **Total M10.1** | **~68** | |

#### Acceptance Criteria

- ≥ 80% extraction on Tier 1 sites (with WKWebView), ≥ 70% on blogs
- All 12 spike-validated sites produce full ImportDraftRecipe
- URLSession path < 3s e2e, WKWebView < 8s
- Cancel-after-preview leaves zero Recipe entities
- Atomic save: Recipe + all Ingredients in single context.save()
- 100% graceful failure rate (every failure → user-facing message)
- Share extension: URL received in main app within 2s
- All 282 existing tests continue passing

---

### M10.2: Text Paste Import — 14-19h

**Objective**: Paste recipe text (from websites, messages, emails) → Foundation Models `@Generable` extraction on supported devices, heuristic line-scoring fallback for others → preview → save.

**Why second**: Builds on M10.1's preview UI. Adds Foundation Models integration that M10.3 also needs.

#### Sub-phases

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.2.1 | Foundation Models extension spike | 1-2h | M10.1 |
| M10.2.2 | Text input UI | 2-3h | M10.1 |
| M10.2.3 | Foundation Models @Generable extractor | 4-5h | M10.2.1 |
| M10.2.4 | Heuristic text fallback (port spike) | 3-4h | — (parallel with M10.2.3) |
| M10.2.5 | Section detection UI | 2-3h | M10.2.3 or M10.2.4 |
| M10.2.6 | Testing & refinement | 2-3h | M10.2.3, M10.2.4 |

#### New Files — Services/Import/

**`FoundationModelsExtractor.swift`** (~200 lines)
- `class FoundationModelsExtractor: RecipeExtractor`
- `@Generable` struct:
  ```swift
  @Generable
  struct ImportedRecipeGenerable {
      @Guide(description: "The recipe title or name")
      var title: String
      @Guide(description: "Array of ingredient lines, each with quantity, unit, and name")
      var ingredients: [String]
      @Guide(description: "Step-by-step cooking instructions as numbered steps")
      var instructions: String
      @Guide(description: "Prep time in minutes, nil if not mentioned")
      var prepTimeMinutes: Int?
      @Guide(description: "Cook time in minutes, nil if not mentioned")
      var cookTimeMinutes: Int?
      @Guide(description: "Number of servings")
      var servings: Int?
  }
  ```
- Runtime check: `LanguageModelSession.isSupported` → returns nil if unavailable
- Maps `ImportedRecipeGenerable` → `ImportDraftRecipe` with `.foundationModels` source
- **Trade-off**: `@Generable` constrains output to fixed struct shape. Alternative: prompt-based `LanguageModelSession.respond(to:)` with free-form text parsing. `@Generable` chosen for structured output with less post-processing. Less flexibility for follow-up questions, but simpler and more reliable for v1.

**`OCRLineClassifier.swift`** (~300 lines) — **Moved from M10.3 to M10.2** (shared dependency)
- Port from spike's `ImageRecipeExtractor.classifyLines()` + all scoring helpers
- `static func classifyLines(_ lines: [OCRLine]) -> [ClassifiedLine]`
- `OCRLine` = `{ text: String, confidence: Float, boundingBox: CGRect }` — for text-only input, use `CGRect.zero`
- `ClassifiedLine` = `{ text, type: LineType, confidence, score }`
- `LineType` = `.title`, `.ingredient`, `.instruction`, `.metadata`, `.sectionHeader`, `.unknown`
- Section-aware context boosting: tracks currentSection, weak lines adopt section type
- Scoring heuristics (from spike):
  - Title: first 3 lines, Title Case, 5-80 chars → score 0.4-0.7
  - Ingredient: starts with digit/fraction (+0.5), unit words (+0.35), short line (+0.1)
  - Instruction: numbered step (+0.5), imperative verb (+0.4, 44 verbs), long line (+0.2)
  - Metadata: serving patterns (+0.7), time patterns (+0.7), temperature (+0.3)
- **Shared by both M10.2 (text paste) and M10.3 (OCR)** — single source of truth for line classification

**`HeuristicTextExtractor.swift`** (~150 lines)
- `class HeuristicTextExtractor: RecipeExtractor`
- Thin adapter over `OCRLineClassifier` — wraps plain text lines as `OCRLine` with `CGRect.zero` bounding boxes
- Algorithm: split text into lines → `OCRLineClassifier.classifyLines()` → assemble ImportDraftRecipe
- Confidence: `.medium` for all heuristic-classified fields

#### New Files — Views

**`TextPasteImportView.swift`** (~200 lines)
- Large TextEditor, paste-from-clipboard button, "Extract Recipe" button
- Progress indicator during extraction
- Transitions to RecipeImportPreviewView on success

**`SectionHighlightView.swift`** (~180 lines)
- Shows pasted text with color-coded section highlights
- User can tap lines to reclassify (title/ingredient/instruction/ignore)

#### Modified Files

| File | Change | Lines |
|------|--------|-------|
| `RecipeImportSheet.swift` | Add "Text" tab/segment | +30 |
| `RecipeImportService.swift` | Add `importFromText(_ text:) async` orchestration | +50 |

#### Test Files

| File | Tests | Coverage |
|------|-------|----------|
| `HeuristicTextExtractorTests.swift` | ~15 | Ingredient/instruction detection, section headers, metadata, Unicode, edge cases |
| `FoundationModelsExtractorTests.swift` | ~5 | Availability check, fallback, mapping layer |
| `OCRLineClassifierTests.swift` | ~15 | All scoring paths, context boosting, title/ingredient/instruction classification |
| **Total M10.2** | **~35** | |

#### Acceptance Criteria

- Heuristic: ≥ 75% ingredient lines correctly identified (50-recipe test corpus)
- Foundation Models: ≥ 90% quality on supported devices (manual device testing)
- Heuristic latency < 1s, Foundation Models < 5s
- Graceful degradation: non-AI devices see heuristic results, not errors
- Section detection: ≥ 80% classification accuracy

> **Target reconciliation note**: The acceptance-criteria.md file states ≥85% ingredient detection. That target applies to the *combined* heuristic + Foundation Models pipeline. The heuristic-only target is ≥75%, based on spike data showing ~80% with context boosting. The PRD targets here are the source of truth.

#### Assumptions to Validate

1. `LanguageModelSession.isSupported` returns `false` on non-Pro devices — needs device testing
2. `@Generable` output consistency — may need post-processing normalization

---

### M10.3: Photo/Image Import — 23-30h

**Objective**: Photograph a cookbook page or select a photo → OCR text recognition → section-aware classification → optional AI refinement → preview → save. Wireframe screens 6-7.

**Why third**: Most complex, benefits from Foundation Models work in M10.2.

#### Sub-phases

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.3.1 | Document scanner integration | 3-4h | M10.2 |
| M10.3.2 | OCR pipeline | 4-5h | M10.3.1 |
| M10.3.3 | Section-aware classification integration (uses `OCRLineClassifier` from M10.2) | 2-3h | M10.3.2 |
| M10.3.4 | Semi-automated section assignment UI | 5-6h | M10.3.3 |
| M10.3.5 | AI-assisted extraction | 4-5h | M10.2.3, M10.3.2 |
| M10.3.6 | Photo library picker | 2-3h | M10.3.2 |
| M10.3.7 | Testing & refinement | 2-3h | M10.3.3, M10.3.5 |

#### New Files — Services/Import/

**`ImageOCRService.swift`** (~120 lines)
- `func performOCR(on image: CGImage) async -> [OCRLine]`
- Uses `VNRecognizeTextRequest` with `.accurate` recognition level, language correction enabled
- 4 languages: en-US, fr-FR, de-DE, es-ES
- Returns: `OCRLine` = `{ text: String, confidence: Float, boundingBox: CGRect }`
- **Adaptation from spike**: `UIImage` → `CGImage` (spike used AppKit's NSImage)

**`ImageRecipeExtractor.swift`** (~150 lines)
- `class ImageRecipeExtractor: RecipeExtractor`
- Pipeline: Image → `ImageOCRService` → `OCRLineClassifier` → (optionally) `FoundationModelsExtractor` → assemble `ImportDraftRecipe`
- Instruction assembly: strips existing numbering, re-numbers steps

#### New Files — Views

**`DocumentScannerView.swift`** (~80 lines)
- `UIViewControllerRepresentable` wrapping `VNDocumentCameraViewController`
- Callback: `onScan: ([UIImage]) -> Void`

**`PhotoImportView.swift`** (~200 lines)
- Camera button (launches DocumentScannerView), photo library button
- Scanned image preview, processing spinner
- Transitions to SectionAssignmentView

**`SectionAssignmentView.swift`** (~350 lines)
- **Mela-style overlay UI** (wireframe screen 6)
- OCR text overlaid on scanned image, color-coded by classification
- Section tags: TITLE (accent), META (info), INGREDIENTS (green), STEPS (amber)
- User taps line to reclassify
- "Review & Save" button → transitions to RecipeImportPreviewView
- Tip: "Tap any section to edit before saving"

**`PhotoPickerView.swift`** (~60 lines)
- `UIViewControllerRepresentable` wrapping `PHPickerViewController` with `.images` filter

#### Modified Files

| File | Change | Lines |
|------|--------|-------|
| `RecipeImportSheet.swift` | Add "Photo" tab/segment | +20 |
| `RecipeImportService.swift` | Add `importFromImage(_ image: UIImage) async` | +40 |
| `Info.plist` | `NSCameraUsageDescription` | +3 |

#### Privacy Permissions

- **Camera**: `NSCameraUsageDescription` = "Forager uses the camera to scan recipe pages from cookbooks"
- **Photo Library**: `PHPickerViewController` uses its own out-of-process picker — no `NSPhotoLibraryUsageDescription` needed
  - **Assumption to validate**: confirm PHPicker doesn't require the key (§16.3)

#### Test Files

| File | Tests | Coverage |
|------|-------|----------|
| `ImageRecipeExtractorTests.swift` | ~8 | Full pipeline with mock OCR, empty image, no text, mixed content |
| **Total M10.3** | **~8** | |

#### Implementation Notes (from testing)

**Bugs found and fixed during M10.3.5 testing:**

1. **Review binding bug (PhotoImportView)**: `PhotoImportPhase` had a custom `Equatable` that returned `true` for all `.reviewing` states — SwiftUI never re-rendered when lines were edited via SectionHighlightView binding. Fix: return `false` for `.reviewing` comparison.

2. **Save UX**: The "Recipe Saved!" success screen was unnecessary ceremony and obscured the CategoryAssignmentModal that should appear for uncategorized ingredients. Fix: removed success view, save now auto-dismisses (showing CategoryAssignmentModal first if needed). Toolbar button renamed "Save Recipe" → "Save" to match manual entry.

3. **Category assignment flow**: `CategoryAssignmentModal` was wired up but the success view took over before the user could see it. Fix: save → category assignment (if uncategorized) → dismiss. Or save → dismiss directly (if all categorized). State reset to `.idle` on dismiss to prevent stale state on next import.

4. **Cold launch blank grocery list**: `HouseholdService.init()` fired `loadCurrentHousehold()` before `PersistenceController` stores were loaded. The `.task` modifier in foragerApp now runs `loadCurrentHousehold()` immediately (stores guaranteed loaded by `isReady` gate), fixing the 4+ second blank screen.

#### M10.3.8: Import Preview Ingredient Matching (1-2h)

**Enhancement**: Parse and match imported ingredients against the user's existing template database during the preview step. Currently the preview shows raw ingredient text with no indication of categorization status. This addition provides:

1. **Parse each ingredient line** at preview time via `IngredientParsingService.parseIngredient()` — extract name/qty/unit
2. **Look up parsed name** against existing `IngredientTemplate` records (read-only, no template creation)
3. **Display match status** per ingredient row:
   - **✓ [Category]** — matched an existing template with a category assigned
   - **? Needs category** — matched an existing template but uncategorized
   - **○ New ingredient** — no template match, will be created on save
4. **Highlight the ingredient name** portion within the raw line (qty/unit in secondary style, name in primary)

**Implementation**: Modify `RecipeImportPreviewView.ingredientsSection` to run the parser on each line, search templates with `IngredientTemplateService.searchTemplates(query:)`, and display the `IngredientStatus` indicator + category label — mirroring `CreateRecipeView.ingredientRow()`.

**Key constraint**: Preview is read-only — templates are NOT created until Save. This is a display-only enhancement using existing `parseIngredient()` (fast, <0.05s per ingredient) and `searchTemplates()` (simple fetch).

#### Acceptance Criteria

- OCR accuracy (clean printed text): ≥ 95% character accuracy
- Section classification: ≥ 90% with context boosting (spike: 90%+)
- End-to-end scan → preview: < 8s
- Camera permission: graceful handling if denied (settings redirect)
- Handwriting: ≥ 80% OCR accuracy (neat handwriting)
- **Import preview shows ingredient match status** (✓/? /○) for every ingredient line
- **Existing categorized ingredients show their category** in preview

---

### M10.4: Polish & Integration — 11-16h

**Objective**: Production hardening: import history, household sharing, telemetry dashboard, performance optimization, legal compliance, and regression testing.

#### Sub-phases

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.4.1 | Import history & queue | 3-4h | M10.1-M10.3 |
| M10.4.2 | Household import sharing | 2-3h | M10.4.1 |
| M10.4.3 | Import telemetry dashboard | 2-3h | M10.4.1 |
| M10.4.4 | Performance optimization | 1-2h | M10.1-M10.3 |
| M10.4.5 | Legal review gates | 1-2h | — |
| M10.4.6 | Regression testing | 2-3h | All |

#### New Files

**`Services/Import/ImportHistoryService.swift`** (~150 lines)
- `@MainActor class ImportHistoryService: ObservableObject`
- Storage: `UserDefaults` JSON array (not Core Data — diagnostic/ephemeral, not user data)
- `ImportHistoryEntry`: id, timestamp, sourceURL, sourceType, status, recipeTitle, extractionMethod, latencyMs, fieldsCorrected
- Retention: last 100 imports, auto-pruned

**`Services/Import/ImportTelemetryService.swift`** (~180 lines)
- Read-only aggregation layer over `ParsingTelemetryService` import events
- Computes KPIs: success rate, partial rate, median latency, cancel-after-preview rate, correction rate per field, failure reasons by domain
- Does NOT store its own data — reads from PTS Documents directory JSON

**`forager/ImportHistoryView.swift`** (~200 lines)
- List of past imports with status icons, tap for details, swipe to retry/delete

**`forager/ImportTelemetryDebugView.swift`** (~120 lines)
- Debug-only view showing import KPIs, accessible from Settings > Debug

#### Modified Files

| File | Change | Lines |
|------|--------|-------|
| `SettingsView.swift` | "Import History" row, debug telemetry link | +15 |
| `RecipeImportService.swift` | Integration with ImportHistoryService, household scope | +30 |

#### Household Integration

Imported recipes are created via `factory.make(Recipe.self, in: scope) { ... }`, which automatically assigns the object to the correct persistent store based on `HouseholdScopeProvider` and `DataScope`. This handles `householdKey` assignment and store placement. CloudKit dual-store architecture handles sync automatically. **No special import sharing logic needed.**

**Important**: `RecipeService.importRecipe()` must use `ManagedObjectFactory` (not raw `Recipe(context:)`) to ensure scope-safe creation — see `Services/Persistence/ManagedObjectFactory.swift`.

#### Test Files

| File | Tests | Coverage |
|------|-------|----------|
| `ImportHistoryServiceTests.swift` | ~8 | Log/retrieve/retention/retry/JSON serialization |
| **Total M10.4** | **~8** | |

#### Acceptance Criteria

- Import history tracks 100% of imports
- All 282 existing tests pass (zero regressions)
- All ~119 new M10 tests pass
- Performance within CLAUDE.md targets
- 28-site regression matrix meets M10.1 extraction rate targets

---

### Effort Summary

| Phase | Hours | Cumulative | New Tests |
|-------|-------|------------|-----------|
| M10.1: URL Import | 24-32h | 24-32h | ~68 |
| M10.2: Text Paste | 14-19h | 38-51h | ~35 |
| M10.3: Photo/Image | 21-28h | 59-79h | ~8 |
| M10.4: Polish | 11-16h | 70-95h | ~8 |
| **Total** | **70-95h** | | **~119** |

> **Note on estimates**: Original research doc estimated 62-84h. Revised upward per Codex review recommendation to account for: draft model plumbing, WKWebView fallback (not in original estimate), App Group setup, dedup logic, telemetry, and production hardening. Slightly reduced from 72-97h after moving `OCRLineClassifier` from M10.3 to M10.2 (shared dependency, eliminates duplicate classification code).

---

## 7. Wireframes

Seven screens designed in `docs/import-research/import-wireframes.html` (open in browser):

| # | Screen | Phase | Description |
|---|--------|-------|-------------|
| 1 | Import Preview | M10.1 | Happy path — all fields extracted with confidence dots (green/amber/red) |
| 2 | Share Extension | M10.1 | Compact extraction view with "Open in Forager" handoff |
| 3 | Partial Extraction | M10.1 | Warning banner, amber indicators for missing fields, edit affordances |
| 4 | Duplicate Detection | M10.1 | Modal dialog — "Similar recipe found" with import/merge/cancel options |
| 5 | Error States | M10.1 | Three mini-frames: paywall detected, no recipe found, network error |
| 6 | Photo Import OCR | M10.3 | Image preview with OCR text overlay, classified sections with confidence tags |
| 7 | Camera Capture | M10.3 | Document scanner with auto edge detection, corner markers, shutter button |

All wireframes use ForagerTheme design tokens, 393x852px phone frames with Dynamic Island, and support light/dark toggle.

### M15 Design System Alignment

Import views follow M15 design patterns established across the app:

| M15 Pattern | Import Application |
|-------------|-------------------|
| Nav bar: back + centered title + trailing action | Cancel + "Import Recipe" + "Save Recipe" button |
| Inline ingredient layout: `• qty unit name` | Per-ingredient rows: `[dot] [qty] [name]` in bordered cards |
| Section headers: 12pt bold uppercase, rounded | "Ingredients", "Instructions" section headers |
| Compact timing row with dot separators | "N servings · N min prep · N min cook" |
| ForagerTheme semantic color tokens | All status colors (success/warning/danger), text hierarchy |
| Instruction steps: numbered prefix + step text | 24px accent circle + step text, with collapse |
| Edit affordances: pencil icon on section headers | Edit pencil on Ingredients/Instructions headers |
| Status surfaces: `surface.warning`, `surface.danger` | Warning banners, low-confidence ingredient rows |
| `ContentUnavailableView` for empty states | Used for error states (no recipe, network error) |
| `.presentationDetents([.medium])` for half-sheets | DuplicateResolutionSheet |

---

## 8. Domain Policy Table

| Domain/Source | Policy | User Message |
|---------------|--------|-------------|
| Paywalled sites (NYT Cooking, etc.) | Attempt extraction; show partial if available | "Recipe may be behind a paywall. Some fields may be incomplete." |
| Pinterest pins | Detect and skip (no recipe data) | "Pinterest pins don't contain recipe data. Try the original link." |
| Social media (TikTok, Instagram) | Out of scope for v1 | "Social media video import not yet supported." |
| GitHub/Markdown | Out of scope (no structured data) | "No recipe found on this page." |
| Sites with only microdata (no JSON-LD) | M10.1: JSON-LD + WKWebView both fail → graceful error. Future: microdata scraper could be added as another `RecipeExtractor` | "No recipe found on this page." |
| Malformed JSON-LD | Try next strategy silently | No message unless all fail |

---

## 9. Observability & Telemetry

### Import KPIs (Must-Have)

| Metric | Target | Phase |
|--------|--------|-------|
| Success rate per source type | Track from day 1 | M10.1 |
| Partial extraction rate | < 25% of successful imports | M10.1 |
| Median + P95 latency | < 3s / < 8s | M10.1 |
| Cancel-after-preview rate | < 25% | M10.1 |
| Correction rate per field | < 3 fields per import average | M10.1 |
| Failure reasons by domain | Categorized (no JSON-LD, paywall, timeout, malformed) | M10.1 |
| OCR accuracy per content type | Track from day 1 | M10.3 |

### Telemetry Event Structure

```swift
struct ImportTelemetryEvent {
    let sourceType: ImportSourceType      // .url, .text, .photo
    let sourceURL: String?
    let extractionMethod: String          // "ld+json", "wkwebview", "foundation_models", "heuristic", "ocr"
    let status: ImportStatus              // .success, .partial, .failed, .cancelled
    let fieldsExtracted: Int
    let fieldsMissing: [String]
    let fieldsCorrected: Int
    let latencyMs: Int
    let failureReason: String?
    let domain: String?
}
```

### Telemetry Integration

Extend existing `ParsingTelemetryService` with import events:
- `importAttempted(source:, url:, method:)`
- `importSucceeded(source:, fieldsExtracted:, fieldsMissing:, latencyMs:)`
- `importFailed(source:, reason:, fallbackUsed:)`
- `importCancelled(source:, afterPreview:, fieldsCorrected:)`

**Schema migration**: Bump `ParsingTelemetryData` schema version from v3 → v4. Add `importEvents: [ImportTelemetryEvent]?` as an optional property. Existing Documents directory JSON files will decode correctly — Codable treats missing keys as `nil` for optionals. No explicit migration logic needed.

---

## 10. File Organization Summary

```
Services/Import/                          Phase
    RecipeExtractor.swift                 M10.1
    ImportDraftRecipe.swift               M10.1
    RecipeJSONLDExtractor.swift           M10.1  (port from spike)
    SchemaRecipeMapper.swift              M10.1  (port from spike)
    ISO8601DurationParser.swift           M10.1  (port from spike)
    HTMLEntityDecoder.swift               M10.1
    RecipeImportService.swift             M10.1  (expanded M10.2-M10.4)
    WKWebViewExtractor.swift              M10.1
    DuplicateDetectionService.swift       M10.1
    FoundationModelsExtractor.swift       M10.2
    OCRLineClassifier.swift              M10.2  (port from spike; shared by M10.2 + M10.3)
    HeuristicTextExtractor.swift          M10.2  (thin adapter over OCRLineClassifier)
    ImageOCRService.swift                 M10.3
    ImageRecipeExtractor.swift            M10.3
    ImportHistoryService.swift            M10.4
    ImportTelemetryService.swift          M10.4

forager/ (views)
    RecipeImportSheet.swift               M10.1  (expanded M10.2-M10.3)
    RecipeImportPreviewView.swift         M10.1  (shared all phases)
    DuplicateResolutionSheet.swift        M10.1
    TextPasteImportView.swift             M10.2
    SectionHighlightView.swift            M10.2
    DocumentScannerView.swift             M10.3
    PhotoImportView.swift                 M10.3
    SectionAssignmentView.swift           M10.3
    PhotoPickerView.swift                 M10.3
    ImportHistoryView.swift               M10.4
    ImportTelemetryDebugView.swift        M10.4

ForagerShareExtension/                    M10.1
    ShareViewController.swift
    Info.plist
    ForagerShareExtension.entitlements

foragerTests/Services/Import/             (manual pbxproj)
    RecipeJSONLDExtractorTests.swift      M10.1  (~20 tests)
    SchemaRecipeMapperTests.swift         M10.1  (~15 tests)
    ISO8601DurationParserTests.swift      M10.1  (~10 tests)
    RecipeImportServiceTests.swift        M10.1  (~15 tests)
    DuplicateDetectionServiceTests.swift  M10.1  (~8 tests)
    HeuristicTextExtractorTests.swift     M10.2  (~15 tests)
    FoundationModelsExtractorTests.swift  M10.2  (~5 tests)
    OCRLineClassifierTests.swift          M10.2  (~15 tests, shared classifier)
    ImageRecipeExtractorTests.swift       M10.3  (~8 tests)
    ImportHistoryServiceTests.swift       M10.4  (~8 tests)
```

### Totals

| Metric | Count |
|--------|-------|
| New production files | ~16 |
| New view files | ~11 |
| New extension files | 3 |
| New test files | ~10 |
| Modified files | ~10 |
| Total new tests | ~119 |
| Core Data schema changes | 0 |
| Estimated new lines | ~4,500-5,000 |

---

## 11. Cross-Cutting Concerns

### Entitlements & Xcode Config

| Change | Phase | Detail |
|--------|-------|--------|
| App Group | M10.1 | `group.com.richhayn.forager` on main + extension targets |
| Share Extension target | M10.1 | New Xcode target (best created in Xcode IDE) |
| Camera permission | M10.3 | `NSCameraUsageDescription` in Info.plist |
| View pbxproj entries | All | `forager/` is a manual PBXGroup — ~11 new view files need PBXFileReference + PBXBuildFile + PBXGroup children entries |
| Test pbxproj entries | All | `foragerTests/` is a manual PBXGroup — ~10 test files x 3 entries = ~30 manual pbxproj modifications |

### Foundation Models Device Coverage

- iPhone 15 Pro+, iPad M1+: Foundation Models available (~60% of iOS 26 users)
- Older devices: heuristic fallback (spike validated at ≥70% quality)
- User NEVER told "AI unavailable" — they just see heuristic results with lower confidence dots

---

## 12. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| WKWebView extraction rate lower than estimated 75-80% | Medium | High | Add heuristic HTML scraping as additional fallback; Foundation Models text extraction in M10.2 covers remaining cases |
| Share extension memory limits prevent rich preview | Medium | Medium | Minimal extension architecture (extract URL only, process in main app) already planned as default |
| Foundation Models unavailable on ~40% of devices | Known | Medium | Heuristic fallback for all AI-dependent features; spike proved heuristics achieve ≥70% quality |
| Recipe sites change HTML structure frequently | Medium | Low | Strategy pattern allows adding/updating extractors without architectural changes |
| Web imageURL breaks when source site changes URLs | Medium | Low | v1 accepted trade-off; future milestone adds `imagePath: String?` for local persistence |
| Multi-component recipes lose structure on import | Known | Low | v1 explicitly flattens groups with section labels; communicated in preview UX |
| `__NEXT_DATA__` fallback may reject legitimate non-@type recipes | Low | Low | Tightened rules require `recipeIngredient` key; build validation corpus of 10+ `__NEXT_DATA__` sites during M10.1 |
| Legal risk from automated recipe extraction | Low | High | Pre-launch legal review gates; source attribution; user-initiated single fetch only (robots.txt stance TBD — see Open Questions §13) |
| WKWebView headless rendering may not work without view hierarchy | Low | Medium | Validate assumption during M10.1.5; fallback: add invisible WKWebView to window hierarchy |

---

## 13. Open Questions

| # | Question | Owner | Decision Needed By | Status |
|---|----------|-------|--------------------|--------|
| 1 | Should import preview allow inline editing or require opening full edit view? | Product | Before M10.1.4 | **Decided: Inline editing** |
| 2 | What is the maximum number of free imports before requiring a premium tier (if any)? | Product | Before M10.1 launch | Open |
| 3 | Should Forager respect `robots.txt` for user-initiated single recipe fetches? | Legal | Before M10.1 launch | Open |
| 4 | Is WKWebView rendering acceptable battery/data impact for the ~30% JS-rendered sites? | Engineering | M10.1.5 | Open |
| 5 | Should imported recipes be visually distinguished from manually created ones? | Design | Before M10.1.4 | Open |
| 6 | When should structured recipe sections (M10+) be scoped as its own milestone? | Product | After M10.1 ships | Open |

---

## 14. Test Plan

### Unit Tests by Phase

| Phase | File | Tests | Coverage |
|-------|------|-------|----------|
| M10.1 | `RecipeJSONLDExtractorTests.swift` | ~20 | ld+json, @graph, array @type, inline scripts, __NEXT_DATA__, HTML entities, malformed |
| M10.1 | `SchemaRecipeMapperTests.swift` | ~15 | All field types, HowToStep/Section, durations, yields, author variants |
| M10.1 | `ISO8601DurationParserTests.swift` | ~10 | PT30M, PT1H30M, bare numbers, edge cases |
| M10.1 | `RecipeImportServiceTests.swift` | ~15 | State transitions, duplicate check, atomic save, cancel-no-persist invariant |
| M10.1 | `DuplicateDetectionServiceTests.swift` | ~8 | URL match, fuzzy title, no false positives |
| M10.2 | `HeuristicTextExtractorTests.swift` | ~15 | Ingredient/instruction detection, section headers, metadata, Unicode |
| M10.2 | `FoundationModelsExtractorTests.swift` | ~5 | Availability check, fallback, mapping layer |
| M10.3 | `OCRLineClassifierTests.swift` | ~15 | All scoring paths, context boosting, classification |
| M10.3 | `ImageRecipeExtractorTests.swift` | ~8 | Full pipeline with mock OCR, empty image, no text |
| M10.4 | `ImportHistoryServiceTests.swift` | ~8 | Log/retrieve/retention/retry/JSON serialization |
| **Total** | | **~119** | |

### Integration Tests

| Scenario | Verification |
|----------|-------------|
| URL → extract → preview → save | Recipe appears in list with all fields |
| URL → extract → preview → cancel | No data persisted (zero Recipe entities) |
| URL → extract fails → error shown | User sees actionable message |
| URL → partial extract → edit → save | Missing fields editable, save completes |
| Share extension → main app handoff | URL arrives in main app within 2s |
| Text paste → heuristic → preview → save | Ingredients connected to templates |
| Photo → OCR → classify → preview → save | Ingredients connected to templates |
| Duplicate URL → detection → user choice | Import/merge/cancel all work correctly |

### Site Regression Matrix

Maintain the 28-site test matrix (`docs/import-research/test-site-matrix.md`) as a regression suite. Run before each phase release to verify extraction rates haven't regressed.

---

## 15. Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|
| M8.4: ML Parsing | ✅ COMPLETE | Imported ingredients use full 3-tier hybrid parser |
| M15: Design System | ✅ COMPLETE | ForagerTheme tokens available for all import UI |
| iOS 26 SDK | Available | Foundation Models `@Generable` required for M10.2-M10.3 AI features |
| Apple Intelligence (device) | ~60% of users | Heuristic fallback ensures universal availability |
| All 282 tests passing | ✅ Verified | Baseline for regression testing |

---

## 16. Assumptions Requiring Validation

| # | Assumption | Validation Point | Risk if Wrong |
|---|-----------|------------------|---------------|
| 1 | WKWebView renders JS without being in view hierarchy | M10.1.5 implementation | Must add invisible WKWebView to window |
| 2 | `LanguageModelSession.isSupported` returns false on non-Pro devices | M10.2.1 spike | Need alternative availability check |
| 3 | PHPickerViewController doesn't require NSPhotoLibraryUsageDescription | M10.3.6 implementation | Add plist key |
| 4 | Share extension passes Apple App Store review | M10.1.7 submission | Adjust activation rules |
| 5 | WKWebView memory impact acceptable in main app | M10.1.5 profiling | Add memory limits or defer to background |

---

## 17. Divergences from Original PRD

These decisions supersede the original PRD (pre-implementation-plan version):

| # | Original PRD | Implementation Plan | Rationale |
|---|-------------|--------------------|-----------|
| 1 | §3.4 Finding #3: "Extend RecipeFormData" with confidence properties | Separate `ImportDraftRecipe` model | RecipeFormData lacks import-specific fields; adding confidence tracking would bloat non-import flows |
| 2 | §3.6: "File storage with CloudKit Assets" for images | v1 uses `imageURL` (web URL) only via AsyncImage | Avoids Core Data schema change; defers local persistence to future milestone |
| 3 | No import history architecture specified | UserDefaults JSON array with 100-entry retention | Diagnostic/ephemeral data, not user content requiring CloudKit sync |
| 4 | `RecipeExtractor` with `canHandle()` method | Extractors return `nil` when unable to extract | Simpler pattern matching `MLIngredientParser.init?()` precedent |
| 5 | §3.2: Separate `NextDataExtractor` | Folded into `RecipeJSONLDExtractor` as 3rd extraction tier | Single extractor handles all JSON-LD variants; simpler routing |

---

## 18. Verification

### Build

```bash
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Tests
- All 282 existing tests continue passing
- All ~119 new tests pass with HTML/text fixture strings (no network)
- Integration: import → preview → cancel → assert zero Recipe entities
- Integration: import → preview → save → assert Recipe with ingredients

### Manual Testing (per phase)
- **M10.1**: Allrecipes URL → full extraction; WordPress blog → WKWebView fallback; non-recipe URL → error; duplicate URL → dialog; Safari Share Sheet → handoff
- **M10.2**: Paste recipe text → structured extraction; no-AI device → heuristic results
- **M10.3**: Photograph cookbook page → OCR → classified sections → preview; photo library → same flow
- **M10.4**: Import history shows all attempts; household member sees imported recipe via CloudKit

---

## 19. References

| Document | Path | Purpose |
|----------|------|---------|
| Research doc | `docs/import-research/recipe-import-research.md` | Full research with competitive analysis, technical decisions |
| Architecture review | `docs/import-research/architecture-review-codex.md` | 5 critical findings, all addressed in this PRD |
| Spike preparation | `docs/import-research/prd-preparation-spike.md` | Work package definitions |
| Test site matrix | `docs/import-research/test-site-matrix.md` | 28 URLs across 4 tiers with extraction results |
| Extraction report | `docs/import-research/extraction-report.json` | Machine-readable spike results |
| Acceptance criteria | `docs/import-research/acceptance-criteria.md` | Measurable thresholds per phase |
| Wireframes | `docs/import-research/import-wireframes.html` | 7 phone-frame screens (open in browser) |
| Spike CLI source | `Tools/import-spike/` | Swift CLI: JSON-LD extractor + OCR pipeline (1,945 lines, 6 files) |
