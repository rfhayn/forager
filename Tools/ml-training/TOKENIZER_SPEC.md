# Tokenizer Specification — M8.4 Ingredient Parser

**Status**: FROZEN (Phase 0b contract)
**Version**: 1.0
**Date**: February 21, 2026

This document is the binding contract between the Python training tokenizer and the Swift runtime tokenizer. Both implementations MUST produce identical output for any given input. Cross-validate against `data/tokenizer_test_vectors.json`.

---

## Tokenization Pipeline

### Step 1: Unicode Normalization
- Apply **NFKD** (Compatibility Decomposition)
- Python: `unicodedata.normalize('NFKD', text)`
- Swift: `text.applyingTransform(.init("NFKD"), reverse: false)!`
- **NOT** NFD — Swift's `.decomposedStringWithCanonicalMapping` produces NFD, not NFKD

### Step 2: Case Folding
- Lowercase the entire string
- Python: `text.lower()`
- Swift: `text.lowercased()`

### Step 3: Whitespace Normalization
- Strip leading/trailing whitespace
- Collapse internal runs of whitespace to single space
- Python: `' '.join(text.split())`
- Swift: components separated by whitespace, joined by single space

### Step 4: Punctuation Splitting
- Split punctuation from word boundaries
- Punctuation characters: `.,;:!?()[]{}"/`
- Hyphens (`-`) are **NOT** split — they are part of compound words (e.g., "all-purpose")
- Apostrophes (`'`) are **NOT** split — they are part of contractions/possessives
- Forward slash (`/`) **IS** split — it separates fractions from words but fractions like "1/2" are handled by the model as tokens

**Algorithm**:
1. Insert space before punctuation if preceded by non-space
2. Insert space after punctuation if followed by non-space
3. Re-split on whitespace

**Examples**:
- `"tomatoes, diced"` → `["tomatoes", ",", "diced"]`
- `"all-purpose flour"` → `["all-purpose", "flour"]`
- `"(14.5 oz)"` → `["(", "14.5", "oz", ")"]`
- `"salt/pepper"` → `["salt", "/", "pepper"]`

### Step 5: Fraction Handling
- Fraction tokens like `"1/2"`, `"3/4"` remain as single tokens
- Unicode fractions (`½`, `¼`, `⅓`) are preserved as-is after NFKD (NFKD decomposes some but not all)
- The model learns fraction patterns from training data

### Step 6: Sequence Limits
- **Max sequence length**: 64 tokens
- **Truncation**: Right-truncate (drop tokens beyond position 64)
- **Padding**: **None** — pass actual token count via dynamic `RangeDim(1, 64)` input shape
- Rationale: Ingredient strings rarely exceed 20 tokens; 64 provides generous headroom

---

## Vocabulary

| Token | ID | Purpose |
|-------|-----|---------|
| `<UNK>` | 0 | Unknown words (not in vocabulary) |
| `<PAD>` | 1 | Reserved for batch/fixed-shape (not used in v1 RangeDim) |
| *word tokens* | 2+ | Assigned by frequency during training |

- Vocabulary built from training data with frequency threshold ≥ 2
- Tokens appearing only once → mapped to `<UNK>` (ID 0)
- Vocabulary saved as `vocabulary.json`: `{"token": id, ...}`

---

## Label Set (7 Forager Labels)

| Label | ID | Meaning |
|-------|-----|---------|
| QTY | 0 | Quantity |
| UNIT | 1 | Unit of measure |
| NAME | 2 | Ingredient name |
| MODIFIER | 3 | Name modifier/size |
| PREP | 4 | Preparation method |
| COMMENT | 5 | Comment/qualifier |
| OTHER | 6 | Punctuation/other |

---

## Reference Implementation

### Python

```python
import unicodedata
import re

PUNCTUATION = set('.,;:!?()[]{}\"/')

def tokenize(text: str) -> list[str]:
    """Reference tokenizer — Swift must match this exactly."""
    # Step 1: NFKD normalization
    text = unicodedata.normalize('NFKD', text)
    # Step 2: Lowercase
    text = text.lower()
    # Step 3: Whitespace normalization
    text = ' '.join(text.split())
    # Step 4: Punctuation splitting
    result = []
    for char in text:
        if char in PUNCTUATION:
            result.append(' ')
            result.append(char)
            result.append(' ')
        else:
            result.append(char)
    tokens = ''.join(result).split()
    # Step 6: Truncate to 64 tokens
    return tokens[:64]
```

### Swift

```swift
func tokenize(_ text: String) -> [String] {
    let punctuation: Set<Character> = [".", ",", ";", ":", "!", "?",
                                        "(", ")", "[", "]", "{", "}",
                                        "\"", "/"]
    // Step 1: NFKD normalization
    guard let normalized = text.applyingTransform(
        StringTransform("NFKD"), reverse: false
    ) else { return text.split(separator: " ").map(String.init) }
    // Step 2: Lowercase
    let lowered = normalized.lowercased()
    // Step 3: Whitespace normalization
    let collapsed = lowered.split(omittingEmptySubsequences: true,
                                   whereSeparator: \.isWhitespace)
                           .joined(separator: " ")
    // Step 4: Punctuation splitting
    var result: [Character] = []
    for char in collapsed {
        if punctuation.contains(char) {
            result.append(" ")
            result.append(char)
            result.append(" ")
        } else {
            result.append(char)
        }
    }
    let tokens = String(result)
        .split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
        .map(String.init)
    // Step 6: Truncate
    return Array(tokens.prefix(64))
}
```

---

## Test Vectors

See `data/tokenizer_test_vectors.json` for 100 test cases.

Format:
```json
[
  {
    "input": "2 cups all-purpose flour",
    "expected_tokens": ["2", "cups", "all-purpose", "flour"]
  }
]
```

Both Python and Swift tokenizers must produce identical `expected_tokens` for every test case.
