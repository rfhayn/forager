# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 6 sessions)
**Status**: M8.4 Phase 0+1 ✅ **COMPLETE** | **Phase 2 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 2 — Model Architecture & Training (4-5h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 4, Phase 2)

### What's Already Done (Phases 0+1)
- ✅ Architecture locked: word-only BiLSTM v1, no char features
- ✅ Tokenizer spec frozen (`TOKENIZER_SPEC.md` + 100-sentence test vectors)
- ✅ Single-parse refactor complete (`parseCore()` → `parseUnified()`)
- ✅ Dataset ready: 68,846 unique samples in 80/10/10 JSONL splits
- ✅ Labels: 7 Forager labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER)
- ✅ Model card template + license attribution (MIT/Apache 2.0)
- ✅ Viterbi parity gate criteria documented

### Key Architecture Decisions (Unchanged)
- **CRF cannot convert to CoreML** — split into 3 components:
  1. BiLSTM emission scorer → CoreML `.mlpackage`
  2. CRF parameters → `crf_params.json` (7×7 transition matrix + 1×7 start transitions + 1×7 end transitions)
  3. Viterbi decoder → Pure Swift (~40 lines)
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers

### Phase 2: Model Training
```
Branch: feature/M8.4-ml-parsing (already created)
Working dir: Tools/ml-training/
```

**Tasks:**
1. Write `train_model.py`:
   - Build vocabulary from training data (word → index mapping)
   - Word-only BiLSTM-CRF architecture (embedding → BiLSTM → linear → CRF)
   - Training loop with early stopping on validation loss
   - Evaluation: token accuracy, sentence accuracy, per-class F1 (QTY, UNIT, NAME)
2. Train on `data/training_data.jsonl` (55,076 samples)
3. Evaluate on `data/validation_data.jsonl` (6,885 samples) during training
4. Final evaluation on `data/test_data.jsonl` (6,885 samples)
5. Export:
   - Model checkpoint (`.pt`)
   - CRF parameters: `crf_params.json` (7×7 transitions + 1×7 start + 1×7 end)
   - Vocabulary: `vocab.json` (word → index + label → index)
6. Fill in `MODEL_CARD.md` with training metadata (accuracy, F1, hyperparameters)

**Targets (from PRD):**
- Token accuracy: ≥96%
- Sentence accuracy: ≥92%
- Per-class F1 (QTY, UNIT, NAME): ≥0.90 each

**Key Implementation Notes:**
- Use PyTorch with `torchcrf` for CRF layer
- Embedding dim: 128, hidden dim: 128, 2 BiLSTM layers, dropout 0.3
- Batch size: 64, learning rate: 0.001 with Adam
- Variable-length inputs — use `pack_padded_sequence` for efficient BiLSTM
- CRF layer handles transition constraints during training (Viterbi during inference)

### Remaining Sessions After Phase 2

**Session 6: Phases 3+4 — CoreML Export + Swift Implementation (5-7h)**
- Extract BiLSTM emission scorer → `.mlpackage` via coremltools
- Export ALL CRF parameters (transitions + start_transitions + end_transitions)
- **Viterbi parity gate**: ≥99.9% token agreement with Python CRF decode
- Implement `ViterbiDecoder.swift` and `MLIngredientParser.swift`
- Cross-validate tokenizer against Phase 0b test vectors

**Session 7: Phases 5+6 — Integration + Test Suite (4-6h)**
- Add `mlParser: IngredientParser?` to HybridIngredientParser init
- Update routing: regex ≥0.9 → ML ≥0.8 → NLP fallback
- Winner-only attribution updates
- 20+ test cases

**Session 8: Phases 7+8 — Corrections + Continuous Learning (4-5h)**
- Telemetry schema v3, correction instrumentation, BIO export

**Session 9: Phase 9 — Integration Testing + Documentation (1-2h)**
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

**Dependencies**: All prerequisites ✅ | Dataset ready ✅ | Training infrastructure set up ✅
**Dataset**: 68,846 samples (55k train / 6.9k val / 6.9k test), 7 labels, 5 sources, stratified splits
**M8.4 PRD**: Execution-ready after 12 review passes. Phase 2 is pure Python ML work — no Swift changes needed.
