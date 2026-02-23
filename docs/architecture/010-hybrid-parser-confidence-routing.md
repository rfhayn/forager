# ADR 010: Hybrid Parser with Confidence-Driven Routing

**Status**: ACTIVE
**Created**: February 8, 2026
**Updated**: February 22, 2026 (M8.4: 3-tier routing, winner-only attribution)
**Context**: M8.3 Hybrid NLP Parser → M8.4 ML-Powered Parsing
**Related**: M8.1 (Parsing Telemetry), `service-layer-pattern.md`

---

## Decision

Route ingredient parsing through a **confidence-scored 3-tier architecture** with winner-only attribution. The fast regex parser runs first; if uncertain, the ML parser (BiLSTM-CRF) is tried; NLP is a final fallback only when both regex and ML are highly uncertain.

```
IngredientParsingService (public API — unchanged)
  └── HybridIngredientParser (router)
        ├── RegexIngredientParser   (tier 1: fast path, microseconds, threshold ≥0.9)
        ├── MLIngredientParser      (tier 2: BiLSTM-CRF, milliseconds, threshold ≥0.8)
        └── NLPIngredientParser     (tier 3: fallback, only when regex <0.5 AND ML <0.5)
```

---

## Context

### The Problem

The original `IngredientParsingService` had 4 regex patterns in a monolithic method. It handled standard inputs well ("2 cups flour" → 1.0 confidence) but failed on:
- Unicode fractions: "½ cup sugar" → 0.0 confidence
- Ranges: "2-3 cloves garlic" → 0.0 confidence
- Parentheticals: "1 can (14.5 oz) tomatoes" → 0.0 confidence
- Word quantities: "one and a half cups milk" → 0.0 confidence
- Qualifiers without quantities: "salt to taste" → 0.0 confidence

Roughly 5% of real-world ingredient inputs produced low confidence.

### Alternatives Considered

1. **More regex patterns only**: Simplest, but has a ceiling — natural language is inherently ambiguous and regex can't handle every variation.

2. **NLP only (replace regex)**: Apple's NaturalLanguage is powerful but slower and less precise for structured formats. "2 cups flour" is perfectly captured by regex in microseconds — NLP would be wasteful overhead.

3. **ML/CoreML model only**: Highest accuracy ceiling but slower than regex for standard inputs. Replaced regex for everything would sacrifice microsecond performance on the 80%+ of inputs regex handles perfectly.

4. **3-tier hybrid with confidence routing** (chosen): Regex handles high-confidence inputs (≥0.9) in microseconds. ML (BiLSTM-CRF) handles the moderate band with 98.49% token accuracy. NLP is a final fallback for the rare cases where both primary parsers are uncertain.

---

## Architecture Details

### The Protocol

```swift
protocol IngredientParser {
    func parse(_ input: String) -> ParserResult
    var parserName: String { get }
}
```

All parsers return a `ParserResult` with a `confidence: Float` (0.0-1.0) and `parserUsed: String` for telemetry tracking.

### Routing Logic (M8.4: 3-Tier)

```
1. Run RegexIngredientParser
2. If confidence >= 0.9 → return regex result (fast path, no ML/NLP overhead)
3. If ML parser available:
   a. Run MLIngredientParser
   b. If ML confidence >= 0.8 → return ML result
   c. If regex < 0.5 AND ML < 0.5 → run NLPIngredientParser, return best of all three
   d. Otherwise → return better of regex vs ML
4. If ML parser unavailable (graceful degradation):
   a. If regex confidence >= 0.8 → return regex result
   b. Run NLPIngredientParser, return better of regex vs NLP
5. parserUsed = winner's parserName ("regex" | "ml" | "nlp") — never "hybrid"
```

### Winner-Only Attribution (M8.4)

Previously, `parserUsed` could be `"hybrid"` when the regex result won after NLP was consulted. M8.4 eliminates this — the winning parser's result is returned directly with its own `parserUsed` value. This makes telemetry directly actionable: each event maps to exactly one parser implementation.

### Why 0.9 Regex Threshold?

Raised from 0.8 (M8.3) to 0.9 (M8.4) to give the ML parser opportunities to run on moderate-confidence inputs. The ML model (98.49% token accuracy, 95.40% sentence accuracy) outperforms NLP in the 0.8-0.9 confidence band. Only very high-confidence regex results (full parse, unicode fractions with unit+name) skip ML.

### Why ML Threshold at 0.8?

ML confidence is computed as the geometric mean of max per-token softmax probabilities. A threshold of 0.8 means the model is confidently labeling most tokens. Below 0.8, the model is uncertain about some tokens — NLP might add value if both parsers are very uncertain (< 0.5).

### Why NLP Only When Both < 0.5?

NLP confidence is capped at 0.75 (see below). In the moderate band (regex 0.5-0.9, ML 0.5-0.8), ML is almost certainly more accurate than NLP, so consulting NLP would only add latency. NLP is reserved for cases where both primary parsers are highly uncertain — unusual inputs like qualifiers without quantities.

### Why Cap NLP at 0.75?

NLP confidence is capped at 0.75 to prevent it from overriding good regex or ML results. Without the cap, NLP could return 0.9 confidence for a plausible-but-wrong parse, beating a correct-but-partial regex parse. The cap ensures the hierarchy: confident regex > confident ML > NLP > uncertain regex/ML.

### Confidence Tiers

| Scenario | Confidence | Parser |
|----------|-----------|--------|
| Full parse: qty + unit + name | 1.0 | regex |
| Unicode fraction + unit + name | 1.0 | regex |
| Unicode fraction + name only | 0.90 | regex |
| ML confident parse (all tokens) | 0.80-0.99 | ml |
| Range + unit + name | 0.85 | regex |
| Compound phrase + unit | 0.85 | regex |
| Range/parenthetical + name | 0.80 | regex |
| NLP full parse (capped) | 0.75 | nlp |
| Qty + name (no unit) | 0.75 | regex |
| Qualifier detected | 0.70 | regex |
| ML moderate parse | 0.50-0.79 | ml |
| Descriptive amount | 0.60 | regex |
| NLP qty + name | 0.60 | nlp |
| NLP name + notes | 0.50 | nlp |
| NLP name only | 0.30 | nlp |
| Nothing parsed | 0.0 | either |

---

## Key Design Principles

### 1. Zero Public API Change

`IngredientParsingService` remains the only public interface. All 6 call sites (`AddListItemView`, `CreateRecipeView`, `EditRecipeView`, `GroceryListDetailView`, `RecipeListView`, `QuantityMigrationService`) were untouched. The hybrid architecture is entirely internal.

### 2. Regex-First for Performance

Regex runs in microseconds. NLP (even on-device via NaturalLanguage framework) runs in milliseconds. For the majority of inputs, NLP is never called. This preserves the <0.05s parsing target.

### 3. Telemetry-Informed Evolution

The `parserUsed` field in telemetry events tracks which parser won each input. With M8.4's winner-only attribution, telemetry shows the exact parser (`"regex"`, `"ml"`, `"nlp"`) that produced each result — enabling data-driven threshold tuning.

### 4. Pattern Priority Order Matters

Regex patterns are tried in a specific order because earlier patterns can shadow later ones:

1. Unicode fractions (must precede standard numeric — `½` doesn't match `[0-9]+`)
2. Ranges (`2-3` would be mishandled by the standard pattern)
3. Parentheticals (must capture before standard swallows the parens)
4. Compound phrases (word-numbers like "two" before standard numeric)
5. Standard qty + unit + name
6. Qualifiers (after standard, since "2 cups flour, diced" needs the number first)
7. Descriptive amounts (lowest priority structured pattern)

---

## Trade-offs

### Benefits
- **Performance**: 80%+ of inputs never touch NLP
- **Accuracy**: Combined approach handles more input formats than either alone
- **Extensibility**: New patterns can be added to either parser independently
- **Observability**: `parserUsed` telemetry shows exactly what's happening
- **Backward compatibility**: Zero call site changes, Codable schema forward/backward compatible

### Costs
- **Complexity**: 4 files instead of 1 (but each is focused and testable)
- **Dual maintenance**: Unit lists and standardization maps exist in both parsers
- **NLP unpredictability**: NLTagger results vary by iOS version and locale
- **Threshold tuning**: The 0.8 threshold and 0.75 cap may need adjustment based on production telemetry

---

## Future Considerations

- **Threshold calibration**: Run all 3 parsers on held-out samples, measure accuracy by confidence band, adjust 0.9/0.8 thresholds based on observed accuracy curves
- **Disagreement arbitration**: If regex and ML disagree on structural slots, NLP could arbitrate (v2)
- **Pattern caching**: RegexIngredientParser re-creates NSRegularExpression objects per call — could be cached as static properties for marginal speedup
- **Locale awareness**: Current patterns are English-only; international expansion would need locale-specific parsers
- **Continuous learning (M8.4 Phases 7-8)**: User corrections feed back into ML model retraining

---

## File Locations

```
Services/Parsing/IngredientParser.swift       # Protocol + ParserResult
Services/Parsing/RegexIngredientParser.swift   # Tier 1: Fast path (7 pattern categories)
Services/Parsing/MLIngredientParser.swift      # Tier 2: BiLSTM-CRF (M8.4)
Services/Parsing/ViterbiDecoder.swift          # CRF decode step (M8.4)
Services/Parsing/NLPIngredientParser.swift     # Tier 3: Fallback (NaturalLanguage)
Services/Parsing/HybridIngredientParser.swift  # Router (3-tier confidence routing)
Services/IngredientParsingService.swift        # Public API (facade)
Services/ParsingTelemetryService.swift         # Tracks parserUsed
forager/MLModel/IngredientTaggerEmissions.mlpackage  # CoreML model (5.15 MB)
forager/MLModel/vocabulary.json               # Token → ID mapping (3,545 tokens)
forager/MLModel/transitions.json              # CRF transition parameters
```
