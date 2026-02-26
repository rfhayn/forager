# Next Implementation Prompt

**Last Updated**: February 26, 2026
**For Milestone**: M10.3 Photo/Image Import (21-28h)
**Status**: M10.1 ✅ **COMPLETE** | M10.2 ✅ **COMPLETE** | M10.5 ✅ **COMPLETE** | M10.6 📋 **PRD READY** | **M10.3 NEXT**
**Branch**: Create `feature/M10.3-photo-import`

---

## **NEXT: M10.3 — Photo/Image Import (21-28h)**

**PRD**: `docs/prds/active/m10-recipe-import.md` (full implementation blueprint — §7 M10.3)
**Spike Research**: `docs/import-research/` (7 supporting documents)
**Wireframes**: `docs/import-research/import-wireframes.html` (open in browser)
**Core Data Impact**: NONE — no schema changes

### What's Already Done (M10.1 + M10.2 Complete)
- ✅ M10.1: URL Import — JSON-LD + WKWebView extraction, in-app browser, preview/save, duplicate detection
- ✅ M10.2: Text Paste Import — Foundation Models `@Generable` + heuristic fallback, SectionHighlightView review
- ✅ `OCRLineClassifier` — Shared between text paste and photo OCR (line scoring, section context boosting)
- ✅ `SectionHighlightView` — Color-coded line classification review (tap-to-reclassify)
- ✅ Import preview UI with per-field confidence dots, wireframe-aligned
- ✅ Error handling with type-specific views
- ✅ Duplicate detection with Replace Existing support
- ✅ CategoryAssignmentModal wired into import save flow

### Reusable Infrastructure from M10.1 + M10.2
- `ImportDraftRecipe` + `ImportField<T>` confidence model
- `ImportJobState` state machine
- `RecipeImportService` orchestrator (save, replace, duplicate check, text import)
- `RecipeImportSheet` + `RecipeImportPreviewView` (preview/save flow)
- `RecipeExtractor` protocol + strategy pattern
- `OCRLineClassifier` — Heuristic line classification (shared with M10.3)
- `SectionHighlightView` — Classification review UI (shared with M10.3)
- `HeuristicTextExtractor` — Text → ImportDraftRecipe adapter
- `FoundationModelsExtractor` — On-device LLM structured extraction

### M10.3 Sub-phase Breakdown

| # | Sub-phase | Hours | Depends On |
|---|-----------|-------|------------|
| M10.3.1 | Document scanner + VNDocumentCameraViewController | 2-3h | — |
| M10.3.2 | OCR pipeline (VNRecognizeTextRequest) | 3-4h | M10.3.1 |
| M10.3.3 | Photo import view + camera/library picker | 3-4h | — |
| M10.3.4 | OCR → line classification → SectionHighlightView integration | 3-4h | M10.3.2, M10.3.3 |
| M10.3.5 | Foundation Models extraction from OCR text | 2-3h | M10.3.4 |
| M10.3.6 | Mela-style split-screen UI (image + classified text) | 4-5h | M10.3.4 |
| M10.3.7 | Testing & refinement | 4-5h | M10.3.6 |

### Key Architecture Decisions
- **VNRecognizeTextRequest .accurate** — 100% character accuracy on clean printed text (validated in spike)
- **OCRLineClassifier reuse** — Same classifier used for text paste, now with real boundingBox data from OCR
- **SectionHighlightView reuse** — Same review UI, but M10.3 adds split-screen with image alongside
- **Foundation Models as enhancement** — OCR text → FM structured extraction for higher confidence
- **Mela-style UI** — Side-by-side image and classified text, similar to Mela app's photo import

### Entry Point
- RecipeListView import Menu gets a third option: "Scan Recipe" or "Import from Photo"
- Camera/library → OCR → classification → SectionHighlightView → preview/save

---

## **AFTER M10.3: M10.4 → M10.6 → M7.7 → M6 → M9 → M11+**

### M10.4: Polish & Integration (11-16h)
- Import history, household sharing, telemetry dashboard

### M10.6: Claude API Integration (8.5-12h) — PRD READY
- **PRD**: `docs/prds/active/m10.6-claude-api-integration.md`
- Optional Claude API for import ingredient parsing (fills ~7-8% semantic gap)
- 5 sub-phases: Protocol → Keychain → Settings UI → Integration → Docs
- Zero Core Data schema changes, ~20 new tests
- App fully functional without it — toggle OFF by default

### M7.7: App Store Submission (3-5h)
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

### M6: Testing Foundation (20-30h)
- 50%+ test coverage on critical services

### M9 Remaining (~120h)
- Technical debt and codebase optimization

---

**Dependencies**: M10.2 merged to main ✅ | M10.5 merged to main ✅ | OCRLineClassifier + SectionHighlightView ready for reuse ✅ | Foundation Models requires iOS 26+ ✅ | M10.6 PRD ready ✅
