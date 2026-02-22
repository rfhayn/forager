# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 6 sessions)
**Status**: M8.4 Phase 0-2 ✅ **COMPLETE** | **Phase 3 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 3 — CoreML Conversion (2-3h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 4, Phase 3)

### What's Already Done (Phases 0-2)
- ✅ Architecture locked: word-only BiLSTM v1, no char features
- ✅ Tokenizer spec frozen (`TOKENIZER_SPEC.md` + 100-sentence test vectors)
- ✅ Single-parse refactor complete (`parseCore()` → `parseUnified()`)
- ✅ Dataset ready: 68,846 unique samples in 80/10/10 JSONL splits
- ✅ Labels: 7 Forager labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER)
- ✅ Model card template + license attribution (MIT/Apache 2.0)
- ✅ BiLSTM-CRF trained: 98.49% token accuracy, 95.40% sentence accuracy
- ✅ All F1 targets met: QTY=0.9968, UNIT=0.9939, NAME=0.9869
- ✅ Checkpoint exported: `models/ingredient_tagger.pt` (5.2 MB, 1.35M params)
- ✅ CRF parameters exported: `models/transitions.json` (7×7 + start/end)
- ✅ Vocabulary exported: `models/vocabulary.json` (5,372 words)
- ✅ MODEL_CARD.md auto-updated with training metadata

### Key Architecture Decisions (Unchanged)
- **CRF cannot convert to CoreML** — split into 3 components:
  1. BiLSTM emission scorer → CoreML `.mlpackage`
  2. CRF parameters → `transitions.json` (7×7 transition matrix + 1×7 start transitions + 1×7 end transitions)
  3. Viterbi decoder → Pure Swift (~40 lines)
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers

### Phase 3: CoreML Conversion
```
Branch: feature/M8.4-ml-parsing (already created)
Working dir: Tools/ml-training/
```

**Tasks:**
1. Write `convert_to_coreml.py`:
   - Load trained checkpoint (`models/ingredient_tagger.pt`)
   - Extract BiLSTM emission scorer (everything except CRF layer)
   - Create wrapper `nn.Module` that outputs raw emissions (batch, seq_len, 7)
   - Convert via `coremltools.convert()` with `ct.RangeDim(1, 64)` for variable-length input
   - Input: `token_ids: Int32 (1, seq_len)` — Output: `emissions: Float32 (1, seq_len, 7)`
   - Save as `.mlpackage` in `models/`
2. Write Python Viterbi decoder (reference implementation):
   - Standalone function using `transitions.json`
   - Must match `pytorch-crf` decode output exactly
3. **Viterbi parity gate** (critical):
   - Run 1,000 test samples through both Python CRF decode and Python Viterbi
   - Require ≥99.9% token-level agreement
   - Document any disagreements
4. Verify CoreML emission outputs match PyTorch emissions (numerical parity)
5. Update `MODEL_CARD.md` with conversion metadata (coremltools version, model size, compute units)

**Targets (from PRD):**
- CoreML model loads and produces valid emissions
- Emission numerical parity: PyTorch vs CoreML within 0.01%
- Viterbi parity: ≥99.9% token agreement with CRF decode
- CoreML model size: reasonable (expect ~5 MB)

**Key Implementation Notes:**
- Use `coremltools` 8.x for conversion
- CoreML compute units: ALL (CPU + Neural Engine)
- The emission scorer is the BiLSTM + linear projection — no CRF layer in CoreML
- Variable-length sequences: use `ct.RangeDim` for dynamic input shape
- Viterbi decoder is the algorithm that CRF uses at inference time — implementing it separately verifies we can replicate CRF decode without the CRF layer

### Remaining Sessions After Phase 3

**Phase 4: MLIngredientParser Implementation (3-4h)**
- Implement `ViterbiDecoder.swift` and `MLIngredientParser.swift`
- Cross-validate tokenizer against Phase 0b test vectors
- Load CoreML model + transitions.json in Swift

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

**Dependencies**: All prerequisites ✅ | Dataset ✅ | Model trained ✅ | Checkpoint + CRF params + vocabulary exported ✅
**Model**: 1.35M params, 5.2 MB, 98.49% token accuracy — ready for CoreML conversion
**M8.4 PRD**: Execution-ready after 12 review passes. Phase 3 is pure Python ML work — no Swift changes needed.
