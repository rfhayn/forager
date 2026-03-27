#!/usr/bin/env python3
"""
M16.9.1: Convert Parsing Test Harness training data to BiLSTM-CRF training format.

Reads the AI-labeled training-data.json from the harness (field-level: name/qty/unit/notes)
and converts to token-level labeled JSONL (tokens + labels) compatible with train_model.py.

Usage:
    python convert_harness_data.py [--input PATH] [--output-dir PATH] [--split] [--verbose]
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VALID_LABELS = {"QTY", "UNIT", "NAME", "MODIFIER", "PREP", "COMMENT", "OTHER"}

# Tokens before the first NAME token that map to MODIFIER instead of NAME
MODIFIER_WORDS = {
    "large", "small", "medium", "mini", "tiny", "big", "jumbo",
    "fresh", "frozen", "dried", "canned", "jarred", "bottled",
    "whole", "baby", "extra-virgin", "low-fat", "nonfat", "fat-free",
    "light", "lite", "reduced-fat", "full-fat", "part-skim",
    "raw", "cooked", "ripe", "unripe", "overripe",
    "thin", "thick", "lean", "boneless", "skinless", "skin-on", "bone-in",
    "organic", "unsalted", "salted", "sweetened", "unsweetened",
    "plain", "smoked", "roasted", "toasted",
    "uncooked", "cooked",
    "extra", "virgin", "extra-virgin",
}

# Notes tokens that map to COMMENT (purpose/optional) rather than PREP (action)
COMMENT_PATTERNS = {
    "optional", "to taste", "for garnish", "for serving", "for decoration",
    "for topping", "if desired", "as needed", "or more", "or less",
    "or to taste", "divided", "plus more", "approximately", "about",
    "such as", "like", "preferably",
}

# Unit synonyms: normalized form -> all raw forms that appear in ingredient text
UNIT_SYNONYMS = {
    "tbsp": {"tablespoon", "tablespoons", "tbsp", "tbsps", "tbs", "tb"},
    "tsp": {"teaspoon", "teaspoons", "tsp", "tsps"},
    "cup": {"cup", "cups", "c"},
    "oz": {"ounce", "ounces", "oz"},
    "lb": {"pound", "pounds", "lb", "lbs"},
    "g": {"gram", "grams", "g"},
    "kg": {"kilogram", "kilograms", "kg"},
    "ml": {"milliliter", "milliliters", "ml"},
    "l": {"liter", "liters", "l"},
    "pt": {"pint", "pints", "pt"},
    "qt": {"quart", "quarts", "qt"},
    "gal": {"gallon", "gallons", "gal"},
    "fl oz": {"fluid ounce", "fluid ounces", "fl oz"},
    "stick": {"stick", "sticks"},
    "clove": {"clove", "cloves"},
    "can": {"can", "cans"},
    "jar": {"jar", "jars"},
    "package": {"package", "packages", "pkg"},
    "bag": {"bag", "bags"},
    "bunch": {"bunch", "bunches"},
    "sprig": {"sprig", "sprigs"},
    "slice": {"slice", "slices"},
    "piece": {"piece", "pieces"},
    "head": {"head", "heads"},
    "stalk": {"stalk", "stalks"},
    "stem": {"stem", "stems"},
    "pinch": {"pinch", "pinches"},
    "dash": {"dash", "dashes"},
    "handful": {"handful", "handfuls"},
    "box": {"box", "boxes"},
    "bottle": {"bottle", "bottles"},
    "drop": {"drop", "drops"},
    "rib": {"rib", "ribs"},
    "ear": {"ear", "ears"},
    "link": {"link", "links"},
    "strip": {"strip", "strips"},
    "sheet": {"sheet", "sheets"},
    "rack": {"rack", "racks"},
    "scoop": {"scoop", "scoops"},
}

# Build reverse lookup: raw token -> normalized form
_UNIT_LOOKUP: dict[str, str] = {}
for norm, variants in UNIT_SYNONYMS.items():
    for v in variants:
        _UNIT_LOOKUP[v] = norm

# Fraction representations: map common decimal -> fraction strings
FRACTION_MAP = {
    0.25: ["1/4", "¼"],
    0.33: ["1/3", "⅓"],
    0.5: ["1/2", "½"],
    0.67: ["2/3", "⅔"],
    0.75: ["3/4", "¾"],
}

log = logging.getLogger("convert_harness")

# ---------------------------------------------------------------------------
# Tokenizer (frozen — matches TOKENIZER_SPEC.md exactly)
# ---------------------------------------------------------------------------

PUNCTUATION = set('.,;:!?()[]{}\"/')


def forager_tokenize(text: str) -> list[str]:
    """Reference tokenizer — must match Swift implementation exactly."""
    text = unicodedata.normalize("NFKD", text)
    text = text.lower()
    text = " ".join(text.split())
    result = []
    for char in text:
        if char in PUNCTUATION:
            result.append(" ")
            result.append(char)
            result.append(" ")
        else:
            result.append(char)
    tokens = "".join(result).split()
    return tokens[:64]


# ---------------------------------------------------------------------------
# Alignment Engine
# ---------------------------------------------------------------------------


def normalize_qty_string(qty: float | None) -> list[str]:
    """Generate all plausible token representations of a quantity value."""
    if qty is None:
        return []

    candidates = []

    # Integer
    if qty == int(qty):
        candidates.append(str(int(qty)))
    else:
        # Decimal forms
        candidates.append(f"{qty:.1f}".rstrip("0").rstrip("."))
        candidates.append(str(qty))

    # Mixed fraction: e.g. 1.5 -> "1 1/2" (two tokens: "1", "1/2")
    whole = int(qty)
    frac = round(qty - whole, 2)

    if frac in FRACTION_MAP:
        for frac_str in FRACTION_MAP[frac]:
            if whole > 0:
                candidates.append(f"{whole} {frac_str}")  # will tokenize to 2 tokens
            else:
                candidates.append(frac_str)

    # Pure fraction (no whole part)
    if whole == 0 and frac in FRACTION_MAP:
        for frac_str in FRACTION_MAP[frac]:
            candidates.append(frac_str)

    return candidates


def tokens_match_unit(token: str, ai_unit: str) -> bool:
    """Check if a token matches the AI unit, accounting for synonyms."""
    token_lower = token.lower()
    ai_unit_lower = ai_unit.lower()

    # Direct match
    if token_lower == ai_unit_lower:
        return True

    # Normalize both and compare
    token_norm = _UNIT_LOOKUP.get(token_lower, token_lower)
    ai_norm = _UNIT_LOOKUP.get(ai_unit_lower, ai_unit_lower)
    return token_norm == ai_norm


def find_token_span(target_tokens: list[str], source_tokens: list[str],
                    claimed: list[bool], fuzzy_unit: str | None = None) -> range | None:
    """Find a contiguous span of target_tokens within source_tokens (unclaimed only)."""
    if not target_tokens or len(target_tokens) > len(source_tokens):
        return None

    for i in range(len(source_tokens) - len(target_tokens) + 1):
        if claimed[i]:
            continue
        match = True
        for j, t in enumerate(target_tokens):
            idx = i + j
            if claimed[idx]:
                match = False
                break
            if source_tokens[idx] != t:
                match = False
                break
        if match:
            return range(i, i + len(target_tokens))

    return None


def find_unit_span(ai_unit: str, source_tokens: list[str], claimed: list[bool]) -> range | None:
    """Find a unit token, accounting for synonym expansion (e.g. ai says 'tbsp', text says 'tablespoons')."""
    ai_lower = ai_unit.lower()
    ai_norm = _UNIT_LOOKUP.get(ai_lower, ai_lower)

    # Multi-token unit (e.g. "fl oz" -> "fl", "oz")
    unit_tokens = forager_tokenize(ai_unit)
    if len(unit_tokens) > 1:
        span = find_token_span(unit_tokens, source_tokens, claimed)
        if span:
            return span

    # Single-token: match by synonym
    for i, tok in enumerate(source_tokens):
        if claimed[i]:
            continue
        tok_norm = _UNIT_LOOKUP.get(tok, tok)
        if tok_norm == ai_norm or tok == ai_lower:
            return range(i, i + 1)

    return None


def find_qty_span(qty: float, source_tokens: list[str], claimed: list[bool]) -> range | None:
    """Find quantity token(s), handling integers, decimals, fractions, and mixed numbers."""
    candidates = normalize_qty_string(qty)

    for candidate in candidates:
        ctokens = forager_tokenize(candidate)
        span = find_token_span(ctokens, source_tokens, claimed)
        if span:
            return span

    # Fallback: try matching individual tokens numerically
    for i, tok in enumerate(source_tokens):
        if claimed[i]:
            continue
        try:
            # Handle fraction tokens like "1/2"
            if "/" in tok:
                parts = tok.split("/")
                if len(parts) == 2:
                    val = float(parts[0]) / float(parts[1])
                    if abs(val - qty) < 0.01:
                        return range(i, i + 1)
            val = float(tok)
            if abs(val - qty) < 0.01:
                return range(i, i + 1)
        except ValueError:
            continue

    # Range quantities: "2-3" as a single token — match if qty falls in range
    for i, tok in enumerate(source_tokens):
        if claimed[i]:
            continue
        m = re.match(r'^(\d+)-(\d+)$', tok)
        if m:
            lo, hi = float(m.group(1)), float(m.group(2))
            if lo <= qty <= hi or abs(qty - lo) < 0.01:
                return range(i, i + 1)

    return None


_IRREGULAR_PLURALS = {
    "leaf": "leaves", "leaves": "leaf",
    "loaf": "loaves", "loaves": "loaf",
    "half": "halves", "halves": "half",
    "calf": "calves", "calves": "calf",
    "knife": "knives", "knives": "knife",
    "life": "lives", "lives": "life",
    "wife": "wives", "wives": "wife",
    "shelf": "shelves", "shelves": "shelf",
    "potato": "potatoes", "potatoes": "potato",
    "tomato": "tomatoes", "tomatoes": "tomato",
}


def _fuzzy_token_match(source_tok: str, target_tok: str) -> bool:
    """Match tokens accounting for singular/plural and minor variations."""
    if source_tok == target_tok:
        return True
    # Irregular plurals
    if _IRREGULAR_PLURALS.get(source_tok) == target_tok:
        return True
    if _IRREGULAR_PLURALS.get(target_tok) == source_tok:
        return True
    # Plural: "eggs" vs "egg", "tomatoes" vs "tomato"
    if source_tok.endswith("s") and source_tok[:-1] == target_tok:
        return True
    if target_tok.endswith("s") and target_tok[:-1] == source_tok:
        return True
    if source_tok.endswith("es") and source_tok[:-2] == target_tok:
        return True
    if target_tok.endswith("es") and target_tok[:-2] == source_tok:
        return True
    # "ies" -> "y": "berries" vs "berry"
    if source_tok.endswith("ies") and source_tok[:-3] + "y" == target_tok:
        return True
    if target_tok.endswith("ies") and target_tok[:-3] + "y" == source_tok:
        return True
    return False


def find_name_tokens(ai_name: str, source_tokens: list[str], claimed: list[bool]) -> list[int] | None:
    """Find name tokens using greedy left-to-right matching. Returns list of indices (not range)."""
    name_tokens = forager_tokenize(ai_name)
    if not name_tokens:
        return None

    # Exact contiguous match first
    span = find_token_span(name_tokens, source_tokens, claimed)
    if span:
        return list(span)

    # Fuzzy contiguous match (singular/plural)
    for i in range(len(source_tokens) - len(name_tokens) + 1):
        if claimed[i]:
            continue
        match = True
        for j, nt in enumerate(name_tokens):
            idx = i + j
            if claimed[idx] or not _fuzzy_token_match(source_tokens[idx], nt):
                match = False
                break
        if match:
            return list(range(i, i + len(name_tokens)))

    # Greedy subsequence with fuzzy matching (handles extra words between name tokens)
    indices = []
    matched = 0
    for i, tok in enumerate(source_tokens):
        if claimed[i]:
            continue
        if matched < len(name_tokens) and _fuzzy_token_match(tok, name_tokens[matched]):
            indices.append(i)
            matched += 1

    if matched == len(name_tokens):
        return indices

    return None


def find_notes_tokens(ai_notes: str, source_tokens: list[str], claimed: list[bool]) -> range | None:
    """Find notes tokens (prep instructions, comments, etc.)."""
    notes_tokens = forager_tokenize(ai_notes)
    if not notes_tokens:
        return None

    # Exact contiguous match
    span = find_token_span(notes_tokens, source_tokens, claimed)
    if span:
        return span

    # Notes often appear comma-separated — try matching individual words
    first_idx = None
    last_idx = None
    matched = 0
    for i, tok in enumerate(source_tokens):
        if claimed[i]:
            continue
        if matched < len(notes_tokens) and tok == notes_tokens[matched]:
            if first_idx is None:
                first_idx = i
            last_idx = i
            matched += 1

    if matched == len(notes_tokens) and first_idx is not None:
        return range(first_idx, last_idx + 1)

    return None


def classify_note_token(token: str, context_tokens: list[str], idx: int) -> str:
    """Classify a notes token as PREP or COMMENT."""
    t = token.lower()

    # Check multi-word comment patterns in surrounding context
    for pattern in COMMENT_PATTERNS:
        ptokens = pattern.split()
        if len(ptokens) == 1 and t == ptokens[0]:
            return "COMMENT"
        # Multi-word pattern: check if this token starts the pattern
        if len(ptokens) > 1 and t == ptokens[0]:
            match = True
            for k, pt in enumerate(ptokens[1:], 1):
                if idx + k < len(context_tokens) and context_tokens[idx + k].lower() == pt:
                    continue
                else:
                    match = False
                    break
            if match:
                return "COMMENT"

    # Common prep verbs / past participles
    if t.endswith("ed") or t.endswith("ing"):
        return "PREP"
    if t in {"minced", "diced", "chopped", "sliced", "grated", "shredded",
             "crushed", "ground", "melted", "softened", "sifted", "peeled",
             "deveined", "trimmed", "halved", "quartered", "julienned",
             "cubed", "mashed", "beaten", "whisked", "thawed", "drained",
             "rinsed", "pitted", "seeded", "cored", "zested"}:
        return "PREP"

    return "PREP"  # Default notes to PREP (most common case)


def align_entry(entry: dict) -> dict | None:
    """
    Convert a single harness training entry to token-level labeled format.

    Returns {"tokens": [...], "labels": [...]} or None if alignment fails.
    """
    raw = entry.get("sanitizedText") or entry.get("rawText", "")
    tokens = forager_tokenize(raw)
    if not tokens:
        return None

    labels = ["OTHER"] * len(tokens)
    claimed = [False] * len(tokens)

    ai_name = entry.get("aiName", "")
    ai_qty = entry.get("aiQuantity")
    ai_unit = entry.get("aiUnit")
    ai_notes = entry.get("aiNotes")

    # 1. Tag QTY tokens
    if ai_qty is not None:
        span = find_qty_span(ai_qty, tokens, claimed)
        if span:
            for i in span:
                labels[i] = "QTY"
                claimed[i] = True

    # 2. Tag UNIT tokens
    if ai_unit:
        span = find_unit_span(ai_unit, tokens, claimed)
        if span:
            for i in span:
                labels[i] = "UNIT"
                claimed[i] = True

    # 3. Tag NAME tokens (with MODIFIER disambiguation)
    if ai_name:
        name_indices = find_name_tokens(ai_name, tokens, claimed)
        if name_indices:
            # Find first actual name token (not modifier)
            first_name_idx = None
            for i in name_indices:
                if tokens[i] not in MODIFIER_WORDS:
                    first_name_idx = i
                    break

            for i in name_indices:
                if tokens[i] in MODIFIER_WORDS and (first_name_idx is None or i < first_name_idx):
                    labels[i] = "MODIFIER"
                else:
                    labels[i] = "NAME"
                claimed[i] = True

    # 4. Detect units before notes — prevents notes from claiming unit tokens
    # 4a. Combined number+unit tokens (e.g. "120g", "15-ounce", "15oz")
    for i, tok in enumerate(tokens):
        if claimed[i]:
            continue
        # Pattern: digits followed by unit abbreviation (e.g. "120g", "15oz", "500ml")
        m = re.match(r'^(\d+(?:\.\d+)?)(g|kg|ml|l|oz|lb)$', tok)
        if m:
            labels[i] = "UNIT"
            claimed[i] = True
            continue
        # Combined with hyphen: "15-ounce", "6-inch"
        m = re.match(r'^(\d+)-(\w+)$', tok)
        if m:
            unit_part = m.group(2)
            if unit_part in _UNIT_LOOKUP or unit_part in {"ounce", "inch", "pound", "oz", "lb"}:
                labels[i] = "UNIT"
                claimed[i] = True
                continue

    # 4b. Unclaimed container units: when AI drops the unit (e.g. "cloves", "cans", "stems")
    # tag them as UNIT if they appear after QTY or another UNIT (e.g. "4 oz can")
    for i, tok in enumerate(tokens):
        if claimed[i]:
            continue
        if tok in _UNIT_LOOKUP and i > 0 and labels[i - 1] in ("QTY", "UNIT"):
            labels[i] = "UNIT"
            claimed[i] = True

    # 5. Tag NOTES tokens (PREP vs COMMENT) — skip already-claimed tokens
    if ai_notes:
        span = find_notes_tokens(ai_notes, tokens, claimed)
        if span:
            for i in span:
                if claimed[i]:
                    continue  # Don't overwrite QTY/UNIT/NAME
                if tokens[i] in {",", ";", ".", "(", ")", "[", "]"}:
                    labels[i] = "OTHER"
                else:
                    labels[i] = classify_note_token(tokens[i], tokens, i)
                claimed[i] = True

    # 6. Reclassify: MODIFIER words labeled PREP that appear before first NAME → MODIFIER
    first_name_idx = None
    for i, lbl in enumerate(labels):
        if lbl == "NAME":
            first_name_idx = i
            break

    if first_name_idx is not None:
        for i in range(first_name_idx):
            if tokens[i] in MODIFIER_WORDS:
                if labels[i] in ("OTHER", "PREP"):
                    labels[i] = "MODIFIER"
                    claimed[i] = True

    # 7. Remaining unclaimed punctuation -> OTHER (already defaulted)

    # Validation
    assert len(tokens) == len(labels), f"Token/label mismatch: {len(tokens)} vs {len(labels)}"
    for lbl in labels:
        assert lbl in VALID_LABELS, f"Invalid label: {lbl}"

    return {"tokens": tokens, "labels": labels}


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

INCLUDE_AGREEMENTS = {"full_match", "core_match", "local_likely_wrong", "ambiguous"}
EXCLUDE_AGREEMENTS = {"ai_likely_wrong", "both_wrong"}


def should_include(entry: dict) -> tuple[bool, str]:
    """Decide whether an entry should be included in training data."""
    agreement = entry.get("agreement", "")

    if agreement in EXCLUDE_AGREEMENTS:
        return False, f"excluded_agreement_{agreement}"

    # Must have AI data
    if not entry.get("aiName"):
        return False, "no_ai_name"

    return True, "included"


# ---------------------------------------------------------------------------
# Main conversion pipeline
# ---------------------------------------------------------------------------


def convert_harness_data(input_path: Path, output_dir: Path, do_split: bool,
                         verbose: bool) -> dict:
    """Convert harness training-data.json to JSONL format for train_model.py."""

    log.info(f"Reading harness data from {input_path}")
    with open(input_path) as f:
        data = json.load(f)

    entries = data.get("entries", [])
    log.info(f"Loaded {len(entries)} entries")

    # Stats tracking
    stats = {
        "total_entries": len(entries),
        "included": 0,
        "excluded": Counter(),
        "alignment_failures": 0,
        "alignment_failure_examples": [],
        "converted": 0,
        "label_distribution": Counter(),
        "token_count_total": 0,
        "agreement_distribution": Counter(),
    }

    samples = []

    for entry in entries:
        stats["agreement_distribution"][entry.get("agreement", "unknown")] += 1

        include, reason = should_include(entry)
        if not include:
            stats["excluded"][reason] += 1
            continue

        stats["included"] += 1
        result = align_entry(entry)

        if result is None:
            stats["alignment_failures"] += 1
            if len(stats["alignment_failure_examples"]) < 10:
                stats["alignment_failure_examples"].append(entry.get("rawText", "?"))
            continue

        # Check that we tagged at least a NAME
        if "NAME" not in result["labels"]:
            stats["alignment_failures"] += 1
            if verbose and len(stats["alignment_failure_examples"]) < 10:
                stats["alignment_failure_examples"].append(
                    f"no NAME: {entry.get('rawText', '?')} -> {result['labels']}"
                )
            continue

        samples.append(result)
        stats["converted"] += 1
        stats["token_count_total"] += len(result["tokens"])

        for lbl in result["labels"]:
            stats["label_distribution"][lbl] += 1

    # Deduplicate by token sequence
    seen = set()
    unique_samples = []
    for s in samples:
        key = " ".join(s["tokens"])
        if key not in seen:
            seen.add(key)
            unique_samples.append(s)
    stats["duplicates_removed"] = len(samples) - len(unique_samples)
    stats["unique_samples"] = len(unique_samples)
    samples = unique_samples

    # Output
    output_dir.mkdir(parents=True, exist_ok=True)

    if do_split and len(samples) >= 10:
        # 80/10/10 split
        import random
        random.seed(42)
        random.shuffle(samples)
        n = len(samples)
        train_end = int(n * 0.8)
        val_end = int(n * 0.9)
        splits = {
            "harness_training.jsonl": samples[:train_end],
            "harness_validation.jsonl": samples[train_end:val_end],
            "harness_test.jsonl": samples[val_end:],
        }
        stats["split"] = {k: len(v) for k, v in splits.items()}
    else:
        splits = {"harness_all.jsonl": samples}
        stats["split"] = {"harness_all.jsonl": len(samples)}

    for filename, split_samples in splits.items():
        path = output_dir / filename
        with open(path, "w") as f:
            for s in split_samples:
                f.write(json.dumps(s) + "\n")
        log.info(f"Wrote {len(split_samples)} samples to {path}")

    return stats


def print_stats(stats: dict) -> None:
    """Print conversion statistics."""
    print("\n" + "=" * 60)
    print("HARNESS DATA CONVERSION REPORT")
    print("=" * 60)

    print(f"\nInput entries:       {stats['total_entries']}")
    print(f"Included:            {stats['included']}")
    print(f"Converted:           {stats['converted']}")
    print(f"Alignment failures:  {stats['alignment_failures']}")
    print(f"Duplicates removed:  {stats.get('duplicates_removed', 0)}")
    print(f"Unique samples:      {stats.get('unique_samples', 0)}")
    print(f"Total tokens:        {stats['token_count_total']}")

    if stats["excluded"]:
        print(f"\nExcluded by reason:")
        for reason, count in stats["excluded"].most_common():
            print(f"  {reason}: {count}")

    print(f"\nAgreement distribution:")
    for agreement, count in stats["agreement_distribution"].most_common():
        print(f"  {agreement}: {count}")

    print(f"\nLabel distribution:")
    total_labels = sum(stats["label_distribution"].values())
    for label in ["QTY", "UNIT", "NAME", "MODIFIER", "PREP", "COMMENT", "OTHER"]:
        count = stats["label_distribution"].get(label, 0)
        pct = (count / total_labels * 100) if total_labels > 0 else 0
        print(f"  {label:10s}: {count:6d} ({pct:5.1f}%)")

    if stats.get("split"):
        print(f"\nOutput splits:")
        for filename, count in stats["split"].items():
            print(f"  {filename}: {count}")

    if stats.get("alignment_failure_examples"):
        print(f"\nAlignment failure examples:")
        for ex in stats["alignment_failure_examples"]:
            print(f"  - {ex}")

    print("=" * 60)


def save_stats(stats: dict, output_dir: Path) -> None:
    """Save conversion stats as JSON for logging/tracking."""
    # Make Counter objects serializable
    serializable = {}
    for k, v in stats.items():
        if isinstance(v, Counter):
            serializable[k] = dict(v)
        else:
            serializable[k] = v

    path = output_dir / "conversion_stats.json"
    with open(path, "w") as f:
        json.dump(serializable, f, indent=2)
    log.info(f"Stats saved to {path}")


# ---------------------------------------------------------------------------
# Spot-check: print N random samples for manual review
# ---------------------------------------------------------------------------

def spot_check(output_dir: Path, n: int = 20) -> None:
    """Print N random samples from the converted data for manual review."""
    import random

    # Find the first JSONL file
    jsonl_files = list(output_dir.glob("harness_*.jsonl"))
    if not jsonl_files:
        print("No JSONL files found for spot-check.")
        return

    all_samples = []
    for f in jsonl_files:
        with open(f) as fh:
            for line in fh:
                all_samples.append(json.loads(line))

    random.seed(123)
    check = random.sample(all_samples, min(n, len(all_samples)))

    print(f"\n{'=' * 60}")
    print(f"SPOT CHECK: {len(check)} random samples")
    print(f"{'=' * 60}")

    for i, sample in enumerate(check, 1):
        print(f"\n--- Sample {i} ---")
        # Reconstruct raw-ish text
        print(f"Tokens: {' '.join(sample['tokens'])}")
        labeled = [f"{t}/{l}" for t, l in zip(sample["tokens"], sample["labels"])]
        print(f"Labels: {' '.join(labeled)}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Convert harness training data to BiLSTM-CRF JSONL format"
    )
    parser.add_argument(
        "--input", type=Path,
        default=Path(__file__).parent.parent / "ParsingTestHarness" / "Results" / "training-data.json",
        help="Path to training-data.json from the harness"
    )
    parser.add_argument(
        "--output-dir", type=Path,
        default=Path(__file__).parent / "data",
        help="Output directory for JSONL files"
    )
    parser.add_argument(
        "--split", action="store_true",
        help="Split into train/val/test (80/10/10). Default: single file."
    )
    parser.add_argument(
        "--spot-check", type=int, default=0, metavar="N",
        help="Print N random samples for manual review"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="Verbose logging"
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s"
    )

    if not args.input.exists():
        log.error(f"Input file not found: {args.input}")
        sys.exit(1)

    stats = convert_harness_data(args.input, args.output_dir, args.split, args.verbose)
    print_stats(stats)
    save_stats(stats, args.output_dir)

    if args.spot_check > 0:
        spot_check(args.output_dir, args.spot_check)


if __name__ == "__main__":
    main()
