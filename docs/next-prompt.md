# Next Implementation Prompt

**Last Updated**: February 22, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 6 sessions)
**Status**: M8.4 Phase 0-4 ✅ **COMPLETE** | **Phase 5 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 5 — HybridIngredientParser Integration (2-3h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 5, Phase 5)

### What's Already Done (Phases 0-4)
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
- ✅ ViterbiDecoder.swift: Pure-Swift Viterbi decoder (~70 lines)
- ✅ MLIngredientParser.swift: Full pipeline (~300 lines) — tokenize → CoreML → Viterbi → ParserResult
- ✅ BUILD SUCCEEDED with both new files

### Key Architecture Decisions (Unchanged)
- **CRF split into 3 runtime components**: CoreML emissions + JSON transitions + Swift Viterbi
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers

### Phase 5 Tasks

**5a: Update HybridIngredientParser routing** (`Services/Parsing/HybridIngredientParser.swift`)
- Add `mlParser: IngredientParser?` parameter to init (default: `MLIngredientParser()`)
- Update routing: regex ≥0.9 → ML ≥0.8 → NLP fallback
- Winner-only attribution: return whichever parser's result is used (no "hybrid" label)
- Comment: M8.4 breadcrumb already exists in the file

**5b: Background dispatch for bulk operations** (`Services/IngredientParsingService.swift`)
- Ensure `parseAndConnectIngredients()` works correctly with ML parser in chain
- Background dispatch owned by callsite/service layer (parsers stay synchronous)

**5c: Update ADR 010** (`docs/architecture/010-hybrid-parser-confidence-routing.md`)
- Add 3-tier routing diagram
- Document ML parser tier between regex and NLP

**5d: Update IngredientParser.swift comments** (`Services/Parsing/IngredientParser.swift`)
- Update protocol doc to list all three implementations
- Update `parserUsed` valid values: "regex", "ml", "nlp"

**Key Files to Reference:**
- `Services/Parsing/HybridIngredientParser.swift` — current routing (has M8.4 breadcrumb comment)
- `Services/Parsing/MLIngredientParser.swift` — new ML parser (just implemented)
- `Services/IngredientParsingService.swift` — public API, `parseCore()` entry point
- PRD Section 5, Phase 5 — detailed routing pseudocode

### Remaining Sessions After Phase 5

**Phase 6: Test Suite (2-3h)**
- Tokenizer test vectors (100 sentences cross-validation)
- MLIngredientParser unit tests
- HybridIngredientParser routing tests with ML tier
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

**Dependencies**: All prerequisites ✅ | CoreML model in bundle ✅ | ViterbiDecoder + MLIngredientParser ✅
**Model**: 1.35M params, 5.15 MB CoreML, 98.49% token accuracy, 100% Viterbi parity
**M8.4 PRD**: Phase 5 is integration — slot MLIngredientParser into HybridIngredientParser routing chain.
