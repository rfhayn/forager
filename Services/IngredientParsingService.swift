//
//  IngredientParsingService.swift
//  forager
//
//  Updated for M3 Phase 2: Structured Quantity Management
//  M8.3: Refactored to delegate to hybrid parser architecture
//  M8.4 Phase 0c: Single-parse refactor — parser.parse() called exactly once per ingredient
//

import Foundation
import CoreData

// MARK: - Structured Quantity Model

struct StructuredQuantity {
    let numericValue: Double?      // 2.0, 1.5, nil for unparseable
    let standardUnit: String?      // "cup", "lb", "tsp" (standardized)
    let displayText: String        // "2 cups", "a pinch" (user-facing)
    let isParseable: Bool          // Can be used in math operations
    let parseConfidence: Float     // 0.0-1.0
    let parserUsed: String?        // M8.3: Which parser produced this result
}

struct ParsedIngredient {
    let originalText: String
    let quantity: String?
    let unit: String?
    let name: String
    let notes: String?

    var displayName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFullyParsed: Bool {
        return quantity != nil && unit != nil && !name.isEmpty
    }
}

/// Service for intelligent ingredient text parsing with structured quantity support
/// M8.3: Now delegates to RegexIngredientParser via protocol-based architecture
class IngredientParsingService: ObservableObject {
    private let context: NSManagedObjectContext
    private let templateService: IngredientTemplateService

    // M9.5: Injectable parser with backward-compatible default
    private let parser: IngredientParser

    // Performance tracking
    @Published var lastParsingDuration: TimeInterval = 0
    @Published var parseSuccessRate: Double = 0.0

    // M10.6.7: Surface LLM errors to callers for better toast messages
    @Published var lastLLMError: String?

    init(context: NSManagedObjectContext,
         templateService: IngredientTemplateService,
         parser: IngredientParser = HybridIngredientParser()) {
        self.context = context
        self.templateService = templateService
        self.parser = parser
    }

    // MARK: - Core Parse (Single Entry Point)

    /// M8.4 Phase 0c: Single parsing entry point — calls parser.parse() exactly once
    /// and logs telemetry. All public parsing methods delegate through this.
    private func parseCore(text: String, source: ParsingTelemetryEvent.ParsingSource) -> ParserResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = parser.parse(text)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        self.lastParsingDuration = duration

        _ = ParsingTelemetryService.shared.logParsingEvent(
            rawInput: text,
            parsedName: result.name,
            parsedQuantity: result.quantity,
            parsedUnit: result.unit,
            parseConfidence: result.confidence,
            parserUsed: result.parserUsed,
            source: source
        )

        return result
    }

    // MARK: - Result Mapping Helpers

    private static func mapToParsedIngredient(_ result: ParserResult) -> ParsedIngredient {
        ParsedIngredient(
            originalText: result.originalText,
            quantity: result.quantity.map { String($0) },
            unit: result.unit,
            name: result.name,
            notes: result.notes
        )
    }

    private static func mapToStructuredQuantity(_ result: ParserResult, text: String) -> StructuredQuantity {
        var displayParts: [String] = []
        if let qty = result.quantity { displayParts.append(String(qty)) }
        if let unit = result.unit { displayParts.append(unit) }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = displayParts.isEmpty ? trimmedText : displayParts.joined(separator: " ")

        return StructuredQuantity(
            numericValue: result.quantity,
            standardUnit: result.unit,
            displayText: displayText,
            isParseable: result.isParseable,
            parseConfidence: result.confidence,
            parserUsed: result.parserUsed
        )
    }

    // MARK: - Unified Parsing (Single Parse → Both Results)

    /// Parse ingredient text once, returning both legacy and structured results with telemetry.
    /// Use this instead of calling parseIngredient() + parseToStructured() separately.
    func parseUnified(text: String, source: ParsingTelemetryEvent.ParsingSource = .recipeIngredient) -> (parsed: ParsedIngredient, structured: StructuredQuantity) {
        let result = parseCore(text: text, source: source)
        return (Self.mapToParsedIngredient(result), Self.mapToStructuredQuantity(result, text: text))
    }

    // MARK: - Legacy Parsing (Lightweight, No Telemetry)

    /// Parse ingredient text into components. Lightweight — no telemetry logging.
    /// Used for intermediate operations (autocomplete, typing previews, template lookup).
    /// For final parse operations that need telemetry, use parseUnified() or parseToStructured().
    func parseIngredient(text: String) -> ParsedIngredient {
        let result = parser.parse(text)
        return Self.mapToParsedIngredient(result)
    }

    // MARK: - Structured Quantity Parsing

    /// Parse ingredient text into structured quantity format with telemetry.
    /// M8.4: Now delegates through parseCore() for single-parse guarantee.
    func parseToStructured(text: String, source: ParsingTelemetryEvent.ParsingSource = .recipeIngredient) -> StructuredQuantity {
        let result = parseCore(text: text, source: source)
        return Self.mapToStructuredQuantity(result, text: text)
    }

    // MARK: - Parse and Connect

    /// Parse ingredient list and connect to templates using structured quantities.
    /// M8.4: Refactored to single-parse via parseUnified().
    func parseAndConnectIngredients(for recipe: Recipe, ingredientTexts: [String]) -> [Ingredient] {
        var createdIngredients: [Ingredient] = []
        var successfulParses = 0

        for (index, text) in ingredientTexts.enumerated() {
            let (parsed, structured) = parseUnified(text: text)

            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = parsed.originalText
            ingredient.numericValue = structured.numericValue ?? 0.0
            ingredient.standardUnit = structured.standardUnit
            ingredient.displayText = structured.displayText
            ingredient.isParseable = structured.isParseable
            ingredient.parseConfidence = structured.parseConfidence
            ingredient.notes = parsed.notes
            ingredient.sortOrder = Int16(index)
            ingredient.recipe = recipe

            let template = templateService.findOrCreateTemplate(
                name: parsed.displayName,
                category: nil
            )
            ingredient.ingredientTemplate = template
            templateService.incrementUsage(template: template)

            createdIngredients.append(ingredient)

            if structured.isParseable {
                successfulParses += 1
            }
        }

        if !ingredientTexts.isEmpty {
            parseSuccessRate = Double(successfulParses) / Double(ingredientTexts.count)
        }

        return createdIngredients
    }

    // MARK: - M10.6.6: User-Triggered LLM Parsing

    /// Whether an LLM parser is configured and available (enabled + API key present)
    @MainActor
    var isLLMAvailable: Bool {
        LLMSettingsService.shared.activeParser() != nil
    }

    /// Parse a single ingredient via LLM. Returns nil on any failure.
    /// Caller should keep existing local result on nil return.
    func parseSingleWithLLM(text: String, source: ParsingTelemetryEvent.ParsingSource) async -> (ParsedIngredient, StructuredQuantity)? {
        let results = await parseBatchWithLLM(texts: [text], source: source)
        return results?.first
    }

    /// Parse a batch of ingredients via LLM. Returns nil on any failure or count mismatch.
    /// Caller should keep existing local results on nil return.
    /// Sets `lastLLMError` with a descriptive message on failure.
    func parseBatchWithLLM(texts: [String], source: ParsingTelemetryEvent.ParsingSource) async -> [(ParsedIngredient, StructuredQuantity)]? {
        guard !texts.isEmpty else { return nil }

        let parser: any LLMIngredientParser
        do {
            guard let p = await LLMSettingsService.shared.activeParser() else {
                await MainActor.run { lastLLMError = "AI parsing not configured" }
                return nil
            }
            parser = p
        }

        do {
            let llmResults = try await parser.parseBatch(texts)

            // Strict validation: count must match input
            guard llmResults.count == texts.count else {
                await MainActor.run { lastLLMError = "AI returned unexpected results" }
                return nil
            }

            var output: [(ParsedIngredient, StructuredQuantity)] = []

            for (index, llmResult) in llmResults.enumerated() {
                let originalText = texts[index]
                let parserResult = llmResult.toParserResult(originalText: originalText, provider: parser.providerName)

                let parsed = Self.mapToParsedIngredient(parserResult)
                let structured = Self.mapToStructuredQuantity(parserResult, text: originalText)

                // Log telemetry per ingredient
                _ = ParsingTelemetryService.shared.logParsingEvent(
                    rawInput: originalText,
                    parsedName: parserResult.name,
                    parsedQuantity: parserResult.quantity,
                    parsedUnit: parserResult.unit,
                    parseConfidence: parserResult.confidence,
                    parserUsed: parser.providerName,
                    source: source
                )

                output.append((parsed, structured))
            }

            await MainActor.run { lastLLMError = nil }
            return output
        } catch let error as LLMParserError {
            let message = error.errorDescription ?? error.localizedDescription
            #if DEBUG
            print("🤖 [LLM Parse] Batch failed: \(message)")
            #endif
            await MainActor.run { lastLLMError = message }
            return nil
        } catch {
            #if DEBUG
            print("🤖 [LLM Parse] Batch failed: \(error.localizedDescription)")
            #endif
            await MainActor.run { lastLLMError = error.localizedDescription }
            return nil
        }
    }

    // MARK: - M9.1.2: Centralized Clean Name Extraction

    private static let sharedParser = HybridIngredientParser()

    /// Extract a clean ingredient name from raw text (e.g., "2 cups flour" → "Flour").
    /// Delegates to the hybrid parser for consistent behavior across the app.
    static func extractCleanIngredientName(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let result = sharedParser.parse(trimmed)
        let name = result.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? trimmed.capitalized : name.capitalized
    }

}
