//
//  RegexIngredientParser.swift
//  forager
//
//  Created for M8.3: Hybrid NLP Parser
//  Fast-path regex-based ingredient parser with enhanced patterns
//

import Foundation

// MARK: - RegexIngredientParser

/// Fast-path ingredient parser using regex pattern matching
/// Handles: unicode fractions, ranges, parentheticals, compound phrases,
/// standard qty+unit+name, qualifiers, descriptive amounts, and plain names
class RegexIngredientParser: IngredientParser {

    let parserName = "regex"

    // MARK: - Unicode Fraction Map

    /// Maps Unicode fraction characters to decimal values
    private static let unicodeFractionMap: [Character: Double] = [
        "½": 0.5, "⅓": 1.0/3.0, "⅔": 2.0/3.0,
        "¼": 0.25, "¾": 0.75,
        "⅕": 0.2, "⅖": 0.4, "⅗": 0.6, "⅘": 0.8,
        "⅙": 1.0/6.0, "⅚": 5.0/6.0,
        "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875
    ]

    // MARK: - Word-Number Map

    /// Maps number words to numeric values for compound phrase parsing
    private static let wordNumberMap: [String: Double] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12,
        "a": 1, "an": 1,
        "half": 0.5, "quarter": 0.25, "third": 1.0/3.0
    ]

    // MARK: - Descriptive Amount Map

    /// Maps descriptive quantity words to approximate numeric values
    private static let descriptiveAmountMap: [String: Double] = [
        "pinch": 0.125, "dash": 0.125, "smidgen": 0.03125,
        "handful": 0.5, "splash": 0.5, "drizzle": 0.5,
        "sprig": 1, "stalk": 1, "leaf": 1
    ]

    // MARK: - IngredientParser Protocol

    func parse(_ input: String) -> ParserResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return ParserResult(
                name: "Unknown ingredient",
                quantity: nil, unit: nil, notes: nil,
                confidence: 0.0, originalText: input, parserUsed: parserName
            )
        }

        if trimmed.count < 3 {
            return ParserResult(
                name: trimmed,
                quantity: nil, unit: nil, notes: nil,
                confidence: 0.0, originalText: input, parserUsed: parserName
            )
        }

        // Pre-process: Insert space between leading digits and letters
        // Handles concatenated qty+unit like "16oz" → "16 oz", "2tbsp" → "2 tbsp"
        let normalized = trimmed.replacingOccurrences(
            of: #"^(\d+(?:\.\d+)?)\s*([a-zA-Z])"#,
            with: "$1 $2",
            options: .regularExpression
        )

        // Try patterns in priority order (highest specificity first)
        // Each returns non-nil if it matched

        if let result = tryUnicodeFractionPattern(normalized, original: input) { return result }
        if let result = tryRangePattern(normalized, original: input) { return result }
        if let result = tryParentheticalPattern(normalized, original: input) { return result }
        if let result = tryCompoundPhrasePattern(normalized, original: input) { return result }
        if let result = tryStandardPattern(normalized, original: input) { return result }
        if let result = tryQualifierPattern(normalized, original: input) { return result }
        if let result = tryDescriptiveAmountPattern(normalized, original: input) { return result }

        // Fallback: just ingredient name
        return ParserResult(
            name: normalized,
            quantity: nil, unit: nil, notes: nil,
            confidence: 0.0, originalText: input, parserUsed: parserName
        )
    }

    // MARK: - Pattern 1: Unicode Fractions
    // Handles: "½ cup sugar", "1½ cups flour", "¼ tsp salt"

    private func tryUnicodeFractionPattern(_ text: String, original: String) -> ParserResult? {
        // Check if text contains any unicode fraction characters
        guard text.unicodeScalars.contains(where: { Self.unicodeFractionMap.keys.contains(Character(UnicodeScalar($0))) }) else {
            return nil
        }

        // Replace unicode fractions with decimal equivalents in-place
        var normalized = text
        var fractionValue: Double = 0

        for (char, value) in Self.unicodeFractionMap {
            if normalized.contains(char) {
                // Check for "1½" pattern (digit immediately before fraction)
                let pattern = #"(\d)"# + String(char)
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
                   let wholeRange = Range(match.range(at: 1), in: normalized),
                   let whole = Double(normalized[wholeRange]) {
                    fractionValue = whole + value
                    normalized = normalized.replacingOccurrences(of: "\(Int(whole))\(char)", with: String(fractionValue))
                } else {
                    fractionValue = value
                    normalized = normalized.replacingOccurrences(of: String(char), with: String(value))
                }
            }
        }

        // Now parse the normalized text with the standard pattern
        let parsed = tryStandardPatternInternal(normalized)

        if let parsed = parsed {
            let numericValue = convertToNumeric(parsed.quantity)
            let standardUnit = standardizeUnit(parsed.unit)

            let confidence: Float
            if numericValue != nil && standardUnit != nil && !parsed.name.isEmpty {
                confidence = 1.0
            } else if numericValue != nil && !parsed.name.isEmpty {
                confidence = 0.90
            } else {
                confidence = 0.75
            }

            return ParserResult(
                name: parsed.displayName,
                quantity: numericValue,
                unit: standardUnit,
                notes: parsed.notes,
                confidence: confidence,
                originalText: original,
                parserUsed: parserName
            )
        }

        return nil
    }

    // MARK: - Pattern 2: Ranges
    // Handles: "2-3 cloves garlic", "1-2 cups flour", "3 to 4 tbsp butter"

    private func tryRangePattern(_ text: String, original: String) -> ParserResult? {
        // Pattern: number[-–—to]number followed by optional unit and name
        let rangePattern = #"^(\d+(?:\.\d+)?)\s*[-–—]\s*(\d+(?:\.\d+)?)\s+([a-zA-Z]+)\s+(.+)$"#
        if let match = matchPattern(rangePattern, in: text) {
            let highValue = match[2] // Use higher value from range
            let potentialUnit = match[3]
            var name = match[4].trimmingCharacters(in: .whitespacesAndNewlines)
            var unit: String? = potentialUnit

            if !isKnownUnit(potentialUnit) {
                name = "\(potentialUnit) \(name)".trimmingCharacters(in: .whitespacesAndNewlines)
                unit = nil
            }

            let numericValue = Double(highValue)
            let standardUnit = standardizeUnit(unit)

            let confidence: Float = (standardUnit != nil) ? 0.85 : 0.80

            return ParserResult(
                name: name,
                quantity: numericValue,
                unit: standardUnit,
                notes: "range: \(match[1])-\(match[2])",
                confidence: confidence,
                originalText: original,
                parserUsed: parserName
            )
        }

        // Range without unit: "2-3 eggs", "1-2 avocados"
        let rangeNoUnitPattern = #"^(\d+(?:\.\d+)?)\s*[-–—]\s*(\d+(?:\.\d+)?)\s+(.+)$"#
        if let match = matchPattern(rangeNoUnitPattern, in: text) {
            let highValue = match[2]
            let name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let numericValue = Double(highValue)

            return ParserResult(
                name: name,
                quantity: numericValue,
                unit: nil,
                notes: "range: \(match[1])-\(match[2])",
                confidence: 0.80,
                originalText: original,
                parserUsed: parserName
            )
        }

        // "3 to 4 cups flour" style ranges
        let wordRangePattern = #"^(\d+(?:\.\d+)?)\s+to\s+(\d+(?:\.\d+)?)\s+([a-zA-Z]+)\s+(.+)$"#
        if let match = matchPattern(wordRangePattern, in: text) {
            let highValue = match[2]
            let potentialUnit = match[3]
            var name = match[4].trimmingCharacters(in: .whitespacesAndNewlines)
            var unit: String? = potentialUnit

            if !isKnownUnit(potentialUnit) {
                name = "\(potentialUnit) \(name)".trimmingCharacters(in: .whitespacesAndNewlines)
                unit = nil
            }

            let numericValue = Double(highValue)
            let standardUnit = standardizeUnit(unit)

            return ParserResult(
                name: name,
                quantity: numericValue,
                unit: standardUnit,
                notes: "range: \(match[1])-\(match[2])",
                confidence: (standardUnit != nil) ? 0.85 : 0.80,
                originalText: original,
                parserUsed: parserName
            )
        }

        return nil
    }

    // MARK: - Pattern 3: Parentheticals
    // Handles: "1 can (14.5 oz) diced tomatoes", "2 (6-inch) tortillas"

    private func tryParentheticalPattern(_ text: String, original: String) -> ParserResult? {
        // Pattern: qty unit (parenthetical) name
        let parenPattern = #"^(\d+(?:[./]\d+)?(?:\s+\d+/\d+)?)\s+([a-zA-Z]+)\s+\(([^)]+)\)\s+(.+)$"#
        if let match = matchPattern(parenPattern, in: text) {
            let quantity = match[1]
            let potentialUnit = match[2]
            let parenthetical = match[3]
            var name = match[4].trimmingCharacters(in: .whitespacesAndNewlines)
            var unit: String? = potentialUnit

            if !isKnownUnit(potentialUnit) {
                name = "\(potentialUnit) \(name)".trimmingCharacters(in: .whitespacesAndNewlines)
                unit = nil
            }

            let numericValue = convertToNumeric(quantity)
            let standardUnit = standardizeUnit(unit)

            return ParserResult(
                name: name,
                quantity: numericValue,
                unit: standardUnit,
                notes: parenthetical,
                confidence: 0.80,
                originalText: original,
                parserUsed: parserName
            )
        }

        // Pattern: qty (parenthetical) name — no unit before parens
        let parenNoUnitPattern = #"^(\d+(?:[./]\d+)?(?:\s+\d+/\d+)?)\s+\(([^)]+)\)\s+(.+)$"#
        if let match = matchPattern(parenNoUnitPattern, in: text) {
            let quantity = match[1]
            let parenthetical = match[2]
            let name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)

            let numericValue = convertToNumeric(quantity)

            return ParserResult(
                name: name,
                quantity: numericValue,
                unit: nil,
                notes: parenthetical,
                confidence: 0.80,
                originalText: original,
                parserUsed: parserName
            )
        }

        return nil
    }

    // MARK: - Pattern 4: Compound Phrases
    // Handles: "one and a half cups milk", "two cups sugar", "a cup of flour"

    private func tryCompoundPhrasePattern(_ text: String, original: String) -> ParserResult? {
        let lowered = text.lowercased()

        // "one and a half cups milk" → 1.5 cups milk
        let andAHalfPattern = #"^(\w+)\s+and\s+a\s+half\s+([a-zA-Z]+)\s+(.+)$"#
        if let match = matchPattern(andAHalfPattern, in: lowered) {
            let wordNum = match[1]
            let potentialUnit = match[2]
            var name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)
            var unit: String? = potentialUnit

            if let base = Self.wordNumberMap[wordNum] {
                let numericValue = base + 0.5

                if !isKnownUnit(potentialUnit) {
                    name = "\(potentialUnit) \(name)".trimmingCharacters(in: .whitespacesAndNewlines)
                    unit = nil
                }

                let standardUnit = standardizeUnit(unit)

                return ParserResult(
                    name: name,
                    quantity: numericValue,
                    unit: standardUnit,
                    notes: nil,
                    confidence: (standardUnit != nil) ? 0.85 : 0.75,
                    originalText: original,
                    parserUsed: parserName
                )
            }
        }

        // "two cups sugar", "three large eggs"
        let wordNumPattern = #"^(\w+)\s+([a-zA-Z]+)\s*(.*)$"#
        if let match = matchPattern(wordNumPattern, in: lowered) {
            let wordNum = match[1]
            let potentialUnit = match[2]
            let rest = match[3].trimmingCharacters(in: .whitespacesAndNewlines)

            // Defer "a pinch of...", "a handful of..." to descriptive amount pattern
            if (wordNum == "a" || wordNum == "an"),
               Self.descriptiveAmountMap.keys.contains(potentialUnit) {
                return nil
            }

            if let numericValue = Self.wordNumberMap[wordNum] {
                var unit: String? = potentialUnit
                var name = rest

                if !isKnownUnit(potentialUnit) {
                    name = rest.isEmpty ? potentialUnit : "\(potentialUnit) \(rest)"
                    name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    unit = nil
                }

                // Don't match "a" followed by non-unit non-food patterns
                // But "a cup of flour" should work
                if wordNum == "a" && unit == nil && !rest.isEmpty {
                    // "a large egg" → qty 1, name "large egg"
                    // But we need name to not be empty
                }

                guard !name.isEmpty else { return nil }

                let standardUnit = standardizeUnit(unit)

                return ParserResult(
                    name: name,
                    quantity: numericValue,
                    unit: standardUnit,
                    notes: nil,
                    confidence: (standardUnit != nil) ? 0.85 : 0.70,
                    originalText: original,
                    parserUsed: parserName
                )
            }
        }

        return nil
    }

    // MARK: - Pattern 5: Standard Qty + Unit + Name (existing logic)
    // Handles: "2 cups flour", "1 1/2 tbsp olive oil", "3 large eggs"

    private func tryStandardPattern(_ text: String, original: String) -> ParserResult? {
        guard let parsed = tryStandardPatternInternal(text) else { return nil }

        let numericValue = convertToNumeric(parsed.quantity)
        let standardUnit = standardizeUnit(parsed.unit)

        let confidence: Float
        if parsed.isFullyParsed && numericValue != nil {
            confidence = 1.0
        } else if numericValue != nil {
            confidence = 0.75
        } else if parsed.quantity != nil {
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
            originalText: original,
            parserUsed: parserName
        )
    }

    /// Internal standard pattern that returns a ParsedIngredient (used by unicode fraction too)
    private func tryStandardPatternInternal(_ text: String) -> ParsedIngredient? {
        // "2 cups flour" or "1 1/2 tbsp olive oil"
        let pattern = #"^([0-9]+(?:\.\d+)?(?:\s+[0-9]+/[0-9]+|[/.][0-9]+)?)\s+([a-zA-Z]+)?\s*(.+)$"#
        if let match = matchPattern(pattern, in: text) {
            let quantity = match[1]
            var unit = match[2].isEmpty ? nil : match[2]
            var name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)

            if let capturedUnit = unit, !isKnownUnit(capturedUnit) {
                let combinedName = "\(capturedUnit) \(name)".trimmingCharacters(in: .whitespacesAndNewlines)
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

        return nil
    }

    // MARK: - Pattern 6: Qualifiers
    // Handles: "salt to taste", "pepper as needed", "garlic, minced"

    private func tryQualifierPattern(_ text: String, original: String) -> ParserResult? {
        // "salt to taste", "pepper as needed", "oil as desired"
        let qualifierPattern = #"^([a-zA-Z\s]+?)\s*,?\s*(to taste|as needed|as desired|for garnish|for serving|optional)$"#
        if let match = matchPattern(qualifierPattern, in: text) {
            let name = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let qualifier = match[2]

            return ParserResult(
                name: name,
                quantity: nil,
                unit: nil,
                notes: qualifier,
                confidence: 0.70,
                originalText: original,
                parserUsed: parserName
            )
        }

        // "garlic, minced" or "onion, diced"
        let commaQualifierPattern = #"^([a-zA-Z\s]+?)\s*,\s*(minced|diced|chopped|sliced|crushed|grated|shredded|julienned|peeled|seeded|trimmed|halved|quartered|torn|fresh|dried|frozen|thawed|softened|melted|room temperature|packed)$"#
        if let match = matchPattern(commaQualifierPattern, in: text) {
            let name = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let prep = match[2]

            return ParserResult(
                name: name,
                quantity: nil,
                unit: nil,
                notes: prep,
                confidence: 0.70,
                originalText: original,
                parserUsed: parserName
            )
        }

        return nil
    }

    // MARK: - Pattern 7: Descriptive Amounts
    // Handles: "a pinch of salt", "a handful of herbs", "a splash of vinegar"

    private func tryDescriptiveAmountPattern(_ text: String, original: String) -> ParserResult? {
        let lowered = text.lowercased()

        // "a pinch of salt", "a dash of cayenne", "a handful of herbs"
        let descriptivePattern = #"^a\s+(pinch|dash|smidgen|handful|splash|drizzle|sprig|stalk|leaf)\s+(?:of\s+)?(.+)$"#
        if let match = matchPattern(descriptivePattern, in: lowered) {
            let descriptor = match[1]
            let name = match[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let approxQty = Self.descriptiveAmountMap[descriptor]

            return ParserResult(
                name: name,
                quantity: approxQty,
                unit: nil,
                notes: "a \(descriptor)",
                confidence: 0.60,
                originalText: original,
                parserUsed: parserName
            )
        }

        // Just the descriptor without "a": "pinch of salt"
        let bareDescriptivePattern = #"^(pinch|dash|smidgen|handful|splash|drizzle)\s+(?:of\s+)?(.+)$"#
        if let match = matchPattern(bareDescriptivePattern, in: lowered) {
            let descriptor = match[1]
            let name = match[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let approxQty = Self.descriptiveAmountMap[descriptor]

            return ParserResult(
                name: name,
                quantity: approxQty,
                unit: nil,
                notes: descriptor,
                confidence: 0.60,
                originalText: original,
                parserUsed: parserName
            )
        }

        return nil
    }

    // MARK: - Helper: Pattern Matching

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

    // MARK: - Helper: Known Unit Check

    func isKnownUnit(_ unit: String) -> Bool {
        let lowercased = unit.lowercased()

        let volumeUnits: Set<String> = ["cup", "cups", "c", "tablespoon", "tablespoons", "tbsp", "tbs", "t",
                          "teaspoon", "teaspoons", "tsp", "ts", "ml", "milliliter", "milliliters",
                          "l", "liter", "liters", "oz", "fl oz", "fluid ounce", "fluid ounces",
                          "pint", "pints", "pt", "quart", "quarts", "qt", "gallon", "gallons", "gal"]

        let weightUnits: Set<String> = ["lb", "lbs", "pound", "pounds", "oz", "ounce", "ounces",
                          "g", "gram", "grams", "kg", "kilogram", "kilograms"]

        let countUnits: Set<String> = ["piece", "pieces", "pc", "clove", "cloves", "slice", "slices",
                         "can", "cans", "package", "packages", "pkg", "bunch", "bunches",
                         "head", "heads", "stick", "sticks", "bag", "bags", "bottle", "bottles",
                         "box", "boxes", "jar", "jars", "sprig", "sprigs"]

        return volumeUnits.contains(lowercased) ||
               weightUnits.contains(lowercased) ||
               countUnits.contains(lowercased)
    }

    // MARK: - Helper: Numeric Conversion

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
               let numerator = Double(parts[0].trimmingCharacters(in: .whitespaces)),
               let denominator = Double(parts[1].trimmingCharacters(in: .whitespaces)),
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

    // MARK: - Helper: Unit Standardization

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
            "head": "head", "heads": "head",
            "stick": "stick", "sticks": "stick",
            "bag": "bag", "bags": "bag",
            "bottle": "bottle", "bottles": "bottle",
            "box": "box", "boxes": "box",
            "jar": "jar", "jars": "jar",
            "sprig": "sprig", "sprigs": "sprig"
        ]

        if let standard = volumeMap[unit] { return standard }
        if let standard = weightMap[unit] { return standard }
        if let standard = countMap[unit] { return standard }

        return unit
    }
}
