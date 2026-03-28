# Model Card — Forager Ingredient Tagger

**Model Name**: IngredientTaggerEmissions
**Version**: 2.0
**Date Trained**: 2026-03-27
**Architecture**: Word-only BiLSTM emission scorer (v2)

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
| Vocabulary size | 5,454 (+82 from v1) |
| Total parameters | 1,359,430 |

### v1 → v2 Changes

- Vocabulary expanded from 5,372 to 5,454 tokens (+82 from harness training data)
- Retrained from scratch on combined dataset (strangetom + harness, 4x oversample)
- No architecture changes — same embedding/hidden dims, same label set

---

## Training Data

| Field | Value |
|-------|-------|
| Primary dataset | strangetom/ingredient-parser (MIT) |
| Supplement | NYT/ingredient-phrase-tagger (Apache 2.0) |
| Harness data | 1,440 AI-labeled entries from M16 parsing harness |
| Total sentences | ~82,700 (68,846 strangetom + ~1,300 harness after dedup) |
| Harness oversample | 4x (effective ~15% of training set) |
| Label mapping | strangetom 13 → Forager 7; harness AI fields → BIO tokens |
| Train/val/test split | 80/10/10 (stratified, harness proportional in all splits) |

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
| Best epoch | 26 |
| Training duration | 2627s (43.8 min) |

---

## Evaluation Metrics

### Strangetom Test Set (6,885 samples)

| Metric | v1.0 | v2.0 | Delta |
|--------|------|------|-------|
| Token-level accuracy | 98.49% | 98.54% | +0.05% |
| Sentence-level accuracy | 95.40% | 95.34% | -0.06% |
| Per-class F1 — QTY | 0.9968 | 0.9970 | +0.0002 |
| Per-class F1 — UNIT | 0.9939 | 0.9942 | +0.0003 |
| Per-class F1 — NAME | 0.9869 | 0.9872 | +0.0003 |
| Per-class F1 — MODIFIER | 0.9261 | 0.9283 | +0.0022 |
| Per-class F1 — PREP | 0.9789 | 0.9790 | +0.0001 |
| Per-class F1 — COMMENT | 0.9463 | 0.9486 | +0.0023 |
| Per-class F1 — OTHER | 0.9997 | 0.9994 | -0.0003 |

### Harness Test Set (132 samples)

| Metric | v1.0 | v2.0 | Delta |
|--------|------|------|-------|
| Token-level accuracy | 65.77% | 79.22% | +13.45% |
| Sentence-level accuracy | 15.91% | 49.24% | +33.33% |

---

## Conversion

| Field | Value |
|-------|-------|
| PyTorch version | 2.8.0 |
| coremltools version | 9.0 |
| CoreML model size (disk) | ~5.2 MB |
| CoreML compute precision | FLOAT32 |
| CoreML minimum deployment | iOS 18 |
| CoreML compute units | ALL (CPU + Neural Engine) |
| Input shape | `token_ids: (1, RangeDim(1, 64))` Int32 |
| Output shape | `emissions: (1, seq_len, 7)` Float32 |

---

## CRF Parameters

Exported separately (not in CoreML model):
- `transitions.json` — 7×7 transition matrix + 1×7 start transitions + 1×7 end transitions + label names
- Decoded by `ViterbiDecoder.swift` at runtime

---

## Intended Use

On-device ingredient string parsing for the Forager iOS app. All inference runs locally — no user data leaves the device.

---

## Limitations

- English only
- Word-level embeddings only (no subword or character features)
- Trained on recipe ingredient strings — may not generalize to other domains
- Requires CRF parameter file and Viterbi decoder for label sequence decoding
- v2 model may label unit tokens differently than v1 on some edge cases (e.g., "cups" as NAME); the hybrid router's regex tier handles standard inputs at higher confidence

---

## Version History

| Version | Date | Vocab | Strangetom Token Acc | Harness Token Acc |
|---------|------|-------|---------------------|-------------------|
| v1.0 | 2026-02-21 | 5,372 | 98.49% | 65.77% |
| v2.0 | 2026-03-27 | 5,454 | 98.54% | 79.22% |
