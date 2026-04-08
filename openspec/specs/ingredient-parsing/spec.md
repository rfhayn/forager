# Spec: Ingredient Parsing

## Overview

Multi-tier ingredient parsing pipeline that converts free-text ingredient strings (e.g., "2 cups all-purpose flour, sifted") into structured data (quantity, unit, name, notes, confidence). The pipeline uses a 3-tier local architecture (Regex, ML, NLP) with confidence-based routing, plus an optional Claude API integration for semantic parsing during recipe import. The IngredientParsingService is the sole public API -- callers never use parsers directly.

## Requirements

- REQ-001: The system MUST route ingredient parsing through a 3-tier local pipeline: RegexIngredientParser (fast path, threshold 0.9) then MLIngredientParser (threshold 0.8) then NLPIngredientParser (fallback, confidence capped at 0.75).
  - Scenario: Given the input "2 cups flour", When RegexIngredientParser returns confidence 0.95, Then the regex result is used immediately without consulting ML or NLP tiers.

- REQ-002: The RegexIngredientParser MUST handle standard ingredient patterns including fractions (1/2, 1/4, 3/4), ranges, units, and qualifiers with performance under 0.05 seconds for 80%+ of inputs.
  - Scenario: Given the input "1 1/2 cups sugar", When the regex parser processes it, Then it returns {quantity: 1.5, unit: "cup", name: "sugar", confidence: 0.95} in under 0.03 seconds.

- REQ-003: The MLIngredientParser MUST use a CoreML BiLSTM sequence labeler trained on 120,000+ ingredient sentences with token-level labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER).
  - Scenario: Given the input "3 cloves garlic, minced", When the ML parser processes it, Then token labels identify "3" as QTY, "cloves" as UNIT, "garlic" as NAME, "minced" as PREP, returning confidence 0.88.

- REQ-004: The NLPIngredientParser MUST use Apple's NaturalLanguage framework as the fallback tier with confidence capped at 0.75, handling complex patterns that regex and ML miss.
  - Scenario: Given the input "juice of 2 lemons", When regex returns 0.6 and ML returns 0.7, Then NLP processes the inverted structure and returns {quantity: 2, name: "lemon", notes: "juice of", confidence: 0.75}.

- REQ-005: The HybridIngredientParser MUST route inputs through the tiers sequentially, returning the highest-confidence result that exceeds its tier's threshold.
  - Scenario: Given an input where regex returns 0.7 and ML returns 0.85, When the hybrid router evaluates both, Then it returns the ML result (0.85 exceeds the 0.8 threshold) without consulting NLP.

- REQ-006: The system MUST provide an optional Claude API integration (ClaudeIngredientParser) that processes all ingredient lines in a single batch API call during recipe import, with silent fallback to the deterministic pipeline on any failure.
  - Scenario: Given LLM is enabled and the user saves a recipe import with 10 ingredients, When the Claude API call succeeds, Then all 10 ingredients are parsed via LLM with 0.95 confidence; When the API returns a 429 error, Then the system silently falls back to the regex/ML/NLP pipeline with no error shown to the user.

- REQ-007: The Claude API integration MUST be OFF by default, with no setup nudges or banners. Users opt in via Settings > AI Integration with their own API key.
  - Scenario: Given a fresh app install, When the user imports a recipe, Then only the local pipeline is used; the user never sees any mention of AI unless they navigate to Settings > AI Integration.

- REQ-008: The system MUST store the LLM API key in the iOS Keychain via LLMSettingsService, with household-level sharing via CloudKit.
  - Scenario: Given the household owner enters a Claude API key in Settings, When a household member opens the app, Then the API key is available to their device via CloudKit sync of the encrypted key.

- REQ-009: The system MUST provide low-confidence detection with visual indicators (yellow badge for parseConfidence < 0.5) and an edit form for manual correction.
  - Scenario: Given an ingredient parses with confidence 0.4, When the item appears in the grocery list, Then a yellow warning badge is visible, indicating the parsed data may need manual review.

- REQ-010: The system MUST log parsing telemetry (ParsingTelemetryService) to a local JSON file for pattern analysis, with privacy-safe storage (no user ID, local only).
  - Scenario: Given 100 ingredients are parsed during import, When telemetry logs, Then each parse event records parser used, confidence, original text, and source type in a Documents directory JSON file.

- REQ-011: The IngredientParsingService MUST be the sole public API for parsing -- callers MUST NOT use RegexIngredientParser, MLIngredientParser, NLPIngredientParser, or ClaudeIngredientParser directly.
  - Scenario: Given a new view needs to parse an ingredient string, When the developer looks for a parsing API, Then only IngredientParsingService methods are available (parseAndConnectIngredients, parseSingleWithLLM, parseBatchWithLLM).

- REQ-012: The LLM parser MUST use a separate protocol (LLMIngredientParser) from the local IngredientParser protocol because the LLM is async and batch-oriented while local parsers are synchronous and per-line.
  - Scenario: Given the LLM parser protocol, When a provider conformer (ClaudeIngredientParser) implements parseBatch, Then it sends all lines in one API call and returns [LLMParserResult], which bridges to the existing ParserResult type via toParserResult().

## Implementation Notes

- Parser architecture: IngredientParser protocol (sync, per-line) with 3 conformers: RegexIngredientParser, MLIngredientParser, NLPIngredientParser
- HybridIngredientParser routes between the 3 local tiers based on confidence thresholds
- LLMIngredientParser protocol (async, batch) is separate -- lives at RecipeImportService level, not inside the hybrid router
- ClaudeIngredientParser uses claude-haiku-4-5 model with tool_use structured output
- ML model: BiLSTM emission scorer (CoreML) + CRF transition matrix (JSON) + Viterbi decoder (Swift)
- Training data: strangetom/ingredient-parser (81K sentences) + NYT ingredient-phrase-tagger (180K examples), deduplicated to ~120-150K
- Telemetry schema version: 3 (current); v4 planned for import events
- Manual recipe entry always uses the local pipeline (no LLM for per-keystroke parsing)
