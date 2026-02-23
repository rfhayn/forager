# M8.4 ML Training Infrastructure

Training tooling for the Forager ingredient parser ML model.

## Architecture

BiLSTM-CRF split into 3 components for on-device inference:
1. **BiLSTM emission scorer** → CoreML `.mlpackage` (word-only v1)
2. **CRF parameters** → `transitions.json` (7×7 transitions + start/end vectors)
3. **Viterbi decoder** → Pure Swift (~40 lines)

## Setup

```bash
cd tools/ml-training
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Pipeline

```bash
# Phase 1: Prepare dataset
python prepare_dataset.py

# Phase 2: Train model
python train_model.py

# Phase 3: Convert to CoreML
python convert_to_coreml.py

# Phase 3: Validate Viterbi parity
python validate_parity.py

# Phase 5: Calibrate routing thresholds (optional)
python calibrate_thresholds.py
```

## Datasets

- **strangetom/ingredient-parser** (MIT) — 81k sentences, SQLite, pre-tokenized
- **NYT/ingredient-phrase-tagger** (Apache 2.0) — 180k examples, CSV, sentence-level labels

See `LICENSES.md` for full attribution.

## Output Files (bundled in iOS app)

- `models/IngredientTaggerEmissions.mlpackage` — CoreML emission scorer
- `models/transitions.json` — CRF parameters
- `models/vocabulary.json` — Token→ID mapping

## Key Documents

- `TOKENIZER_SPEC.md` — Frozen tokenizer contract (Python ↔ Swift must match)
- `MODEL_CARD.md` — Model governance metadata
- `LICENSES.md` — Dataset license attribution
