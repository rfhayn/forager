# Next Implementation Prompt

**Last Updated**: March 7, 2026
**For Milestone**: M16 Knowledge MCP Server
**Status**: **M16 🔄 ACTIVE** (M16.1 in progress) | M10.6 🔄 ACTIVE (M10.6.5 remaining)

---

## **M16 — 🔄 ACTIVE: Knowledge MCP Server (6-10h)**

**PRD**: `docs/prds/active/m16-knowledge-mcp-server.md`
**Branch**: `feature/M16-knowledge-mcp-server`
**Location**: `Tools/mcp-knowledge/`

Python MCP server that indexes all project knowledge (185+ docs, 5.3 MB) for search/retrieval in Claude Desktop. Includes newsletter drafting with .docx generation.

### M16.1: Foundation (2-3h) — ACTIVE

**Build order:**
1. `pyproject.toml` — dependencies: `mcp`, `python-docx`, `rank-bm25`
2. `src/documents.py` — load .md and .docx files, extract text
3. `src/indexer.py` — chunk documents by H2 headers, categorize by type
4. `src/search.py` — BM25 index over all chunks
5. `src/server.py` — MCP server with `search_knowledge`, `read_document`, `list_documents`
6. Move newsletters from `~/Desktop/forager/Newsletter/Articles/` to `docs/newsletters/`
7. Test: start server, verify tools respond in Claude Desktop

**Key files to create:**
- `Tools/mcp-knowledge/pyproject.toml`
- `Tools/mcp-knowledge/src/__init__.py`
- `Tools/mcp-knowledge/src/server.py`
- `Tools/mcp-knowledge/src/indexer.py`
- `Tools/mcp-knowledge/src/search.py`
- `Tools/mcp-knowledge/src/documents.py`

**Categories for indexing:**
- `core-doc` — current-story, roadmap, requirements, project-index, insights-log, development-journal, next-prompt
- `learning-note` — docs/learning-notes/*.md
- `adr` — docs/architecture/*.md
- `prd` — docs/prds/**/*.md
- `newsletter` — docs/newsletters/*.docx
- `research` — docs/import-research/*.md, docs/ux-research/*.md
- `guideline` — development-guidelines, session-startup-checklist, etc.

### M16.2: Newsletter + Status Tools (2-3h) — READY

- `get_project_status` — curated current-story + next-prompt summary
- `get_newsletter_context` — search project docs for a topic + pull style from recent newsletters
- `draft_newsletter_section` — context bundle + outline for drafting
- `create_newsletter_draft` — generate .docx from content (markdown → docx conversion)
- `src/newsletter.py` — newsletter-specific helpers

### M16.3: Polish (1-2h) — PLANNED

- README.md with setup instructions
- Tune chunking/search quality
- Test with real newsletter writing session

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
