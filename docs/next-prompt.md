# Next Implementation Prompt

**Last Updated**: February 22, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 7 sessions)
**Status**: M8.4 Phase 0-6 ✅ **COMPLETE** | **Phase 7 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 7 — Correction Instrumentation (2-3h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 5, Phase 7)

### What's Already Done (Phases 0-6)
- ✅ Architecture locked: word-only BiLSTM v1, no char features
- ✅ Tokenizer spec frozen + cross-validated (tokenizer bug fix in Phase 6)
- ✅ Single-parse refactor complete (`parseCore()` → `parseUnified()`)
- ✅ Dataset ready: 68,846 unique samples in 80/10/10 JSONL splits
- ✅ BiLSTM-CRF trained: 98.49% token accuracy, 95.40% sentence accuracy
- ✅ CoreML model: `IngredientTaggerEmissions.mlpackage` (5.15 MB)
- ✅ Emission parity: PyTorch vs CoreML max diff 4.77e-06
- ✅ Viterbi parity gate: 100.0000% token agreement (8,030/8,030 on 1,000 samples)
- ✅ ViterbiDecoder.swift + MLIngredientParser.swift (full pipeline)
- ✅ HybridIngredientParser: 3-tier routing (regex ≥0.9 → ML ≥0.8 → NLP fallback)
- ✅ Winner-only attribution: `parserUsed` = `"regex"` / `"ml"` / `"nlp"`
- ✅ ViterbiDecoderTests: 15 pure algorithm tests, all passing
- ✅ MLIngredientParserTests: 21 integration tests, all passing (0.84ms/parse)
- ✅ Tokenizer fix: fraction/decimal/NFKD combining marks now match Python training tokenizer

### Key Architecture Decisions (Unchanged)
- **CRF split into 3 runtime components**: CoreML emissions + JSON transitions + Swift Viterbi
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers
- **3-tier routing**: regex ≥0.9 → ML ≥0.8 → NLP fallback (only when both < 0.5)

### Phase 7 Tasks

**7a: Telemetry Schema v3 Changes** (must complete before 7b)
- Add `parserUsed: String?` and `source: CorrectionSource?` to `ParsingCorrectionEvent`
- Define `CorrectionSource` enum with 4 cases: `.editRecipe`, `.createRecipe`, `.groceryListEdit`, `.templateRename`
- Update `logCorrection()` signature with new parameters
- Bump `currentSchemaVersion` to 3
- Backward compatible: new fields are optionals, v2 data loads fine

**7b: Wire Correction Logging into Edit Flows**
- **EditRecipeView**: Compare original vs edited values on save, log correction with `source: .editRecipe`
- **CreateRecipeView**: Same pattern, `parserUsed` available from in-memory `ParserResult`
- **GroceryListDetailView**: Compare original name with edited name, `source: .groceryListEdit`
- **IngredientsView**: Template rename → correction, `source: .templateRename`

**7c: Minimum Corpus Gate**
- ≥50 corrections before enabling retraining workflow
- Add correction count display in debug menu

**Key Files to Reference:**
- `Services/ParsingTelemetryService.swift` — logCorrection() method to extend
- `forager/EditRecipeView.swift` — edit flow to wire
- `forager/CreateRecipeView.swift` — edit flow to wire
- `forager/GroceryListDetailView.swift` — edit flow to wire
- `forager/IngredientsView.swift` — template rename flow to wire
- PRD Section 5, Phase 7 — detailed specifications + schema v3 migration details

**IMPORTANT: Correction Linkage Contract**
- v1: Corrections logged **unlinked** (`originalEventId: nil`)
- `parserUsed` only available in CreateRecipeView (in-memory ParserResult)
- Other flows: `parserUsed: nil` (unattributable)
- Per-parser rates computed on attributable subset only (N ≥ 20 guardrail)

### Remaining Sessions After Phase 7

**Phase 8: Continuous Learning Pipeline (2h)**
- BIO export from correction events, retraining script hooks

**Phase 9: Integration Testing + Documentation (1-2h)**
- 8 end-to-end scenarios, core doc updates

---

## **AFTER M8.4: M7.7 → M6 → M9 → M10+**

### M7.7: App Store Submission (3-5h)
- Beta landing page, README update, App Store listing, submission
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

### M6: Testing Foundation (20-30h)
- 50%+ test coverage on critical services
- **PRD**: `docs/prds/active/milestone-6-testing-foundation-ai-augmentation.md`

### M9 Remaining (~120h)
- **PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md`

---

**Dependencies**: All prerequisites ✅ | CoreML model in bundle ✅ | 3-tier routing ✅ | Test suite ✅
**Model**: 1.35M params, 5.15 MB CoreML, 98.49% token accuracy, 100% Viterbi parity
**M8.4 PRD**: Phase 7 is correction instrumentation — schema v3 + edit flow wiring + corpus gate.
