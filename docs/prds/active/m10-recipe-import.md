# M10: Recipe Import

**Status**: PLANNED
**Priority**: Next major feature (post-M8.4)
**Estimated Effort**: 72-97 hours (4 phases + architecture hardening buffer)
**Prerequisites**: M8.4 (ML parsing), M15 (design system)
**Last Updated**: February 24, 2026
**Spike Validation**: JSON-LD extraction spike (28 sites, 4 tiers) + OCR image extraction spike — see `docs/import-research/`

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
| Recipe extractable (URLSession) | 13/28 (46%) | Server-rendered HTML only |
| Full extraction (all core fields) | 9/28 (32%) | Title + ingredients + instructions + times + servings |
| Partial extraction (1-2 fields missing) | 4/28 (14%) | Typically prepTime or cookTime omitted |
| Client-rendered JSON-LD | ~8/28 (29%) | WordPress WPRM/Tasty plugins inject via JS |
| Dead URLs / no structured data | ~7/28 (25%) | 404s, social media, markdown, no schema.org |
| Median extraction time | 150ms | Fetch + parse combined |
| P95 extraction time | 1.7s | Slowest successful extractions |

**Key finding — why 46% ≠ 90%**: The research doc's claim that "~90%+ of major recipe sites have JSON-LD" is accurate — sites DO embed JSON-LD for Google Rich Results. However, ~30% render it via client-side JavaScript (WordPress recipe plugins inject `<script type="application/ld+json">` after page load). `URLSession` only gets server-rendered HTML.

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
| __NEXT_DATA__ SSR payloads | ~7% (2/28) | Recursive key search in Next.js JSON |
| Inline script JSON-LD (not ld+json type) | ~4% (1/28) | Regex scan for Recipe JSON in script blocks |

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

### 2.4 Per-Field Extraction Rates (13 Successful Sites)

| Field | Extraction Rate | Notes |
|-------|----------------|-------|
| Title | 100% (13/13) | Always present in Recipe JSON-LD |
| Ingredients | 100% (13/13) | recipeIngredient is the core field |
| Instructions | 100% (13/13) | Occasionally missing on partial extractions |
| Prep time | 69% (9/13) | ISO 8601 parsing; some sites omit |
| Cook time | 62% (8/13) | More commonly omitted than prepTime |
| Servings | 85% (11/13) | Various formats handled by yield parser |
| Image URL | 92% (12/13) | Nearly always present |
| Author | 85% (11/13) | Present in most JSON-LD |

---

## 3. Architecture

### 3.1 Core Design Principles

1. **Draft-first workflow** — Never persist `Recipe` entities during extraction or preview. Populate `RecipeFormData` for user review. Single final transaction writes recipe + ingredients + links on confirm. (Addresses Codex Finding #1: preview flow conflicts with persistence)

2. **Strategy pattern extractors** — `RecipeExtractor` protocol with `JSONLDExtractor`, `WKWebViewExtractor`, `HeuristicExtractor`, `AIExtractor` implementations. Mirrors `HybridIngredientParser`'s proven architecture. (Addresses Codex recommendation for extractor interface)

3. **Existing service convergence** — All imported ingredient strings flow through `IngredientParsingService.parseAndConnectIngredients()` → template matching → structured quantities. No new parsing infrastructure needed.

4. **Confidence-forward UX** — Every extracted field carries a confidence indicator. Users see what was auto-populated vs. what needs review. Addresses the #1 competitive complaint (inconsistent extraction quality).

5. **Zero silent failures** — Every extraction failure produces a user-visible message explaining what happened and what the user can do.

### 3.2 Import Orchestrator

```
ImportOrchestrator
├── Input Adapters
│   ├── URLImportAdapter        (Phase 1)
│   ├── TextPasteAdapter        (Phase 2)
│   └── PhotoImportAdapter      (Phase 3)
├── Extractor Chain (Strategy Pattern)
│   ├── JSONLDExtractor         (URLSession, server-rendered HTML)
│   ├── WKWebViewExtractor      (JS-rendered fallback)
│   ├── NextDataExtractor       (__NEXT_DATA__ SSR payloads)
│   ├── HeuristicTextExtractor  (line scoring, section detection)
│   └── FoundationModelsExtractor (@Generable, iOS 26+)
├── Draft Assembly
│   └── RecipeFormData population with field-level confidence
└── Commit Path
    └── RecipeService.createRecipe() + parseAndConnectIngredients()
```

### 3.3 Import Job State Machine

```
received → fetching → extracting → needs_review → saving → saved
                  ↓           ↓              ↓
               failed      failed          failed
```

Each state carries:
- Timestamp
- Failure reason (if applicable)
- Retry count (max 1 automatic retry for network failures)
- Extraction method used (for telemetry)

### 3.4 Addressing Codex Review Findings

| # | Finding | Resolution |
|---|---------|------------|
| 1 | Preview flow creates persistent entities too early | **Draft-first workflow**: `RecipeFormData` staging, persist only on confirm |
| 2 | Share Extension + Foundation Models constraint overstated | **Treat as unverified runtime assumption**: keep minimal extension as product-safe default, add Phase 2 spike to validate on target hardware |
| 3 | `RecipeFormData` reuse over-assumed | **Extend, not replace**: Add `init(from extractedRecipe:)` convenience + field-level confidence properties. Full `ImportDraftRecipe` model deferred unless RecipeFormData proves insufficient during Phase 1 |
| 4 | No structured multi-component recipe support | **v1 flattens groups**: Prepend section headers as comment lines ("--- For the sauce ---"). Preview communicates this. Structured sections scoped as future milestone |
| 5 | Legal section too absolute | **Add legal review gates**: Source attribution policy, paywall handling policy, caching/retention policy as explicit pre-launch checkpoints |

### 3.5 Duplicate Detection Strategy

1. **Exact URL match** — `sourceURL` comparison (fastest, catches re-imports)
2. **Fuzzy title match** — Levenshtein distance < 3 on normalized titles
3. **User resolution** — "Similar recipe found — import as new or merge?"

### 3.6 Image Storage

Recipe images stored in app's documents directory with Core Data path reference. Core Data binary storage adds complexity with CloudKit sync. URL-only breaks when sites change. File storage with CloudKit Assets is the best balance.

---

## 4. Phase Breakdown

### Phase 1: URL Import (M10.1) — 24-32h

**Why first**: Highest value, lowest complexity. Covers the most common use case. Leverages existing services heavily.

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| JSON-LD extractor | 4-5h | `RecipeJSONLDExtractor` — pure Foundation (spike code as reference) |
| WKWebView fallback | 4-5h | JS-rendered page extraction for WordPress blogs |
| Schema.org → Forager mapper | 3-4h | `SchemaRecipeMapper` with ISO 8601 + yield parsing |
| Import draft model + preview UI | 5-6h | `RecipeFormData` import initializer, `RecipeImportPreviewView` with confidence indicators |
| Share extension + App Group | 4-5h | Safari Share Sheet → shared container → main app handoff |
| Duplicate detection | 2-3h | `sourceURL` match + fuzzy title match before import |
| Error handling & edge cases | 2-3h | Fallback flows, partial extraction UI, domain policy messaging |

**Acceptance criteria**: See `docs/import-research/acceptance-criteria.md` §Phase 1

**Key targets**:
- ≥ 80% extraction rate on Tier 1 sites (with WKWebView)
- ≥ 70% extraction rate on Tier 2 blogs
- < 3s end-to-end for URLSession path
- < 8s end-to-end for WKWebView fallback
- 100% graceful failure rate (every failure shows user-facing message)

### Phase 2: Text Paste Import (M10.2) — 14-19h

**Why second**: Builds on Phase 1's preview UI. Adds Foundation Models integration that Phase 3 also needs.

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| Foundation Models extension spike | 1-2h | Validate runtime feasibility in share extension |
| Text input UI | 2-3h | Paste/type multiline text view |
| Foundation Models `@Generable` | 4-5h | `ImportedRecipe` struct with guided extraction |
| Heuristic fallback | 3-4h | Line scoring for non-AI devices (spike code as reference) |
| Section detection UI | 2-3h | Highlight detected sections, allow correction |
| Testing & refinement | 2-3h | Edge cases, Unicode, multi-language |

**Key targets**:
- ≥ 85% ingredient detection accuracy (test corpus of 50 recipes)
- ≥ 90% quality with Foundation Models (iPhone 15 Pro+)
- ≥ 70% quality on heuristic fallback
- < 5s Foundation Models latency, < 1s heuristic

### Phase 3: Photo/Image Import (M10.3) — 23-30h

**Why third**: Most complex, benefits from Foundation Models work in Phase 2.

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| Document scanner integration | 3-4h | `VNDocumentCameraViewController` wrapper |
| OCR pipeline | 4-5h | `VNRecognizeTextRequest` with text block positioning |
| Section-aware classification | 4-5h | Heuristic line classification with context boosting (spike code as reference) |
| Semi-automated section assignment | 5-6h | Mela-style UI — text overlaid on image, user assigns/confirms sections |
| AI-assisted extraction | 4-5h | OCR text → Foundation Models → structured recipe |
| Photo library picker | 2-3h | Select existing photos for OCR |
| Testing & refinement | 2-3h | Various cookbook formats, handwriting |

**Key targets**:
- ≥ 95% OCR character accuracy (clean printed text)
- ≥ 80% OCR accuracy (neat handwriting)
- ≥ 75% end-to-end field extraction accuracy (OCR → structure)
- < 8s scan → preview latency

### Phase 4: Polish & Integration (M10.4) — 11-16h

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| Import history/queue | 3-4h | Track imported recipes, retry failed imports |
| Household import sharing | 2-3h | Share import queue with household members via CloudKit |
| Import telemetry | 2-3h | Success rate, latency, cancel rate, correction rate per source |
| Performance optimization | 1-2h | Caching, background processing |
| Legal review gates | 1-2h | Source attribution, paywall policy, compliance notes |
| Regression testing | 2-3h | Verify all 267 existing tests pass, CLAUDE.md performance targets met |

### Effort Summary

| Phase | Hours | Cumulative |
|-------|-------|------------|
| M10.1: URL Import | 24-32h | 24-32h |
| M10.2: Text Paste | 14-19h | 38-51h |
| M10.3: Photo/Image | 23-30h | 61-81h |
| M10.4: Polish | 11-16h | 72-97h |

> **Note on estimates**: Original research doc estimated 62-84h. Revised upward (+15-20%) per Codex review recommendation to account for: draft model plumbing, WKWebView fallback (not in original estimate), App Group setup, dedup logic, telemetry, and production hardening (error/retry edge cases, site-specific extraction fixes).

---

## 5. Wireframes

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

All wireframes use ForagerTheme design tokens, 393×852px phone frames with Dynamic Island, and support light/dark toggle.

---

## 6. Observability & Telemetry

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

### Telemetry Integration

Extend existing `ParsingTelemetryService` with import events:
- `importAttempted(source:, url:, method:)`
- `importSucceeded(source:, fieldsExtracted:, fieldsMissing:, latencyMs:)`
- `importFailed(source:, reason:, fallbackUsed:)`
- `importCancelled(source:, afterPreview:, fieldsCorrected:)`

---

## 7. Domain Policy Table

| Domain/Source | Policy | User Message |
|---------------|--------|-------------|
| Paywalled sites (NYT Cooking, etc.) | Attempt extraction; show partial if available | "This recipe may be behind a paywall. Some fields may be incomplete." |
| Pinterest pins | Detect and skip (no recipe data) | "Pinterest pins don't contain recipe data. Try opening the original recipe link." |
| Social media (TikTok, Instagram) | Out of scope for v1 | "Social media video import is not yet supported." |
| GitHub/Markdown | Out of scope for v1 (no structured data) | "No recipe found on this page." |
| Sites with only microdata (no JSON-LD) | Fallback to heuristic in Phase 2 | "Attempting alternative extraction..." |
| Malformed JSON-LD | Log issue, try next strategy silently | No user message unless all strategies fail |

---

## 8. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| WKWebView extraction rate lower than estimated 75-80% | Medium | High | Add heuristic HTML scraping as additional fallback; Foundation Models text extraction in Phase 2 covers remaining cases |
| Share extension memory limits prevent rich preview | Medium | Medium | Minimal extension architecture (extract URL only, process in main app) already planned as default |
| Foundation Models unavailable on ~40% of devices | Known | Medium | Heuristic fallback for all AI-dependent features; spike proved heuristics achieve ≥70% quality |
| Recipe sites change HTML structure frequently | Medium | Low | Strategy pattern allows adding/updating extractors without architectural changes |
| CloudKit sync issues with imported recipe images | Medium | Medium | File-based storage with CloudKit Assets; images stored in documents directory with Core Data path reference |
| Multi-component recipes lose structure on import | Known | Low | v1 explicitly flattens groups with section labels; communicated in preview UX |
| Legal risk from automated recipe extraction | Low | High | Pre-launch legal review gates; source attribution; respect robots.txt; user-initiated single fetch only |

---

## 9. Open Questions

| # | Question | Owner | Decision Needed By |
|---|----------|-------|--------------------|
| 1 | Should import preview allow inline editing or require opening full edit view? | Product | Before M10.1 UI implementation |
| 2 | What is the maximum number of free imports before requiring a premium tier (if any)? | Product | Before M10.1 launch |
| 3 | Should Forager respect `robots.txt` for user-initiated single recipe fetches? | Legal | Before M10.1 launch |
| 4 | Is WKWebView rendering acceptable battery/data impact for the ~30% JS-rendered sites? | Engineering | M10.1 WKWebView sub-phase |
| 5 | Should imported recipes be visually distinguished from manually created ones? | Design | Before M10.1 preview UI |
| 6 | When should structured recipe sections (M10+) be scoped as its own milestone? | Product | After M10.1 ships |

---

## 10. Test Plan

### Unit Tests

| Area | Count | Coverage |
|------|-------|----------|
| JSON-LD extraction (various patterns) | 15-20 | @graph, array @type, inline scripts, __NEXT_DATA__ |
| ISO 8601 duration parsing | 8-10 | PT30M, PT1H30M, P0DT2H15M, bare numbers |
| Recipe yield parsing | 8-10 | "4 servings", "Makes 12", "6-8", "4 personnes" |
| Schema.org field mapping | 10-15 | All field types, missing fields, HTML entity decoding |
| HTML entity decoding | 5-8 | Named entities, numeric entities, nested entities |
| Heuristic line classification | 10-15 | Ingredients, instructions, metadata, section headers |
| OCR text classification | 8-10 | Section-aware context boosting |
| Duplicate detection | 5-8 | URL match, fuzzy title, no false positives |

### Integration Tests

| Scenario | Verification |
|----------|-------------|
| URL → extract → preview → save | Recipe appears in list with all fields |
| URL → extract → preview → cancel | No data persisted |
| URL → extract fails → error shown | User sees actionable message |
| URL → partial extract → edit → save | Missing fields editable, save completes |
| Share extension → main app handoff | URL arrives in main app within 2s |
| Photo → OCR → classify → preview → save | Ingredients connected to templates |
| Duplicate URL → detection → user choice | Import/merge/cancel all work correctly |

### Site Regression Matrix

Maintain the 28-site test matrix (`docs/import-research/test-site-matrix.md`) as a regression suite. Run before each Phase 1 release to verify extraction rates haven't regressed.

---

## 11. Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|
| M8.4: ML Parsing | READY | Phase 1 can proceed without ML; imported ingredients would use regex + NLP fallback |
| M15: Design System | COMPLETE | ForagerTheme tokens available for all import UI |
| iOS 26 SDK | Available | Foundation Models `@Generable` required for Phase 2-3 AI features |
| Apple Intelligence (device) | ~60% of users | Heuristic fallback ensures universal availability |

---

## 12. References

| Document | Path | Purpose |
|----------|------|---------|
| Research doc | `docs/import-research/recipe-import-research.md` | Full research with competitive analysis, technical decisions |
| Architecture review | `docs/import-research/architecture-review-codex.md` | 5 critical findings, all addressed in this PRD |
| Spike preparation | `docs/import-research/prd-preparation-spike.md` | Work package definitions |
| Test site matrix | `docs/import-research/test-site-matrix.md` | 28 URLs across 4 tiers with extraction results |
| Extraction report | `docs/import-research/extraction-report.json` | Machine-readable spike results |
| Acceptance criteria | `docs/import-research/acceptance-criteria.md` | Measurable thresholds per phase |
| Wireframes | `docs/import-research/import-wireframes.html` | 7 phone-frame screens (open in browser) |
| Spike CLI source | `Tools/import-spike/` | Swift CLI: JSON-LD extractor + OCR pipeline |
