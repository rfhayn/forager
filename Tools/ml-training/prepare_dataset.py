#!/usr/bin/env python3
from __future__ import annotations

"""
M8.4 Phase 1: Dataset Preparation
Converts strangetom/ingredient-parser SQLite database to Forager training format.

Input:  data/strangetom.sqlite (81,316 sentences, 13 labels)
Output: data/training_data.jsonl, data/validation_data.jsonl, data/test_data.jsonl
        (7 Forager labels: QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER)
"""

import json
import random
import re
import sqlite3
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from sklearn.model_selection import train_test_split

# strangetom 13 → Forager 7 label mapping
LABEL_MAP = {
    "QTY": "QTY",
    "UNIT": "UNIT",
    "B_NAME_TOK": "NAME",
    "I_NAME_TOK": "NAME",
    "NAME_VAR": "NAME",
    "NAME_SEP": "NAME",
    "NAME_MOD": "MODIFIER",
    "SIZE": "MODIFIER",
    "PREP": "PREP",
    "COMMENT": "COMMENT",
    "PURPOSE": "COMMENT",
    "PUNC": "OTHER",
    "OTHER": "OTHER",
}


def decode_fraction(token: str) -> str:
    """Decode all strangetom fraction notation within a token.

    Uses re.sub to find and replace fraction patterns anywhere in the token,
    preserving surrounding text (handles ranges, dimensions, suffixes, etc.).

    Three passes in order of specificity:
        1. whole#num$den  (e.g., 1#1$2 → 1.5)
        2. #num$den       (e.g., #1$2 → 0.5)
        3. num$den        (e.g., 3$4 → 0.75)
    """
    def _mixed(m):
        whole, num, den = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if den == 0:
            return m.group(0)
        value = whole + num / den
        return str(value) if value != int(value) else str(int(value))

    def _simple(m):
        num, den = int(m.group(1)), int(m.group(2))
        if den == 0:
            return m.group(0)
        value = num / den
        return str(value) if value != int(value) else str(int(value))

    # Pass 1: whole#numerator$denominator (e.g., 1#1$2 → 1.5)
    result = re.sub(r"(\d+)#(\d+)\$(\d+)", _mixed, token)
    # Pass 2: #numerator$denominator (e.g., #1$2 → 0.5)
    result = re.sub(r"#(\d+)\$(\d+)", _simple, result)
    # Pass 3: plain numerator$denominator (e.g., 3$4 → 0.75)
    result = re.sub(r"(\d+)\$(\d+)", _simple, result)

    return result


def load_strangetom(db_path: str) -> list[dict]:
    """Load and convert strangetom SQLite database."""
    conn = sqlite3.connect(db_path)
    cursor = conn.execute("SELECT id, source, sentence, tokens, labels FROM en")

    samples = []
    skipped = 0

    for row_id, source, sentence, tokens_json, labels_json in cursor:
        tokens = json.loads(tokens_json)
        labels = json.loads(labels_json)

        if len(tokens) != len(labels):
            skipped += 1
            continue

        # Decode fraction notation in tokens
        decoded_tokens = [decode_fraction(t) for t in tokens]

        # Map labels: strangetom 13 → Forager 7
        mapped_labels = []
        valid = True
        for label in labels:
            mapped = LABEL_MAP.get(label)
            if mapped is None:
                print(f"  Warning: Unknown label '{label}' in row {row_id}, skipping")
                valid = False
                break
            mapped_labels.append(mapped)

        if not valid:
            skipped += 1
            continue

        samples.append({
            "tokens": decoded_tokens,
            "labels": mapped_labels,
            "source": source,
            "sentence": sentence,
        })

    conn.close()

    if skipped > 0:
        print(f"  Skipped {skipped} rows (token/label mismatch or unknown labels)")

    return samples


def validate_samples(samples: list[dict]) -> None:
    """Validate dataset quality."""
    valid_labels = set(LABEL_MAP.values())
    issues = 0

    for i, sample in enumerate(samples):
        # Check token/label alignment
        if len(sample["tokens"]) != len(sample["labels"]):
            print(f"  ISSUE: Sample {i} has {len(sample['tokens'])} tokens but {len(sample['labels'])} labels")
            issues += 1

        # Check all labels are valid
        for label in sample["labels"]:
            if label not in valid_labels:
                print(f"  ISSUE: Sample {i} has invalid label '{label}'")
                issues += 1

        # Check no fraction notation remains
        for token in sample["tokens"]:
            if "#" in token and "$" in token:
                print(f"  ISSUE: Sample {i} has undecoded fraction: '{token}'")
                issues += 1

    if issues == 0:
        print("  All samples validated — no issues found")
    else:
        print(f"  Found {issues} issues")


def compute_statistics(samples: list[dict]) -> dict:
    """Compute dataset statistics."""
    label_counts = Counter()
    source_counts = Counter()
    token_lengths = []

    for sample in samples:
        for label in sample["labels"]:
            label_counts[label] += 1
        source_counts[sample["source"]] += 1
        token_lengths.append(len(sample["tokens"]))

    total_tokens = sum(label_counts.values())

    stats = {
        "total_sentences": len(samples),
        "total_tokens": total_tokens,
        "label_distribution": {
            label: {"count": count, "pct": f"{100 * count / total_tokens:.1f}%"}
            for label, count in sorted(label_counts.items())
        },
        "source_distribution": dict(sorted(source_counts.items())),
        "token_length": {
            "min": min(token_lengths),
            "max": max(token_lengths),
            "mean": f"{np.mean(token_lengths):.1f}",
            "median": f"{np.median(token_lengths):.1f}",
            "p95": f"{np.percentile(token_lengths, 95):.0f}",
        },
    }

    return stats


def split_dataset(
    samples: list[dict],
    train_ratio: float = 0.8,
    val_ratio: float = 0.1,
    test_ratio: float = 0.1,
    seed: int = 42,
) -> tuple[list[dict], list[dict], list[dict]]:
    """Split dataset into train/val/test, stratified by source."""
    sources = [s["source"] for s in samples]

    # First split: train vs (val + test)
    train_samples, remaining = train_test_split(
        samples,
        test_size=(val_ratio + test_ratio),
        random_state=seed,
        stratify=sources,
    )

    # Second split: val vs test
    remaining_sources = [s["source"] for s in remaining]
    relative_test = test_ratio / (val_ratio + test_ratio)
    val_samples, test_samples = train_test_split(
        remaining,
        test_size=relative_test,
        random_state=seed,
        stratify=remaining_sources,
    )

    return train_samples, val_samples, test_samples


def write_jsonl(samples: list[dict], path: str) -> None:
    """Write samples to JSONL format (tokens + labels only, no metadata)."""
    with open(path, "w") as f:
        for sample in samples:
            line = json.dumps(
                {"tokens": sample["tokens"], "labels": sample["labels"]},
                ensure_ascii=False,
            )
            f.write(line + "\n")


def main():
    data_dir = Path(__file__).parent / "data"
    db_path = data_dir / "strangetom.sqlite"

    if not db_path.exists():
        print(f"ERROR: Database not found at {db_path}")
        print("Download from: https://github.com/strangetom/ingredient-parser/raw/master/train/data/training.sqlite3")
        sys.exit(1)

    print("=" * 60)
    print("M8.4 Phase 1: Dataset Preparation")
    print("=" * 60)

    # Step 1: Load strangetom
    print("\n[1/6] Loading strangetom database...")
    samples = load_strangetom(str(db_path))
    print(f"  Loaded {len(samples)} samples")

    # Step 1b: Deduplicate by sentence to prevent data leakage
    seen = set()
    unique_samples = []
    for s in samples:
        if s["sentence"] not in seen:
            seen.add(s["sentence"])
            unique_samples.append(s)
    dupes = len(samples) - len(unique_samples)
    if dupes > 0:
        print(f"  Removed {dupes} duplicate sentences ({len(unique_samples)} unique)")
    samples = unique_samples

    # Step 2: Validate
    print("\n[2/6] Validating samples...")
    validate_samples(samples)

    # Step 3: Compute statistics
    print("\n[3/6] Computing statistics...")
    stats = compute_statistics(samples)
    print(f"  Total sentences: {stats['total_sentences']}")
    print(f"  Total tokens: {stats['total_tokens']}")
    print(f"  Token length: min={stats['token_length']['min']}, "
          f"max={stats['token_length']['max']}, "
          f"mean={stats['token_length']['mean']}, "
          f"p95={stats['token_length']['p95']}")
    print("  Label distribution:")
    for label, info in stats["label_distribution"].items():
        print(f"    {label:10s} {info['count']:>8d}  ({info['pct']})")
    print("  Source distribution:")
    for source, count in stats["source_distribution"].items():
        print(f"    {source:15s} {count:>6d}")

    # Step 4: Split
    print("\n[4/6] Splitting dataset (80/10/10, stratified by source)...")
    train, val, test = split_dataset(samples)
    print(f"  Train: {len(train)} samples")
    print(f"  Val:   {len(val)} samples")
    print(f"  Test:  {len(test)} samples")

    # Verify no data leakage
    train_sentences = {s["sentence"] for s in train}
    val_sentences = {s["sentence"] for s in val}
    test_sentences = {s["sentence"] for s in test}
    train_val_overlap = train_sentences & val_sentences
    train_test_overlap = train_sentences & test_sentences
    val_test_overlap = val_sentences & test_sentences

    if train_val_overlap or train_test_overlap or val_test_overlap:
        print(f"  WARNING: Data leakage detected!")
        print(f"    Train-Val overlap: {len(train_val_overlap)}")
        print(f"    Train-Test overlap: {len(train_test_overlap)}")
        print(f"    Val-Test overlap: {len(val_test_overlap)}")
    else:
        print("  No data leakage — splits are clean")

    # Step 5: Spot-check samples
    print("\n[5/6] Spot-checking decoded samples...")
    random.seed(42)
    spot_indices = random.sample(range(len(train)), min(5, len(train)))
    for idx in spot_indices:
        s = train[idx]
        pairs = list(zip(s["tokens"], s["labels"]))
        print(f"  [{idx}] {' '.join(s['tokens'])}")
        print(f"        {' '.join(s['labels'])}")

    # Step 6: Write output
    print("\n[6/6] Writing JSONL files...")
    write_jsonl(train, str(data_dir / "training_data.jsonl"))
    write_jsonl(val, str(data_dir / "validation_data.jsonl"))
    write_jsonl(test, str(data_dir / "test_data.jsonl"))
    print("  Written: training_data.jsonl, validation_data.jsonl, test_data.jsonl")

    # Save statistics
    stats_path = data_dir / "dataset_statistics.json"
    stats["splits"] = {"train": len(train), "val": len(val), "test": len(test)}
    with open(stats_path, "w") as f:
        json.dump(stats, f, indent=2)
    print(f"  Statistics saved to: {stats_path}")

    print("\n" + "=" * 60)
    print("Dataset preparation complete!")
    print(f"  {len(samples)} sentences → {len(train)} train / {len(val)} val / {len(test)} test")
    print("=" * 60)


if __name__ == "__main__":
    main()
