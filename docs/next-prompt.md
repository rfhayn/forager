# Next Implementation Prompt

**Last Updated**: March 21, 2026
**For Milestone**: Launch Path
**Status**: **M9.27 ✅** | **M9.25.1 ✅** | **M9.24 🔄** | **M9.15.3 🔄** | M9.26 🚀 | M10.6.5 🚀 | M9.28-M9.29 ⏳ | M7.7 ⏳

**Launch Path**: M9.24 → M9.15.3 → M9.26 → M10.6.5 → M9.28 → M9.29 → M7.7

---

## **M9.15.3 — 🔄 ACTIVE: Returning User Detection**

**PRD**: `docs/prds/active/m9.15-household-creation-architecture-fix.md` (Phase 3)
**Branch**: `feature/M9.15.3-returning-user-detection`
**Problem**: After app reinstall, UserDefaults is lost → `currentHousehold` is nil → shared data invisible

### What's Done (Phase 3)
- `discoverExistingHousehold()` — background polling loop (30 attempts × 2s = 60s)
- `DiscoveryState` enum + `@Published` for UI consumption
- `cancelDiscovery()` — stops background task when user creates household
- `foragerApp.swift` — kicks off discovery after initial `loadCurrentHousehold()` finds nothing
- `HouseholdView` — discovery status in no-household section + live sync indicator from CloudKitSyncMonitor
- Build succeeds

### What's Left
- Test on device with real CloudKit (delete app, reinstall, verify household restores)
- Verify edge cases: left-household flag (Keychain survives reinstall), multiple households
- Consider: should `checkForAcceptedInvitations()` also run after discovery timeout?

### Key Design Decisions
1. **Trust CloudKit membership**: If Household is in shared store, user is a participant (CloudKit guarantees this)
2. **Non-blocking**: App loads instantly with empty state, discovery runs in background
3. **Re-uses `loadCurrentHousehold()`**: No new fetch logic — the existing method already validates CKShare + left-household flags
4. **Pre-creation guard**: `createHouseholdAndShare()` already checks for existing households (M7.3.3), plus we cancel discovery

### Previous Phases (Complete, merged as PR #73)
- **Phase 1**: Promoted Ingredient + GroceryListItem to HouseholdScoped (schema v9)
- **Phase 2**: Rewrote household creation with create-empty-then-copy pattern

---

## **M16 — 🔄 ACTIVE: Knowledge MCP Server (M16.3 remaining)**

**PRD**: `docs/prds/active/m16-knowledge-mcp-server.md`
**Branch**: Merged to main (PR #63)
**Location**: `Tools/mcp-knowledge/`

Python MCP server that indexes all project knowledge (182 docs, 2,472 chunks) for search/retrieval in Claude Desktop. Deployed and operational. 7 MCP tools across core search and newsletter drafting.

### M16.1: Foundation (2-3h) — ✅ COMPLETE
### M16.2: Newsletter + Status Tools (2-3h) — ✅ COMPLETE

### M16.3: Polish (1-2h) — PLANNED
- Tune chunking/search quality based on real usage
- Test with real newsletter writing session
- Verify README accuracy

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

## **M10.6 — 🔄 ACTIVE: Claude API Integration (17.5-24h)**

**PRD**: `docs/prds/active/m10.6-claude-api-integration.md`
**Branch**: `feature/M10.6-claude-api-integration`

Optional Claude API for ingredient parsing (fills ~7-8% semantic gap). M10.6.6 adds user-triggered AI parsing across all views. App fully functional without it — toggle OFF by default. Zero Core Data schema changes.

### Sub-phases

| Sub-phase | Scope | Hours | Status |
|-----------|-------|-------|--------|
| M10.6.1 | Protocol + ClaudeIngredientParser + mock + tests | 2-3h | ✅ |
| M10.6.2 | KeychainHelper extension + LLMSettingsService + tests | 1.5-2h | ✅ |
| M10.6.3 | Settings UI — AI Import section | 1.5-2h | ✅ |
| M10.6.4 | RecipeImportService integration + telemetry + tests | 2-3h | ✅ |
| M10.6.5 | Documentation + full verification | 1-2h | READY |
| M10.6.6 | User-triggered AI parsing across all views | 9-12h | ✅ |
| M10.6.7 | Household-shared API key via CloudKit | 3-4h | ✅ |
| M10.6.8 | Shared IngredientMatchService + IngredientMatchRow | 4-5h | ✅ |
| M10.6.9 | AI category validation + import persistence fixes | 2-3h | ✅ |
| M10.6.10 | Ingredient autocomplete + three-state match icons | 1-2h | ✅ |

### What's Done (M10.6.6-M10.6.10)
- `IngredientParsingService` LLM public API: `isLLMAvailable`, `parseSingleWithLLM()`, `parseBatchWithLLM()`
- `LLMParsingToast` reusable view modifier (capsule, auto-dismiss 2s)
- CreateRecipeView + EditRecipeView: batch sparkle + per-ingredient context menu
- RecipeImportPreviewView: batch sparkle + per-ingredient context menu (index-keyed)
- GroceryListDetailView: sparkle quick-add with local-parse fallback
- AddListItemView: "AI Add" sparkle with local-parse fallback
- M10.6.7: Household-shared API key stored in CloudKit Household entity (`llmAPIKey` field, v7 schema)
- M10.6.8: Shared `IngredientMatchService` + `IngredientMatchRow` components across all 4 ingredient views
- M10.6.9: AI category validation, index-based category persistence, grocery merge fix, inline add ingredient
- M10.6.10: Autocomplete dropdowns in RecipeDetailView + RecipeImportPreviewView, three-state status icons (ready/needsCategory/needsTemplate)

### What's Next (M10.6.5)
- Update all 7 core docs with completion status
- Final build verification
- Create PR for squash merge to main

### After M10.6

- M10.4: Polish & Integration (11-16h)
- M7.7: App Store Submission (3-5h)
- M6: Testing Foundation (20-30h)
- M9 Remaining (~120h)

---

**Dependencies**: M10.3 dev complete ✅ | M10.8 complete ✅ | M10.6 PRD audited ✅ | All 267+ existing tests expected to pass (no schema changes)
