//
//  IngredientParsingService.swift
//  forager
//
//  Updated for M3 Phase 2: Structured Quantity Management
//  Enhanced with numeric conversion and unit standardization
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
class IngredientParsingService: ObservableObject {
    private let context: NSManagedObjectContext
    private let templateService: IngredientTemplateService
    
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
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else {
            return ParsedIngredient(
                originalText: text,
                quantity: nil,
                unit: nil,
                name: "Unknown ingredient",
                notes: nil
            )
        }
        
        if trimmedText.count < 3 {
            return ParsedIngredient(
                originalText: text,
                quantity: nil,
                unit: nil,
                name: trimmedText,
                notes: nil
            )
        }
        
        let parsed = parseWithPatterns(text: trimmedText)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        self.lastParsingDuration = duration
        
        return parsed
    }
    
    // MARK: - Structured Quantity Parsing (NEW)

    /// Parse ingredient text into structured quantity format
    /// M8.1: Now logs telemetry for low-confidence parses
    func parseToStructured(text: String, source: ParsingTelemetryEvent.ParsingSource = .recipeIngredient) -> StructuredQuantity {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse using existing patterns
        let parsed = parseWithPatterns(text: trimmedText)
        
        // Convert to numeric and standardize
        let numericValue = convertToNumeric(parsed.quantity)
        let standardUnit = standardizeUnit(parsed.unit)
        
        // Determine if parseable
        let isParseable = numericValue != nil
        
        // Calculate confidence
        let confidence: Float
        if parsed.isFullyParsed && isParseable {
            confidence = 1.0
        } else if isParseable {
            confidence = 0.7
        } else if parsed.quantity != nil {
            confidence = 0.3
        } else {
            confidence = 0.0
        }
        
        // Build display text
        var displayParts: [String] = []
        if let qty = parsed.quantity {
            displayParts.append(qty)
        }
        if let unit = parsed.unit {
            displayParts.append(unit)
        }
        let displayText = displayParts.isEmpty ? trimmedText : displayParts.joined(separator: " ")
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        self.lastParsingDuration = duration

        // M8.1: Log telemetry for all parsing events
        _ = ParsingTelemetryService.shared.logParsingEvent(
            rawInput: text,
            parsedName: parsed.displayName,
            parsedQuantity: numericValue,
            parsedUnit: standardUnit,
            parseConfidence: confidence,
            source: source
        )

        return StructuredQuantity(
            numericValue: numericValue,
            standardUnit: standardUnit,
            displayText: displayText,
            isParseable: isParseable,
            parseConfidence: confidence
        )
    }
    
    // MARK: - Numeric Conversion
    
    /// Convert quantity string to numeric value
    func convertToNumeric(_ quantity: String?) -> Double? {
        guard let qty = quantity?.trimmingCharacters(in: .whitespacesAndNewlines),
              !qty.isEmpty else {
            return nil
        }
        
        // Handle simple decimals: "2", "1.5", "0.75"
        if let value = Double(qty) {
            return value
        }
        
        // Handle fractions: "3/4", "1/2", "2/3"
        if qty.contains("/") {
            let parts = qty.split(separator: "/").map(String.init)
            if parts.count == 2,
               let numerator = Double(parts[0]),
               let denominator = Double(parts[1]),
               denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Handle mixed fractions: "1 1/2", "2 3/4"
        let mixedPattern = #"^(\d+)\s+(\d+)/(\d+)$"#
        if let regex = try? NSRegularExpression(pattern: mixedPattern),
           let match = regex.firstMatch(in: qty, range: NSRange(qty.startIndex..., in: qty)) {
            
            if let wholeRange = Range(match.range(at: 1), in: qty),
               let numRange = Range(match.range(at: 2), in: qty),
               let denomRange = Range(match.range(at: 3), in: qty),
               let whole = Double(qty[wholeRange]),
               let numerator = Double(qty[numRange]),
               let denominator = Double(qty[denomRange]),
               denominator != 0 {
                return whole + (numerator / denominator)
            }
        }
        
        // Unparseable
        return nil
    }
    
    // MARK: - Unit Standardization
    
    /// Standardize unit strings to canonical forms
    func standardizeUnit(_ unit: String?) -> String? {
        guard let unit = unit?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
              !unit.isEmpty else {
            return nil
        }
        
        // Volume units
        let volumeMap: [String: String] = [
            "cup": "cup", "cups": "cup", "c": "cup",
            "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp", "tbs": "tbsp", "t": "tbsp",
            "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp", "ts": "tsp",
            "milliliter": "ml", "milliliters": "ml", "ml": "ml", "mls": "ml",
            "liter": "l", "liters": "l", "l": "l", "ls": "l",
            "fluid ounce": "fl oz", "fluid ounces": "fl oz", "fl oz": "fl oz", "fl. oz.": "fl oz",
            "pint": "pint", "pints": "pint", "pt": "pint",
            "quart": "quart", "quarts": "quart", "qt": "quart",
            "gallon": "gallon", "gallons": "gallon", "gal": "gallon"
        ]
        
        // Weight units
        let weightMap: [String: String] = [
            "pound": "lb", "pounds": "lb", "lb": "lb", "lbs": "lb",
            "ounce": "oz", "ounces": "oz", "oz": "oz",
            "gram": "g", "grams": "g", "g": "g",
            "kilogram": "kg", "kilograms": "kg", "kg": "kg"
        ]
        
        // Count/other units
        let countMap: [String: String] = [
            "piece": "piece", "pieces": "piece", "pc": "piece",
            "clove": "clove", "cloves": "clove",
            "slice": "slice", "slices": "slice",
            "can": "can", "cans": "can",
            "package": "package", "packages": "package", "pkg": "package",
            "bunch": "bunch", "bunches": "bunch",
            "head": "head", "heads": "head"
        ]
        
        // Check all maps
        if let standard = volumeMap[unit] { return standard }
        if let standard = weightMap[unit] { return standard }
        if let standard = countMap[unit] { return standard }
        
        // Return original if not found
        return unit
    }
    
    // MARK: - Parse and Connect (UPDATED for Structured Quantities)
    
    /// Parse ingredient list and connect to templates using structured quantities
    func parseAndConnectIngredients(for recipe: Recipe, ingredientTexts: [String]) -> [Ingredient] {
        var createdIngredients: [Ingredient] = []
        var successfulParses = 0
        
        for (index, text) in ingredientTexts.enumerated() {
            let parsed = parseIngredient(text: text)
            let structured = parseToStructured(text: text)
            
            // Create Ingredient entity with NEW structured fields
            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = parsed.originalText // Store original text as name
            
            // NEW: Set structured quantity fields
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
    
    // MARK: - Pattern-Based Parsing (Existing - Unchanged)
    
    // M4.3.5: Helper to check if a string is a known measurement unit
    private func isKnownUnit(_ unit: String) -> Bool {
        let lowercased = unit.lowercased()
        
        // Volume units
        let volumeUnits = ["cup", "cups", "c", "tablespoon", "tablespoons", "tbsp", "tbs", "t",
                          "teaspoon", "teaspoons", "tsp", "ts", "ml", "milliliter", "milliliters",
                          "l", "liter", "liters", "oz", "fl oz", "fluid ounce", "fluid ounces",
                          "pint", "pints", "pt", "quart", "quarts", "qt", "gallon", "gallons", "gal"]
        
        // Weight units
        let weightUnits = ["lb", "lbs", "pound", "pounds", "oz", "ounce", "ounces",
                          "g", "gram", "grams", "kg", "kilogram", "kilograms"]
        
        // Count/other units
        let countUnits = ["piece", "pieces", "pc", "clove", "cloves", "slice", "slices",
                         "can", "cans", "package", "packages", "pkg", "bunch", "bunches",
                         "head", "heads"]
        
        return volumeUnits.contains(lowercased) || 
               weightUnits.contains(lowercased) || 
               countUnits.contains(lowercased)
    }
    
    private func parseWithPatterns(text: String) -> ParsedIngredient {
        // Pattern 1: "2 cups flour" or "1 1/2 tbsp olive oil"
        let pattern1 = #"^([0-9]+(?:\s+[0-9]+/[0-9]+|[/.][0-9]+)?)\s+([a-zA-Z]+)?\s*(.+)$"#
        if let match = matchPattern(pattern1, in: text) {
            let quantity = match[1]
            var unit = match[2].isEmpty ? nil : match[2]
            var name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // M4.3.5 BUG FIX: Validate that captured "unit" is actually a known unit
            // If not (like "egg" from "2 eggs"), combine it with the name
            if let capturedUnit = unit, !isKnownUnit(capturedUnit) {
                // Combine unit and name, handling cases where name might be empty or just whitespace
                let combinedName = "\(capturedUnit)\(name)".trimmingCharacters(in: .whitespacesAndNewlines)
                name = combinedName
                unit = nil
            }
            
            return ParsedIngredient(
                originalText: text,
                quantity: quantity,
                unit: unit,
                name: name,
                notes: nil
            )
        }
        
        // Pattern 2: "Salt to taste" or "Pepper as needed"
        let pattern2 = #"^([a-zA-Z\s]+?)\s+(to taste|as needed|as desired)$"#
        if let match = matchPattern(pattern2, in: text) {
            let name = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let notes = match[2]
            
            return ParsedIngredient(
                originalText: text,
                quantity: nil,
                unit: nil,
                name: name,
                notes: notes
            )
        }
        
        // Pattern 3: "A pinch of salt" or "A handful of nuts"
        let pattern3 = #"^(a\s+(?:pinch|dash|handful))\s+of\s+(.+)$"#
        if let match = matchPattern(pattern3, in: text) {
            let quantity = match[1]
            let name = match[2].trimmingCharacters(in: .whitespacesAndNewlines)
            
            return ParsedIngredient(
                originalText: text,
                quantity: quantity,
                unit: nil,
                name: name,
                notes: nil
            )
        }
        
        // Pattern 4: Just ingredient name
        return ParsedIngredient(
            originalText: text,
            quantity: nil,
            unit: nil,
            name: text,
            notes: nil
        )
    }
    
    private func matchPattern(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        var results: [String] = []
        for i in 0..<match.numberOfRanges {
            let matchRange = match.range(at: i)
            if matchRange.location != NSNotFound,
               let range = Range(matchRange, in: text) {
                results.append(String(text[range]))
            } else {
                results.append("")
            }
        }
        
        return results.isEmpty ? nil : results
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
