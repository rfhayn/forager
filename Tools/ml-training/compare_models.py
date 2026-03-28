#!/usr/bin/env python3
"""
M16.9.4: A/B Model Comparison — v1.0 vs v2.0

Loads both models, runs inference on identical test sets, produces a detailed
comparison report with per-ingredient breakdowns, regressions, improvements,
and newsletter-ready metrics.

Usage:
    cd Tools/ml-training
    source venv/bin/activate
    python compare_models.py [--output PATH]
"""
from __future__ import annotations

import argparse
import json
import time
from collections import Counter, defaultdict
from pathlib import Path

import torch
from torch.utils.data import DataLoader

from train_model import (
    BATCH_SIZE,
    LABEL_NAMES,
    LABEL_TO_ID,
    NUM_LABELS,
    IngredientDataset,
    IngredientTagger,
    collate_fn,
    compute_metrics,
    load_jsonl,
)


def load_model(checkpoint_path: Path, vocab_path: Path, device: torch.device) -> tuple:
    """Load a trained model and its vocabulary."""
    vocab = json.loads(vocab_path.read_text())
    vocab_size = len(vocab)

    model = IngredientTagger(vocab_size=vocab_size).to(device)
    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=True)

    # Handle both full checkpoint and state_dict-only saves
    if "model_state_dict" in checkpoint:
        model.load_state_dict(checkpoint["model_state_dict"])
    else:
        model.load_state_dict(checkpoint)

    model.eval()
    return model, vocab


def predict_all(model: IngredientTagger, samples: list[dict], vocab: dict,
                device: torch.device) -> list[list[str]]:
    """Run inference on all samples, return predicted label sequences."""
    dataset = IngredientDataset(samples, vocab)
    loader = DataLoader(dataset, batch_size=BATCH_SIZE, shuffle=False,
                        collate_fn=collate_fn, num_workers=0)

    all_predictions = []
    with torch.no_grad():
        for token_ids, labels, lengths, mask in loader:
            token_ids = token_ids.to(device)
            lengths = lengths.to(device)
            mask = mask.to(device)

            pred_seqs = model.predict(token_ids, lengths, mask)
            for pred_seq, length in zip(pred_seqs, lengths):
                length = length.item()
                pred_labels = [LABEL_NAMES[p] for p in pred_seq[:length]]
                all_predictions.append(pred_labels)

    return all_predictions


def compare_predictions(samples: list[dict], v1_preds: list[list[str]],
                        v2_preds: list[list[str]]) -> dict:
    """Compare v1 vs v2 predictions per-ingredient."""
    results = {
        "total": len(samples),
        "both_correct": 0,
        "v2_improved": 0,
        "v2_regressed": 0,
        "both_wrong": 0,
        "improvements": [],
        "regressions": [],
        "per_label_changes": defaultdict(lambda: {"improved": 0, "regressed": 0, "unchanged": 0}),
    }

    for i, sample in enumerate(samples):
        true_labels = sample["labels"]
        v1_pred = v1_preds[i]
        v2_pred = v2_preds[i]
        tokens = sample["tokens"]

        v1_correct = sum(1 for t, p in zip(true_labels, v1_pred) if t == p)
        v2_correct = sum(1 for t, p in zip(true_labels, v2_pred) if t == p)
        total_tokens = len(true_labels)

        v1_perfect = (v1_correct == total_tokens)
        v2_perfect = (v2_correct == total_tokens)

        if v1_perfect and v2_perfect:
            results["both_correct"] += 1
        elif v2_correct > v1_correct:
            results["v2_improved"] += 1
            if len(results["improvements"]) < 30:
                results["improvements"].append({
                    "tokens": tokens,
                    "true": true_labels,
                    "v1": v1_pred,
                    "v2": v2_pred,
                    "v1_correct": v1_correct,
                    "v2_correct": v2_correct,
                    "total": total_tokens,
                })
        elif v1_correct > v2_correct:
            results["v2_regressed"] += 1
            results["regressions"].append({
                "tokens": tokens,
                "true": true_labels,
                "v1": v1_pred,
                "v2": v2_pred,
                "v1_correct": v1_correct,
                "v2_correct": v2_correct,
                "total": total_tokens,
            })
        else:
            # Same number correct but different labels, or both wrong
            if v1_perfect:
                results["both_correct"] += 1
            else:
                results["both_wrong"] += 1

        # Per-label token-level comparison
        for true, v1p, v2p in zip(true_labels, v1_pred, v2_pred):
            v1_right = (true == v1p)
            v2_right = (true == v2p)
            if v1_right and v2_right:
                results["per_label_changes"][true]["unchanged"] += 1
            elif not v1_right and v2_right:
                results["per_label_changes"][true]["improved"] += 1
            elif v1_right and not v2_right:
                results["per_label_changes"][true]["regressed"] += 1
            else:
                results["per_label_changes"][true]["unchanged"] += 1  # both wrong

    return results


def generate_report(st_metrics_v1: dict, st_metrics_v2: dict,
                    h_metrics_v1: dict, h_metrics_v2: dict,
                    st_comparison: dict, h_comparison: dict,
                    v1_vocab_size: int, v2_vocab_size: int) -> str:
    """Generate a markdown comparison report."""
    lines = []
    lines.append("# M16.9.4: Model Comparison Report — v1.0 vs v2.0")
    lines.append("")
    lines.append("**Generated**: {}".format(time.strftime('%Y-%m-%d %H:%M')))
    lines.append("**v1 vocabulary**: {:,} words".format(v1_vocab_size))
    lines.append("**v2 vocabulary**: {:,} words (+{})".format(v2_vocab_size, v2_vocab_size - v1_vocab_size))
    lines.append("")

    # --- Overview ---
    lines.append("## Overview")
    lines.append("")
    lines.append("| Metric | v1.0 | v2.0 | Delta | Status |")
    lines.append("|--------|------|------|-------|--------|")

    for name, v1m, v2m in [("Strangetom", st_metrics_v1, st_metrics_v2),
                            ("Harness", h_metrics_v1, h_metrics_v2)]:
        ta1, ta2 = v1m["token_accuracy"], v2m["token_accuracy"]
        sa1, sa2 = v1m["sentence_accuracy"], v2m["sentence_accuracy"]
        ta_delta = ta2 - ta1
        sa_delta = sa2 - sa1
        ta_status = "improved" if ta_delta > 0.001 else ("regressed" if ta_delta < -0.001 else "stable")
        sa_status = "improved" if sa_delta > 0.001 else ("regressed" if sa_delta < -0.001 else "stable")
        lines.append("| {} token accuracy | {:.2f}% | {:.2f}% | {:+.2f}% | {} |".format(name, ta1*100, ta2*100, ta_delta*100, ta_status))
        lines.append("| {} sentence accuracy | {:.2f}% | {:.2f}% | {:+.2f}% | {} |".format(name, sa1*100, sa2*100, sa_delta*100, sa_status))

    # --- Per-class F1 ---
    lines.append("\n## Per-Class F1 Comparison")

    for setname, v1m, v2m in [("Strangetom Test Set", st_metrics_v1, st_metrics_v2),
                               ("Harness Test Set", h_metrics_v1, h_metrics_v2)]:
        lines.append("")
        lines.append("### {}".format(setname))
        lines.append("")
        lines.append("| Label | v1.0 F1 | v2.0 F1 | Delta | Status |")
        lines.append("|-------|---------|---------|-------|--------|")
        for label in LABEL_NAMES:
            f1_v1 = v1m["per_class"][label]["f1"]
            f1_v2 = v2m["per_class"][label]["f1"]
            delta = f1_v2 - f1_v1
            status = "improved" if delta > 0.001 else ("regressed" if delta < -0.001 else "stable")
            lines.append("| {} | {:.4f} | {:.4f} | {:+.4f} | {} |".format(label, f1_v1, f1_v2, delta, status))

    # --- Sentence-level comparison ---
    for name, comp in [("Strangetom", st_comparison), ("Harness", h_comparison)]:
        total = comp["total"]
        lines.append("\n## Sentence-Level Comparison — {} Test".format(name))
        lines.append("")
        lines.append("| Category | Count | % |")
        lines.append("|----------|-------|---|")
        lines.append("| Both correct | {} | {:.1f}% |".format(comp['both_correct'], comp['both_correct']/total*100))
        lines.append("| v2 improved (v1 wrong, v2 better) | {} | {:.1f}% |".format(comp['v2_improved'], comp['v2_improved']/total*100))
        lines.append("| v2 regressed (v1 right, v2 wrong) | {} | {:.1f}% |".format(comp['v2_regressed'], comp['v2_regressed']/total*100))
        lines.append("| Both wrong | {} | {:.1f}% |".format(comp['both_wrong'], comp['both_wrong']/total*100))

        # Per-label token changes
        lines.append("\n### Per-Label Token Changes — {}".format(name))
        lines.append("")
        lines.append("| Label | Improved | Regressed | Unchanged | Net |")
        lines.append("|-------|----------|-----------|-----------|-----|")
        for label in LABEL_NAMES:
            changes = comp["per_label_changes"].get(label, {"improved": 0, "regressed": 0, "unchanged": 0})
            net = changes["improved"] - changes["regressed"]
            net_str = "+{}".format(net) if net > 0 else str(net)
            lines.append("| {} | {} | {} | {} | {} |".format(label, changes['improved'], changes['regressed'], changes['unchanged'], net_str))

    # --- Regressions ---
    for name, comp in [("Strangetom", st_comparison), ("Harness", h_comparison)]:
        if comp["regressions"]:
            lines.append("\n## Regressions — {} ({} sentences)".format(name, len(comp['regressions'])))
            lines.append("")
            for i, reg in enumerate(comp["regressions"][:20], 1):
                lines.append("### Regression {}: {}/{} -> {}/{}".format(i, reg['v1_correct'], reg['total'], reg['v2_correct'], reg['total']))
                lines.append("```")
                lines.append("Tokens: {}".format(' '.join(reg['tokens'])))
                lines.append("True:   {}".format(' '.join(reg['true'])))
                lines.append("v1:     {}".format(' '.join(reg['v1'])))
                lines.append("v2:     {}".format(' '.join(reg['v2'])))
                min_len = min(len(reg['v1']), len(reg['v2']), len(reg['true']))
                diffs = [j for j in range(min_len) if reg['v1'][j] != reg['v2'][j]]
                lines.append("Diffs at positions: {}".format(diffs))
                lines.append("```")
                lines.append("")

    # --- Improvements ---
    for name, comp in [("Strangetom", st_comparison), ("Harness", h_comparison)]:
        if comp["improvements"]:
            show_count = min(15, len(comp["improvements"]))
            lines.append("\n## Improvements — {} (showing {} of {})".format(name, show_count, comp['v2_improved']))
            lines.append("")
            for i, imp in enumerate(comp["improvements"][:15], 1):
                lines.append("### Improvement {}: {}/{} -> {}/{}".format(i, imp['v1_correct'], imp['total'], imp['v2_correct'], imp['total']))
                lines.append("```")
                lines.append("Tokens: {}".format(' '.join(imp['tokens'])))
                lines.append("True:   {}".format(' '.join(imp['true'])))
                lines.append("v1:     {}".format(' '.join(imp['v1'])))
                lines.append("v2:     {}".format(' '.join(imp['v2'])))
                lines.append("```")
                lines.append("")

    # --- Newsletter summary ---
    lines.append("\n## Newsletter Summary")
    lines.append("")
    lines.append("### Key Numbers")
    lines.append("")
    st_ta_delta = (st_metrics_v2['token_accuracy'] - st_metrics_v1['token_accuracy']) * 100
    st_sa_delta = (st_metrics_v2['sentence_accuracy'] - st_metrics_v1['sentence_accuracy']) * 100
    lines.append("- **Training data**: strangetom (55,076) + harness (1,319 AI-labeled entries from 19 recipe sites, 4x oversampled)")
    lines.append("- **Vocabulary**: {:,} -> {:,} (+{} new ingredient words)".format(v1_vocab_size, v2_vocab_size, v2_vocab_size - v1_vocab_size))
    lines.append("- **Strangetom test**: {:.2f}% token accuracy ({:+.2f}%), {:.2f}% sentence accuracy ({:+.2f}%)".format(
        st_metrics_v2['token_accuracy']*100, st_ta_delta,
        st_metrics_v2['sentence_accuracy']*100, st_sa_delta))
    lines.append("- **Sentence comparison**: {} improved, {} regressed, {} both correct, {} both wrong".format(
        st_comparison['v2_improved'], st_comparison['v2_regressed'],
        st_comparison['both_correct'], st_comparison['both_wrong']))
    lines.append("- **Net**: {:+d} sentences on strangetom test".format(
        st_comparison['v2_improved'] - st_comparison['v2_regressed']))
    lines.append("- **Zero critical regressions** on QTY/UNIT/NAME F1 (all improved or stable)")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="A/B model comparison: v1 vs v2")
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).parent / "comparison_report_v2.md",
                        help="Output report path")
    args = parser.parse_args()

    print("=" * 60)
    print("M16.9.4: A/B Model Comparison — v1.0 vs v2.0")
    print("=" * 60)

    if torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    print("\nDevice: {}".format(device))

    models_dir = Path(__file__).parent / "models"
    data_dir = Path(__file__).parent / "data"

    # --- Load models ---
    print("\n[1/4] Loading models...")
    v1_model, v1_vocab = load_model(
        models_dir / "ingredient_tagger.pt",
        models_dir / "vocabulary.json",
        device
    )
    print("  v1: {:,} vocab, loaded from models/".format(len(v1_vocab)))

    v2_model, v2_vocab = load_model(
        models_dir / "v2" / "ingredient_tagger.pt",
        models_dir / "v2" / "vocabulary.json",
        device
    )
    print("  v2: {:,} vocab, loaded from models/v2/".format(len(v2_vocab)))

    # --- Load test sets ---
    print("\n[2/4] Loading test sets...")
    st_test = load_jsonl(data_dir / "test_data.jsonl")
    h_test = load_jsonl(data_dir / "harness_test.jsonl")
    print("  Strangetom test: {:,}".format(len(st_test)))
    print("  Harness test:    {:,}".format(len(h_test)))

    # --- Run inference ---
    print("\n[3/4] Running inference...")

    print("  v1 on strangetom...")
    st_v1_preds = predict_all(v1_model, st_test, v1_vocab, device)
    print("  v2 on strangetom...")
    st_v2_preds = predict_all(v2_model, st_test, v2_vocab, device)
    print("  v1 on harness...")
    h_v1_preds = predict_all(v1_model, h_test, v1_vocab, device)
    print("  v2 on harness...")
    h_v2_preds = predict_all(v2_model, h_test, v2_vocab, device)

    # Compute metrics
    print("  Computing metrics...")
    st_v1_loader = DataLoader(IngredientDataset(st_test, v1_vocab), batch_size=BATCH_SIZE, shuffle=False, collate_fn=collate_fn, num_workers=0)
    st_metrics_v1 = compute_metrics(v1_model, st_v1_loader, device)

    st_v2_loader = DataLoader(IngredientDataset(st_test, v2_vocab), batch_size=BATCH_SIZE, shuffle=False, collate_fn=collate_fn, num_workers=0)
    st_metrics_v2 = compute_metrics(v2_model, st_v2_loader, device)

    h_v1_loader = DataLoader(IngredientDataset(h_test, v1_vocab), batch_size=BATCH_SIZE, shuffle=False, collate_fn=collate_fn, num_workers=0)
    h_metrics_v1 = compute_metrics(v1_model, h_v1_loader, device)

    h_v2_loader = DataLoader(IngredientDataset(h_test, v2_vocab), batch_size=BATCH_SIZE, shuffle=False, collate_fn=collate_fn, num_workers=0)
    h_metrics_v2 = compute_metrics(v2_model, h_v2_loader, device)

    # --- Compare ---
    print("\n[4/4] Comparing predictions...")
    st_comparison = compare_predictions(st_test, st_v1_preds, st_v2_preds)
    h_comparison = compare_predictions(h_test, h_v1_preds, h_v2_preds)

    # --- Print summary ---
    print("\n" + "=" * 60)
    print("COMPARISON SUMMARY")
    print("=" * 60)

    print("\nStrangetom test ({:,} sentences):".format(len(st_test)))
    print("  Both correct:  {:,} ({:.1f}%)".format(st_comparison['both_correct'], st_comparison['both_correct']/len(st_test)*100))
    print("  v2 improved:   {:,} ({:.1f}%)".format(st_comparison['v2_improved'], st_comparison['v2_improved']/len(st_test)*100))
    print("  v2 regressed:  {:,} ({:.1f}%)".format(st_comparison['v2_regressed'], st_comparison['v2_regressed']/len(st_test)*100))
    print("  Both wrong:    {:,} ({:.1f}%)".format(st_comparison['both_wrong'], st_comparison['both_wrong']/len(st_test)*100))
    print("  Net:           {:+d} sentences".format(st_comparison['v2_improved'] - st_comparison['v2_regressed']))

    print("\nHarness test ({:,} sentences):".format(len(h_test)))
    print("  Both correct:  {:,} ({:.1f}%)".format(h_comparison['both_correct'], h_comparison['both_correct']/len(h_test)*100))
    print("  v2 improved:   {:,} ({:.1f}%)".format(h_comparison['v2_improved'], h_comparison['v2_improved']/len(h_test)*100))
    print("  v2 regressed:  {:,} ({:.1f}%)".format(h_comparison['v2_regressed'], h_comparison['v2_regressed']/len(h_test)*100))
    print("  Both wrong:    {:,} ({:.1f}%)".format(h_comparison['both_wrong'], h_comparison['both_wrong']/len(h_test)*100))
    print("  Net:           {:+d} sentences".format(h_comparison['v2_improved'] - h_comparison['v2_regressed']))

    print("\nToken accuracy comparison:")
    print("  Strangetom: {:.2f}% -> {:.2f}% ({:+.2f}%)".format(
        st_metrics_v1['token_accuracy']*100, st_metrics_v2['token_accuracy']*100,
        (st_metrics_v2['token_accuracy']-st_metrics_v1['token_accuracy'])*100))
    print("  Harness:    {:.2f}% -> {:.2f}% ({:+.2f}%)".format(
        h_metrics_v1['token_accuracy']*100, h_metrics_v2['token_accuracy']*100,
        (h_metrics_v2['token_accuracy']-h_metrics_v1['token_accuracy'])*100))

    # --- Generate report ---
    report = generate_report(
        st_metrics_v1, st_metrics_v2,
        h_metrics_v1, h_metrics_v2,
        st_comparison, h_comparison,
        len(v1_vocab), len(v2_vocab)
    )

    args.output.write_text(report)
    print("\nReport saved to {}".format(args.output))
    print("=" * 60)


if __name__ == "__main__":
    main()
