#!/usr/bin/env python3
from __future__ import annotations

"""
M8.4 Phase 8: Continuous Learning Pipeline — Retrain with Corrections

Fine-tunes the existing BiLSTM-CRF model using exported user corrections.
Reuses all infrastructure from train_model.py — no duplication of model/dataset/training code.

Usage:
    cd Tools/ml-training
    python retrain_with_corrections.py --corrections corrections.jsonl
    python retrain_with_corrections.py --corrections corrections.jsonl --skip-gate  # testing

Pipeline:
    1. Load corrections JSONL (validate format)
    2. Corpus gate (≥50 corrections, skip with --skip-gate)
    3. Load base training data
    4. Load existing model, evaluate baseline on test set
    5. Merge corrections into training set with oversampling, fine-tune
    6. Compare metrics, save retrained model only if improved
"""

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import DataLoader

from train_model import (
    BATCH_SIZE,
    GRAD_CLIP,
    LABEL_NAMES,
    LABEL_TO_ID,
    NUM_LABELS,
    IngredientDataset,
    IngredientTagger,
    collate_fn,
    compute_metrics,
    export_checkpoint,
    export_crf_params,
    load_jsonl,
    train_epoch,
    validate_epoch,
)

# Fine-tuning hyperparameters (lower LR to avoid catastrophic forgetting)
FINE_TUNE_LR = 0.0005
FINE_TUNE_MAX_EPOCHS = 10
FINE_TUNE_PATIENCE = 3
MAX_OVERSAMPLE = 50
MIN_CORRECTIONS = 50
SEED = 42


def load_corrections(path: Path) -> list[dict]:
    """Load and validate corrections JSONL file.

    Each line must be {"tokens": [...], "labels": [...]}.
    Validates: matching counts, valid labels.
    """
    corrections = []
    valid_labels = set(LABEL_NAMES)
    errors = []

    with open(path) as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                sample = json.loads(line)
            except json.JSONDecodeError as e:
                errors.append(f"  Line {line_num}: Invalid JSON — {e}")
                continue

            if "tokens" not in sample or "labels" not in sample:
                errors.append(f"  Line {line_num}: Missing 'tokens' or 'labels' key")
                continue

            tokens = sample["tokens"]
            labels = sample["labels"]

            if len(tokens) != len(labels):
                errors.append(
                    f"  Line {line_num}: Token count ({len(tokens)}) != label count ({len(labels)})"
                )
                continue

            invalid = [l for l in labels if l not in valid_labels]
            if invalid:
                errors.append(
                    f"  Line {line_num}: Invalid labels: {invalid}"
                )
                continue

            corrections.append(sample)

    if errors:
        print(f"\nValidation errors ({len(errors)}):")
        for e in errors:
            print(e)

    return corrections


def print_metrics_table(baseline: dict, retrained: dict) -> None:
    """Print before/after metrics comparison table."""
    print("\n" + "=" * 70)
    print("Metrics Comparison")
    print("=" * 70)
    print(f"  {'Metric':<30s}  {'Baseline':>10s}  {'Retrained':>10s}  {'Delta':>10s}")
    print(f"  {'-' * 64}")

    # Primary metrics
    for key, label in [
        ("token_accuracy", "Token accuracy"),
        ("sentence_accuracy", "Sentence accuracy"),
    ]:
        base_val = baseline[key] * 100
        new_val = retrained[key] * 100
        delta = new_val - base_val
        sign = "+" if delta >= 0 else ""
        print(f"  {label:<30s}  {base_val:>9.2f}%  {new_val:>9.2f}%  {sign}{delta:>9.2f}%")

    # Per-class F1
    print(f"\n  {'Per-class F1':<30s}")
    print(f"  {'-' * 64}")
    for label_name in LABEL_NAMES:
        base_f1 = baseline["per_class"][label_name]["f1"]
        new_f1 = retrained["per_class"][label_name]["f1"]
        delta = new_f1 - base_f1
        sign = "+" if delta >= 0 else ""
        print(
            f"  {label_name:<30s}  {base_f1:>10.4f}  {new_f1:>10.4f}  {sign}{delta:>10.4f}"
        )


def main():
    parser = argparse.ArgumentParser(
        description="M8.4 Phase 8: Fine-tune BiLSTM-CRF with user corrections"
    )
    parser.add_argument(
        "--corrections",
        type=Path,
        required=True,
        help="Path to corrections JSONL file (exported from ParsingTelemetryService)",
    )
    parser.add_argument(
        "--skip-gate",
        action="store_true",
        help=f"Skip minimum corpus gate ({MIN_CORRECTIONS} corrections)",
    )
    args = parser.parse_args()

    print("=" * 60)
    print("M8.4 Phase 8: Retrain with Corrections")
    print("=" * 60)

    torch.manual_seed(SEED)
    np.random.seed(SEED)

    if torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    print(f"\nDevice: {device}")

    data_dir = Path(__file__).parent / "data"
    models_dir = Path(__file__).parent / "models"
    retrained_dir = models_dir / "retrained"

    # --- 1. Load corrections ---
    print(f"\n[1/6] Loading corrections from {args.corrections}...")
    if not args.corrections.exists():
        print(f"  ERROR: File not found: {args.corrections}")
        sys.exit(1)

    corrections = load_corrections(args.corrections)
    print(f"  Loaded: {len(corrections)} valid corrections")

    if not corrections:
        print("  ERROR: No valid corrections found")
        sys.exit(1)

    # --- 2. Corpus gate ---
    print(f"\n[2/6] Corpus gate (minimum {MIN_CORRECTIONS} corrections)...")
    if len(corrections) < MIN_CORRECTIONS and not args.skip_gate:
        print(
            f"  SKIPPED: Only {len(corrections)} corrections (need {MIN_CORRECTIONS}). "
            f"Use --skip-gate to override."
        )
        sys.exit(0)
    elif args.skip_gate and len(corrections) < MIN_CORRECTIONS:
        print(f"  WARNING: Only {len(corrections)} corrections (gate skipped with --skip-gate)")
    else:
        print(f"  PASSED: {len(corrections)} corrections >= {MIN_CORRECTIONS}")

    # --- 3. Load base training data ---
    print("\n[3/6] Loading base training data...")
    train_samples = load_jsonl(data_dir / "training_data.jsonl")
    val_samples = load_jsonl(data_dir / "validation_data.jsonl")
    test_samples = load_jsonl(data_dir / "test_data.jsonl")
    print(f"  Train: {len(train_samples):,}")
    print(f"  Val:   {len(val_samples):,}")
    print(f"  Test:  {len(test_samples):,}")

    # --- 4. Load existing model + evaluate baseline ---
    print("\n[4/6] Loading existing model and evaluating baseline...")
    checkpoint_path = models_dir / "ingredient_tagger.pt"
    vocab_path = models_dir / "vocabulary.json"

    if not checkpoint_path.exists():
        print(f"  ERROR: Checkpoint not found: {checkpoint_path}")
        sys.exit(1)
    if not vocab_path.exists():
        print(f"  ERROR: Vocabulary not found: {vocab_path}")
        sys.exit(1)

    with open(vocab_path) as f:
        vocab = json.load(f)

    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)
    vocab_size = checkpoint["vocab_size"]

    model = IngredientTagger(
        vocab_size=vocab_size,
        embedding_dim=checkpoint.get("embedding_dim", 128),
        hidden_dim=checkpoint.get("hidden_dim", 256),
        num_labels=checkpoint.get("num_labels", NUM_LABELS),
        num_layers=checkpoint.get("num_layers", 2),
        dropout=checkpoint.get("dropout", 0.5),
    ).to(device)
    model.load_state_dict(checkpoint["model_state_dict"])

    test_dataset = IngredientDataset(test_samples, vocab)
    test_loader = DataLoader(
        test_dataset, batch_size=BATCH_SIZE, shuffle=False,
        collate_fn=collate_fn, num_workers=0,
    )

    baseline_metrics = compute_metrics(model, test_loader, device)
    print(f"  Baseline token accuracy:    {baseline_metrics['token_accuracy'] * 100:.2f}%")
    print(f"  Baseline sentence accuracy: {baseline_metrics['sentence_accuracy'] * 100:.2f}%")

    # --- 5. Merge + fine-tune ---
    print("\n[5/6] Merging corrections and fine-tuning...")

    # Calculate oversampling factor: target ~4.5% of training set
    target_fraction = 0.045
    target_count = int(len(train_samples) * target_fraction)
    oversample_factor = min(max(target_count // len(corrections), 1), MAX_OVERSAMPLE)
    oversampled_corrections = corrections * oversample_factor

    merged_train = train_samples + oversampled_corrections
    print(f"  Base training samples:  {len(train_samples):,}")
    print(f"  Corrections:            {len(corrections)} x {oversample_factor} = {len(oversampled_corrections)}")
    print(f"  Merged training set:    {len(merged_train):,}")
    print(f"  Correction fraction:    {len(oversampled_corrections) / len(merged_train) * 100:.1f}%")

    train_dataset = IngredientDataset(merged_train, vocab)
    val_dataset = IngredientDataset(val_samples, vocab)

    train_loader = DataLoader(
        train_dataset, batch_size=BATCH_SIZE, shuffle=True,
        collate_fn=collate_fn, num_workers=0,
    )
    val_loader = DataLoader(
        val_dataset, batch_size=BATCH_SIZE, shuffle=False,
        collate_fn=collate_fn, num_workers=0,
    )

    optimizer = torch.optim.Adam(model.parameters(), lr=FINE_TUNE_LR)

    print(f"\n  Fine-tuning (LR={FINE_TUNE_LR}, max {FINE_TUNE_MAX_EPOCHS} epochs, patience={FINE_TUNE_PATIENCE})...")
    best_val_loss = float("inf")
    patience_counter = 0
    best_epoch = 0
    best_state = None

    for epoch in range(1, FINE_TUNE_MAX_EPOCHS + 1):
        avg_train_loss = train_epoch(model, train_loader, optimizer, device)
        avg_val_loss = validate_epoch(model, val_loader, device)

        marker = ""
        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            best_epoch = epoch
            patience_counter = 0
            best_state = {k: v.clone() for k, v in model.state_dict().items()}
            marker = " *"
        else:
            patience_counter += 1

        print(f"  Epoch {epoch:2d}/{FINE_TUNE_MAX_EPOCHS} | Train: {avg_train_loss:.4f} | Val: {avg_val_loss:.4f}{marker}")

        if patience_counter >= FINE_TUNE_PATIENCE:
            print(f"\n  Early stopping at epoch {epoch} (best: epoch {best_epoch})")
            break

    # Load best fine-tuned state
    if best_state is not None:
        model.load_state_dict(best_state)

    # --- 6. Compare metrics ---
    print("\n[6/6] Evaluating fine-tuned model...")
    retrained_metrics = compute_metrics(model, test_loader, device)

    print_metrics_table(baseline_metrics, retrained_metrics)

    # Improvement gate: both primary metrics must improve
    token_improved = retrained_metrics["token_accuracy"] >= baseline_metrics["token_accuracy"]
    sentence_improved = retrained_metrics["sentence_accuracy"] >= baseline_metrics["sentence_accuracy"]

    if token_improved and sentence_improved:
        retrained_dir.mkdir(parents=True, exist_ok=True)

        # Save retrained checkpoint
        retrained_checkpoint = retrained_dir / "ingredient_tagger.pt"
        export_checkpoint(model, vocab_size, best_epoch, retrained_metrics, retrained_checkpoint)
        print(f"\n  Saved retrained checkpoint: {retrained_checkpoint}")

        # Save retrained CRF params
        retrained_transitions = retrained_dir / "transitions.json"
        export_crf_params(model, retrained_transitions)
        print(f"  Saved retrained CRF params: {retrained_transitions}")

        # Copy vocabulary (unchanged)
        retrained_vocab = retrained_dir / "vocabulary.json"
        retrained_vocab.write_text(vocab_path.read_text())
        print(f"  Copied vocabulary: {retrained_vocab}")

        print("\n  RESULT: Model IMPROVED — retrained artifacts saved to models/retrained/")
    else:
        reasons = []
        if not token_improved:
            reasons.append("token accuracy decreased")
        if not sentence_improved:
            reasons.append("sentence accuracy decreased")
        print(f"\n  RESULT: Model NOT improved ({', '.join(reasons)}) — no artifacts saved")

    print("=" * 60)


if __name__ == "__main__":
    main()
