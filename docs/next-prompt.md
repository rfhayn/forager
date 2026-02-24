# Next Implementation Prompt

**Last Updated**: February 24, 2026
**For Milestone**: M10.1 URL Import (24-32h)
**Status**: M8.4 ✅ **COMPLETE** | M8.4.1 ✅ **COMPLETE** | **M10 NEXT**
**Branch**: Create `feature/M10.1-url-import`

---

## **NEXT: M10.1 — URL Import (24-32h)**

**PRD**: `docs/prds/active/m10-recipe-import.md` (full implementation blueprint — §6 M10.1)
**Spike Research**: `docs/import-research/` (7 supporting documents)
**Wireframes**: `docs/import-research/import-wireframes.html` (open in browser)
**Acceptance Criteria**: `docs/import-research/acceptance-criteria.md`
**Core Data Impact**: NONE — no schema changes

### What's Already Done
- ✅ M8.4: ML-powered parsing — 3-tier hybrid parser, 282 tests, correction feedback loop
- ✅ M8.4.1: Normalization qualifier reclassification — identity qualifiers preserved
- ✅ M15: UX design system — Liquid Glass, ForagerTheme, all screens polished
- ✅ M7: CloudKit sync — Dual-store, household sharing, public link invitations
- ✅ M9.5-partial: Service layer DI, code quality improvements
- ✅ All 282 tests passing, 0 failures
- ✅ Spike validated: 28-site extraction test, JSON-LD + WKWebView + OCR
- ✅ Implementation blueprint reviewed (PRD §3-6 with full data models, file lists, sub-phases)

### M10.1 Sub-phase Breakdown (with dependencies)

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.1.1 | Import models + extraction infrastructure | 4-5h | — |
| M10.1.2 | JSON-LD extractor + schema mapper (port spike) | 5-6h | M10.1.1 |
| M10.1.3 | Import orchestrator + service | 4-5h | M10.1.2 |
| M10.1.4 | Import preview UI | 5-6h | M10.1.3 |
| M10.1.5 | WKWebView fallback | 3-4h | M10.1.2 |
| M10.1.6 | Duplicate detection | 2-3h | M10.1.3 |
| M10.1.7 | Share extension + App Group | 3-4h | M10.1.4 |
| M10.1.8 | Error handling + edge cases | 2-3h | M10.1.4, M10.1.6 |

### Key Architecture Decisions
- **ImportDraftRecipe (separate model)** — NOT extending RecipeFormData; import needs author, imageURL, cuisine + `ImportField<T>` generic confidence wrapper
- **Draft-first workflow** — `ImportDraftRecipe` in-memory, persist only on user confirm
- **Strategy pattern extractors** — `RecipeExtractor` protocol returning `nil` (mirrors `MLIngredientParser.init?()`)
- **Atomic save** — New `RecipeService.importRecipe(from:ingredientTexts:sourceURL:)` — single `context.save()`
- **Image handling v1** — `imageURL` (web URL) only via AsyncImage; no schema change
- **Existing service convergence** — All ingredients flow through `IngredientParsingService.parseAndConnectIngredients()`

### Data Models (defined in PRD §5)
- `ImportDraftRecipe` — extraction result with `ImportField<T>` confidence per field
- `ImportField<T>` — generic wrapper: value + `ImportConfidence` + `ImportFieldSource` + wasEdited
- `ImportJobState` — state machine enum (idle → received → fetching → extracting → needsReview → saving → saved | failed)
- `ImportError` — complete taxonomy: network, extraction, duplicate, save errors with `userMessage` and `isRetryable`
- `RecipeExtractor` protocol + `RecipeExtractionInput` enum

### New Files (M10.1 only — see PRD §6 for complete list)
**Services/Import/**: `RecipeExtractor.swift`, `ImportDraftRecipe.swift`, `RecipeJSONLDExtractor.swift`, `SchemaRecipeMapper.swift`, `ISO8601DurationParser.swift`, `HTMLEntityDecoder.swift`, `RecipeImportService.swift`, `WKWebViewExtractor.swift`, `DuplicateDetectionService.swift`
**Views**: `RecipeImportSheet.swift`, `RecipeImportPreviewView.swift`, `DuplicateResolutionSheet.swift`
**Extension**: `ForagerShareExtension/` (ShareViewController, Info.plist, entitlements)

### Modified Files (M10.1)
- `RecipeService.swift` (+40 lines: atomic import method)
- `RecipeFormModels.swift` (+25 lines: init from ImportDraftRecipe, sourceURL)
- `ParsingTelemetryService.swift` (+60 lines: import telemetry methods)
- `foragerApp.swift` (+20 lines: RecipeImportService, .onOpenURL)
- `RecipeListView.swift` (+15 lines: toolbar import button)
- `forager.entitlements` (+5 lines: App Group)

### Test Files (~68 tests, manual pbxproj entries required)
- `RecipeJSONLDExtractorTests.swift` (~20), `SchemaRecipeMapperTests.swift` (~15), `ISO8601DurationParserTests.swift` (~10), `RecipeImportServiceTests.swift` (~15), `DuplicateDetectionServiceTests.swift` (~8)

### Key Targets
- ≥ 80% extraction rate on Tier 1 sites (with WKWebView)
- ≥ 70% extraction rate on Tier 2 blogs
- < 3s end-to-end for URLSession path
- < 8s end-to-end for WKWebView fallback
- 100% graceful failure rate (every failure shows user-facing message)
- All 282 existing tests continue passing

### Assumptions to Validate During M10.1
1. WKWebView renders JS without being in view hierarchy (M10.1.5)
2. Share extension passes App Store review (M10.1.7)
3. WKWebView memory impact acceptable in main app (M10.1.5)

### Files to Reference
- `Tools/import-spike/` — Spike CLI source (JSON-LD + OCR, 1,945 lines, 6 files)
- `docs/import-research/test-site-matrix.md` — 28 URLs across 4 tiers
- `docs/import-research/extraction-report.json` — Machine-readable spike results
- `docs/import-research/architecture-review-codex.md` — 5 critical findings (all addressed in PRD)

---

## **AFTER M10: M7.7 → M6 → M9 → M11+**

### M7.7: App Store Submission (3-5h)
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

### M6: Testing Foundation (20-30h)
- 50%+ test coverage on critical services
- **PRD**: `docs/prds/active/milestone-6-testing-foundation-ai-augmentation.md`

### M9 Remaining (~120h)
- **PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md`

### M11: Analytics & Insights (8-12h)
- Usage analytics, insights dashboard, recommendations

---

**Dependencies**: All prerequisites ✅ | App fully functional ✅ | 282 tests passing ✅ | Spike validated ✅ | Implementation blueprint reviewed ✅
