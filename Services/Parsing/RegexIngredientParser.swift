//
//  RegexIngredientParser.swift
//  forager
//
//  Created for M8.3: Hybrid NLP Parser
//  Fast-path regex-based ingredient parser, extracted from IngredientParsingService
//

import Foundation

// MARK: - RegexIngredientParser

/// Fast-path ingredient parser using regex pattern matching
/// Extracted from IngredientParsingService to support the hybrid architecture
class RegexIngredientParser: IngredientParser {

    let parserName = "regex"

    // MARK: - IngredientParser Protocol

    func parse(_ input: String) -> ParserResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return ParserResult(
                name: "Unknown ingredient",
                quantity: nil,
                unit: nil,
                notes: nil,
                confidence: 0.0,
                originalText: input,
                parserUsed: parserName
            )
        }

        if trimmed.count < 3 {
            return ParserResult(
                name: trimmed,
                quantity: nil,
                unit: nil,
                notes: nil,
                confidence: 0.0,
                originalText: input,
                parserUsed: parserName
            )
        }

        let parsed = parseWithPatterns(text: trimmed)

        // Convert to numeric and standardize unit
        let numericValue = convertToNumeric(parsed.quantity)
        let standardUnit = standardizeUnit(parsed.unit)

        // Calculate confidence
        let confidence: Float
        if parsed.isFullyParsed && numericValue != nil {
            confidence = 1.0
        } else if numericValue != nil {
            confidence = 0.75
        } else if parsed.quantity != nil {
            confidence = 0.3
        } else if parsed.notes != nil {
            // Has notes (like "to taste") — partial parse
            confidence = 0.3
        } else {
            confidence = 0.0
        }

        return ParserResult(
            name: parsed.displayName,
            quantity: numericValue,
            unit: standardUnit,
            notes: parsed.notes,
            confidence: confidence,
            originalText: input,
            parserUsed: parserName
        )
    }

    // MARK: - Pattern-Based Parsing

    /// Check if a string is a known measurement unit
    func isKnownUnit(_ unit: String) -> Bool {
        let lowercased = unit.lowercased()

        let volumeUnits = ["cup", "cups", "c", "tablespoon", "tablespoons", "tbsp", "tbs", "t",
                          "teaspoon", "teaspoons", "tsp", "ts", "ml", "milliliter", "milliliters",
                          "l", "liter", "liters", "oz", "fl oz", "fluid ounce", "fluid ounces",
                          "pint", "pints", "pt", "quart", "quarts", "qt", "gallon", "gallons", "gal"]

        let weightUnits = ["lb", "lbs", "pound", "pounds", "oz", "ounce", "ounces",
                          "g", "gram", "grams", "kg", "kilogram", "kilograms"]

        let countUnits = ["piece", "pieces", "pc", "clove", "cloves", "slice", "slices",
                         "can", "cans", "package", "packages", "pkg", "bunch", "bunches",
                         "head", "heads"]

        return volumeUnits.contains(lowercased) ||
               weightUnits.contains(lowercased) ||
               countUnits.contains(lowercased)
    }

    func parseWithPatterns(text: String) -> ParsedIngredient {
        // Pattern 1: "2 cups flour" or "1 1/2 tbsp olive oil"
        let pattern1 = #"^([0-9]+(?:\s+[0-9]+/[0-9]+|[/.][0-9]+)?)\s+([a-zA-Z]+)?\s*(.+)$"#
        if let match = matchPattern(pattern1, in: text) {
            let quantity = match[1]
            var unit = match[2].isEmpty ? nil : match[2]
            var name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate that captured "unit" is actually a known unit
            if let capturedUnit = unit, !isKnownUnit(capturedUnit) {
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

    func matchPattern(_ pattern: String, in text: String) -> [String]? {
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

        return nil
    }

    // MARK: - Unit Standardization

    /// Standardize unit strings to canonical forms
    func standardizeUnit(_ unit: String?) -> String? {
        guard let unit = unit?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
              !unit.isEmpty else {
            return nil
        }

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

        let weightMap: [String: String] = [
            "pound": "lb", "pounds": "lb", "lb": "lb", "lbs": "lb",
            "ounce": "oz", "ounces": "oz", "oz": "oz",
            "gram": "g", "grams": "g", "g": "g",
            "kilogram": "kg", "kilograms": "kg", "kg": "kg"
        ]

        let countMap: [String: String] = [
            "piece": "piece", "pieces": "piece", "pc": "piece",
            "clove": "clove", "cloves": "clove",
            "slice": "slice", "slices": "slice",
            "can": "can", "cans": "can",
            "package": "package", "packages": "package", "pkg": "package",
            "bunch": "bunch", "bunches": "bunch",
            "head": "head", "heads": "head"
        ]

        if let standard = volumeMap[unit] { return standard }
        if let standard = weightMap[unit] { return standard }
        if let standard = countMap[unit] { return standard }

        return unit
    }
}
