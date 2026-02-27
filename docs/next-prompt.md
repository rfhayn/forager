# Next Implementation Prompt

**Last Updated**: February 26, 2026
**For Milestone**: M10.3 Photo/Image Import — DEV COMPLETE
**Status**: M10.1 ✅ **COMPLETE** | M10.2 ✅ **COMPLETE** | M10.5 ✅ **COMPLETE** | M10.3 ✅ **DEV COMPLETE** | M10.6 📋 **PRD READY**
**Branch**: `feature/M10.3-photo-import` (ready for PR)

---

## **M10.3 — DEV COMPLETE**

### What's Done
- ✅ `ImageOCRService.swift` — VNRecognizeTextRequest wrapper → [OCRLine] with real boundingBox
- ✅ `DocumentScannerView.swift` — VNDocumentCameraViewController UIViewControllerRepresentable
- ✅ `PhotoImportView.swift` — Full local phase state machine with dual extraction path
- ✅ `.photo` ImportMode added to RecipeImportSheet
- ✅ "Import from Photo" menu button in RecipeListView
- ✅ `NSCameraUsageDescription` in Info.plist
- ✅ Build succeeds with zero warnings
- ✅ Bug fix: PhotoImportPhase Equatable causing review binding to freeze
- ✅ Bug fix: "Recipe Saved!" screen removed, save auto-dismisses
- ✅ Bug fix: CategoryAssignmentModal appears properly before dismiss
- ✅ Bug fix: Cold launch blank grocery list (HouseholdService timing)
- ✅ Bug fix: "Templates" → "Ingredients" in HouseholdView shared data
- ✅ M10.3.8: Import preview ingredient matching — parse + template lookup + status display

### What Still Needs Manual Testing
- Clean printed recipes (cookbooks, magazines)
- Screenshot recipes from websites
- Handwritten recipes (expect lower accuracy)
- Multi-page scans via document scanner
- Error paths: no text, camera denied, scanner cancelled
- FM path vs heuristic path on FM-capable device
- M10.3.8 ingredient matching display (verify ✓/?/○ icons + category labels)

### Tests
- No new unit tests needed — M10.3.8 is view-layer glue connecting already-tested services
- `IngredientParsingService.parseIngredient()` and `IngredientTemplateService.searchTemplates()` have existing coverage
- All 267+ existing tests expected to pass (no schema changes)

---

## **NEXT: M10.4 → M10.6 → M7.7 → M6 → M9 → M11+**

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

**Dependencies**: M10.3 dev complete ✅ | M10.3.8 implemented ✅ | M10.6 PRD ready ✅ | All 267+ existing tests expected to pass (no schema changes)
