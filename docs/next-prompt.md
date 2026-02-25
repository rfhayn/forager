# Next Implementation Prompt

**Last Updated**: February 25, 2026
**For Milestone**: M10.2 Text Paste Import (14-19h)
**Status**: M10.1 ✅ **COMPLETE** (testing before merge) | **M10.2 NEXT**
**Branch**: Create `feature/M10.2-text-paste-import` (after M10.1 merges)

---

## **NEXT: M10.2 — Text Paste Import (14-19h)**

**PRD**: `docs/prds/active/m10-recipe-import.md` (full implementation blueprint — §6 M10.2)
**Spike Research**: `docs/import-research/` (7 supporting documents)
**Wireframes**: `docs/import-research/import-wireframes.html` (open in browser)
**Core Data Impact**: NONE — no schema changes

### What's Already Done (M10.1 Complete)
- ✅ M10.1: URL Import — JSON-LD + WKWebView extraction, in-app browser, preview/save, duplicate detection
- ✅ In-app WKWebView browser (replaced share extension — better UX)
- ✅ Import preview UI with per-field confidence dots, wireframe-aligned
- ✅ Error handling with type-specific views (paywall, no recipe, network, generic)
- ✅ Duplicate detection (exact URL + fuzzy title) with Replace Existing support
- ✅ CategoryAssignmentModal wired into import save flow
- ✅ HTML metadata title enhancement (og:title fallback for incomplete JSON-LD names)
- ✅ Validation limits increased for imported data (250 char template names, 300 char titles)

### Reusable Infrastructure from M10.1
- `ImportDraftRecipe` + `ImportField<T>` confidence model
- `ImportJobState` state machine
- `RecipeImportService` orchestrator (save, replace, duplicate check)
- `RecipeImportSheet` + `RecipeImportPreviewView` (preview/save flow)
- `RecipeExtractor` protocol + strategy pattern
- `SchemaRecipeMapper` (maps structured dicts → ImportDraftRecipe)
- `IngredientParsingService.parseAndConnectIngredients()` for atomic save

### M10.2 Sub-phase Breakdown

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.2.1 | Foundation Models extension spike | 1-2h | — |
| M10.2.2 | Text input UI | 2-3h | — |
| M10.2.3 | Foundation Models @Generable extractor | 4-5h | M10.2.1 |
| M10.2.4 | Heuristic text fallback — port spike | 3-4h | M10.2.2 (parallel with M10.2.3) |
| M10.2.5 | Section detection UI | 2-3h | M10.2.3, M10.2.4 |
| M10.2.6 | Testing & refinement | 2-3h | M10.2.5 |

### Key Architecture Decisions
- **Foundation Models `@Generable`** — iOS 26+ on-device LLM for structured recipe extraction from free text
- **Heuristic fallback** — For devices without Foundation Models or when AI extraction fails
- **Shared line classifier** — Section detection (title vs ingredient vs instruction) reused across text + photo paths
- **Same preview/save flow** — Text extraction produces `ImportDraftRecipe`, feeds into existing `RecipeImportSheet`

### Entry Point
- RecipeListView import Menu already has "Paste URL" option
- M10.2 adds a third option: "Paste Recipe Text" → text input view → extraction → preview/save

---

## **AFTER M10.2: M10.3 → M10.4 → M7.7 → M6 → M9 → M11+**

### M10.3: Photo/Image Import (21-28h)
- Document scanner, OCR pipeline, section classification, AI extraction

### M10.4: Polish & Integration (11-16h)
- Import history, household sharing, telemetry dashboard

### M7.7: App Store Submission (3-5h)
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

### M6: Testing Foundation (20-30h)
- 50%+ test coverage on critical services

### M9 Remaining (~120h)
- Technical debt and codebase optimization

---

**Dependencies**: M10.1 merged to main ✅ | All import infrastructure in place ✅ | Foundation Models requires iOS 26+ ✅
