# ADR 010: Hybrid Parser with Confidence-Driven Routing

**Status**: ACTIVE
**Created**: February 8, 2026
**Context**: M8.3 Hybrid NLP Parser
**Related**: M8.1 (Parsing Telemetry), `service-layer-pattern.md`

---

## Decision

Route ingredient parsing through a **confidence-scored hybrid architecture** where a fast regex parser runs first, and an NLP fallback is only consulted when regex confidence falls below a threshold.

```
IngredientParsingService (public API — unchanged)
  └── HybridIngredientParser (router, confidence threshold = 0.8)
        ├── RegexIngredientParser (fast path, microseconds)
        └── NLPIngredientParser (fallback, Apple NaturalLanguage)
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

3. **ML/CoreML model**: Highest accuracy ceiling but requires training data, model management, and significant implementation effort. Overkill for current scale.

4. **Hybrid with confidence routing** (chosen): Regex handles the 80%+ of inputs it excels at. NLP handles the ambiguous remainder. Confidence scores drive the routing decision.

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

### Routing Logic

```
1. Run RegexIngredientParser
2. If confidence >= 0.8 → return regex result (fast path, no NLP overhead)
3. If confidence < 0.8 → also run NLPIngredientParser
4. Return whichever result has higher confidence
5. Tag parserUsed = "regex" | "nlp" | "hybrid"
```

### Why 0.8 Threshold?

The threshold sits between two tiers:
- **Above 0.8**: Full parse (1.0), unicode fractions (0.90), ranges with units (0.85) — patterns where regex is confident and correct
- **Below 0.8**: Parentheticals (0.80), qualifiers (0.70), descriptive amounts (0.60), name-only fallback (0.0) — patterns where NLP might extract additional structure

Setting the threshold at 0.8 means regex results at 0.85+ skip NLP entirely, while 0.80 and below get a second opinion.

### Why Cap NLP at 0.75?

NLP confidence is capped at 0.75 to prevent it from overriding good regex results. Without the cap, NLP could return 0.9 confidence for a plausible-but-wrong parse, beating a correct-but-partial regex parse. The cap ensures the hierarchy: confident regex > NLP > uncertain regex.

### Confidence Tiers

| Scenario | Confidence | Parser |
|----------|-----------|--------|
| Full parse: qty + unit + name | 1.0 | regex |
| Unicode fraction + unit + name | 1.0 | regex |
| Unicode fraction + name only | 0.90 | regex |
| Range + unit + name | 0.85 | regex |
| Compound phrase + unit | 0.85 | regex |
| Range/parenthetical + name | 0.80 | regex |
| NLP full parse (capped) | 0.75 | nlp |
| Qty + name (no unit) | 0.75 | regex |
| Qualifier detected | 0.70 | regex |
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

The `parserUsed` field in telemetry events enables data-driven decisions about whether to invest in ML-based parsing (M8.4). If NLP handles >20% of inputs in production, the ML investment is justified.

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

- **M8.4 (ML-Powered Parsing)**: If telemetry shows NLP handling >20% of inputs, consider a trained CoreML model as a third parser option
- **Confidence threshold tuning**: Production telemetry may reveal a better threshold than 0.8
- **Pattern caching**: RegexIngredientParser re-creates NSRegularExpression objects per call — could be cached as static properties for marginal speedup
- **Locale awareness**: Current patterns are English-only; international expansion would need locale-specific parsers

---

## File Locations

```
Services/Parsing/IngredientParser.swift       # Protocol + ParserResult
Services/Parsing/RegexIngredientParser.swift   # Fast path (7 pattern categories)
Services/Parsing/NLPIngredientParser.swift     # Fallback (NaturalLanguage)
Services/Parsing/HybridIngredientParser.swift  # Router
Services/IngredientParsingService.swift        # Public API (facade)
Services/ParsingTelemetryService.swift         # Tracks parserUsed
```
