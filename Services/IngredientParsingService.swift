//
//  IngredientParsingService.swift
//  forager
//
//  Updated for M3 Phase 2: Structured Quantity Management
//  M8.3: Refactored to delegate to hybrid parser architecture
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

    // M8.3: Internal parser instance (will become HybridIngredientParser in Phase 4)
    private let parser: IngredientParser = RegexIngredientParser()

    // Performance tracking
    @Published var lastParsingDuration: TimeInterval = 0
    @Published var parseSuccessRate: Double = 0.0

    init(context: NSManagedObjectContext, templateService: IngredientTemplateService) {
        self.context = context
        self.templateService = templateService
    }

    // MARK: - Smart Ingredient Parsing (Legacy)

    /// Parse ingredient text into components (legacy method)
    func parseIngredient(text: String) -> ParsedIngredient {
        let startTime = CFAbsoluteTimeGetCurrent()

        let result = parser.parse(text)

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        self.lastParsingDuration = duration

        // Convert ParserResult back to ParsedIngredient for legacy callers
        return ParsedIngredient(
            originalText: result.originalText,
            quantity: result.quantity.map { String($0) },
            unit: result.unit,
            name: result.name,
            notes: result.notes
        )
    }

    // MARK: - Structured Quantity Parsing

    /// Parse ingredient text into structured quantity format
    /// M8.1: Logs telemetry for low-confidence parses
    /// M8.3: Now delegates to parser protocol
    func parseToStructured(text: String, source: ParsingTelemetryEvent.ParsingSource = .recipeIngredient) -> StructuredQuantity {
        let startTime = CFAbsoluteTimeGetCurrent()

        let result = parser.parse(text)

        // Build display text
        var displayParts: [String] = []
        if let qty = result.quantity {
            displayParts.append(String(qty))
        }
        if let unit = result.unit {
            displayParts.append(unit)
        }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = displayParts.isEmpty ? trimmedText : displayParts.joined(separator: " ")

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        self.lastParsingDuration = duration

        // M8.1: Log telemetry for all parsing events
        _ = ParsingTelemetryService.shared.logParsingEvent(
            rawInput: text,
            parsedName: result.name,
            parsedQuantity: result.quantity,
            parsedUnit: result.unit,
            parseConfidence: result.confidence,
            parserUsed: result.parserUsed,
            source: source
        )

        return StructuredQuantity(
            numericValue: result.quantity,
            standardUnit: result.unit,
            displayText: displayText,
            isParseable: result.isParseable,
            parseConfidence: result.confidence,
            parserUsed: result.parserUsed
        )
    }

    // MARK: - Parse and Connect (UPDATED for Structured Quantities)

    /// Parse ingredient list and connect to templates using structured quantities
    func parseAndConnectIngredients(for recipe: Recipe, ingredientTexts: [String]) -> [Ingredient] {
        var createdIngredients: [Ingredient] = []
        var successfulParses = 0

        for (index, text) in ingredientTexts.enumerated() {
            let parsed = parseIngredient(text: text)
            let structured = parseToStructured(text: text)

            // Create Ingredient entity with structured fields
            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = parsed.originalText // Store original text as name

            ingredient.numericValue = structured.numericValue ?? 0.0
            ingredient.standardUnit = structured.standardUnit
            ingredient.displayText = structured.displayText
            ingredient.isParseable = structured.isParseable
            ingredient.parseConfidence = structured.parseConfidence

            ingredient.notes = parsed.notes
            ingredient.sortOrder = Int16(index)
            ingredient.recipe = recipe

            // Connect to IngredientTemplate for normalization
            let template = templateService.findOrCreateTemplate(
                name: parsed.displayName,
                category: categorizeIngredient(parsed.displayName)
            )
            ingredient.ingredientTemplate = template
            templateService.incrementUsage(template: template)

            createdIngredients.append(ingredient)

            if structured.isParseable {
                successfulParses += 1
            }
        }

        // Update success rate
        if !ingredientTexts.isEmpty {
            parseSuccessRate = Double(successfulParses) / Double(ingredientTexts.count)
        }

        return createdIngredients
    }

    // MARK: - Category Inference

    private func categorizeIngredient(_ name: String) -> String? {
        let lowercased = name.lowercased()

        if lowercased.contains("chicken") || lowercased.contains("beef") ||
           lowercased.contains("pork") || lowercased.contains("fish") {
            return "Meat & Seafood"
        } else if lowercased.contains("milk") || lowercased.contains("cheese") ||
                  lowercased.contains("butter") || lowercased.contains("cream") {
            return "Dairy"
        } else if lowercased.contains("apple") || lowercased.contains("banana") ||
                  lowercased.contains("orange") || lowercased.contains("berry") {
            return "Produce"
        } else if lowercased.contains("bread") || lowercased.contains("pasta") ||
                  lowercased.contains("rice") || lowercased.contains("flour") {
            return "Pantry"
        }

        return "Other"
    }
}
