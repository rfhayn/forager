# Model Card — Forager Ingredient Tagger

**Model Name**: IngredientTaggerEmissions
**Version**: (filled after training)
**Date Trained**: (filled after training)
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
| Vocabulary size | (filled after training) |
| Total parameters | (filled after training) |

### v1 Decision: Word-Only

Character-level features (char CNN/LSTM) add dual-input CoreML conversion complexity and per-token character ID preprocessing with marginal accuracy gain on this vocabulary. strangetom CRF achieves 95.25% sentence accuracy without them.

---

## Training Data

| Field | Value |
|-------|-------|
| Primary dataset | strangetom/ingredient-parser (MIT) |
| Supplement | NYT/ingredient-phrase-tagger (Apache 2.0) |
| Total sentences | (filled after training) |
| Unique sentences (after dedup) | (filled after training) |
| Label mapping | strangetom 13 → Forager 7 |
| Dataset snapshot SHA-256 | (filled after training) |
| Train/val/test split | 80/10/10 (stratified by source) |
| Split hash | (filled after training) |

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
| Random seed | (filled after training) |
| Training duration | (filled after training) |

---

## Evaluation Metrics

| Metric | Value |
|--------|-------|
| Token-level accuracy (test) | (filled after training) |
| Sentence-level accuracy (test) | (filled after training) |
| Per-class F1 — QTY | (filled after training) |
| Per-class F1 — UNIT | (filled after training) |
| Per-class F1 — NAME | (filled after training) |
| Per-class F1 — MODIFIER | (filled after training) |
| Per-class F1 — PREP | (filled after training) |
| Per-class F1 — COMMENT | (filled after training) |
| Per-class F1 — OTHER | (filled after training) |

---

## Conversion

| Field | Value |
|-------|-------|
| PyTorch version | (filled after training) |
| coremltools version | (filled after training) |
| CoreML model size (disk) | (filled after training) |
| CoreML compute units | ALL (CPU + Neural Engine) |
| Input shape | `token_ids: (1, RangeDim(1, 64))` Int32 |
| Output shape | `emissions: (1, seq_len, 7)` Float |

---

## CRF Parameters

Exported separately (not in CoreML model):
- `transitions.json` — 7×7 transition matrix + 1×7 start transitions + 1×7 end transitions + label names
- Decoded by `ViterbiDecoder.swift` at runtime

---

## Viterbi Parity

| Metric | Value |
|--------|-------|
| Test samples | 1000 held-out |
| Token agreement (Swift vs Python) | (filled after conversion) |
| Gate threshold | ≥ 99.9% |
| Disagreements documented | (filled after conversion) |

---

## Intended Use

On-device ingredient string parsing for the Forager iOS app. All inference runs locally — no user data leaves the device.

---

## Limitations

- English only
- Word-level embeddings only (no subword or character features)
- Trained on recipe ingredient strings — may not generalize to other domains
- Requires CRF parameter file and Viterbi decoder for label sequence decoding
