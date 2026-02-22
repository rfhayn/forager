# M8.4 Phase 3: Viterbi Parity Report

**Date**: 2026-02-22 10:42
**Model**: IngredientTagger (BiLSTM-CRF, word-only v1)
**Checkpoint**: `models/ingredient_tagger.pt`
**CoreML output**: `models/IngredientTaggerEmissions.mlpackage`

---

## Emission Parity (PyTorch vs CoreML)

| Sequence Length | Max Absolute Difference |
|-----------------|------------------------|
| 3 | 4.768372e-06 |
| 7 | 4.768372e-06 |
| 10 | 3.814697e-06 |
| 15 | 2.384186e-06 |
| 20 | 3.814697e-06 |

**Overall max difference**: 4.768372e-06
**Status**: PASS (threshold: <0.01)

## Viterbi Parity Gate (PyTorch CRF decode vs Python Viterbi)

- **Test samples**: 1000
- **Total tokens**: 8030
- **Matching tokens**: 8030
- **Token agreement**: 100.0000%
- **Sentence agreement**: 100.00%
- **Gate threshold**: >=99.9% token agreement
- **Status**: PASS

## End-to-End (CoreML emissions + Python Viterbi vs PyTorch CRF)

- **Test samples**: 100
- **Total tokens**: 794
- **Matching tokens**: 794
- **Token agreement**: 100.0000%

## Disagreements

None -- perfect parity.

## Model Summary

- **CoreML model size**: 5.15 MB
- **coremltools version**: 9.0
- **Compute precision**: FLOAT32
- **Minimum deployment target**: iOS 18
- **Input**: `token_ids: Int32 (1, seq_len)` where seq_len in [1, 64]
- **Output**: `emissions: Float32 (1, seq_len, 7)`
