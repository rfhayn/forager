# Next Implementation Prompt

**Last Updated**: February 22, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 8 sessions)
**Status**: M8.4 Phase 0-7 ✅ **COMPLETE** | **Phase 8 NEXT**
**Branch**: `feature/M8.4-ml-parsing`

---

## **NEXT: M8.4 Phase 8 — Continuous Learning Pipeline (2h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (Section 5, Phase 8)

### What's Already Done (Phases 0-7)
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
- ✅ Correction instrumentation: schema v3, 3 edit flows wired, corpus gate display, 6 new tests

### Phase 8 Tasks

**BIO Export from Correction Events**
- Export correction events as BIO-format training data
- Script in `Tools/ml-training/retrain_with_corrections.py`

**Retraining Pipeline**
- Merge correction corpus with original training data
- Fine-tune existing model with user corrections
- Gate: requires ≥50 corrections (corpus gate from Phase 7)

**Key Files to Reference:**
- `Services/ParsingTelemetryService.swift` — correction events to export
- `Tools/ml-training/train_model.py` — existing training pipeline
- PRD Section 5, Phase 8 — detailed specifications

### Remaining Sessions After Phase 8

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

**Dependencies**: All prerequisites ✅ | CoreML model in bundle ✅ | 3-tier routing ✅ | Test suite ✅ | Correction instrumentation ✅
**Model**: 1.35M params, 5.15 MB CoreML, 98.49% token accuracy, 100% Viterbi parity
**M8.4 PRD**: Phase 8 is continuous learning — BIO export + retraining pipeline. Gated on ≥50 corrections.
