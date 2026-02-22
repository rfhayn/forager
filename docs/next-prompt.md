# Next Implementation Prompt

**Last Updated**: February 22, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 6 sessions)
**Status**: M8.4 Phase 0-5 ✅ **COMPLETE** | **Phase 6 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 6 — Test Suite (2-3h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 5, Phase 6)

### What's Already Done (Phases 0-5)
- ✅ Architecture locked: word-only BiLSTM v1, no char features
- ✅ Tokenizer spec frozen (`TOKENIZER_SPEC.md` + 100-sentence test vectors)
- ✅ Single-parse refactor complete (`parseCore()` → `parseUnified()`)
- ✅ Dataset ready: 68,846 unique samples in 80/10/10 JSONL splits
- ✅ Labels: 7 Forager labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER)
- ✅ BiLSTM-CRF trained: 98.49% token accuracy, 95.40% sentence accuracy
- ✅ CoreML model: `IngredientTaggerEmissions.mlpackage` (5.15 MB)
- ✅ Emission parity: PyTorch vs CoreML max diff 4.77e-06
- ✅ Viterbi parity gate: 100.0000% token agreement (8,030/8,030 on 1,000 samples)
- ✅ Xcode integration: .mlpackage in Sources, JSON in Bundle Resources
- ✅ ViterbiDecoder.swift: Pure-Swift Viterbi decoder (~70 lines)
- ✅ MLIngredientParser.swift: Full pipeline (~300 lines)
- ✅ HybridIngredientParser: 3-tier routing (regex ≥0.9 → ML ≥0.8 → NLP fallback)
- ✅ Winner-only attribution: `parserUsed` = `"regex"` / `"ml"` / `"nlp"`, never `"hybrid"`
- ✅ CoreML warmup in `foragerApp.init()` (background queue)
- ✅ ADR 010 updated for 3-tier routing
- ✅ Routing tests rewritten for 3-tier with mockML
- ✅ BUILD SUCCEEDED + TEST BUILD SUCCEEDED

### Key Architecture Decisions (Unchanged)
- **CRF split into 3 runtime components**: CoreML emissions + JSON transitions + Swift Viterbi
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers
- **3-tier routing**: regex ≥0.9 → ML ≥0.8 → NLP fallback (only when both < 0.5)

### Phase 6 Tasks

**6a: ViterbiDecoderTests.swift** (NEW)
- Pure algorithm tests — no CoreML dependency, runs in CI
- Hand-crafted emission matrices testing forward pass, backpointers
- Start/end transition handling
- Single-token sequences, empty input
- Edge cases: all labels equal score, single dominant label

**6b: MLIngredientParserTests.swift** (NEW)
- **Model presence guard**: `XCTAssertNotNil(MLIngredientParser())` — fails loudly if .mlpackage missing
- Unit extraction accuracy (known failure cases for regex):
  - "3 cloves garlic" → name: "garlic", qty: 3.0, unit: "clove"
  - "1/4 tsp black pepper" → name: "black pepper"
  - "milk 2%" → name: "milk 2%", qty: nil
- Standard format regression: "2 cups flour" → qty: 2.0, unit: "cup", name: "flour"
- Tokenizer tests: cross-validate against `tokenizer_test_vectors.json` (100 sentences)
- Performance test: < 5ms per parse (steady-state)

**6c: Update HybridParserRoutingTests.swift** (ALREADY DONE in Phase 5)
- ML mock injection tests already rewritten with 3-tier assertions
- May need additional edge case tests

**Key Files to Reference:**
- `Services/Parsing/ViterbiDecoder.swift` — algorithm to test
- `Services/Parsing/MLIngredientParser.swift` — parser to test (has public `tokenize()`)
- `Tools/ml-training/data/tokenizer_test_vectors.json` — 100 cross-validation sentences
- `foragerTests/Mocks/MockIngredientParser.swift` — mock infrastructure
- PRD Section 5, Phase 6 — detailed test specifications

**IMPORTANT: pbxproj test registration**
- `foragerTests/` uses manual `PBXGroup` — must add PBXFileReference, PBXBuildFile, group children, PBXSourcesBuildPhase entries
- Test Sources build phase ID: `9B731C392E535C3300CE26F0`
- ForagerTests root group ID: `9B0555692EDB69CD00A57B34`
- Test Services group ID: `9B78C7B52F36335900B24679`

### Remaining Sessions After Phase 6

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

**Dependencies**: All prerequisites ✅ | CoreML model in bundle ✅ | 3-tier routing ✅
**Model**: 1.35M params, 5.15 MB CoreML, 98.49% token accuracy, 100% Viterbi parity
**M8.4 PRD**: Phase 6 is testing — ViterbiDecoder pure tests + MLIngredientParser integration tests + tokenizer cross-validation.
