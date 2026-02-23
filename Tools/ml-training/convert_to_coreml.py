#!/usr/bin/env python3
from __future__ import annotations

"""
M8.4 Phase 3: CoreML Conversion + Viterbi Parity Gate

Converts the trained BiLSTM-CRF into:
  1. CoreML .mlpackage (BiLSTM emission scorer only — no CRF)
  2. Verifies transitions.json already exported in Phase 2
  3. Python reference Viterbi decoder
  4. Viterbi parity gate (1,000 test samples, >=99.9% token agreement)

The CRF layer cannot convert to CoreML (dynamic programming is not a static
graph op). Instead we ship the CRF's learned parameters as JSON and implement
Viterbi decoding in Swift (Phase 4).

Usage:
    cd Tools/ml-training
    python convert_to_coreml.py
"""

import json
import sys
import time
from pathlib import Path

import coremltools as ct
import numpy as np
import torch
import torch.nn as nn
from torch.nn.utils.rnn import pack_padded_sequence, pad_packed_sequence, pad_sequence

# Import model architecture and constants from training script
from train_model import (
    EMBEDDING_DIM,
    HIDDEN_DIM,
    LABEL_NAMES,
    LABEL_TO_ID,
    NUM_LABELS,
    NUM_LSTM_LAYERS,
    DROPOUT,
    PAD_ID,
    UNK_ID,
    IngredientTagger,
    IngredientDataset,
    collate_fn,
    load_jsonl,
)

# --- Paths ---

MODELS_DIR = Path("models")
DATA_DIR = Path("data")
CHECKPOINT_PATH = MODELS_DIR / "ingredient_tagger.pt"
TRANSITIONS_PATH = MODELS_DIR / "transitions.json"
VOCABULARY_PATH = MODELS_DIR / "vocabulary.json"
COREML_OUTPUT_PATH = MODELS_DIR / "IngredientTaggerEmissions.mlpackage"
PARITY_REPORT_PATH = Path("parity_report.md")
TEST_DATA_PATH = DATA_DIR / "test_data.jsonl"


# --- Emission Scorer Wrapper ---


class EmissionScorer(nn.Module):
    """Wraps word embedding + BiLSTM + linear projection, excluding CRF.

    This is the portion of the model that converts to CoreML. It takes
    token_ids (1, seq_len) and returns emission scores (1, seq_len, 7).

    For CoreML conversion, we cannot use pack_padded_sequence (dynamic op),
    so we run the LSTM on the full padded input. For single-sequence inference
    (batch_size=1) with no padding, this produces identical results.
    """

    def __init__(self, full_model: IngredientTagger):
        super().__init__()
        self.embedding = full_model.embedding
        self.lstm = full_model.lstm
        self.linear = full_model.linear
        # No dropout at inference time (model is in evaluation mode)

    def forward(self, token_ids: torch.Tensor) -> torch.Tensor:
        """Forward pass producing raw emission scores.

        Args:
            token_ids: (1, seq_len) int32 tensor of token indices

        Returns:
            emissions: (1, seq_len, num_labels) float32 emission scores
        """
        embedded = self.embedding(token_ids)
        lstm_out, _ = self.lstm(embedded)
        emissions = self.linear(lstm_out)
        return emissions


# --- Python Reference Viterbi Decoder ---


def viterbi_decode(
    emissions: np.ndarray,
    transitions: np.ndarray,
    start_transitions: np.ndarray,
    end_transitions: np.ndarray,
) -> list[int]:
    """Reference Viterbi decoder matching pytorch-crf decode behavior.

    Standard Viterbi algorithm: forward pass with backpointers, then backtrace.

    Args:
        emissions: (seq_len, num_labels) emission scores
        transitions: (num_labels, num_labels) transition[i][j] = score for i->j
        start_transitions: (num_labels,) start-of-sequence scores
        end_transitions: (num_labels,) end-of-sequence scores

    Returns:
        Best label sequence as list of label indices
    """
    seq_len, num_labels = emissions.shape

    # Viterbi scores and backpointers
    viterbi = np.full((seq_len, num_labels), -np.inf, dtype=np.float64)
    backpointers = np.zeros((seq_len, num_labels), dtype=np.int64)

    # Initialize: start transitions + first token emissions
    viterbi[0] = start_transitions + emissions[0]

    # Forward pass
    for t in range(1, seq_len):
        for j in range(num_labels):
            # Score of arriving at label j at position t from each label i
            scores = viterbi[t - 1] + transitions[:, j] + emissions[t, j]
            best_i = np.argmax(scores)
            viterbi[t, j] = scores[best_i]
            backpointers[t, j] = best_i

    # Add end transitions
    viterbi[seq_len - 1] += end_transitions

    # Backtrace
    best_path = [0] * seq_len
    best_path[seq_len - 1] = int(np.argmax(viterbi[seq_len - 1]))
    for t in range(seq_len - 2, -1, -1):
        best_path[t] = int(backpointers[t + 1][best_path[t + 1]])

    return best_path


# --- Main ---


def set_inference_mode(m: nn.Module) -> None:
    """Set model to inference mode (disables dropout, batchnorm, etc.)."""
    m.train(False)


def main():
    print("=" * 60)
    print("M8.4 Phase 3: CoreML Conversion + Viterbi Parity Gate")
    print("=" * 60)

    # --- Step 1: Load checkpoint ---
    print("\n[1/6] Loading trained checkpoint...")
    checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=False)
    vocab = json.loads(VOCABULARY_PATH.read_text())
    vocab_size = len(vocab)
    print(f"  Vocabulary size: {vocab_size}")
    print(f"  Checkpoint keys: {list(checkpoint.keys())}")

    # Reconstruct full model
    model = IngredientTagger(vocab_size=vocab_size)
    model.load_state_dict(checkpoint["model_state_dict"])
    set_inference_mode(model)
    print("  Model loaded and set to inference mode")

    # --- Step 2: Extract emission scorer ---
    print("\n[2/6] Extracting emission scorer (embedding + BiLSTM + linear)...")
    emission_scorer = EmissionScorer(model)
    set_inference_mode(emission_scorer)

    # Verify emission outputs match the full model's _get_emissions
    test_input = torch.tensor([[3, 10, 50, 100, 7]], dtype=torch.long)
    test_lengths = torch.tensor([5])

    with torch.no_grad():
        # Full model emissions (uses pack_padded_sequence)
        full_emissions = model._get_emissions(test_input, test_lengths)
        # Wrapper emissions (no packing -- for CoreML compatibility)
        wrapper_emissions = emission_scorer(test_input)

    max_diff = (full_emissions - wrapper_emissions).abs().max().item()
    print(f"  Emission parity check (pack vs no-pack): max_diff = {max_diff:.6e}")
    if max_diff > 1e-5:
        print(f"  WARNING: Emission difference {max_diff} exceeds 1e-5 threshold")
        print("  This may indicate a packing/padding issue")
    else:
        print("  PASS: Emissions match within tolerance")

    # --- Step 3: Trace and convert to CoreML ---
    print("\n[3/6] Converting to CoreML...")
    # Trace with a representative input
    example_input = torch.randint(0, vocab_size, (1, 10), dtype=torch.long)
    traced_model = torch.jit.trace(emission_scorer, example_input)

    # Convert to CoreML with variable-length input
    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.TensorType(
                name="token_ids",
                shape=ct.Shape(shape=(1, ct.RangeDim(1, 64))),
                dtype=np.int32,
            )
        ],
        outputs=[ct.TensorType(name="emissions")],
        compute_precision=ct.precision.FLOAT32,
        minimum_deployment_target=ct.target.iOS18,
    )

    # Add metadata
    mlmodel.author = "Forager"
    mlmodel.short_description = (
        "BiLSTM emission scorer for ingredient token labeling. "
        "Outputs raw emission scores per token for 7 labels "
        "(QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER). "
        "Use with Viterbi decoder + transitions.json for final predictions."
    )
    mlmodel.version = "1.0"

    mlmodel.save(str(COREML_OUTPUT_PATH))
    coreml_size = sum(
        f.stat().st_size for f in COREML_OUTPUT_PATH.rglob("*") if f.is_file()
    )
    print(f"  Saved: {COREML_OUTPUT_PATH} ({coreml_size / 1024 / 1024:.2f} MB)")

    # --- Step 4: Verify CoreML emission parity ---
    print("\n[4/6] Verifying CoreML emission parity...")
    coreml_model = ct.models.MLModel(str(COREML_OUTPUT_PATH))

    # Test with multiple sequence lengths
    parity_diffs = []
    for seq_len in [3, 7, 10, 15, 20]:
        test_ids = torch.randint(0, vocab_size, (1, seq_len), dtype=torch.long)
        with torch.no_grad():
            pytorch_out = emission_scorer(test_ids).numpy()

        coreml_out = coreml_model.predict(
            {"token_ids": test_ids.numpy().astype(np.int32)}
        )["emissions"]

        diff = np.abs(pytorch_out - coreml_out).max()
        parity_diffs.append(diff)
        print(f"  seq_len={seq_len}: max_diff={diff:.6e}")

    max_parity_diff = max(parity_diffs)
    emission_parity_pass = max_parity_diff < 0.01
    print(
        f"  Overall max diff: {max_parity_diff:.6e} "
        f"{'PASS' if emission_parity_pass else 'FAIL'} (threshold: 0.01)"
    )

    # --- Step 5: Viterbi parity gate ---
    print("\n[5/6] Running Viterbi parity gate (1,000 test samples)...")

    # Load CRF parameters
    crf_params = json.loads(TRANSITIONS_PATH.read_text())
    trans = np.array(crf_params["transitions"], dtype=np.float64)
    start_trans = np.array(crf_params["start_transitions"], dtype=np.float64)
    end_trans = np.array(crf_params["end_transitions"], dtype=np.float64)

    # Load test data
    test_samples = load_jsonl(TEST_DATA_PATH)[:1000]
    print(f"  Loaded {len(test_samples)} test samples")

    total_tokens = 0
    matching_tokens = 0
    total_sentences = 0
    matching_sentences = 0
    disagreements = []

    for i, sample in enumerate(test_samples):
        tokens = sample["tokens"]
        token_ids = [vocab.get(t, UNK_ID) for t in tokens]
        token_tensor = torch.tensor([token_ids], dtype=torch.long)
        lengths = torch.tensor([len(token_ids)])
        mask = torch.ones(1, len(token_ids), dtype=torch.bool)

        # Full PyTorch CRF decode (ground truth)
        with torch.no_grad():
            crf_labels = model.predict(token_tensor, lengths, mask)[0]

        # Split decode: PyTorch emissions + Python Viterbi
        with torch.no_grad():
            emissions = emission_scorer(token_tensor).numpy()[0]  # (seq_len, 7)

        viterbi_labels = viterbi_decode(emissions, trans, start_trans, end_trans)

        # Compare
        seq_match = True
        for j, (crf_l, vit_l) in enumerate(zip(crf_labels, viterbi_labels)):
            total_tokens += 1
            if crf_l == vit_l:
                matching_tokens += 1
            else:
                seq_match = False
                if len(disagreements) < 20:  # Cap logged disagreements
                    disagreements.append(
                        {
                            "sample_idx": i,
                            "token_idx": j,
                            "token": tokens[j],
                            "crf_label": LABEL_NAMES[crf_l],
                            "viterbi_label": LABEL_NAMES[vit_l],
                        }
                    )

        total_sentences += 1
        if seq_match:
            matching_sentences += 1

    token_agreement = matching_tokens / total_tokens * 100
    sentence_agreement = matching_sentences / total_sentences * 100
    viterbi_parity_pass = token_agreement >= 99.9

    print(f"  Token agreement: {matching_tokens}/{total_tokens} ({token_agreement:.4f}%)")
    print(f"  Sentence agreement: {matching_sentences}/{total_sentences} ({sentence_agreement:.2f}%)")
    print(f"  Viterbi parity gate: {'PASS' if viterbi_parity_pass else 'FAIL'} (threshold: >=99.9%)")

    if disagreements:
        print(f"  Disagreements ({len(disagreements)} logged):")
        for d in disagreements[:5]:
            print(
                f"    Sample {d['sample_idx']}, token {d['token_idx']} "
                f"'{d['token']}': CRF={d['crf_label']} vs Viterbi={d['viterbi_label']}"
            )

    # --- Step 5b: Also run CoreML emissions through Viterbi (end-to-end check) ---
    print("\n[5b/6] End-to-end check: CoreML emissions + Python Viterbi...")
    e2e_matching = 0
    e2e_total = 0
    for i, sample in enumerate(test_samples[:100]):  # 100 samples for e2e
        tokens = sample["tokens"]
        token_ids = [vocab.get(t, UNK_ID) for t in tokens]
        token_np = np.array([token_ids], dtype=np.int32)

        # CRF ground truth
        token_tensor = torch.tensor([token_ids], dtype=torch.long)
        lengths = torch.tensor([len(token_ids)])
        mask = torch.ones(1, len(token_ids), dtype=torch.bool)
        with torch.no_grad():
            crf_labels = model.predict(token_tensor, lengths, mask)[0]

        # CoreML emissions + Viterbi
        coreml_emissions = coreml_model.predict({"token_ids": token_np})["emissions"][0]
        viterbi_labels = viterbi_decode(coreml_emissions, trans, start_trans, end_trans)

        for crf_l, vit_l in zip(crf_labels, viterbi_labels):
            e2e_total += 1
            if crf_l == vit_l:
                e2e_matching += 1

    e2e_agreement = e2e_matching / e2e_total * 100
    print(f"  CoreML end-to-end agreement: {e2e_matching}/{e2e_total} ({e2e_agreement:.4f}%)")

    # --- Step 6: Write parity report ---
    print("\n[6/6] Writing parity report...")
    report = f"""# M8.4 Phase 3: Viterbi Parity Report

**Date**: {time.strftime('%Y-%m-%d %H:%M')}
**Model**: IngredientTagger (BiLSTM-CRF, word-only v1)
**Checkpoint**: `models/ingredient_tagger.pt`
**CoreML output**: `models/IngredientTaggerEmissions.mlpackage`

---

## Emission Parity (PyTorch vs CoreML)

| Sequence Length | Max Absolute Difference |
|-----------------|------------------------|
"""
    for seq_len, diff in zip([3, 7, 10, 15, 20], parity_diffs):
        report += f"| {seq_len} | {diff:.6e} |\n"

    report += f"""
**Overall max difference**: {max_parity_diff:.6e}
**Status**: {'PASS' if emission_parity_pass else 'FAIL'} (threshold: <0.01)

## Viterbi Parity Gate (PyTorch CRF decode vs Python Viterbi)

- **Test samples**: {len(test_samples)}
- **Total tokens**: {total_tokens}
- **Matching tokens**: {matching_tokens}
- **Token agreement**: {token_agreement:.4f}%
- **Sentence agreement**: {sentence_agreement:.2f}%
- **Gate threshold**: >=99.9% token agreement
- **Status**: {'PASS' if viterbi_parity_pass else 'FAIL'}

## End-to-End (CoreML emissions + Python Viterbi vs PyTorch CRF)

- **Test samples**: 100
- **Total tokens**: {e2e_total}
- **Matching tokens**: {e2e_matching}
- **Token agreement**: {e2e_agreement:.4f}%

"""

    if disagreements:
        report += "## Disagreements (first 20)\n\n"
        report += "| Sample | Token Idx | Token | CRF Label | Viterbi Label |\n"
        report += "|--------|-----------|-------|-----------|---------------|\n"
        for d in disagreements:
            report += (
                f"| {d['sample_idx']} | {d['token_idx']} | "
                f"`{d['token']}` | {d['crf_label']} | {d['viterbi_label']} |\n"
            )
    else:
        report += "## Disagreements\n\nNone -- perfect parity.\n"

    report += f"""
## Model Summary

- **CoreML model size**: {coreml_size / 1024 / 1024:.2f} MB
- **coremltools version**: {ct.__version__}
- **Compute precision**: FLOAT32
- **Minimum deployment target**: iOS 18
- **Input**: `token_ids: Int32 (1, seq_len)` where seq_len in [1, 64]
- **Output**: `emissions: Float32 (1, seq_len, 7)`
"""

    PARITY_REPORT_PATH.write_text(report)
    print(f"  Report saved: {PARITY_REPORT_PATH}")

    # --- Summary ---
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    all_pass = emission_parity_pass and viterbi_parity_pass
    print(f"  Emission parity:  {'PASS' if emission_parity_pass else 'FAIL'}")
    print(f"  Viterbi parity:   {'PASS' if viterbi_parity_pass else 'FAIL'} ({token_agreement:.4f}%)")
    print(f"  End-to-end:       {e2e_agreement:.4f}%")
    print(f"  CoreML model:     {coreml_size / 1024 / 1024:.2f} MB")
    print(f"  Overall:          {'ALL GATES PASSED' if all_pass else 'GATE FAILURE'}")
    print("=" * 60)

    if not all_pass:
        sys.exit(1)


if __name__ == "__main__":
    main()
