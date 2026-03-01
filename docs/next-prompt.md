# Next Implementation Prompt

**Last Updated**: March 1, 2026
**For Milestone**: M10.6 Claude API Integration
**Status**: M10.1 ✅ **COMPLETE** | M10.2 ✅ **COMPLETE** | M10.5 ✅ **COMPLETE** | M10.8 ✅ **COMPLETE** | M10.3 ✅ **DEV COMPLETE** | M10.6 🔄 **ACTIVE**

---

## **M10.8 — ✅ COMPLETE**

Inline ingredient + instruction + metadata editing across RecipeDetailView, CreateRecipeView, EditRecipeView, and RecipeImportPreviewView. Edit Recipe modal removed. TestFlight build 29 deployed.

**PRD**: `docs/prds/complete/m10.8-inline-ingredient-editing.md`

---

## **M10.3 — DEV COMPLETE (Ready to Merge)**

### What's Done
- ✅ `ImageOCRService.swift` — VNRecognizeTextRequest wrapper → [OCRLine] with real boundingBox
- ✅ `DocumentScannerView.swift` — VNDocumentCameraViewController UIViewControllerRepresentable
- ✅ `PhotoImportView.swift` — Full local phase state machine with dual extraction path
- ✅ `.photo` ImportMode added to RecipeImportSheet
- ✅ "Import from Photo" menu button in RecipeListView
- ✅ `NSCameraUsageDescription` in Info.plist
- ✅ Build succeeds with zero warnings
- ✅ Bug fixes: PhotoImportPhase Equatable, auto-dismiss, CategoryAssignmentModal, cold launch, label fix
- ✅ M10.3.8: Import preview ingredient matching — parse + template lookup + status display

### What Still Needs Manual Testing
- Clean printed recipes (cookbooks, magazines)
- Screenshot recipes from websites
- Handwritten recipes (expect lower accuracy)
- Multi-page scans via document scanner
- Error paths: no text, camera denied, scanner cancelled
- FM path vs heuristic path on FM-capable device
- M10.3.8 ingredient matching display (verify ✓/?/○ icons + category labels)

---

## **M10.6 — 🔄 ACTIVE: Claude API Integration (8.5-12h)**

**PRD**: `docs/prds/active/m10.6-claude-api-integration.md`
**Branch**: `feature/M10.6-claude-api-integration`

Optional Claude API for import ingredient parsing (fills ~7-8% semantic gap). App fully functional without it — toggle OFF by default. Zero Core Data schema changes.

### Sub-phases

| Sub-phase | Scope | Hours |
|-----------|-------|-------|
| M10.6.1 | Protocol + ClaudeIngredientParser + mock + tests | 2-3h |
| M10.6.2 | KeychainHelper extension + LLMSettingsService + tests | 1.5-2h |
| M10.6.3 | Settings UI — AI Import section | 1.5-2h |
| M10.6.4 | RecipeImportService integration + telemetry + tests | 2-3h |
| M10.6.5 | Documentation + full verification | 1-2h |

### Key Implementation Notes (from PRD audit)
- `KeychainHelper.read`/`write` are `private static` — add LLM methods inside the enum body, not as an extension
- `RecipeImportService.saveImport(from:)` is sync (line 144) — needs async conversion
- `parserUsed` is already `String?` — add `"claude"` with zero schema change
- ~20 new tests across 3 test files, 7 new production files, 10 modified files

### After M10.6

- M10.4: Polish & Integration (11-16h)
- M7.7: App Store Submission (3-5h)
- M6: Testing Foundation (20-30h)
- M9 Remaining (~120h)

---

**Dependencies**: M10.3 dev complete ✅ | M10.8 complete ✅ | M10.6 PRD audited ✅ | All 267+ existing tests expected to pass (no schema changes)
