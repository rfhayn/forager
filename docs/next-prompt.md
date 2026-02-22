# Next Implementation Prompt

**Last Updated**: February 22, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 6 sessions)
**Status**: M8.4 Phase 0-3 ✅ **COMPLETE** | **Phase 4 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 4 — MLIngredientParser Implementation (3-4h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 5, Phase 4)

### What's Already Done (Phases 0-3)
- ✅ Architecture locked: word-only BiLSTM v1, no char features
- ✅ Tokenizer spec frozen (`TOKENIZER_SPEC.md` + 100-sentence test vectors)
- ✅ Single-parse refactor complete (`parseCore()` → `parseUnified()`)
- ✅ Dataset ready: 68,846 unique samples in 80/10/10 JSONL splits
- ✅ Labels: 7 Forager labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER)
- ✅ BiLSTM-CRF trained: 98.49% token accuracy, 95.40% sentence accuracy
- ✅ CoreML model: `IngredientTaggerEmissions.mlpackage` (5.15 MB)
- ✅ Emission parity: PyTorch vs CoreML max diff 4.77e-06
- ✅ Viterbi parity gate: 100.0000% token agreement (8,030/8,030 on 1,000 samples)
- ✅ Xcode integration: .mlpackage in Sources, JSON in Bundle Resources, BUILD SUCCEEDED
- ✅ Xcode auto-generated `IngredientTaggerEmissions` Swift prediction class

### Key Architecture Decisions (Unchanged)
- **CRF split into 3 runtime components**: CoreML emissions + JSON transitions + Swift Viterbi
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers

### Phase 4 Tasks

**4a: ViterbiDecoder.swift** (`Services/Parsing/ViterbiDecoder.swift`, ~40 lines)
- Port the Python reference Viterbi decoder to Swift
- Load `transitions.json` from bundle at init
- `decode(emissions: [[Float]]) -> [String]` — standard forward pass + backtrace
- Must consume ALL CRF params: 7×7 transitions + start_transitions + end_transitions

**4b: MLIngredientParser.swift** (`Services/Parsing/MLIngredientParser.swift`)
- Implements `IngredientParser` protocol
- Load CoreML model (`IngredientTaggerEmissions`), vocabulary, and ViterbiDecoder at init
- Tokenize input: NFKD normalize → lowercase → whitespace split → punctuation split (per TOKENIZER_SPEC.md)
- Map tokens to IDs via vocabulary (unknown → UNK=0)
- Run CoreML prediction → get emissions → Viterbi decode → label sequence
- Reconstruct `ParserResult` from token-label pairs (group consecutive NAME tokens, etc.)
- Cross-validate tokenizer against `data/tokenizer_test_vectors.json` (100 sentences)
- `parserUsed = "ml"`, confidence based on emission entropy

**Key Files to Reference:**
- `Tools/ml-training/TOKENIZER_SPEC.md` — tokenizer contract (must match exactly)
- `Tools/ml-training/data/tokenizer_test_vectors.json` — cross-validation vectors
- `Services/Parsing/IngredientParser.swift` — protocol to implement
- `Services/Parsing/RegexIngredientParser.swift` — reference for ParserResult construction
- PRD Section 5, Phase 4 — detailed pseudocode for both files

### Remaining Sessions After Phase 4

**Phases 5+6: Integration + Test Suite (4-6h)**
- Add `mlParser: IngredientParser?` to HybridIngredientParser init
- Update routing: regex ≥0.9 → ML ≥0.8 → NLP fallback
- Winner-only attribution updates
- 20+ test cases

**Phases 7+8: Corrections + Continuous Learning (4-5h)**
- Telemetry schema v3, correction instrumentation, BIO export

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

**Dependencies**: All prerequisites ✅ | CoreML model in bundle ✅ | Viterbi parity verified ✅
**Model**: 1.35M params, 5.15 MB CoreML, 98.49% token accuracy, 100% Viterbi parity
**M8.4 PRD**: Phase 4 is Swift implementation — ViterbiDecoder + MLIngredientParser.
