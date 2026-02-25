# Current Development Story

**Last Updated**: February 24, 2026
**Status**: M8.4 ✅ **COMPLETE** | M8.4.1 ✅ **COMPLETE** | M9.5-partial ✅ **COMPLETE** | M15 ✅ **COMPLETE** | **M10.1 ACTIVE**
**Total Progress**: ~241 hours | 89% planning accuracy
**Current Branch**: `feature/M10.1-url-import`
**Current Milestone**: M10.1 URL Import — 🔧 **ACTIVE** (6/8 sub-phases complete)
**Implementation Plans**: `docs/prds/complete/plans/` — 8 detailed plans, cross-validated and externally reviewed
**Next Priority**: M10 (Recipe Import) → M7.7 → M6 → M9 → M11+

---

## 🔧 **M10: RECIPE IMPORT - ACTIVE**

**Status**: 🔧 **ACTIVE** — M10.1 URL Import in progress (6/8 sub-phases complete)
**Estimated**: 70-95 hours (4 phases)
**PRD**: `docs/prds/active/m10-recipe-import.md` (full implementation blueprint)
**Spike Research**: `docs/import-research/` (7 supporting documents)
**Wireframes**: `docs/import-research/import-wireframes.html`
**Branch**: Create `feature/M10.1-url-import`

### Phase Overview

| Phase | Scope | Hours | Sub-phases | New Tests |
|-------|-------|-------|------------|-----------|
| M10.1: URL Import | JSON-LD + WKWebView extraction, Share extension, preview UI, duplicate detection | 24-32h | M10.1.1-M10.1.8 | ~68 |
| M10.2: Text Paste Import | Foundation Models `@Generable` + heuristic fallback, shared line classifier, section detection | 14-19h | M10.2.1-M10.2.6 | ~35 |
| M10.3: Photo/Image Import | OCR + section classification, AI-assisted extraction, Mela-style UI | 21-28h | M10.3.1-M10.3.7 | ~8 |
| M10.4: Polish & Integration | History, household sharing, telemetry dashboard, regression testing | 11-16h | M10.4.1-M10.4.6 | ~8 |

### Key Architecture Decisions
- **ImportDraftRecipe (separate model)** — NOT extending RecipeFormData; import needs fields it lacks (author, imageURL, cuisine) + field-level confidence tracking via `ImportField<T>` generic wrapper. Same save validation gate as manual creation (title + ≥1 ingredient + instructions required).
- **Draft-first workflow** — `ImportDraftRecipe` in-memory staging, persist only on confirm via atomic `RecipeService.importRecipe()` using `factory.make(Recipe.self, in: scope) { ... }` for household scope safety (single `context.save()`)
- **Strategy pattern extractors** — `RecipeExtractor` protocol with 5 implementations (mirrors `HybridIngredientParser`); return `nil` pattern like `MLIngredientParser.init?()`
- **Image handling v1** — `imageURL` (web URL) only via AsyncImage; no Core Data schema change; local persistence deferred
- **Flat ingredient groups v1** — Multi-component recipes flattened; structured `RecipeSection` is future milestone
- **Telemetry ownership** — PTS owns raw import events (Documents directory JSON), ImportTelemetryService (M10.4) is read-only KPI aggregation, ImportHistoryService is user-facing log (UserDefaults)
- **Zero Core Data schema changes** — No model version bump, no migration needed

### Key Targets
- ≥ 80% extraction rate on Tier 1 sites, ≥ 70% on Tier 2 blogs
- < 3s URLSession path, < 8s WKWebView fallback
- 100% graceful failure rate (every failure → user-facing message)
- ~119 new tests across 10 test files, ~4,500-5,000 new lines
- Spike-validated: 28 sites tested, 12/28 server-rendered, ~8 more via WKWebView

### M10.1 Implementation Progress
1. ✅ M10.1.1: Import models + extraction infrastructure — COMPLETE
2. ✅ M10.1.2: JSON-LD extractor + schema mapper — COMPLETE
3. ✅ M10.1.3: Import orchestrator + service — COMPLETE
4. ✅ M10.1.4: Import preview UI — COMPLETE (wireframe-aligned rewrite in progress)
5. ✅ M10.1.5: WKWebView fallback — COMPLETE
6. ✅ M10.1.6: Duplicate detection — COMPLETE (+ "Replace Existing" service method added)
7. M10.1.7: Share extension + App Group (3-4h) — NEXT
8. ✅ M10.1.8: Error handling + edge cases — COMPLETE

**View wireframe alignment** (M10.1.4 follow-up):
- ✅ RecipeImportPreviewView — rewritten to match wireframe screens 1 & 3
- ✅ DuplicateResolutionSheet — 3 buttons, "Similar Recipe Found" title
- ✅ RecipeImportSheet — Replace Existing wired up, nav bar coordination
- ✅ RecipeImportService — `replaceExistingRecipe()` method added
- ✅ ImportJobState — `isReviewing` property for nav bar coordination
- ✅ PRD updated with implementation status markers
- ✅ RecipeImportSheet errorView — refactored to 4 type-specific presentations (wireframe screen 5)
- ✅ ImportError — `errorTitle` + `errorIcon` computed properties for UI dispatch
- ✅ RecipeImportService — `checkUnsupportedSource()` for Pinterest/TikTok/Instagram fail-fast

### Files Created This Session
**Services/Import/** (auto-detected):
- `ImportDraftRecipe.swift` — Core models, state machine, error taxonomy
- `RecipeExtractor.swift` — Protocol + input enum + context struct
- `ISO8601DurationParser.swift` — Duration + yield parsers
- `HTMLEntityDecoder.swift` — HTML entity decoding
- `RecipeJSONLDExtractor.swift` — 3-tier JSON-LD extraction
- `SchemaRecipeMapper.swift` — Schema.org dict → ImportDraftRecipe
- `RecipeImportService.swift` — Import orchestrator (URL fetch, extraction, atomic save)
- `DuplicateDetectionService.swift` — Exact URL + fuzzy title matching
- `WKWebViewExtractor.swift` — JS-rendered fallback extractor

**forager/** (manual pbxproj):
- `RecipeImportSheet.swift` — Entry point sheet
- `RecipeImportPreviewView.swift` — Preview with confidence dots
- `DuplicateResolutionSheet.swift` — Duplicate resolution modal

**Modified**:
- `RecipeListView.swift` — Import button + sheet
- `forager.xcodeproj/project.pbxproj` — 3 view file entries

---

## ✅ **M8.4.1: NORMALIZATION QUALIFIER RECLASSIFICATION - COMPLETE**

**Status**: ✅ **COMPLETE** — Bug fix for identity qualifier stripping
**Session**: February 24, 2026 (session 38)
**Branch**: `main`
**PRD**: `docs/prds/complete/m8.4.1-normalization-qualifier-reclassification.md`
**Actual**: ~2 hours

### Summary
Fixed `IngredientTemplateService.normalize()` stripping identity qualifiers (ground, fresh, frozen, dried, etc.) from ingredient names. "Ground beef" was becoming "beef". Root cause: `removeVariations()` conflated identity qualifiers with preparation qualifiers. Data-driven fix using strangetom training data (68,846 samples) to reclassify — reduced strip list from 30+ to 9 pure preparation qualifiers. 282 tests pass, 0 failures.

---

## ✅ **M8.4: ML-POWERED PARSING - COMPLETE**

**Status**: ✅ **COMPLETE** — All 10 phases (0-9) done
**Sessions**: February 2026 (sessions 20-34)
**Branch**: `feature/M8.4-ml-parsing`
**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md`
**Actual**: ~25 hours across 10 phases

### **Phase 0: Contract Lock + Single-Parse Refactor** ✅

Architecture locked and parsing infrastructure hardened for ML integration.

**Phase 0a: Architecture Lock**
- Word-only BiLSTM v1 (no char features) — locked for v1

**Phase 0b: Tokenizer Spec**
- `TOKENIZER_SPEC.md` — binding contract between Python training and Swift runtime tokenizers
- NFKD normalization, case folding, whitespace normalization, punctuation splitting
- 100-sentence test vectors in `data/tokenizer_test_vectors.json`

**Phase 0c: Single-Parse Refactor**
- Added `parseCore()` — private, single telemetry-instrumented entry point
- Added `parseUnified()` — public, returns both `ParsedIngredient` + `StructuredQuantity` from one parse call
- Added static mapping helpers (`mapToParsedIngredient`, `mapToStructuredQuantity`)
- Refactored `parseAndConnectIngredients()` to use `parseUnified()` (was calling `parser.parse()` twice per ingredient)
- Fixed 3 view files with double-parse patterns (GroceryListDetailView, AddListItemView, RecipeListView)

**Phase 0d-e: Governance**
- Viterbi parity gate criteria documented in PRD
- Model card template + license attribution (MIT/Apache 2.0 for strangetom)

**Training Infrastructure**
- `Tools/ml-training/` directory with README, requirements.txt
- `.gitignore` for data/model artifacts (SQLite, JSONL, checkpoints, .mlpackage)

### **Phase 1: Dataset Preparation Pipeline** ✅

Converted strangetom SQLite database to Forager training format.

**Data Pipeline** (`Tools/ml-training/prepare_dataset.py`, 335 lines)
- Loaded strangetom SQLite: 81,316 sentences, 13 token-level labels
- Mapped 13 strangetom labels → 7 Forager labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER)
- Decoded all fraction notation via `re.sub` (handles mixed `1#1$2`, prefixed `#1$2`, simple `1$2`, ranges, dimensions)
- Deduplicated by sentence: removed 12,470 duplicates → 68,846 unique samples
- Split 80/10/10 stratified by source, verified no cross-split data leakage

**Dataset Statistics** (68,846 sentences, 533,235 tokens)
- Label distribution: NAME 30.4%, PREP 16.7%, QTY 15.2%, OTHER 13.3%, UNIT 13.4%, COMMENT 10.0%, MODIFIER 1.1%
- Sources: NYT 18,940 | AllRecipes 14,792 | BBC 14,738 | Cookstr 14,087 | TC 6,289
- Token length: mean 7.7, median 7.0, p95 15, max 50
- Splits: train 55,076 | val 6,885 | test 6,885

**Output Files**
- `data/training_data.jsonl` (55,076 samples)
- `data/validation_data.jsonl` (6,885 samples)
- `data/test_data.jsonl` (6,885 samples)
- `data/dataset_statistics.json` (distribution and split metadata)

### **Phase 2: Model Architecture & Training** ✅

Trained BiLSTM-CRF sequence labeler — all acceptance criteria met.

**Model Architecture** (`Tools/ml-training/train_model.py`, 340 lines)
- `IngredientTagger(nn.Module)`: embedding → BiLSTM → dropout → linear → CRF
- Embedding dim: 128, Hidden dim: 256, 2 BiLSTM layers, dropout: 0.5
- `pytorch-crf` for CRF layer (Viterbi decoding during inference)
- Variable-length inputs via `pack_padded_sequence` with sorted batch collation
- Gradient clipping at 5.0, Adam optimizer, lr=0.001, batch size 64

**Training Results** (MPS device, ~39 min)
- Vocabulary: 5,372 words (min_freq=2), UNK rate: 1.47%
- Parameters: 1,348,934 (all trainable)
- Best epoch: 21/30 (early stopped at epoch 26, patience=5)
- Best validation loss: 0.2045

**Test Set Evaluation**
- Token accuracy: **98.49%** (target: ≥96%) ✅
- Sentence accuracy: **95.40%** (target: ≥92%) ✅
- Per-class F1: QTY=0.9968, UNIT=0.9939, NAME=0.9869, MODIFIER=0.9261, PREP=0.9789, COMMENT=0.9463, OTHER=0.9997
- All key F1 ≥ 0.90: QTY ✅, UNIT ✅, NAME ✅

**Exported Artifacts** (gitignored)
- `models/ingredient_tagger.pt` — 5.2 MB checkpoint (target: <10 MB) ✅
- `models/transitions.json` — 7×7 CRF transition matrix + start/end transitions + label names
- `models/vocabulary.json` — 5,372 word→index mappings

**Model Card** updated with training metadata, hyperparameters, and evaluation metrics.

### **Phase 3: CoreML Conversion** ✅

Converted BiLSTM emission scorer to CoreML and passed all parity gates.

**CoreML Conversion** (`Tools/ml-training/convert_to_coreml.py`, 283 lines)
- Extracted `EmissionScorer` wrapper (embedding + BiLSTM + linear, no CRF)
- Traced and converted via coremltools 9.0 with variable-length input `(1, RangeDim(1, 64))`
- FLOAT32 precision, iOS 18 minimum deployment target
- CoreML model size: 5.15 MB

**Emission Parity** (PyTorch vs CoreML)
- Max absolute difference: 4.77e-06 across sequence lengths 3-20
- Well within 0.01 threshold

**Viterbi Parity Gate** (HARD GATE — PASSED)
- Python reference Viterbi decoder implemented (~40 lines)
- 1,000 test samples: **100.0000% token agreement** (8,030/8,030 tokens)
- 100.00% sentence agreement (1,000/1,000 sentences)
- End-to-end (CoreML emissions + Viterbi): 100.0000% (794/794 tokens on 100 samples)
- Zero disagreements

**Xcode Integration**
- `IngredientTaggerEmissions.mlpackage` → Sources build phase (auto-generates Swift prediction class)
- `transitions.json` → Copy Bundle Resources
- `vocabulary.json` → Copy Bundle Resources
- All 3 files in app bundle, BUILD SUCCEEDED

### **Phase 4: MLIngredientParser Implementation** ✅

Swift runtime components consuming the CoreML model.

**ViterbiDecoder.swift** (~70 lines)
- Pure-Swift Viterbi algorithm: forward pass with backpointers + backtrace
- Consumes ALL CRF parameters: 7×7 transitions + start_transitions + end_transitions
- Matches Python reference decoder (verified at 100.0000% parity in Phase 3)

**MLIngredientParser.swift** (~300 lines)
- Implements `IngredientParser` protocol with failable `init?()`
- Tokenizer: NFKD normalize → lowercase → whitespace normalize → punctuation split → truncate to 64
- CoreML inference: `MLMultiArray` input → emission scores → Viterbi decode → label sequence
- Result assembly: token-label pairs → quantity/unit/name/notes
- Handles Unicode fraction slash (U+2044) from NFKD decomposition of ½, ¼, etc.
- Confidence: geometric mean of max per-token softmax probability
- Graceful degradation: `init?()` returns nil if model/vocabulary/transitions unavailable

**Key Details:**
- `transitions.json` uses `label_names` key (not `labels` as PRD pseudocode showed)
- MODIFIER labels grouped with NAME for ingredient name construction
- PREP + COMMENT labels grouped for notes field
- Unit standardization matches existing parser patterns

### **Phase 5: HybridIngredientParser Integration** ✅

3-tier routing integration — ML parser slotted between regex and NLP.

**HybridIngredientParser.swift** (rewritten)
- Added `mlParser: IngredientParser?` parameter (default: `MLIngredientParser()`)
- Raised regex threshold from 0.8 → 0.9 (skip ML only for very high-confidence regex)
- 3-tier routing: regex ≥0.9 → ML ≥0.8 → NLP fallback (only when both < 0.5)
- Winner-only attribution: `parserUsed` reports winning parser, never `"hybrid"`
- `#if DEBUG` warning when ML parser fails to load
- Graceful degradation: when `mlParser == nil`, falls back to original 2-tier behavior

**Comment Updates**
- `IngredientParser.swift`: Protocol doc updated for 3 implementations, `parserUsed` values: `"regex"`, `"ml"`, `"nlp"`
- `ParsingTelemetryService.swift`: `parserUsed` comment updated from `"hybrid"` to winner-only

**CoreML Warmup**
- `foragerApp.init()`: Background warmup via `DispatchQueue.global(qos: .utility).async`
- Triggers lazy model loading off main thread, prevents first-prediction latency spike

**Test Updates**
- `HybridParserRoutingTests.swift`: Rewritten for 3-tier routing with `mockML` parser
- New tests: ML wins when confident, regex vs ML moderate range, NLP gate, no-ML degradation
- `HybridIngredientParserTests.swift`: Updated `testMediumConfidenceConsultsMLOrNLP` assertion

**ADR 010 Updated**
- Routing diagram: 3-tier (regex → ML → NLP) with thresholds
- Winner-only attribution documented
- File locations updated with MLIngredientParser, ViterbiDecoder, CoreML model

### **Phase 6: Test Suite + Tokenizer Fix** ✅

Comprehensive tests for ML parser, Viterbi decoder, and tokenizer cross-validation.

**ViterbiDecoderTests.swift** (NEW — 15 tests, pure algorithm, no CoreML)
- Empty input, single token, multi-token sequences (2-5 tokens)
- Start/end transition influence on label selection
- Transition overrides vs emission scores
- Backpointer correctness (non-greedy path selection)
- Edge cases: all-equal scores, negative emissions, very large values
- Full 7-label Forager label set (QTY/UNIT/NAME/MODIFIER/PREP/COMMENT/OTHER)

**MLIngredientParserTests.swift** (NEW — 21 tests, requires CoreML model)
- Model presence guard: `XCTAssertNotNil(MLIngredientParser())`
- Standard format regression: cups flour, tbsp olive oil, lb ground beef
- Known regex failure cases: cloves as unit, fractions with compound names, product variants
- Fractions: simple (1/2), unicode (½), mixed fractions
- Complex inputs: parentheticals, comma-separated prep, name-only, single-word
- Confidence range validation, parser attribution, original text preservation
- Tokenizer cross-validation against frozen test vectors (inline subset)
- Performance: 0.84ms per parse (100 parses, well under 5ms target)

**Tokenizer Bug Fix** (discovered by cross-validation tests)
- Fixed `/` between digits being split (fractions: `1/4` → was `["1", "/", "4"]`, now `["1/4"]`)
- Fixed `.` between digits being split (decimals: `14.5` → was `["14", ".", "5"]`, now `["14.5"]`)
- Fixed NFKD combining marks not stripped (`jalapeño` → now correctly `jalapeno`)
- Root cause: Swift tokenizer had punctuation splitting that didn't match Python training tokenizer
- Impact: Model now receives correct token IDs matching what it was trained on

### **Phase 7: Correction Instrumentation** ✅

Wired `logCorrection()` into production edit flows, creating the data foundation for Phase 8's continuous learning pipeline.

**Schema v3** (`ParsingTelemetryService.swift`)
- Added `CorrectionSource` enum: `.editRecipe`, `.createRecipe`, `.groceryListEdit`, `.templateRename`
- Added `parserUsed: String?` and `source: CorrectionSource?` to `ParsingCorrectionEvent`
- Updated `logCorrection()` with new params (nil defaults preserve all existing callsites)
- Bumped `currentSchemaVersion` from 2 → 3
- Added `getTotalCorrectionCount()` convenience method

**IngredientInput original state tracking** (`RecipeFormModels.swift`)
- Added 4 optional fields: `originalFullText`, `originalNumericValue`, `originalStandardUnit`, `originalParseConfidence`
- Enables change detection: compare original vs edited values at save time

**Edit flow wiring** (3 views)
- `EditRecipeView`: Populates originals in `loadRecipeData()`, detects corrections in `completeSave()` via `parseUnified()`
- `CreateRecipeView`: Sets `originalFullText` at add time, detects corrections in `completeSave()` via `parseUnified()`
- `IngredientsView`: Logs corrections in both rename and merge branches of `saveNameEdit()`
- `GroceryListDetailView`: Skipped (no item name editing in UI)

**Corpus gate display** (`SettingsView.swift`)
- Debug-only row showing correction count + gate status ("Need N more" or "Ready for retraining")

**Tests**: 6 new tests (v2 compat decode, v3 encode/decode, CorrectionSource round-trip, schema version check, getTotalCorrectionCount, logCorrection field passthrough)

### **Phase 7.5: Pre-Existing Test Failure Fixes + Test Infrastructure** ✅

Fixed 14+ pre-existing test failures across 7 test classes. Also fixed test runner crashes from test host app lifecycle and CloudKit mirroring on in-memory stores.

**Root causes discovered:**
- Recipe `validateForInsert()` requires non-empty `instructions` (added after test creation)
- IngredientTemplate `validateForInsert()` requires `dateCreated`
- GroceryListItem `displayText` required at Core Data model level (not in Swift types)
- `preferPlural` dict intentionally maps eggs→eggs, tomatoes→tomatoes
- 3-tier routing (0.9 threshold) sends medium-confidence to ML parser
- Core Data property renames: name→title, quantity→numericValue, weekStart→dateCreated
- Test host app rendering full TabView with `@FetchRequest` against unconfigured stores
- CloudKit mirroring delegates on in-memory test stores causing teardown crashes

**Files modified (7 test files):**
- `RecipeServiceTests.swift` — instructions + @MainActor tearDown
- `CoreDataInvariantsTests.swift` — instructions, dateCreated, resetSeedingStatus
- `ParsingIntegrationTests.swift` — instructions, "cup" assertion, @MainActor tearDown
- `IngredientTemplateNormalizationTests.swift` — preferPlural assertions
- `HybridIngredientParserTests.swift` — parser-agnostic assertions
- `MigrationValidationTests.swift` — property name corrections
- `WeeklyListServiceTests.swift` — displayText + @MainActor tearDown

### **Phase 8: Continuous Learning Pipeline** ✅

Closed the feedback loop: correction export + retraining script.

**Shared tokenizer extraction:**
- Extracted `foragerTokenize()` from `MLIngredientParser` into `IngredientTokenizer.swift`
- Ensures token consistency between ML inference and correction export
- `MLIngredientParser.tokenize()` now delegates to shared function

**Correction export (`ParsingTelemetryService.exportCorrectionsAsTrainingData()`):**
- Synthetic reconstruction from corrected fields (QTY/UNIT/NAME labels)
- Quality filter: skips no-op corrections and empty names
- Output: JSONL matching Phase 1 training data schema
- 6 new tests (TEST-TEL-032 through TEST-TEL-037), all passing

**Python retraining script (`Tools/ml-training/retrain_with_corrections.py`):**
- Fine-tunes from existing checkpoint (lower LR: 0.0005 vs 0.001)
- Auto-oversampling (up to 50x) to give corrections meaningful influence
- Improvement gate: saves retrained model only if both primary metrics improve
- Reuses all infrastructure from `train_model.py`

### **Phase 9: Integration Testing & Documentation** ✅

Final validation and milestone documentation.

**8 end-to-end integration tests added to `ParsingIntegrationTests.swift`:**
1. Quick-add "3 cloves garlic" → qty=3, unit=clove, template created
2. Quick-add "milk 2%" → name contains "milk"
3. Recipe "1/4 tsp black pepper" → qty=0.25, unit=tsp, template contains "pepper"
4. Recipe "a handful of fresh cilantro" → name contains "cilantro"
5. Quick-add "bananas" → plural preserved, template created
6. Bulk add 4 ingredients → all parsed, templates assigned, sort order preserved
7. Recipe scaling 2x → parseable ingredients auto-scaled, servings doubled
8. Edit recipe → structured fields updated, template reference preserved

**Documentation:**
- Learning note 38: ML parsing + CoreML integration
- CLAUDE.md: Parser architecture section, updated test count (259), ADR 010 description
- All 7 core docs updated for milestone completion

### **Commits**
1. `dd332c9` — M8.4 Phase 0: Contract lock + single-parse refactor
2. `e39b098` — M8.4 Phase 1: Dataset preparation pipeline
3. `ce98e43` — M8.4 Phase 2: BiLSTM-CRF model training pipeline
4. `6c37b28` — M8.4 Phase 3: CoreML conversion + Viterbi parity gate
5. (pending) — M8.4 Phase 4: ViterbiDecoder + MLIngredientParser
6. (pending) — M8.4 Phase 5: HybridIngredientParser 3-tier integration

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build with CoreML model + JSON resources |
| Existing tests | ✅ ALL PASSING | 259/259 unit tests, 0 failures, TEST SUCCEEDED (251 + 8 Phase 9 integration tests) |
| Dataset integrity | ✅ VERIFIED | No cross-split leakage, all labels mapped |
| Fraction decoding | ✅ VERIFIED | Mixed, prefixed, simple, range patterns all correct |
| Model training | ✅ ALL TARGETS MET | Token 98.49% ≥96%, Sentence 95.40% ≥92%, all F1 ≥0.90 |
| Model size | ✅ 5.2 MB checkpoint | Under 10 MB budget |
| CoreML conversion | ✅ 5.15 MB | Emissions match PyTorch within 4.77e-06 |
| Viterbi parity gate | ✅ 100.0000% | 8,030/8,030 tokens, 1,000/1,000 sentences |
| Xcode integration | ✅ BUILD SUCCEEDED | .mlpackage compiled, JSON in bundle |
| ViterbiDecoder | ✅ BUILD SUCCEEDED | Compiles, matches PRD + Python reference |
| MLIngredientParser | ✅ BUILD SUCCEEDED | Full pipeline compiles, IngredientParser protocol |
| 3-tier routing | ✅ BUILD SUCCEEDED | HybridIngredientParser with ML tier, winner-only attribution |
| Test target | ✅ TEST BUILD SUCCEEDED | Updated routing tests compile with 3-tier assertions |
| ViterbiDecoderTests | ✅ 15/15 PASSING | Pure algorithm tests, no CoreML dependency |
| MLIngredientParserTests | ✅ 21/21 PASSING | Model presence guard, accuracy, tokenizer, performance |
| ML parse performance | ✅ 0.84ms/parse | Well under 5ms target (100 parses steady-state) |
| Tokenizer cross-validation | ✅ PASSING | Inline vectors match after fraction/decimal/NFKD fix |

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `Services/IngredientParsingService.swift` | MODIFIED | +parseCore(), +parseUnified(), +static mappers, refactored parseAndConnectIngredients |
| `forager/GroceryListDetailView.swift` | MODIFIED | Single-parse refactor (eliminated double parse) |
| `forager/AddListItemView.swift` | MODIFIED | Single-parse refactor |
| `forager/RecipeListView.swift` | MODIFIED | Single-parse refactor |
| `Tools/ml-training/TOKENIZER_SPEC.md` | NEW | Tokenizer contract (frozen) |
| `Tools/ml-training/prepare_dataset.py` | NEW | Dataset preparation pipeline (335 lines) |
| `Tools/ml-training/data/tokenizer_test_vectors.json` | NEW | 100 cross-validation sentences |
| `Tools/ml-training/data/dataset_statistics.json` | NEW | Distribution and split metadata |
| `Tools/ml-training/MODEL_CARD.md` | NEW | Model card template |
| `Tools/ml-training/LICENSES.md` | NEW | License attribution (MIT/Apache 2.0) |
| `Tools/ml-training/README.md` | NEW | Training infrastructure overview |
| `Tools/ml-training/requirements.txt` | NEW | Python dependencies |
| `.gitignore` | MODIFIED | +data/model artifact exclusions |
| `Tools/ml-training/train_model.py` | NEW | BiLSTM-CRF training pipeline (340 lines) |
| `Tools/ml-training/convert_to_coreml.py` | NEW | CoreML conversion + Viterbi parity gate (283 lines) |
| `Tools/ml-training/parity_report.md` | NEW | Viterbi parity gate results |
| `forager/IngredientTaggerEmissions.mlpackage` | NEW | CoreML emission scorer (5.15 MB) |
| `forager/MLModel/transitions.json` | NEW | CRF transition parameters (copy for bundle) |
| `forager/MLModel/vocabulary.json` | NEW | Token vocabulary (copy for bundle) |
| `forager.xcodeproj/project.pbxproj` | MODIFIED | +mlpackage in Sources, +JSON in Resources |
| `Services/Parsing/ViterbiDecoder.swift` | NEW | Pure-Swift Viterbi decoder (~70 lines) |
| `Services/Parsing/MLIngredientParser.swift` | NEW | ML parser: tokenize → CoreML → Viterbi → result (~300 lines) |
| `Services/Parsing/HybridIngredientParser.swift` | MODIFIED | 3-tier routing, mlParser param, winner-only attribution |
| `Services/Parsing/IngredientParser.swift` | MODIFIED | Protocol/parserUsed comment updates for ML tier |
| `Services/ParsingTelemetryService.swift` | MODIFIED | parserUsed comment update (winner-only) |
| `forager/foragerApp.swift` | MODIFIED | CoreML warmup in init() |
| `docs/architecture/010-hybrid-parser-confidence-routing.md` | MODIFIED | 3-tier routing, winner-only attribution |
| `foragerTests/Services/Parsing/HybridParserRoutingTests.swift` | MODIFIED | Rewritten for 3-tier with mockML |
| `foragerTests/Services/Parsing/HybridIngredientParserTests.swift` | MODIFIED | Winner-only assertion update |
| `foragerTests/Services/Parsing/ViterbiDecoderTests.swift` | NEW | 15 pure algorithm tests |
| `foragerTests/Services/Parsing/MLIngredientParserTests.swift` | NEW | 21 integration tests (model + tokenizer + perf) |
| `Services/Parsing/MLIngredientParser.swift` | MODIFIED | Tokenizer fix: fraction/decimal/NFKD combining marks |

---

## ✅ **M9.5-partial: PARSER DEPENDENCY INJECTION - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 21, 2026 (session 23)
**Branch**: `feature/M9.5-parser-di`
**PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md` (M9.5-partial section)

### **What Was Delivered** ✅

Made parser construction injectable with backward-compatible defaults so M8.4 can add an ML parser to the chain without modifying existing code.

**Phase A: HybridIngredientParser DI**
- Converted hardcoded sub-parsers to injectable init parameters
- `regexParser: IngredientParser = RegexIngredientParser()`
- `nlpParser: IngredientParser = NLPIngredientParser()`
- `regexConfidenceThreshold: Float = 0.8` (instance property, was static)
- M8.4 breadcrumb comment for future `mlParser` parameter

**Phase B: IngredientParsingService DI**
- Added `parser: IngredientParser = HybridIngredientParser()` to init
- Static `extractCleanIngredientName()` unchanged (keeps own sharedParser)
- All 11 existing instantiation sites continue working unchanged

**Phase C: MockIngredientParser + Routing Tests**
- Created `foragerTests/Mocks/` directory (new PBXGroup in pbxproj)
- `MockIngredientParser`: configurable results, call tracking, preset injection
- `HybridParserRoutingTests`: 8 tests covering routing logic with mocks
- Tests: high-confidence short-circuit, NLP fallback, custom threshold, zero-confidence, call tracking, backward compat

**Phase D: Demo Injection Test**
- Added `testMockParserInjectionThroughFullChain` to ParsingIntegrationTests
- Demonstrates: MockIngredientParser → IngredientParsingService → verified output

**Phase E: QuantityMigrationService DI (Optional)**
- Added optional `parsingService` parameter with backward-compatible default
- `MigrationDebugView.swift:22` uses default (no change needed)

**PRD Corrections Applied:**
- M9 PRD: Phase E caller fix, time estimates, Mocks dir note, breadcrumb comment, post-M9.5 action item
- M8.4 PRD: Phase 5 uses protocol type `IngredientParser?` (not concrete `MLIngredientParser?`)

### **Commits**
1. `45e2dc3` — M9.5: Add parser dependency injection with backward-compatible defaults

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ ZERO WARNINGS | Clean build, BUILD SUCCEEDED |
| Routing tests | ✅ 8 PASSING | All new routing tests green |
| Existing tests | ✅ 127 PASSING | No regressions (5 pre-existing failures unchanged) |
| Demo injection | ✅ COMPILES | Mock flows through full chain correctly |

---

## ✅ **M9.1.2: CENTRALIZE extractCleanIngredientName - COMPLETE**

**Status**: ✅ **COMPLETE**
**Sessions**: February 21, 2026 (sessions 21-22)
**Branch**: `feature/M9.1.2-centralize-extract-clean-name` (PR pending)
**PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md` (Phase 1, M9.1 task 3)

### **What Was Delivered** ✅

Centralized two diverging `extractCleanIngredientName(from:)` implementations into a single static method on `IngredientParsingService` that delegates to the `HybridIngredientParser`.

**Core Change:**
- Added `static func extractCleanIngredientName(from:)` to `IngredientParsingService` (10 lines)
- Uses `static let sharedParser = HybridIngredientParser()` (thread-safe, lazy atomic)
- Replaced 40-line regex in AddIngredientsToListView (7 pattern groups, qualifier stripping)
- Replaced 18-line regex in MealPlanDetailView (2 pattern groups, no qualifier stripping)
- ~58 lines of hand-rolled regex deleted
- Fixed merge comparison in `findExistingItem()` to normalize both sides (was normalizing target but not existing item names)

**Unit Tests:** 12 tests in `IngredientParsingServiceCleanNameTests.swift` — standard measurements, fractions, unicode, count units, parentheticals, qualifiers, edge cases.

### **Commits**
1. `91f8fde` — M9.1.2: Centralize extractCleanIngredientName via parser delegation
2. `d9f7002` — M9.1.2: Update insights log and development journal
3. `f4c56ed` — M9.1.2: Fix merge comparison to normalize both sides

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ ZERO WARNINGS | Clean build, BUILD SUCCEEDED |
| Unit tests | ✅ 12 PASSING | Clean name extraction tests |
| Existing tests | ✅ ALL PASSING | No regressions |

---

## ✅ **M9.0: WARNING RESOLUTION - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 21, 2026
**Branch**: `feature/M9.0-warning-resolution` → merged to main (PR #41)
**PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md` (Phase 0)

### **What Was Delivered** ✅

Zero-warning build baseline established. All 18 compiler warnings resolved across 7 source files.

**Group A: Deprecated CloudKit APIs (2 warnings)**
- Removed `discoverUserIdentity` and `userIdentity(forUserRecordID:)` — deprecated in iOS 17 with no replacement
- Simplified `getCurrentUserInfo()` from 57-line continuation to 2-line async call
- Removed "Try 1" block from `refreshDisplayName()`, renumbered remaining tries

**Group B: Unused Variables (8 warnings)**
- Removed unused `householdName` in `leaveHousehold()` and `deleteHousehold()`
- Removed unused `originalCompleted`/`originalDate` in GroceryListDetailView
- Changed `if let` to `if != nil` for 2 unused bindings in DatePickerSheet
- Removed unused `targetCategoryID` in ManageCategoriesView
- Changed unused `storeID` to `_` in HouseholdScopeProvider debug util

**Group C: Unnecessary `await` (3 warnings)**
- Removed `await` from `onStatus()` calls and `fetchShares(matching:)` in `@MainActor` class

**Group D: Non-exhaustive Switch (2 warnings)**
- Added `case .available:` to CKAccountStatus switch
- Added `case .unknown:` to CKShare.ParticipantAcceptanceStatus switch

**Group E: Code Quality (3 warnings)**
- Changed `var result` to `let result` in IngredientTemplateService
- Removed redundant `as! NSPersistentCloudKitContainer` cast
- Added `_ =` to `withAnimation` result in auto-collapse

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ ZERO WARNINGS | Clean build, BUILD SUCCEEDED |
| App launch | ✅ | Household features still work |

---

## ✅ **M7.5: ARCHITECTURE HARDENING - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 20, 2026
**Branch**: `feature/M7.5-service-ownership` → merged to main (PR #39)
**PRD**: `docs/prds/complete/m7.5-architecture-hardening-ux-service-cleanup.md`

### **What Was Delivered** ✅

Complete architecture hardening across 3 phases — service layer ownership, navigation cleanup, and test/polish.

**Phase 1: Service Ownership of Saves**
- Created `RecipeService` and `WeeklyListService`; extended `IngredientTemplateService`
- 24 unit tests across 3 test files
- Integration tests for parse → service → persist pipeline
- 35 direct `context.save()` calls eliminated from 13 production views

**Phase 2: Navigation Cleanup**
- 3 highest-complexity views converted to enum-based sheet/alert routing
- IngredientsView, CreateRecipeView, EditRecipeView

**Phase 3: Tests & Polish**
- 2 remaining ad-hoc empty states → `ContentUnavailableView`
- 5 Core Data invariant tests

### **Commits**
1. `f1b96aa` — M7.5: Create RecipeService, WeeklyListService, extend IngredientTemplateService
2. `a227b4c` — M7.5: Add service unit tests — 24 tests across 3 test files
3. `24595a8` — M7.5: Add integration tests for parse → service → persist pipeline
4. `cf81f65` — M7.5: Wire 13 production views to service layer, eliminate 35 direct saves
5. `ea75dcf` — M7.5: Convert 3 views to enum-based sheet/alert routing
6. `b913fe3` — M7.5: Add empty state cleanup and Core Data invariant tests

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean builds across all phases |
| Unit tests | ✅ 24 PASSING | Service unit tests |
| Integration | ✅ PASSING | Parse → service → persist pipeline |
| Invariant tests | ✅ 5 PASSING | Core Data relationship integrity |

---

## ✅ **M15 TESTING BUG FIXES - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 20, 2026
**Branch**: `feature/M15-ux-design-system`
**PRD**: `docs/prds/complete/m15-testing-bug-fixes.md`

### **Context**
User testing on M15.5b build revealed 12 issues across parsing, display, data propagation, and styling.

### **Commits**
1. ✅ **Fix EditRecipeView structured quantity loss (P0)** — Added `parseToStructured()` in completeSave()
2. ✅ **Remove redundant quantity displays (P1)** — Removed right-aligned displayText in grocery list, fixed recipe ingredient rows
3. ✅ **Fix takeout strikethrough + SettingsView dark mode (P1)** — Added strikethrough to quick options, warm background for Settings
4. ✅ **Template name sanitization (P1)** — Phase 0 sanitization in normalize(), fixed extractCleanIngredientName() regexes, wired up re-normalization
5. ✅ **Fix category chip refresh (P1)** — refreshAllObjects() on appear to force relationship-derived data refresh
6. ✅ **Fix code review findings** — Hardcoded shadow color → ForagerTheme token, silent delete error → user-facing alert, stale "6 test recipes" comment
7. ✅ **Fix bananas pluralization and milk 2% false review flag** — Added 10 entries to preferPlural, product variant exception in needsReview

### **Not Changing (Documented Decisions)**
- Title centering: iOS platform convention (left-aligned large titles)
- Template → grocery item name propagation: Point-in-time snapshot by design

---

## 🔄 **M8.4: ML-POWERED PARSING - ACTIVE (Details)**

**Status**: 🔄 **ACTIVE** — Phase 0+1 ✅ COMPLETE
**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md`
**Estimated**: 23-32 hours (10 phases including Phase 0 feasibility gate) + 9 hours M9 prerequisites (complete)
**Actual so far**: ~7h (Phase 0-3)
**Approach**: Dataset-bootstrapped CoreML BiLSTM-CRF sequence labeler (word-only v1)
**External Review**: 12 review passes (9 external, 3 internal) — 60 findings integrated + priority validation pass

### **Phase Progress**

| Phase | Description | Est. | Status |
|-------|-------------|------|--------|
| 0 | Contract Lock + Single-Parse Refactor | 2-3h | ✅ COMPLETE |
| 1 | Dataset Preparation Pipeline | 3-4h | ✅ COMPLETE |
| 2 | Model Architecture & Training | 4-5h | ✅ COMPLETE |
| 3 | CoreML Conversion | 2-3h | ✅ COMPLETE |
| 4 | MLIngredientParser Implementation | 3-4h | ✅ COMPLETE |
| 5 | HybridIngredientParser Integration | 2-3h | ✅ COMPLETE |
| 6 | Test Suite + Tokenizer Fix | 2-3h | ✅ COMPLETE |
| 7 | Correction Instrumentation | 2-3h | ⏳ |
| 8 | Continuous Learning Pipeline | 2h | ⏳ |
| 9 | Integration Testing & Documentation | 1-2h | ⏳ |

### **Prerequisites (M9 subset) — ALL COMPLETE**
1. ~~M9.0: Warning resolution (2-3h)~~ — ✅ COMPLETE (<1h actual, Feb 21)
2. ~~M9.1.2: Centralize extractCleanIngredientName (2-3h)~~ — ✅ COMPLETE (~2h actual, Feb 21)
3. ~~M9.5-partial: Parser dependency injection (4h)~~ — ✅ COMPLETE (~3h actual, Feb 21)

### **Execution Order**
M7.5 ✅ → M9 Prerequisites ✅ → M8.4 Phases 0-6 ✅ → **Phase 7 NEXT** → Phases 8-9 → M7.7 App Store

---

## ✅ **M15.7: DARK MODE, ACCESSIBILITY & FINAL QA - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Final accessibility and polish pass across the entire M15 design system — dark mode glass rim light, empty state modernization, VoiceOver labels, Dynamic Type scaling, and Reduce Motion guards.

**Sub-Phases Completed:**
- **A**: Dark mode glass rim light — added subtle 0.08-opacity white overlay inside glass cards for edge definition in dark mode. Applied to both `.foragerGlassCard()` and `.foragerProminentGlassCard()` in ForagerCard.swift
- **B**: Empty state replacement — replaced custom `StandardEmptyStateView` with native `ContentUnavailableView` across 5 views (IngredientsView, MealPlanListView, RecipeListView, UnifiedSearchView, WeeklyListsView). Deleted `StandardEmptyStateView.swift` and cleaned 4 pbxproj references
- **C**: VoiceOver accessibility labels — comprehensive audit and labeling of all interactive elements: grocery list rows, grocery items (name + checked state + toggle hint), quick-add field, celebration banner, recipe cards (title + favorite state + view hint), filter/scale pills (label + selection state), meal plan summary cards (name + date range + days + open hint), day dots (schedule summary), action buttons (Done/Swap/Remove hints), quick-select pills, ingredient category pills, review banner, ingredient rows (name + category + staple status)
- **D**: Dynamic Type scaling — `@ScaledMetric` on ForagerProgressRing (56pt ring) and MealPlanSummaryCard day circles (22pt). Changed MealPlanListView tonight snippet from `.lineLimit(1)` to `.lineLimit(2).minimumScaleFactor(0.8)`
- **E**: Reduce Motion guards — added `@Environment(\.accessibilityReduceMotion)` to 10 view structs (ForagerProgressRing, GroceryListDetailView, GroceryListItemRow, RecipeListView, RecipeDetailView, IngredientsView, IngredientReviewSheet, MealPlanDetailView, WeeklyListsView, UnifiedSearchView). All spring/slide animations guarded with `reduceMotion ? nil : .animation(...)` pattern. State-change animations use `.easeInOut(duration: 0.15)` crossfade instead

**Skipped Sub-Phases (manual/visual tasks — deferred to testing session):**
- **F**: Glass contrast WCAG verification — requires visual walkthrough in simulator
- **G**: Performance profiling — requires Instruments.app 60fps validation

### **Files Modified/Deleted**

| File | Status | Notes |
|------|--------|-------|
| `forager/ForagerCard.swift` | MODIFIED | Dark mode rim light overlay |
| `forager/StandardEmptyStateView.swift` | DELETED | Replaced by ContentUnavailableView |
| `forager/IngredientsView.swift` | MODIFIED | ContentUnavailableView, accessibility, reduce motion |
| `forager/MealPlanListView.swift` | MODIFIED | ContentUnavailableView, accessibility, Dynamic Type |
| `forager/RecipeListView.swift` | MODIFIED | ContentUnavailableView, accessibility, reduce motion |
| `forager/UnifiedSearchView.swift` | MODIFIED | ContentUnavailableView, reduce motion |
| `forager/WeeklyListsView.swift` | MODIFIED | ContentUnavailableView, accessibility, reduce motion |
| `forager/GroceryListDetailView.swift` | MODIFIED | Accessibility labels, reduce motion |
| `forager/MealPlanDetailView.swift` | MODIFIED | Accessibility hints, reduce motion |
| `forager/ForagerProgressRing.swift` | MODIFIED | @ScaledMetric, reduce motion |
| `forager.xcodeproj/project.pbxproj` | MODIFIED | Removed 4 StandardEmptyStateView references |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | 5 clean builds (one per sub-phase) |
| VoiceOver | ✅ COMPILED | All labels, values, hints compile correctly |
| Dynamic Type | ✅ COMPILED | @ScaledMetric on ring + day circles |
| Reduce Motion | ✅ COMPILED | All 10 view structs guarded |
| Empty states | ✅ COMPILED | ContentUnavailableView on 5 views |

---

## ✅ **M15.6: LIQUID GLASS POLISH - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Applied iOS 26 Liquid Glass effects across the app, replacing shadow-based depth with glass refraction on cards and floating elements. Tab bar now minimizes on scroll for content immersion.

**Sub-Phases Completed:**
- **A**: Glass card helpers — `.foragerGlassCard()` (regular glass, radius.md) and `.foragerProminentGlassCard()` (larger radius.lg) added to ForagerCard.swift. API validation: `Glass` type has `.regular`/`.clear`/`.identity` (no `.prominent` — differs from WWDC docs)
- **B**: Glass on card views — WeeklyListsView, RecipeListView, MealPlanListView, MealPlanDetailView all switched from `.foragerCard()` to `.foragerGlassCard()`. Loading/progress overlays use direct `.glassEffect()`. Shadows removed from glass-effected views
- **C**: Glass on floating elements — autocomplete dropdowns (GroceryListDetailView, AddListItemView, EditRecipeView, CreateRecipeView) use `.glassEffect(.regular)`. Shadow removed from IngredientsView ingredient rows and SettingsView household creation overlay
- **D**: Button glass evaluation — **Decision: Keep current styling.** `.buttonStyle(.glass)` would override semantic color states on Done/Swap/Remove action buttons. Quick-select pills use themed background fills that communicate secondary-action nature. Glass buttons lack semantic color communication
- **E**: Tab bar — `.tabBarMinimizeBehavior(.onScrollDown)` added to TabView for content immersion
- **Skipped**: App icon (requires Xcode Icon Composer GUI — deferred to manual session)

### **Key API Discovery**
- `Glass` type: `.regular`, `.clear`, `.identity` — no `.prominent` variant
- `.glassEffect(.regular, in: Shape)` — standard API, shape parameter required for custom geometry
- `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` — available but not adopted (see decision above)
- `.tabBarMinimizeBehavior(.onScrollDown)` — works as documented

### **Files Modified**

| File | Status | Notes |
|------|--------|-------|
| `forager/ForagerCard.swift` | MODIFIED | +foragerGlassCard(), +foragerProminentGlassCard() |
| `forager/WeeklyListsView.swift` | MODIFIED | Glass card + glass loading overlay |
| `forager/RecipeListView.swift` | MODIFIED | Glass recipe cards |
| `forager/MealPlanListView.swift` | MODIFIED | Glass summary cards |
| `forager/MealPlanDetailView.swift` | MODIFIED | Glass day cards + glass progress overlay |
| `forager/GroceryListDetailView.swift` | MODIFIED | Glass autocomplete dropdown |
| `forager/AddListItemView.swift` | MODIFIED | Glass autocomplete dropdown |
| `forager/EditRecipeView.swift` | MODIFIED | Glass autocomplete dropdown |
| `forager/CreateRecipeView.swift` | MODIFIED | Glass autocomplete dropdown |
| `forager/IngredientsView.swift` | MODIFIED | Shadow removed from ingredient rows |
| `forager/SettingsView.swift` | MODIFIED | Glass on household creation overlay |
| `forager/foragerApp.swift` | MODIFIED | Tab bar minimize on scroll |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | 4 clean builds (one per sub-phase) |
| Glass API | ✅ COMPILED | .glassEffect(.regular) verified on iOS 26 |
| Tab bar | ✅ COMPILED | .tabBarMinimizeBehavior(.onScrollDown) |
| Shadow audit | ✅ CLEAN | Only MigrationDebugView + ForagerCard fallback retain shadows |

---

## ✅ **M15.5b: SETTINGS, CATEGORIES & HOUSEHOLD VISUAL REDESIGN - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Extracted HouseholdView from SettingsView, restructured Settings with NavigationLink + version footer, and polished ManageCategoriesView with nav bar `+`, lock icon, and footer help text.

**Sub-Phases Completed:**
- **A**: HouseholdView extracted — dedicated screen with editable name, iCloud sync indicator, inline member rows with avatar circles/role badges, NavigationLink to HouseholdMembersView, invite section (ForagerPrimaryButtonStyle), sharing stats (Core Data count queries for recipes/lists/plans), Danger Zone (leave/delete with migration options), no-household CTA
- **B**: SettingsView restructured (867 → 549 lines) — replaced ~215-line inline household section with NavigationLink to HouseholdView, removed ~15 household @State variables, removed 5 helper methods, added version footer using Bundle.main.infoDictionary
- **C**: ManageCategoriesView polished — nav bar `+` button (alongside Reorder), removed inline "Add Custom Category" button, added footer help text ("Drag categories to reorder. Swipe left to delete…"), lock icon on Uncategorized row, hidden drag handle for default categories

**Additional Changes:**
- Async data loading via `.task` for `isOwner`, `getParticipants`, `getOwnerParticipant`
- `ForagerPrimaryButtonStyle` for invite button
- Core Data count queries for sharing stats (no new service methods needed)
- Version footer: `Forager v{version} ({build})` using CFBundleShortVersionString/CFBundleVersion

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `forager/HouseholdView.swift` | NEW | Dedicated household management screen (~340 lines) |
| `forager/SettingsView.swift` | MODIFIED | 867 → 549 lines, NavigationLink to HouseholdView |
| `forager/ManageCategoriesView.swift` | MODIFIED | Nav bar +, lock icon, footer text |
| `forager.xcodeproj/project.pbxproj` | MODIFIED | +4 entries for HouseholdView.swift |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build after all sub-phases |
| HouseholdView | ✅ COMPILED | Async loading, member rows, sharing stats, alerts |
| SettingsView | ✅ COMPILED | NavigationLink, version footer, reduced state |
| ManageCategoriesView | ✅ COMPILED | Nav bar +, lock icon, footer text |

---

## ✅ **M15.5: MEAL PLANS & INGREDIENTS UX - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Complete UX overhaul of meal plans and ingredients views — from flat lists to card-based layouts with day dots, horizontal day strip, quick-select pills, category filter pills, and guided ingredient review.

**Sub-Phases Completed:**
- **A.0**: Core Data v6 migration — added `quickOption: String?` to PlannedMeal entity with `QuickOption` enum (Takeout, Dining Out, Leftovers, No Meal)
- **A**: MealPlansListView rewritten — summary cards with lettered day dots, Tonight snippet (recipe or quick option), Generate Grocery List button on active plans, 4px green left border on active, 60% opacity on completed, DisclosureGroup for completed plans
- **B**: MealPlanDetailView rewritten — horizontal day strip with ScrollViewReader auto-scroll to today, centered day headers with TODAY badge, planned/unplanned day cards, action buttons (Done with haptics / Swap / Remove with confirmation), recipe picker sheet, quick-select pills (Takeout/Dining Out/Leftovers/No Meal) with dashed border, sticky bottom "Add to Grocery List" button
- **C**: IngredientsView overhauled — individual category filter pills replacing dropdown menu, sort moved to toolbar Menu, ForagerSectionHeader replacing emoji category headers, 4px category-colored left-border strip on rows, usage badge (Nx), "Staple" label, ForagerTheme tokens throughout
- **D**: Ingredient review banner (warning background, count, "Review Now" button), guided review sheet (one-at-a-time triage with progress bar, reason badge, editable name, category Menu picker, staple toggle, Save & Next / Skip), staples summary header with count

**Additional Changes:**
- `PlannedMeal.QuickOption` enum with SF Symbol icons (bag, fork.knife, refrigerator, moon.zzz)
- `MealPlanService.setQuickOption(_:for:in:)` for non-recipe day planning
- `MealPlanSummaryCard` replaces `MealPlanRowView` (now dead code)
- `MealPlanStatus` enum with ForagerTheme colors
- `IngredientReviewSheet` with `reviewReason(for:)` explaining why each ingredient needs review

### **Files Modified**

| File | Status | Notes |
|------|--------|-------|
| `forager 6.xcdatamodel/contents` | CREATED | Core Data v6 — quickOption on PlannedMeal |
| `PlannedMeal+CoreDataProperties.swift` | MODIFIED | +quickOption: String? |
| `PlannedMeal+Extensions.swift` | MODIFIED | +QuickOption enum, isQuickOption, quickOptionEnum |
| `Services/MealPlanService.swift` | MODIFIED | +setQuickOption method |
| `forager/MealPlanListView.swift` | REWRITTEN | Summary cards with day dots, Tonight snippet |
| `forager/MealPlanDetailView.swift` | REWRITTEN | Day strip, action buttons, recipe picker, quick-select |
| `forager/IngredientsView.swift` | REWRITTEN | Category pills, sort toolbar, review banner/sheet |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | 5 clean builds (one per sub-phase) |
| Core Data v6 | ✅ COMPILED | Lightweight migration, quickOption field |
| Summary cards | ✅ COMPILED | Day dots, Tonight snippet, Generate button |
| Day strip | ✅ COMPILED | ScrollViewReader, action buttons, quick-select |
| Category pills | ✅ COMPILED | FilterPill per category, sort menu |
| Review sheet | ✅ COMPILED | Progress bar, reason badge, category picker |

---

## ✅ **M15.4: RECIPES UX OVERHAUL - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Complete UX overhaul of recipe browsing and detail views — from flat lists with system colors to card-based layouts with timing pills, inline scaling, and numbered instructions.

**Sub-Phases Completed:**
- **A**: Card-based recipe list with timing pills, ForagerCard rows, filter pills (All/Favorites/Recent), sort menu (Recent/A-Z/Most Used), `.searchable` modifier, ForagerTheme tokens throughout
- **B**: Hero detail header — 28pt bold title, compact timing row (clock/flame/timer), simplified nav bar (Edit text + ellipsis menu with Add to Meal Plan, Mark as Made, Delete)
- **C**: Inline scale pills — 6 presets (0.5×–3×) + custom two-component picker (whole + fraction), dynamic servings count next to INGREDIENTS header
- **D**: Flat ingredient layout — monospaced digits for quantities, confidence-colored bullets (green high / amber low), no category grouping
- **E**: Dynamic CTA ("Add to Grocery List" / "Add to Grocery List · N servings"), numbered instructions with accent step numbers, `cleanStepText()` regex, collapsible usage footer via DisclosureGroup

**Additional Changes:**
- RecipeScalingView modal replaced by inline scale pills (modal no longer presented)
- `RecipeFilter` and `RecipeSortOrder` enums added for list filtering/sorting
- `RecipeCardView` replaces `EnhancedRecipeRowView` with timing pills and favorite heart
- `SearchMatchType` colors migrated to ForagerTheme tokens
- Delete recipe added to ellipsis menu with confirmation dialog

### **Files Modified**

| File | Status | Notes |
|------|--------|-------|
| `forager/RecipeListView.swift` | REWRITTEN | Card list + detail view completely overhauled |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build after both commits |
| Card layout | ✅ COMPILED | Timing pills, filter pills, sort menu |
| Hero header | ✅ COMPILED | Compact timing, favorite heart, simplified nav |
| Scale pills | ✅ COMPILED | 6 presets + custom picker, dynamic servings |
| Ingredients | ✅ COMPILED | Monospaced digits, confidence bullets, flat layout |
| Instructions | ✅ COMPILED | Numbered steps, accent prefix, cleanStepText regex |
| CTA button | ✅ COMPILED | Dynamic label with scaled servings |

---

## ✅ **M15.3: GROCERY LISTS UX OVERHAUL - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Comprehensive UX overhaul of the grocery list experience — the primary daily workflow — from flat lists into card-based layouts with progress rings, collapsible sections, haptics, and celebration.

**Sub-Phases Completed:**
- **A**: 7 shared components created — ForagerCard, ForagerProgressRing, ForagerSectionHeader, CategoryChipPills, FlowLayout, FilterPill (shared, replaces embedded version), ForagerButtonStyles
- **B**: WeeklyListsView rewritten — card-based layout with progress rings, category chip pills, 3-option creation dialog (From Staples / From Meal Plan / Empty List), MealPlanGrocerySheet
- **C**: Sticky bottom progress bar — `.safeAreaInset(edge: .bottom)` with 6pt capsule bar, color shift (accentPrimary → accentSecondary → statusSuccessFG), quick-add TextField moved to bottom
- **D**: Collapsible category sections — ForagerSectionHeader with collapse chevron, auto-collapse after 2s for completed categories
- **E**: Check-off haptics and animation — medium/light impact feedback, spring animations, checkbox scale (1.1x), strikethrough + color shift, monospacedDigit quantities, recipe badges with ForagerTheme tokens
- **F**: 100% completion celebration — banner with success haptic, 3s auto-dismiss, progress bar color shift at 100%

**Additional Changes:**
- `MealPlanService.generateGroceryList(from:)` added for "From Meal Plan" creation option
- Shared `FilterPill` extracted from IngredientsView, 4 callers updated
- All 7 new files registered in pbxproj (4 entries each)

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `forager/ForagerCard.swift` | NEW | `.foragerCard()` ViewModifier |
| `forager/ForagerProgressRing.swift` | NEW | 56pt circular progress ring |
| `forager/ForagerSectionHeader.swift` | NEW | Collapsible section header |
| `forager/CategoryChipPills.swift` | NEW | Category composition pills |
| `forager/FlowLayout.swift` | NEW | Custom Layout protocol |
| `forager/FilterPill.swift` | NEW | Shared filter pill (3 sizes) |
| `forager/ForagerButtonStyles.swift` | NEW | Primary/Secondary/Tertiary styles |
| `forager/WeeklyListsView.swift` | REWRITTEN | Card layout, 3-option creation |
| `forager/GroceryListDetailView.swift` | REWRITTEN | Sticky bar, collapsible, haptics, celebration |
| `forager/IngredientsView.swift` | MODIFIED | Deleted embedded FilterPill |
| `Services/MealPlanService.swift` | MODIFIED | +generateGroceryList(from:) |
| `forager.xcodeproj/project.pbxproj` | MODIFIED | 7 new file registrations |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build after every sub-phase (4 builds) |
| Shared components | ✅ COMPILED | All 7 components compile and register |
| Card layout | ✅ COMPILED | Progress rings + category chips render |
| Sticky bottom bar | ✅ COMPILED | .safeAreaInset participates in safe area |
| Collapsible sections | ✅ COMPILED | Toggle + auto-collapse logic in place |
| Haptics + celebration | ✅ COMPILED | UIImpactFeedbackGenerator + UINotificationFeedbackGenerator |

---

## ✅ **M15.2: COLOR & TYPOGRAPHY MIGRATION - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

Mechanical migration of ~300+ hardcoded color, typography, and radius values to ForagerTheme semantic tokens across ~25 files.

**Sub-Phases Completed:**
- **A**: categoryColor consolidation into ForagerTheme
- **B**: Grocery item views (AddGroceryItemView, RecipeDetailView)
- **C**: Recipe views (AddRecipeSheet, EditRecipeSheet, RecipeIngredientRow, RecipeIngredientEditRow)
- **D+E**: Meal plan & category views (8 files)
- **F**: Settings & household views (7 files)
- **G**: Shared components (StandardEmptyStateView, UnifiedSearchView, OnboardingView)
- **H**: Debug views (4 files) + straggler staple views (2 files)

**Key Patterns Applied:**
- `.foregroundColor(.blue)` → `.foregroundStyle(ForagerTheme.accentPrimary)` (CTAs) or `.accentSecondary` (decorative)
- `.foregroundColor(.secondary)` → `.foregroundStyle(ForagerTheme.textSecondary)`
- `.cornerRadius(12)` → `.cornerRadius(ForagerTheme.Radius.md)` (and sm/lg/xs variants)
- Raw `Color.blue/green/red/gray` backgrounds → `ForagerTheme.*` semantic tokens
- All `.foregroundColor()` deprecated calls → `.foregroundStyle()`

**6 files explicitly skipped** (rewritten by M15.3-M15.5): RecipeListView, WeeklyListsView, GroceryListDetailView, MealPlanDetailView, MealPlanListView, IngredientsView

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build after every sub-phase |
| Verification scan | ✅ PASSED | `.foregroundColor(` only in 6 skipped files |

---

## ✅ **M15.1: DESIGN SYSTEM FOUNDATION & LIQUID GLASS TABVIEW - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 17, 2026
**Branch**: `feature/M15-ux-design-system` (local)

### **What Was Delivered** ✅

- ForagerTheme.swift: 38 semantic color tokens, Radius enum, Typography helpers
- Deployment target raised to iOS 26 for Liquid Glass support
- Replaced CustomBottomNavigation with native Liquid Glass TabView (5 tabs)
- SettingsView preview wraps in NavigationStack

---

## ✅ **M7.6.8: OWNER DISPLAY NAME FIX - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 15, 2026
**Branch**: `feature/M7.6.8-owner-display-name-fix` (PR #33, squash merged)
**PRD**: `docs/prds/complete/m7.6.8-owner-display-name-fix.md`

### **What Was Delivered** ✅

**Fixed owner display name on shared Household record.** After CloudKit sharing, the owner's name showed as blank or "(You)" on both devices because `container.share()` only migrates the root record — HouseholdMember stays in the private store.

**1. Repurposed `ownerEmail` Field**
   - Added `ownerDisplayName` computed alias on Household entity
   - Stores owner's name on the shared root record (survives CloudKit share migration)
   - No schema change needed — reused deprecated field

**2. Fixed Empty Name Detection**
   - iOS 16+ returns empty `nameComponents` (not nil) for current user
   - `PersonNameComponentsFormatter` produces `""`, not "You"
   - Added empty/whitespace check to trigger name lookup

**3. Multi-Strategy Name Resolution**
   - Strategy 1-2: HouseholdMember relationship/fetch (existing)
   - Strategy 3: Household.ownerDisplayName (NEW — shared root record)
   - Strategy 4: UserDefaults cache (existing)

**4. Migration for Existing Households**
   - Detects `_`-prefixed recordNames in `ownerDisplayName`
   - Replaces with cached display name from UserDefaults on launch

### **Also Delivered (PR #32)**

**M7.6.8 TestFlight Beta Bug Fixes:**
- Fixed onboarding tap-through bug (`.ultraThinMaterial` intercepting touches)
- Fixed household creation error handling with retry logic
- Multi-strategy owner name lookup with UserDefaults cache

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build |
| Owner device name display | ✅ VERIFIED | Name shows correctly after create and on relaunch |
| Joinee device name display | ✅ VERIFIED | Owner name visible via TestFlight on second device |
| Existing household migration | ✅ VERIFIED | `_`-prefixed recordName replaced with cached name |
| Owner-only actions | ✅ VERIFIED | isOwner() works via ownerRecordName |

---

## ✅ **M7.6.7: TESTFLIGHT SUBMISSION - COMPLETE**

**Status**: ✅ **COMPLETE**
**Sessions**: February 12-15, 2026

### **What Was Delivered** ✅

- CloudKit schema deployed to Production
- App Privacy questionnaire completed
- Archive uploaded to App Store Connect (build 10, v1.1)
- External testing group created with public link
- Apple review approved
- TestFlight distributed to external testers
- Owner display name fix verified cross-device

---

## ✅ **M7.6.3 (partial): FIRST-LAUNCH LOADING SCREEN - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 12, 2026
**Branch**: `feature/M7.6-pre-launch-testflight`

### **What Was Delivered** ✅

**Branded SwiftUI loading screen** bridging the gap between storyboard disappearing and main app rendering with populated data.

**1. Two-Phase PersistenceController Init**
   - `init()` now only creates container + configures store descriptions (fast)
   - `prepare()` deferred method loads stores on background thread, then runs seeding/migrations
   - `@Published var isReady` signals completion; `ObservableObject` conformance added
   - Preview/test path (`inMemory`) still loads synchronously and marks ready immediately

**2. AppLoadingView**
   - Matches storyboard aesthetic: `Color("LaunchBackground")` + `Image("LaunchIcon")` + `ProgressView` spinner
   - Supports light/dark mode automatically via named asset catalog colors
   - ~15 lines, private struct inside `foragerApp.swift`

**3. Animated Transition**
   - `@State isReady` bridged from `PersistenceController.$isReady` via Combine `.onReceive`
   - `withAnimation(.easeIn(duration: 0.3))` crossfade from splash to main content
   - Coach marks fire after splash dismisses (not during)

### **Files Modified**

| File | Status | Notes |
|------|--------|-------|
| `Services/Persistence/PersistenceController.swift` | MODIFIED | ObservableObject, @Published isReady, two-phase init, prepare() |
| `forager/foragerApp.swift` | MODIFIED | AppLoadingView, conditional rendering, Combine bridge |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build |
| Clean install | ✅ VERIFIED | Storyboard → spinner splash → main app with coach marks |
| Subsequent launch | ✅ VERIFIED | Splash barely visible (setup near-instant) |
| Replay onboarding | ✅ VERIFIED | No splash, just coach marks |

---

## ✅ **M7.6.1: APP CONFIGURATION - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 11, 2026
**Branch**: `feature/M7.6-pre-launch-testflight`
**PRD**: `docs/prds/active/m7.6-pre-launch-prep-testflight.md`

### **What Was Delivered** ✅

**1. Deployment Target** — iOS 18.5 → 18.0
   - All 4 build configurations updated (app Debug/Release, test Debug/Release)
   - No iOS 18.1+ APIs in use (verified via codebase scan)

**2. Launch Screen** — Branded storyboard with light/dark mode support
   - `LaunchScreen.storyboard` with centered sprout icon on themed background
   - `LaunchIcon` image set with transparent sprout (Vision framework background removal)
   - `LaunchBackground` color set with light (cream) and dark (charcoal) variants
   - Asset catalog appearance variants resolve automatically per system appearance

**3. Display Name** — Already correctly set as "forager" (no change needed)

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `forager.xcodeproj/project.pbxproj` | MODIFIED | Deployment target 18.0, storyboard refs, removed auto-gen launch |
| `forager/Info.plist` | MODIFIED | Added UILaunchStoryboardName |
| `forager/LaunchScreen.storyboard` | NEW | Centered icon + named color background |
| `forager/Assets.xcassets/LaunchIcon.imageset/` | NEW | Transparent sprout @1x/2x/3x, light+dark |
| `forager/Assets.xcassets/LaunchBackground.colorset/` | NEW | Cream (light) + charcoal (dark) |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build |
| Light mode launch screen | ✅ VERIFIED | Cream background, sprout centered |
| Dark mode launch screen | ✅ VERIFIED | Dark background, bright sprout |
| Deployment target | ✅ VERIFIED | MinimumOSVersion = 18.0 in compiled plist |

---

## ✅ **M8.3: HYBRID NLP PARSER - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 8, 2026
**Branch**: `feature/M8.3-hybrid-nlp-parser`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

### **What Was Delivered** ✅

**1. Protocol Abstraction** - `Services/Parsing/IngredientParser.swift`
   - `IngredientParser` protocol with `parse(_ input:) -> ParserResult`
   - `ParserResult` value type with confidence, parserUsed tracking

**2. Enhanced Regex Parser** - `Services/Parsing/RegexIngredientParser.swift` (~650 lines)
   - 7 pattern categories in priority order:
     1. Unicode fractions: ½, ¼, ⅓, 1½ (combined forms)
     2. Range patterns: "2-3 cloves garlic", "1 to 2 cups"
     3. Parenthetical patterns: "1 can (14.5 oz) tomatoes"
     4. Compound phrases: "one and a half cups", "two cups"
     5. Standard qty+unit+name (existing, preserved)
     6. Qualifier patterns: "salt to taste", "garlic, minced"
     7. Descriptive amounts: "a pinch of salt", "a handful"
   - Expanded known units: stick, bag, bottle, box, jar, sprig
   - Word-to-number mapping (one→1 through twelve→12)
   - Unicode fraction map (15 fraction characters)

**3. NLP Fallback Parser** - `Services/Parsing/NLPIngredientParser.swift` (~310 lines)
   - Apple NaturalLanguage framework with NLTagger
   - Part-of-speech tagging for token classification
   - Qualifier phrase detection and separation
   - Confidence capped at 0.75 (lower ceiling than regex)

**4. Hybrid Router** - `Services/Parsing/HybridIngredientParser.swift` (~60 lines)
   - Regex first (microseconds), NLP fallback if confidence < 0.8
   - Returns whichever parser produces higher confidence
   - Tracks parserUsed: "regex", "nlp", or "hybrid"

**5. Service Integration** - `Services/IngredientParsingService.swift`
   - Delegates to HybridIngredientParser (no public API change)
   - All call sites unchanged (zero modifications needed)

**6. Telemetry Enhancement** - `Services/ParsingTelemetryService.swift`
   - Added `parserUsed` field to `ParsingTelemetryEvent`
   - Schema version bumped to 2 (backward compatible)

**7. Test Suite** - 3 test files (~600 lines total)
   - `RegexIngredientParserTests`: 30 tests (regression + new patterns)
   - `NLPIngredientParserTests`: 12 tests (fallback behavior)
   - `HybridIngredientParserTests`: 16 tests (router + integration)
   - Performance benchmarks included

### **Confidence Tiers**

| Scenario | Confidence |
|----------|-----------|
| Full parse: qty + unit + name | 1.0 |
| Unicode fraction + unit + name | 1.0 |
| Unicode fraction + name (no unit) | 0.90 |
| Range + unit + name | 0.85 |
| Compound phrase + unit | 0.85 |
| Range + name (no unit) | 0.80 |
| Parenthetical parsed | 0.80 |
| Qty + name (no unit) | 0.75 |
| NLP full parse (capped) | 0.75 |
| Qualifier detected | 0.70 |
| Descriptive amount | 0.60 |
| NLP qty + name | 0.60 |
| NLP name + notes | 0.50 |
| NLP name only | 0.30 |
| Nothing parsed | 0.0 |

### **Files Created/Modified**

| File | Status | Lines |
|------|--------|-------|
| `Services/Parsing/IngredientParser.swift` | NEW | ~35 |
| `Services/Parsing/RegexIngredientParser.swift` | NEW | ~650 |
| `Services/Parsing/NLPIngredientParser.swift` | NEW | ~310 |
| `Services/Parsing/HybridIngredientParser.swift` | NEW | ~60 |
| `foragerTests/Services/Parsing/RegexIngredientParserTests.swift` | NEW | ~260 |
| `foragerTests/Services/Parsing/NLPIngredientParserTests.swift` | NEW | ~100 |
| `foragerTests/Services/Parsing/HybridIngredientParserTests.swift` | NEW | ~150 |
| `Services/IngredientParsingService.swift` | MODIFIED | Delegate to hybrid parser |
| `Services/ParsingTelemetryService.swift` | MODIFIED | +parserUsed field |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build on iPhone 17 Pro |
| Regression | ✅ PASSING | All existing patterns preserved |
| New patterns | ✅ IMPLEMENTED | 6 new pattern categories |
| Performance | ✅ TARGET MET | <0.1s per parse |

---

## ✅ **M8.3.1: TEMPLATE NAME HYGIENE & BADGE FIX - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 8, 2026
**Branch**: `feature/M8.3-hybrid-nlp-parser` (same branch as M8.3)
**PRD**: `docs/prds/complete/m8.3.1-template-hygiene-badge-fix.md`

### **What Was Delivered** ✅

**1. Centralized Template Creation** - 5 view files modified
   - All template creation paths now route through `findOrCreateTemplate`
   - Ensures 4-phase normalization (case, plural, abbreviation, variation)
   - Sets `canonicalName` for semantic deduplication
   - Files: CreateRecipeView, EditRecipeView, AddListItemView, GroceryListDetailView, AddIngredientsToListView

**2. Template Quality Heuristic** - `IngredientTemplate+Validation.swift`
   - `needsReview` computed property with 4 detection rules:
     1. Parenthetical text: "butter (room temperature)"
     2. Digits/Unicode fractions: "2 cloves garlic", "½ cup"
     3. Qualifier suffixes: "salt to taste", "herbs for garnish"
     4. Leading unit words: "loaf french bread", "can tomatoes"

**3. Review UI on Ingredients Tab** - `IngredientsView.swift`
   - Yellow triangle badges on templates needing review
   - "Review (N)" filter pill with count badge
   - Scrollable filter pills (prevents overflow)
   - Bottom scroll clearance fix for custom navigation

**4. Merge-on-Rename Dedup** - `IngredientsView.swift`
   - Renaming a template to an existing name merges instead of blocking
   - Reassigns all Ingredient relationships, sums usage counts, deletes old template
   - `.buttonStyle(.borderless)` fix for List row tap handling
   - Error callback from child rows to parent view

**5. Compound Plural Normalization** - `IngredientTemplateService.swift`
   - `alwaysPluralSuffixes` last-word matching for compound names
   - "black beans", "red pepper flakes", "tortilla strips" stay plural
   - `normalize(name:)` changed to internal for test access

**6. Badge Threshold Calibration** - `RecipeListView.swift`, `GroceryListDetailView.swift`
   - Raised from `< 0.5` to `< 0.7` (aligned with M8.3 confidence tiers)

**7. Unit Tests** - 21 new tests
   - `IngredientTemplateValidationTests.swift` (17 tests): needsReview heuristic coverage
   - `IngredientTemplateNormalizationTests.swift` (21 tests): compound plural + normalization pipeline

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `IngredientTemplate+Validation.swift` | MODIFIED | +needsReview heuristic |
| `Services/IngredientTemplateService.swift` | MODIFIED | Compound plural fix, normalize → internal |
| `forager/IngredientsView.swift` | MODIFIED | Badges, filter, merge-on-rename, scroll fix |
| `forager/CreateRecipeView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/EditRecipeView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/AddListItemView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/GroceryListDetailView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/AddIngredientsToListView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/RecipeListView.swift` | MODIFIED | Badge threshold → 0.7 |
| `foragerTests/Services/IngredientTemplateValidationTests.swift` | NEW | 17 tests |
| `foragerTests/Services/IngredientTemplateNormalizationTests.swift` | NEW | 21 tests |

---

## ✅ **M8.3.2: AUTO-MERGE GROCERY QUANTITIES - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 8, 2026
**Branch**: `feature/M8.3-hybrid-nlp-parser` (same branch as M8.3)
**PRD**: `docs/prds/complete/m8.3.2-auto-merge-grocery-quantities.md`

### **What Was Delivered** ✅

**1. GroceryMergeService** - `Services/GroceryMergeService.swift`
   - Pure computation service (no Core Data dependency)
   - Handles: same-unit addition, convertible-unit conversion, incompatible-unit rejection
   - Parseable/unparseable collision handling
   - Display text formatting
   - Confidence tracking: `min(existing, incoming)`

**2. Wired into AddIngredientsToListView** - `forager/AddIngredientsToListView.swift`
   - Replaces string concatenation ("8 oz + 12 oz") with numeric merging ("20 oz")
   - Source recipe tracking preserved

**3. Consolidation Button Removed** - `forager/GroceryListDetailView.swift`
   - Manual merge button removed from grocery list toolbar
   - Related state and functions cleaned up

**4. Unit Tests** - 19 tests
   - `GroceryMergeServiceTests.swift`: Same-unit, convertible, incompatible, confidence, display text

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `Services/GroceryMergeService.swift` | NEW | Pure merge logic service |
| `foragerTests/Services/GroceryMergeServiceTests.swift` | NEW | 19 tests |
| `forager/AddIngredientsToListView.swift` | MODIFIED | Auto-merge wiring |
| `forager/GroceryListDetailView.swift` | MODIFIED | Consolidation button removed |

---

## ✅ **M8.1: PARSING RESILIENCE & TELEMETRY - COMPLETE**

**Status**: ✅ **COMPLETE**
**Sessions**: February 6-7, 2026
**Branch**: `feature/M8.1-parsing-resilience-telemetry`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

### **What Was Delivered** ✅

**1. ParsingTelemetryService** - `Services/ParsingTelemetryService.swift` (~400 lines)
   - Logs parsing events with confidence scores
   - Logs user corrections (before/after)
   - JSON persistence to Documents folder
   - Analysis APIs (getStatistics, getLowConfidenceEvents)
   - Privacy-safe (local storage only)

**2. Unit Tests** - `foragerTests/Services/ParsingTelemetryServiceTests.swift` (~660 lines)
   - 20/20 tests passing
   - Test isolation with `resetForTesting()` and `waitForPendingOperations()`

**3. Yellow Badge (Recipes)** - `forager/RecipeListView.swift`
   - Yellow exclamation triangle for `parseConfidence < 0.5`
   - Shows in ingredient rows within recipe detail view

**4. Yellow Badge (Grocery List)** - `forager/GroceryListDetailView.swift`
   - Low-confidence indicator in grocery list view

**5. Telemetry Integration** - `Services/IngredientParsingService.swift`
   - Added `source` parameter to `parseToStructured()`
   - Logs all parsing events to ParsingTelemetryService

**6. Sample Test Recipes** - `forager/RecipeListView.swift`
   - 3 sample recipes with low-confidence ingredients for validation
   - Access via: Recipes → Menu (⋯) → Create Test Recipes

### **What Was Removed (Scope Reduction)**

- **EditIngredientSheet** — Removed structured edit form. Users can already edit ingredients inline via the recipe edit view. The structured form would be replaced by M8.3's improved parser anyway.
- **Context menu on ingredient rows** — Removed (was only used to launch EditIngredientSheet)

### **Bug Fixes During Testing**

- **Crash fix**: `IngredientTemplate.normalizedName` was declared in CoreDataProperties but didn't exist in the Core Data model. Removed phantom property.
- **Build fix**: Cleaned up all references from project.pbxproj

### **Files Created/Modified**

| File | Status | Lines |
|------|--------|-------|
| `Services/ParsingTelemetryService.swift` | NEW | ~400 |
| `foragerTests/Services/ParsingTelemetryServiceTests.swift` | NEW | ~660 |
| `docs/testing/M8.1-ParsingTelemetryService-test-plan.md` | NEW | - |
| `foragerTests/Info.plist` | NEW | - |
| `foragerUITests/Info.plist` | NEW | - |
| `Services/IngredientParsingService.swift` | MODIFIED | +10 |
| `forager/RecipeListView.swift` | MODIFIED | +60 |
| `forager/GroceryListDetailView.swift` | MODIFIED | +10 |
| `IngredientTemplate+CoreDataProperties.swift` | MODIFIED | -1 (removed phantom normalizedName) |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Unit tests | ✅ 20/20 PASSING | All telemetry service tests pass |
| Build | ✅ BUILD SUCCEEDED | Clean build on iPhone 17 Pro |
| Yellow badge (Recipes) | ✅ VERIFIED | Badges visible on low-confidence ingredients |
| Yellow badge (Grocery) | ✅ VERIFIED | Indicator shows in grocery list |

---

## ✅ **M7.4: UI POLISH & PRE-LAUNCH FIXES - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 5, 2026
**Branch**: `feature/M7.4-ui-polish-pre-launch`
**PRD**: `docs/prds/active/m7.4-ui-polish-pre-launch.md`

### **What Was Implemented** ✅

**Ad-hoc UI Polish (retroactively documented):**

1. **Apple Music-Style Bottom Navigation** - CustomBottomNavigation.swift
   - Grouped pill container with 4 main tabs
   - Separate circular search button that expands inline
   - Two-step search interaction (expand bar, then tap to focus)
   - Smooth spring animations on state changes
   - `.regularMaterial` for iOS 26 Liquid Glass design

2. **Hamburger Menu Navigation** - HamburgerMenuModifier.swift
   - Settings and Categories moved from tabs to hamburger menu
   - Sheet-based navigation with full-height presentation
   - Consistent access across all main views

3. **Settings Restructure** - SettingsView.swift
   - Clear visual hierarchy with section groupings
   - Migration status banner for post-household users
   - Household Management section (contextual, owner-only options)
   - App Information section with version display

4. **Keyboard Search Bar Fix** - CustomBottomNavigation.swift
   - Removed `.ignoresSafeArea(.keyboard)` that blocked keyboard avoidance
   - iOS natural keyboard avoidance now pushes nav bar up correctly

5. **Ingredients Filter Pill Sizing** - IngredientsView.swift
   - Added FilterPill.Size enum (compact, regular, large)
   - "All Categories" uses `.large` to prevent text truncation
   - "Staples First" shortened to "Staples" with `.compact` size
   - Sort button uses `.compact` size

### **Files Modified/Created**
- `forager/CustomBottomNavigation.swift` - NEW: Apple Music-style navigation
- `forager/HamburgerMenuModifier.swift` - NEW: Hamburger menu sheet
- `forager/SettingsView.swift` - Restructured with clear hierarchy
- `forager/IngredientsView.swift` - FilterPill sizing improvements
- `docs/prds/active/m7.4-ui-polish-pre-launch.md` - NEW: Retroactive PRD

### **Testing Status**
| Test | Status | Notes |
|------|--------|-------|
| Bottom nav animations | ✅ PASSED | Smooth spring transitions |
| Search keyboard interaction | ✅ PASSED | Keyboard pushes nav bar up |
| Filter pill readability | ✅ PASSED | No text truncation |
| Hamburger menu navigation | ✅ PASSED | Settings/Categories accessible |

---

## ✅ **M7.3.4: ERROR HANDLING & STABILITY IMPROVEMENTS - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 5, 2026
**Branch**: `feature/M7.3.3-remove-member-delete-household` (includes M7.3.4 changes)

### **What Was Implemented** ✅

**P0 Fixes:**
1. **ERR-001: Ghost Data Bug Fix** - `loadCurrentHousehold()` no longer auto-clears left flag
2. **ERR-002: Replace exit(0)** - Check Again button flow in AcceptInvitationSheet

**P1 Technical Debt:**
3. **ERR-010: CloudKitErrorMapper** - Single source of truth for CKError messages
4. **ERR-011: Magic Numbers** - Replaced with CKError.Code enum
5. **ERR-012: OSLog/CloudKitLogger** - Structured logging for CloudKit operations

**Additional Fixes (discovered during testing):**
6. **Offline Leave Hanging** - NWPathMonitor connectivity check before CKShare operations
7. **Pending Leave Queue** - KeychainHelper stores pending leaves for offline scenarios
8. **Autocomplete Ghost Data** - householdKey filtering across all autocomplete surfaces
9. **Category Management Ghost Data** - householdKey filtering for category operations

### **Files Modified/Created**
- `Services/HouseholdService.swift` - ERR-001 fix, connectivity check, pending leave processing, logging
- `forager/AcceptInvitationSheet.swift` - ERR-002 Check Again button
- `Services/Persistence/CloudKitErrorMapper.swift` - NEW
- `Services/Persistence/CloudKitLogger.swift` - NEW
- `Services/CloudKitSyncMonitor.swift` - Uses CloudKitErrorMapper
- `Services/Persistence/CloudKitDiagnostics.swift` - Uses CloudKitErrorMapper
- `Services/KeychainHelper.swift` - Pending leave queue
- `forager/MealPlanDetailView.swift` - householdKey filter for recipe autocomplete
- `Services/IngredientAutocompleteService.swift` - householdKey filter for ingredient autocomplete
- `forager/AddListItemView.swift` - Pass householdKey to autocomplete
- `forager/GroceryListDetailView.swift` - Pass householdKey to autocomplete (quick add)
- `forager/CreateRecipeView.swift` - Pass householdKey to autocomplete
- `forager/EditRecipeView.swift` - Pass householdKey to autocomplete
- `forager/AddCategoryView.swift` - householdKey filter for duplicate check and sort order
- `forager/ManageCategoriesView.swift` - householdKey filter for ingredient template operations
- `forager/IngredientsView.swift` - householdKey filter for ingredient rename duplicate check

### **Testing Status**
| Test | Status | Notes |
|------|--------|-------|
| Test 1: Offline Leave | ✅ PASSED | Pending leave queue works |
| Test 2: Rejoin + Ghost Data | ✅ PASSED | Autocomplete filtering fixed |
| Test 3: Multi-Device Leave | ⏭️ SKIPPED | User decision - not testing kid's iPad |
| Test 4: OSLog Validation | ✅ VALIDATED | Code implemented, use Console.app to verify |
| Test 5: Regression Testing | ⏭️ SKIPPED | User decision - exhaustive household testing already done |

---

## ✅ **M7.3.3: REMOVE MEMBER & DELETE HOUSEHOLD - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 3, 2026
**Branch**: `feature/M7.3.3-remove-member-delete-household` (ready to merge)

### **What Was Implemented** ✅

**1. Remove Member (Owner-only)**
- `removeMember(_:from:)` in HouseholdService - uses CKShare.removeParticipant()
- Swipe-to-delete UI in HouseholdMembersView (only shows for owner, excludes self/owner rows)
- Confirmation alert before removal
- Error handling: `cannotRemoveSelf`, `cannotRemoveOwner`

**2. Delete Household (Owner-only)**
- `deleteHousehold(_:migrateData:)` in HouseholdService
- Optional data migration (reuses `migrateHouseholdDataToPersonal()`)
- Deletes CKShare from private database (revokes all participants' access)
- Purges shared store objects
- "Delete Household" button in SettingsView (red, destructive)
- Two-option confirmation alert: "Migrate & Delete" / "Clean Delete"

**3. Household Protection (Prevents Multi-Household State)**
- `alreadyInHousehold` error case added to `HouseholdError`
- Protection in `createHouseholdAndShare()` - cannot create when already in one
- Protection in `checkForAcceptedInvitations()` - cannot join when already in one
- SceneDelegate protection - rejects share invitation when already in household
- `cloudKitShareRejectedAlreadyInHousehold` notification for UI feedback

**4. Removed Member Detection**
- `checkIfRemovedFromHousehold()` detects when member loses access
- Automatically clears household state and purges shared data
- Marks household as "left" to prevent re-join loops

**5. Category Sync Diagnostics**
- `dumpCategorySyncDiagnostics()` for troubleshooting sync issues
- "Category Sync Diagnostic" button in Settings (DEBUG only)

**6. Deprecated API Cleanup**
- Removed `userDiscoverability` permission code from foragerApp.swift (~75 lines)
- Fixed `rootRecordID` → `hierarchicalRootRecordID` in SceneDelegate and PasteInvitationSheet

### **Files Modified**
- `Services/HouseholdService.swift` - removeMember(), deleteHousehold(), protections, diagnostics
- `forager/HouseholdMembersView.swift` - Swipe-to-delete UI with confirmation
- `forager/SettingsView.swift` - Delete Household button, diagnostic button
- `forager/SceneDelegate.swift` - Share rejection when already in household
- `forager/foragerApp.swift` - Removed deprecated permission code (-75 lines)
- `forager/PasteInvitationSheet.swift` - Fixed deprecated API

---

## ✅ **M7.2.2: LEAVE HOUSEHOLD - COMPLETE**

**Status**: ✅ **COMPLETE**
**Sessions**: January 18 - February 2, 2026
**Key Achievement**: Full member leave flow with data migration, CKShare cleanup, owner notification, rejoin support, and code cleanup

### **What Was Implemented** ✅

**1. Member Leave Flow (HouseholdService.swift)**
- `leaveHousehold()` - Complete leave sequence with data migration option
- `migrateHouseholdDataToPersonal()` - Full data migration (recipes, categories, ingredient templates, lists)
- `deleteCKShareFromSharedDatabase()` - Member self-removal from CKShare (workaround for CloudKit limitation)
- `purgeAllSharedStoreObjects(from:)` - Extracted shared-store purge helper on PersistenceController
- `destroyAndRecreateSharedStore()` - Nuclear cleanup of shared store

**2. Owner-Controlled Member Removal**
- Owner can remove members from household via CKShare participant management
- Real-time leave request detection via Combine sync observer
- Local notification to owner when member leaves

**3. Rejoin Fix & Keychain Tracking**
- `KeychainHelper` - Persistent tracking of left households (survives app reinstall)
- Fixed re-joining blocked by stale left-household flag
- Proper cleanup on successful rejoin

**4. PasteInvitationSheet API Fix**
- Changed from `CKContainer.accept(metadata)` to `NSPersistentCloudKitContainer.acceptShareInvitations(from:into:)`
- Matches SceneDelegate pattern for consistent sync behavior

**5. Dead Code Removal & Optimization (~450 lines removed)**
- Removed 9 dead functions: `stopParticipatingInShare`, `fetchShare`, `createHousehold(name:ownerName:)`, `createCloudKitShare`, `getCurrentUserDisplayName`, `getDisplayNameFromShare`, `waitForCloudKitExport`, `waitForMemberDeletionSync`, `removeParticipantFromShare`, `syncParticipantsFromShare`
- Extracted `purgeAllSharedStoreObjects(from:)` to PersistenceController
- CKShare caching opportunity identified for future optimization

**6. Invitation Message Enhancement**
- Outgoing text message includes friendly description above iCloud link
- CKShare title set to "Join [Household Name] on forager"

### **Commits on Branch**
1. `73a1909` - M7.2.2: Add real-time leave request detection via Combine sync observer
2. `463ab89` - M7.2.2: Fix re-joining household blocked by stale left-household flag
3. `a5dd9a6` - M7.2.2: Switch to owner-controlled member removal, fix recipe picker duplication
4. `9f47102` - M7.2.2: Harden leave flow — CKShare deletion, shared store nuke, rejoin fix
5. `c84cb20` - M7.2.2: Remove dead code, extract purge helper, fix PasteInvitationSheet API

### **Files Modified/Created**
- `Services/HouseholdService.swift` - Major refactor (~450 lines removed, leave flow hardened)
- `Services/Persistence/PersistenceController.swift` - Added `purgeAllSharedStoreObjects(from:)` helper
- `Services/KeychainHelper.swift` - NEW: Persistent left-household tracking
- `forager/PasteInvitationSheet.swift` - Fixed acceptance API
- `forager/ShareSheet.swift` - Invitation message enhancement

---

## **Previous Session Progress**

### **M7.3.1: Rename Household** ✅ COMPLETE (Jan 13, 2026)
- Owner-only household renaming functionality
- Inline text field edit UI in Settings

### **M7.2.3: CloudKit Hardening** ✅ COMPLETE (Jan 4, 2026)
- Dual-store architecture (private + shared)
- Scope-based store assignment
- CategoryDeduplicator for multi-device sync
- Attach-then-share migration

### **M7.2.2: Member Invitation** ✅ COMPLETE (Jan 12, 2026)
- Public link sharing (bypassed UICloudSharingController bugs)
- CKShare.participants as source of truth

---

## **Known Issues & Limitations**

1. **CloudKit Limitation**: Members cannot remove themselves from CKShare.participants
   - Workaround: `deleteCKShareFromSharedDatabase()` deletes CKShare from shared database
2. **Migration**: PlannedMeals not migrated (require recipe mapping)
   - User can recreate meal assignments manually
3. **CKShare caching**: `getShare(for:)` hits CloudKit on every call; could cache per operation
4. **Household Recovery**: No recovery mechanism if owner reinstalls app before CloudKit syncs household data. Creating a new household before old one syncs could cause duplicate households. Tracked in roadmap under Future Considerations.

---

## **What's Next**

### **Pre-Launch Roadmap** 🚀

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.6: Pre-Launch Prep & TestFlight | ✅ COMPLETE | ~12h |
| M15: UX Design System & Visual Refresh | ✅ COMPLETE | ~50h |
| TestFlight push (post-M15) | 📋 PLANNED | ~1h |
| **M7.7: App Store Submission & Public Presence** | 📋 READY | 3-5h |

**M15 Phases** (7 phases — PRD: `docs/prds/complete/m15-ux-design-system.md`):

| Phase | Description | Est. |
|-------|-------------|------|
| M15.1 | Design System Foundation & Liquid Glass TabView | ✅ COMPLETE |
| M15.2 | Color & Typography Migration | ✅ COMPLETE |
| M15.3 | Grocery Lists UX Overhaul | ✅ COMPLETE |
| M15.4 | Recipes UX Overhaul | ✅ COMPLETE |
| M15.5 | Meal Plans & Ingredients UX | ✅ COMPLETE |
| M15.5b | Settings, Categories & Household | ✅ COMPLETE |
| M15.6 | Liquid Glass Polish | ✅ COMPLETE |
| M15.7 | Dark Mode, Accessibility & Final QA | ✅ COMPLETE |

**Key Decisions (February 17, 2026)**:
- M15 elevated to pre-launch — polished UI before App Store debut
- Design phase complete: HTML mockups, PRD v1.1, 5-phase design review all done
- TestFlight already live with external testers; LinkedIn share imminent
- After M15: new TestFlight build → M7.7 App Store submission
- M15 first makes M7.5 Architecture Hardening easier (navigation cleanup reduced)

### **Post-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.5: Architecture Hardening | ✅ COMPLETE | ~5h |
| M9.0: Warning Resolution | ✅ COMPLETE | <1h |
| M9.1.2: Centralize extractCleanIngredientName | ✅ COMPLETE | ~2h |
| M9.5-partial: Parser Dependency Injection | ✅ COMPLETE | ~3h |
| M8.4: ML-Powered Parsing | ✅ COMPLETE | ~25h actual |
| **M10: Recipe Import** | **🚀 NEXT** | **70-95h** |
| M7.7: App Store Submission | QUEUED | 3-5h |
| M6: Testing Foundation | PLANNED | 20-30h |
| M9: Remaining Technical Debt | PLANNED | ~120h |
| M11: Analytics & Insights | PLANNED | 8-12h |
| M12-M16: Advanced Features | FUTURE | 40-60h |

---

## **SESSION STARTUP REMINDER**

**For EVERY development session**, follow the mandatory startup sequence:

1. Read `docs/session-startup-checklist.md`
2. Read `docs/project-naming-standards.md`
3. Read `docs/current-story.md` (this file)
4. Read `docs/next-prompt.md`

---

**Last Session**: February 22, 2026 - M8.4 Phase 6 COMPLETE (36 new tests, tokenizer bug fix, 0.84ms/parse performance)
**Next Action**: M8.4 Phase 7+8 (corrections + continuous learning, 4-5h) → Phase 9 (integration, 1-2h)
**Branch**: `feature/M8.4-ml-parsing`
**Confidence**: **GREEN** (Phase 0-6 complete, 36 new tests passing, tokenizer bug discovered and fixed by cross-validation, ML parsing fully tested)
**Version**: February 22, 2026 - M8.4 Phase 0-6 COMPLETE, Phase 7 NEXT
