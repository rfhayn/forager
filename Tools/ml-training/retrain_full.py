#!/usr/bin/env python3
"""
M16.9.3: Full retrain of BiLSTM-CRF model with combined strangetom + harness data.

Combines original strangetom training data (55K) with harness-generated data (1.3K),
rebuilds vocabulary, oversamples harness data, trains from scratch, evaluates on
both strangetom and harness test sets.

Usage:
    cd Tools/ml-training
    source venv/bin/activate
    python retrain_full.py [--oversample N] [--dry-run]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import time
from collections import Counter
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import DataLoader

from train_model import (
    BATCH_SIZE,
    EMBEDDING_DIM,
    GRAD_CLIP,
    HIDDEN_DIM,
    LABEL_NAMES,
    LEARNING_RATE,
    MAX_EPOCHS,
    MIN_WORD_FREQ,
    NUM_LABELS,
    NUM_LSTM_LAYERS,
    PATIENCE,
    SEED,
    IngredientDataset,
    IngredientTagger,
    build_vocab,
    collate_fn,
    compute_metrics,
    export_checkpoint,
    export_crf_params,
    load_jsonl,
    sha256_file,
    train_epoch,
    validate_epoch,
)


def deduplicate(samples: list[dict]) -> list[dict]:
    """Remove duplicate samples by token sequence."""
    seen = set()
    unique = []
    for s in samples:
        key = " ".join(s["tokens"])
        if key not in seen:
            seen.add(key)
            unique.append(s)
    return unique


def label_distribution(samples: list[dict]) -> Counter:
    """Count label frequencies across all samples."""
    counts = Counter()
    for s in samples:
        for lbl in s["labels"]:
            counts[lbl] += 1
    return counts


def print_distribution(name: str, samples: list[dict]) -> None:
    """Print label distribution for a dataset."""
    dist = label_distribution(samples)
    total = sum(dist.values())
    print(f"  {name} ({len(samples):,} samples, {total:,} tokens):")
    for label in LABEL_NAMES:
        count = dist.get(label, 0)
        pct = count / total * 100 if total > 0 else 0
        print(f"    {label:10s}: {count:8,d} ({pct:5.1f}%)")


def metrics_table(metrics: dict, label: str = "") -> str:
    """Format metrics as a readable string."""
    lines = []
    if label:
        lines.append(f"  {label}:")
    lines.append(f"    Token accuracy:    {metrics['token_accuracy'] * 100:.2f}%")
    lines.append(f"    Sentence accuracy: {metrics['sentence_accuracy'] * 100:.2f}%")
    lines.append(f"    {'Label':10s}  {'Precision':>9s}  {'Recall':>9s}  {'F1':>9s}")
    lines.append(f"    {'-' * 42}")
    for lbl in LABEL_NAMES:
        s = metrics["per_class"][lbl]
        lines.append(f"    {lbl:10s}  {s['precision']:9.4f}  {s['recall']:9.4f}  {s['f1']:9.4f}")
    return "\n".join(lines)


def check_thresholds(metrics: dict, label: str) -> list[tuple[str, bool, str]]:
    """Check metrics against minimum thresholds from PRD."""
    ta = metrics["token_accuracy"]
    sa = metrics["sentence_accuracy"]
    checks = [
        (f"{label} token accuracy >= 98%", ta >= 0.98, f"{ta * 100:.2f}%"),
        (f"{label} sentence accuracy >= 95%", sa >= 0.95, f"{sa * 100:.2f}%"),
    ]

    thresholds = {
        "QTY": 0.99, "UNIT": 0.99, "NAME": 0.98,
        "MODIFIER": 0.92, "PREP": 0.97, "COMMENT": 0.94,
    }
    for lbl, min_f1 in thresholds.items():
        f1 = metrics["per_class"][lbl]["f1"]
        checks.append((f"{label} {lbl} F1 >= {min_f1}", f1 >= min_f1, f"{f1:.4f}"))

    return checks


def main():
    parser = argparse.ArgumentParser(description="Full retrain with combined strangetom + harness data")
    parser.add_argument("--oversample", type=int, default=8, help="Harness data oversample factor (default: 8)")
    parser.add_argument("--dry-run", action="store_true", help="Load and merge data without training")
    args = parser.parse_args()

    print("=" * 60)
    print("M16.9.3: Full Retrain — Combined Dataset")
    print("=" * 60)

    torch.manual_seed(SEED)
    np.random.seed(SEED)
    random.seed(SEED)

    # Device
    if torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    print(f"\nDevice: {device}")

    data_dir = Path(__file__).parent / "data"
    models_dir = Path(__file__).parent / "models" / "v2"
    models_dir.mkdir(parents=True, exist_ok=True)

    # ──────────────────────────────────────────────────────────
    # 1. Load datasets
    # ──────────────────────────────────────────────────────────
    print("\n[1/7] Loading datasets...")

    # Strangetom (original)
    st_train = load_jsonl(data_dir / "training_data.jsonl")
    st_val = load_jsonl(data_dir / "validation_data.jsonl")
    st_test = load_jsonl(data_dir / "test_data.jsonl")
    print(f"  Strangetom — Train: {len(st_train):,}  Val: {len(st_val):,}  Test: {len(st_test):,}")

    # Harness
    h_train = load_jsonl(data_dir / "harness_training.jsonl")
    h_val = load_jsonl(data_dir / "harness_validation.jsonl")
    h_test = load_jsonl(data_dir / "harness_test.jsonl")
    print(f"  Harness   — Train: {len(h_train):,}  Val: {len(h_val):,}  Test: {len(h_test):,}")

    # ──────────────────────────────────────────────────────────
    # 2. Merge + deduplicate + oversample
    # ──────────────────────────────────────────────────────────
    print(f"\n[2/7] Merging datasets (oversample harness {args.oversample}x)...")

    # Oversample harness training data
    h_train_oversampled = h_train * args.oversample
    random.shuffle(h_train_oversampled)

    # Combine training sets
    combined_train = st_train + h_train_oversampled
    combined_train = deduplicate(combined_train)
    random.shuffle(combined_train)

    # Combine validation sets (no oversampling)
    combined_val = deduplicate(st_val + h_val)

    # Test sets kept separate for independent evaluation
    print(f"  Combined train: {len(combined_train):,} (strangetom: {len(st_train):,} + harness: {len(h_train):,} x {args.oversample} = {len(h_train_oversampled):,})")
    print(f"  Combined val:   {len(combined_val):,}")
    print(f"  Strangetom test: {len(st_test):,}")
    print(f"  Harness test:    {len(h_test):,}")

    harness_pct = len(h_train_oversampled) / (len(st_train) + len(h_train_oversampled)) * 100
    print(f"  Harness % of effective training set: {harness_pct:.1f}%")

    # ──────────────────────────────────────────────────────────
    # 3. Label distributions
    # ──────────────────────────────────────────────────────────
    print("\n[3/7] Label distributions...")
    print_distribution("Strangetom train", st_train)
    print_distribution("Harness train (1x)", h_train)
    print_distribution("Combined train", combined_train)

    if args.dry_run:
        print("\n[DRY RUN] Stopping before training.")
        return

    # ──────────────────────────────────────────────────────────
    # 4. Build vocabulary
    # ──────────────────────────────────────────────────────────
    print(f"\n[4/7] Building vocabulary from combined training data...")
    vocab = build_vocab(combined_train)
    vocab_size = len(vocab)

    # Compare with original
    v1_vocab_path = Path(__file__).parent / "models" / "vocabulary.json"
    if v1_vocab_path.exists():
        v1_vocab = json.loads(v1_vocab_path.read_text())
        v1_size = len(v1_vocab)
        new_words = set(vocab.keys()) - set(v1_vocab.keys())
        lost_words = set(v1_vocab.keys()) - set(vocab.keys())
        print(f"  v1 vocabulary: {v1_size:,}")
        print(f"  v2 vocabulary: {vocab_size:,} ({vocab_size - v1_size:+d})")
        print(f"  New words: {len(new_words):,}")
        if len(new_words) <= 20:
            print(f"    {sorted(new_words)}")
        else:
            print(f"    (first 20) {sorted(new_words)[:20]}")
        print(f"  Lost words: {len(lost_words):,}")
    else:
        print(f"  Vocabulary size: {vocab_size:,}")

    # UNK rates
    for name, samples in [("strangetom val", st_val), ("harness val", h_val), ("combined val", combined_val)]:
        total_tok = sum(len(s["tokens"]) for s in samples)
        unk_tok = sum(1 for s in samples for t in s["tokens"] if t not in vocab)
        print(f"  UNK rate ({name}): {unk_tok}/{total_tok} ({100 * unk_tok / total_tok:.2f}%)")

    vocab_path = models_dir / "vocabulary.json"
    with open(vocab_path, "w") as f:
        json.dump(vocab, f, ensure_ascii=False)
    print(f"  Saved: {vocab_path}")

    # ──────────────────────────────────────────────────────────
    # 5. Train
    # ──────────────────────────────────────────────────────────
    print(f"\n[5/7] Creating model and training...")
    model = IngredientTagger(vocab_size=vocab_size).to(device)
    total_params = sum(p.numel() for p in model.parameters())
    print(f"  Parameters: {total_params:,}")

    train_dataset = IngredientDataset(combined_train, vocab)
    val_dataset = IngredientDataset(combined_val, vocab)

    train_loader = DataLoader(
        train_dataset, batch_size=BATCH_SIZE, shuffle=True,
        collate_fn=collate_fn, num_workers=0,
    )
    val_loader = DataLoader(
        val_dataset, batch_size=BATCH_SIZE, shuffle=False,
        collate_fn=collate_fn, num_workers=0,
    )

    optimizer = torch.optim.Adam(model.parameters(), lr=LEARNING_RATE)

    print(f"  Training (max {MAX_EPOCHS} epochs, patience={PATIENCE})...")
    best_val_loss = float("inf")
    patience_counter = 0
    best_epoch = 0
    best_model_path = models_dir / "ingredient_tagger_best.pt"
    train_start = time.time()

    for epoch in range(1, MAX_EPOCHS + 1):
        epoch_start = time.time()
        avg_train_loss = train_epoch(model, train_loader, optimizer, device)
        avg_val_loss = validate_epoch(model, val_loader, device)
        epoch_time = time.time() - epoch_start
        marker = ""

        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            best_epoch = epoch
            patience_counter = 0
            torch.save(model.state_dict(), best_model_path)
            marker = " *"
        else:
            patience_counter += 1

        print(f"  Epoch {epoch:2d}/{MAX_EPOCHS} | Train: {avg_train_loss:.4f} | Val: {avg_val_loss:.4f} | {epoch_time:.1f}s{marker}")

        if patience_counter >= PATIENCE:
            print(f"\n  Early stopping at epoch {epoch} (best: epoch {best_epoch})")
            break

    training_duration = time.time() - train_start
    print(f"\n  Training complete: {training_duration:.0f}s ({training_duration / 60:.1f} min)")
    print(f"  Best epoch: {best_epoch} (val loss: {best_val_loss:.4f})")

    # Load best model
    model.load_state_dict(
        torch.load(best_model_path, map_location=device, weights_only=True)
    )

    # ──────────────────────────────────────────────────────────
    # 6. Evaluate on BOTH test sets
    # ──────────────────────────────────────────────────────────
    print(f"\n[6/7] Evaluating...")

    # Strangetom test set
    st_test_dataset = IngredientDataset(st_test, vocab)
    st_test_loader = DataLoader(st_test_dataset, batch_size=BATCH_SIZE, shuffle=False, collate_fn=collate_fn, num_workers=0)
    st_metrics = compute_metrics(model, st_test_loader, device)
    print(metrics_table(st_metrics, "Strangetom test"))

    # Harness test set
    h_test_dataset = IngredientDataset(h_test, vocab)
    h_test_loader = DataLoader(h_test_dataset, batch_size=BATCH_SIZE, shuffle=False, collate_fn=collate_fn, num_workers=0)
    h_metrics = compute_metrics(model, h_test_loader, device)
    print(metrics_table(h_metrics, "Harness test"))

    # ──────────────────────────────────────────────────────────
    # 7. Export artifacts
    # ──────────────────────────────────────────────────────────
    print(f"\n[7/7] Exporting artifacts...")

    # Checkpoint
    checkpoint_path = models_dir / "ingredient_tagger.pt"
    export_checkpoint(model, vocab_size, best_epoch, st_metrics, checkpoint_path)
    model_size_mb = checkpoint_path.stat().st_size / (1024 * 1024)
    print(f"  Checkpoint: {checkpoint_path} ({model_size_mb:.1f} MB)")

    # CRF parameters
    transitions_path = models_dir / "transitions.json"
    export_crf_params(model, transitions_path)
    print(f"  CRF params: {transitions_path}")

    # Vocabulary already saved above

    # Training report
    report = {
        "version": "2.0",
        "date": time.strftime("%Y-%m-%d"),
        "training_duration_s": round(training_duration, 1),
        "best_epoch": best_epoch,
        "oversample_factor": args.oversample,
        "datasets": {
            "strangetom_train": len(st_train),
            "harness_train": len(h_train),
            "harness_oversampled": len(h_train_oversampled),
            "combined_train": len(combined_train),
            "combined_val": len(combined_val),
            "strangetom_test": len(st_test),
            "harness_test": len(h_test),
        },
        "vocabulary_size": vocab_size,
        "total_params": total_params,
        "strangetom_metrics": {
            "token_accuracy": st_metrics["token_accuracy"],
            "sentence_accuracy": st_metrics["sentence_accuracy"],
            "per_class_f1": {lbl: st_metrics["per_class"][lbl]["f1"] for lbl in LABEL_NAMES},
        },
        "harness_metrics": {
            "token_accuracy": h_metrics["token_accuracy"],
            "sentence_accuracy": h_metrics["sentence_accuracy"],
            "per_class_f1": {lbl: h_metrics["per_class"][lbl]["f1"] for lbl in LABEL_NAMES},
        },
    }
    report_path = models_dir / "training_report.json"
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"  Training report: {report_path}")

    # ──────────────────────────────────────────────────────────
    # Summary + acceptance criteria
    # ──────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("TRAINING SUMMARY")
    print("=" * 60)
    print(f"  Vocabulary:     {vocab_size:,} words")
    print(f"  Parameters:     {total_params:,}")
    print(f"  Best epoch:     {best_epoch}")
    print(f"  Training time:  {training_duration:.0f}s ({training_duration / 60:.1f} min)")
    print(f"  Model size:     {model_size_mb:.1f} MB")

    print("\n  Acceptance Criteria (Strangetom test):")
    st_checks = check_thresholds(st_metrics, "Strangetom")
    all_pass = True
    for desc, passed, value in st_checks:
        icon = "+" if passed else "X"
        status = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        print(f"    [{icon}] {desc:45s} {value} ({status})")

    print("\n  Harness test (informational):")
    h_checks = [
        ("Harness token accuracy >= 95%", h_metrics["token_accuracy"] >= 0.95,
         f"{h_metrics['token_accuracy'] * 100:.2f}%"),
        ("Harness sentence accuracy >= 90%", h_metrics["sentence_accuracy"] >= 0.90,
         f"{h_metrics['sentence_accuracy'] * 100:.2f}%"),
    ]
    for desc, passed, value in h_checks:
        icon = "+" if passed else "X"
        status = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        print(f"    [{icon}] {desc:45s} {value} ({status})")

    if all_pass:
        print(f"\n  Overall: ALL TARGETS MET")
        print(f"\n  Next: Run convert_to_coreml.py to produce CoreML model")
        print(f"    python convert_to_coreml.py --model-dir models/v2")
    else:
        print(f"\n  Overall: SOME TARGETS MISSED — review before proceeding")

    print("=" * 60)


if __name__ == "__main__":
    main()
