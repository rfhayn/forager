# Next Implementation Prompt

**Last Updated**: February 26, 2026
**For Milestone**: M10.3 Photo/Image Import — Testing & Refinement
**Status**: M10.1 ✅ **COMPLETE** | M10.2 ✅ **COMPLETE** | M10.5 ✅ **COMPLETE** | **M10.3 ACTIVE (code complete, needs testing)** | M10.6 📋 **PRD READY**
**Branch**: `feature/M10.3-photo-import`

---

## **CURRENT: M10.3 — Testing & Refinement**

### What's Done
- ✅ `ImageOCRService.swift` — VNRecognizeTextRequest wrapper → [OCRLine] with real boundingBox
- ✅ `DocumentScannerView.swift` — VNDocumentCameraViewController UIViewControllerRepresentable
- ✅ `PhotoImportView.swift` — Full local phase state machine with dual extraction path
- ✅ `.photo` ImportMode added to RecipeImportSheet
- ✅ "Import from Photo" menu button in RecipeListView
- ✅ `NSCameraUsageDescription` in Info.plist
- ✅ Build succeeds with zero warnings

### What Needs Testing
Manual testing with real recipe photos:
- Clean printed recipes (cookbooks, magazines)
- Screenshot recipes from websites
- Handwritten recipes (expect lower accuracy)
- Multi-column layouts
- Low-light / angled photos
- Multi-page scans via document scanner
- Empty OCR result → ImportError.noTextDetected
- Camera permission denied → ImportError.cameraPermissionDenied
- Scanner cancelled → graceful dismiss
- FM path vs heuristic path (compare on FM-capable device)

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

**Dependencies**: M10.3 code complete, needs manual testing ✅ | M10.6 PRD ready ✅ | All 267+ existing tests expected to pass (no schema changes)
