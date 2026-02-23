# Model Card — Forager Ingredient Tagger

**Model Name**: IngredientTaggerEmissions
**Version**: 1.0
**Date Trained**: 2026-02-21
**Architecture**: Word-only BiLSTM emission scorer (v1)

---

## Model Description

Token-level sequence labeler for ingredient string parsing. Classifies each word token into one of 7 labels: QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER.

The emission scorer is the BiLSTM + linear projection component of a BiLSTM-CRF model. CRF transition parameters are exported separately as `transitions.json` and decoded via a pure-Swift Viterbi decoder at runtime.

---

## Architecture

| Component | Value |
|-----------|-------|
| Type | BiLSTM + Linear (emission scorer only) |
| Embedding dim | 128 (word-only, no char features) |
| Hidden dim | 256 |
| LSTM layers | 2 |
| Dropout | 0.5 |
| Output labels | 7 |
| Vocabulary size | 5,372 |
| Total parameters | 1,348,934 |

### v1 Decision: Word-Only

Character-level features (char CNN/LSTM) add dual-input CoreML conversion complexity and per-token character ID preprocessing with marginal accuracy gain on this vocabulary. strangetom CRF achieves 95.25% sentence accuracy without them.

---

## Training Data

| Field | Value |
|-------|-------|
| Primary dataset | strangetom/ingredient-parser (MIT) |
| Supplement | NYT/ingredient-phrase-tagger (Apache 2.0) |
| Total sentences | 81,316 |
| Unique sentences (after dedup) | 68,846 |
| Label mapping | strangetom 13 → Forager 7 |
| Dataset snapshot SHA-256 | `ead59b783d4a8ff8...` |
| Train/val/test split | 80/10/10 (stratified by source) |
| Split hash | `de9b8c5cb0b7fdee...` |

---

## Training Configuration

| Hyperparameter | Value |
|----------------|-------|
| Optimizer | Adam |
| Learning rate | 0.001 |
| Batch size | 64 |
| Max epochs | 30 |
| Early stopping patience | 5 |
| Dropout | 0.5 |
| Random seed | 42 |
| Training duration | 2326s (38.8 min) |

---

## Evaluation Metrics

| Metric | Value |
|--------|-------|
| Token-level accuracy (test) | 98.49% |
| Sentence-level accuracy (test) | 95.40% |
| Per-class F1 — QTY | 0.9968 |
| Per-class F1 — UNIT | 0.9939 |
| Per-class F1 — NAME | 0.9869 |
| Per-class F1 — MODIFIER | 0.9261 |
| Per-class F1 — PREP | 0.9789 |
| Per-class F1 — COMMENT | 0.9463 |
| Per-class F1 — OTHER | 0.9997 |

---

## Conversion

| Field | Value |
|-------|-------|
| PyTorch version | 2.8.0 |
| coremltools version | 9.0 |
| CoreML model size (disk) | 5.15 MB |
| CoreML compute precision | FLOAT32 |
| CoreML minimum deployment | iOS 18 |
| CoreML compute units | ALL (CPU + Neural Engine) |
| Input shape | `token_ids: (1, RangeDim(1, 64))` Int32 |
| Output shape | `emissions: (1, seq_len, 7)` Float32 |
| Emission parity (PyTorch vs CoreML) | max diff 4.77e-06 |

---

## CRF Parameters

Exported separately (not in CoreML model):
- `transitions.json` — 7×7 transition matrix + 1×7 start transitions + 1×7 end transitions + label names
- Decoded by `ViterbiDecoder.swift` at runtime

---

## Viterbi Parity

| Metric | Value |
|--------|-------|
| Test samples | 1,000 held-out |
| Token agreement (Python CRF vs Python Viterbi) | 100.0000% (8,030/8,030) |
| Sentence agreement | 100.00% (1,000/1,000) |
| End-to-end (CoreML + Viterbi vs CRF) | 100.0000% (794/794 on 100 samples) |
| Gate threshold | >= 99.9% |
| Gate status | **PASS** |
| Disagreements | 0 |

---

## Intended Use

On-device ingredient string parsing for the Forager iOS app. All inference runs locally — no user data leaves the device.

---

## Limitations

- English only
- Word-level embeddings only (no subword or character features)
- Trained on recipe ingredient strings — may not generalize to other domains
- Requires CRF parameter file and Viterbi decoder for label sequence decoding
