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

    // MARK: - Measurement Modifiers

    /// M8.5: Words that modify a measurement but aren't units themselves
    /// "2 heaping tablespoons" → strip "heaping" so parser sees "2 tablespoons"
    private static let measurementModifiers: Set<String> = [
        "heaping", "rounded", "scant", "generous", "level",
        "packed", "lightly", "loosely", "firmly", "overflowing"
    ]

    // MARK: - M9.35 P3B: Comma-Qualifier Prep Detection

    /// First words that signal the text after a comma is prep, not part of the name
    private static let commaQualifierPrepWords: Set<String> = [
        "minced", "diced", "chopped", "sliced", "crushed", "grated", "shredded",
        "julienned", "peeled", "seeded", "trimmed", "halved", "quartered", "torn",
        "roughly", "finely", "thinly", "coarsely", "lightly", "freshly",
        "cut", "at room", "room temp", "plus more", "or more",
        "divided", "separated", "whisked", "beaten", "sifted"
    ]

    /// Exact multi-word prep phrases after comma
    private static let commaQualifierExactPhrases: Set<String> = [
        "room temperature", "at room temperature", "optional",
        "packed", "to taste", "for garnish", "for serving",
        "fresh", "dried", "frozen", "thawed", "softened", "melted"
    ]

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
        "sprig": 1, "stalk": 1, "leaf": 1,
        "bunch": 1, "sprinkling": 0.125, "squeeze": 1
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

        // Fix 1: Strip bullet/list prefixes so ^-anchored patterns see actual content
        let stripped = Self.stripBulletPrefix(trimmed)

        // Fix 7: Extract parenthetical prep notes before main parsing
        // "butter (softened)" → text="butter", prepNote="softened"
        let (textWithoutParenPrep, parenPrepNote) = Self.extractParentheticalPrep(stripped)

        // Pre-process: Insert space between leading digits and letters
        // Handles concatenated qty+unit like "16oz" → "16 oz", "2tbsp" → "2 tbsp"
        let spacedDigits = textWithoutParenPrep.replacingOccurrences(
            of: #"^(\d+(?:\.\d+)?)\s*([a-zA-Z])"#,
            with: "$1 $2",
            options: .regularExpression
        )

        // M8.5: Strip measurement modifiers before known units
        // "2 heaping tablespoons tomato paste" → "2 tablespoons tomato paste"
        let normalized = Self.stripMeasurementModifiers(spacedDigits)

        // Try patterns in priority order (highest specificity first)
        // Each returns non-nil if it matched

        if let result = tryUnicodeFractionPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryRangePattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryParentheticalPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryCompoundPhrasePattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryStandardPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryCountNounPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryPrefixQuantityPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryQualifierPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }
        if let result = tryDescriptiveAmountPattern(normalized, original: input) { return mergeParenPrep(result, parenPrepNote) }

        // Fallback: just ingredient name (with parenthetical prep if extracted)
        return ParserResult(
            name: normalized,
            quantity: nil, unit: nil, notes: parenPrepNote,
            confidence: 0.0, originalText: input, parserUsed: parserName
        )
    }

    // MARK: - Bullet Prefix Stripping (Fix 1)

    /// Strip leading bullet/list prefixes so ^-anchored patterns see actual content.
    /// Only strips punctuated numbered lists (1. / 2) / 3:), NOT bare "2 cups flour".
    private static func stripBulletPrefix(_ text: String) -> String {
        // Bullet/dash/star prefixes: "- text", "• text", "* text"
        if let range = text.range(of: #"^\s*[-•*]\s+"#, options: .regularExpression) {
            let stripped = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty { return stripped }
        }
        // Numbered list prefixes: "1. text", "2) text", "3: text" — requires punctuation after digit
        if let range = text.range(of: #"^\s*\d+[.\):]\s+"#, options: .regularExpression) {
            let stripped = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty { return stripped }
        }
        return text
    }

    // MARK: - Parenthetical Prep Extraction (Fix 7)

    /// Extract parenthetical prep notes like "(softened)", "(diced)", "(at room temperature)"
    /// Returns the cleaned text and the extracted prep note (if any)
    private static func extractParentheticalPrep(_ text: String) -> (String, String?) {
        // Match trailing parenthetical: "butter (softened)" or "chicken thighs (cubed)"
        guard let regex = try? NSRegularExpression(pattern: #"\s*\(([^)]+)\)\s*$"#),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let contentRange = Range(match.range(at: 1), in: text),
              let fullRange = Range(match.range(at: 0), in: text) else {
            return (text, nil)
        }

        let prepContent = String(text[contentRange]).trimmingCharacters(in: .whitespaces)

        // Only treat as prep if it looks like a prep method, not a size/weight note like "(14.5 oz)"
        // M9.35 P3A: Expanded from 31 to 55+ prep keywords
        let prepKeywords: Set<String> = [
            // Single-word prep methods
            "softened", "melted", "diced", "cubed", "chopped", "sliced", "crushed",
            "grated", "shredded", "minced", "julienned", "peeled", "seeded", "trimmed",
            "halved", "quartered", "torn", "thawed", "drained", "rinsed", "crumbled",
            "mashed", "sifted", "whisked", "beaten", "warmed", "chilled",
            // State/condition
            "room temperature", "at room temperature", "at room temp",
            "optional", "packed", "divided", "separated",
            "fresh", "dried", "frozen", "toasted", "roasted", "ground", "smashed",
            // Multi-word prep
            "cut into chunks", "cut into pieces", "cut into cubes", "cut into strips",
            "cut into wedges", "cut into bite-size pieces",
            "thinly sliced", "finely chopped", "finely diced", "finely minced",
            "roughly chopped", "coarsely chopped",
            "peeled and deveined", "cored and sliced", "seeded and diced",
            "stemmed and seeded", "halved and seeded",
            // Serving/garnish context
            "for garnish", "for serving", "for dusting", "for dipping", "for topping",
            "for drizzling",
            // Quantity modifiers
            "plus more to taste", "plus more for serving", "plus more for garnish",
            "plus more as needed", "or more to taste", "or to taste", "to taste",
            "if needed", "if desired", "as needed"
        ]

        let lowerPrep = prepContent.lowercased()
        let isPrep = prepKeywords.contains(lowerPrep) ||
                     prepKeywords.contains(where: { lowerPrep.hasPrefix($0) })

        if isPrep {
            let cleaned = String(text[text.startIndex..<fullRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            return (cleaned, prepContent)
        }

        return (text, nil)
    }

    /// Merge parenthetical prep note into a parser result's notes field
    private func mergeParenPrep(_ result: ParserResult, _ parenPrep: String?) -> ParserResult {
        guard let prep = parenPrep else { return result }
        let mergedNotes: String
        if let existing = result.notes, !existing.isEmpty {
            mergedNotes = "\(existing), \(prep)"
        } else {
            mergedNotes = prep
        }
        return ParserResult(
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
            notes: mergedNotes,
            confidence: result.confidence,
            originalText: result.originalText,
            parserUsed: result.parserUsed
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

            let confidence: Float = (standardUnit != nil) ? 0.95 : 0.92

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
                confidence: 0.92,
                originalText: original,
                parserUsed: parserName
            )
        }

        // "3 to 4 cups flour" or "2 or 3 cups flour" style ranges
        let wordRangePattern = #"^(\d+(?:\.\d+)?)\s+(?:to|or)\s+(\d+(?:\.\d+)?)\s+([a-zA-Z]+)\s+(.+)$"#
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
                confidence: (standardUnit != nil) ? 0.95 : 0.92,
                originalText: original,
                parserUsed: parserName
            )
        }

        // M9.35 P4A: "6 to 8 carrots" or "2 or 3 sprigs rosemary" — word range without unit
        let wordRangeNoUnitPattern = #"^(\d+(?:\.\d+)?)\s+(?:to|or)\s+(\d+(?:\.\d+)?)\s+(.+)$"#
        if let match = matchPattern(wordRangeNoUnitPattern, in: text) {
            let highValue = match[2]
            let name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let numericValue = Double(highValue)

            return ParserResult(
                name: name,
                quantity: numericValue,
                unit: nil,
                notes: "range: \(match[1])-\(match[2])",
                confidence: 0.90,
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
                    confidence: (standardUnit != nil) ? 0.95 : 0.92,
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
                    confidence: (standardUnit != nil) ? 0.95 : 0.92,
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
            confidence = 0.92
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
        // "2 cups flour", "1 1/2 tbsp olive oil", "2-1/2 cups chicken stock"
        let pattern = #"^([0-9]+(?:\.\d+)?(?:[-\s]+[0-9]+/[0-9]+|[/.][0-9]+)?)\s+([a-zA-Z]+)?\s*(.+)$"#
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

    // MARK: - Pattern 5b: Count Nouns (Fix 3)
    // Handles: "2 eggs", "3 bay leaves", "5 cloves garlic", "1 cinnamon stick"
    // Items where the number is a count, not a measurement

    private func tryCountNounPattern(_ text: String, original: String) -> ParserResult? {
        // Pattern: digit(s) + optional adjective + count noun (with optional trailing name)
        let countPattern = #"^(\d+)\s+(.+)$"#
        guard let match = matchPattern(countPattern, in: text) else { return nil }

        let quantity = match[1]
        let rest = match[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let words = rest.lowercased().split(separator: " ").map(String.init)

        guard !words.isEmpty else { return nil }

        // Check if any word in the rest is a count noun
        for (i, word) in words.enumerated() {
            let singular = Self.countNounSingulars[word] ?? word
            if Self.countNouns.contains(singular) || Self.countNouns.contains(word) {
                // If count noun is a unit-like word (e.g., "cloves"), treat as unit + name
                // "5 cloves garlic" → qty=5, name="garlic"
                if i < words.count - 1 {
                    let name = words[(i+1)...].joined(separator: " ")
                    return ParserResult(
                        name: name,
                        quantity: Double(quantity),
                        unit: nil,
                        notes: nil,
                        confidence: 0.95,
                        originalText: original,
                        parserUsed: parserName
                    )
                }
                // Count noun IS the name: "2 eggs" → qty=2, name="eggs"
                return ParserResult(
                    name: rest,
                    quantity: Double(quantity),
                    unit: nil,
                    notes: nil,
                    confidence: 0.95,
                    originalText: original,
                    parserUsed: parserName
                )
            }
        }

        return nil
    }

    /// Count nouns (singular forms) — items counted without units
    private static let countNouns: Set<String> = [
        "egg", "leaf", "bay leaf", "clove", "sprig", "stalk", "strip",
        "sheet", "fillet", "breast", "thigh", "drumstick", "rasher",
        "tortilla", "pita", "naan", "roll", "bun", "patty",
        "chilli", "chili", "pepper", "tomato", "onion", "potato",
        "carrot", "zucchini", "avocado", "banana", "apple", "lemon", "lime", "orange",
        "shallot", "scallion", "anchovy"
    ]

    /// Plural → singular map for count noun matching
    private static let countNounSingulars: [String: String] = [
        "eggs": "egg", "leaves": "leaf", "bay leaves": "bay leaf",
        "cloves": "clove", "sprigs": "sprig", "stalks": "stalk", "strips": "strip",
        "sheets": "sheet", "fillets": "fillet", "breasts": "breast",
        "thighs": "thigh", "drumsticks": "drumstick", "rashers": "rasher",
        "tortillas": "tortilla", "pitas": "pita", "naans": "naan",
        "rolls": "roll", "buns": "bun", "patties": "patty",
        "chillies": "chilli", "chilies": "chili", "peppers": "pepper",
        "tomatoes": "tomato", "onions": "onion", "potatoes": "potato",
        "carrots": "carrot", "zucchinis": "zucchini", "avocados": "avocado",
        "bananas": "banana", "apples": "apple", "lemons": "lemon",
        "limes": "lime", "oranges": "orange",
        "shallots": "shallot", "scallions": "scallion", "anchovies": "anchovy"
    ]

    // MARK: - Pattern 5c: Prefix-Before-Quantity (Fix 9)
    // Handles: "Juice of 1/2 lemon", "Zest of 1 lemon", "Juice of 2 lemons"

    private func tryPrefixQuantityPattern(_ text: String, original: String) -> ParserResult? {
        let lowered = text.lowercased()

        // "Juice of 1/2 lemon", "Zest of 1 lemon", "Juice of 2 lemons"
        let prefixPattern = #"^(juice|zest)\s+of\s+(\d+(?:\s*/\s*\d+)?)\s+(.+)$"#
        guard let match = matchPattern(prefixPattern, in: lowered) else { return nil }

        let descriptor = match[1]
        let quantityStr = match[2]
        let name = match[3].trimmingCharacters(in: .whitespacesAndNewlines)

        let numericValue = convertToNumeric(quantityStr)

        return ParserResult(
            name: name,
            quantity: numericValue,
            unit: nil,
            notes: "\(descriptor) of",
            confidence: 0.95,
            originalText: original,
            parserUsed: parserName
        )
    }

    // MARK: - Pattern 6: Qualifiers
    // Handles: "salt to taste", "pepper as needed", "garlic, minced"

    private func tryQualifierPattern(_ text: String, original: String) -> ParserResult? {
        // "salt to taste", "pepper as needed", "oil as desired"
        let qualifierPattern = #"^([a-zA-Z\s]+?)\s*,?\s*(to taste|as needed|as desired|for garnish|for garnishing|for serving|for dusting|for glazing|to serve|to garnish|optional)$"#
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

        // M9.35 P3B: Procedural comma-qualifier detection (replaces single-word regex)
        // Handles multi-word preps: "finely minced", "peeled and deveined", "cut into pieces"
        if let commaIndex = text.firstIndex(of: ",") {
            let name = String(text[text.startIndex..<commaIndex]).trimmingCharacters(in: .whitespaces)
            let qualifier = String(text[text.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
            let lowerQualifier = qualifier.lowercased()

            let isPrep = Self.commaQualifierPrepWords.contains(where: { lowerQualifier.hasPrefix($0) }) ||
                         Self.commaQualifierExactPhrases.contains(lowerQualifier)

            if isPrep && !name.isEmpty {
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
        }

        return nil
    }

    // MARK: - Pattern 7: Descriptive Amounts
    // Handles: "a pinch of salt", "a handful of herbs", "a splash of vinegar"

    private func tryDescriptiveAmountPattern(_ text: String, original: String) -> ParserResult? {
        let lowered = text.lowercased()

        // "a pinch of salt", "a dash of cayenne", "a handful of herbs"
        let descriptivePattern = #"^a\s+(pinch|dash|smidgen|handful|splash|drizzle|sprig|stalk|leaf|bunch|sprinkling|squeeze)\s+(?:of\s+)?(.+)$"#
        if let match = matchPattern(descriptivePattern, in: lowered) {
            let descriptor = match[1]
            let name = match[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let approxQty = Self.descriptiveAmountMap[descriptor]

            return ParserResult(
                name: name,
                quantity: approxQty,
                unit: nil,
                notes: "a \(descriptor)",
                confidence: 0.95,
                originalText: original,
                parserUsed: parserName
            )
        }

        // Just the descriptor without "a": "pinch of salt"
        let bareDescriptivePattern = #"^(pinch|dash|smidgen|handful|splash|drizzle|bunch|sprinkling|squeeze)\s+(?:of\s+)?(.+)$"#
        if let match = matchPattern(bareDescriptivePattern, in: lowered) {
            let descriptor = match[1]
            let name = match[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let approxQty = Self.descriptiveAmountMap[descriptor]

            return ParserResult(
                name: name,
                quantity: approxQty,
                unit: nil,
                notes: descriptor,
                confidence: 0.95,
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

    // MARK: - Helper: Strip Measurement Modifiers

    /// M8.5: Remove modifier words that appear between a quantity and a known unit
    /// "2 heaping tablespoons tomato paste" → "2 tablespoons tomato paste"
    /// Only strips when the word after the modifier IS a known unit (safety check)
    static func stripMeasurementModifiers(_ text: String) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard words.count >= 3 else { return text }

        // Check if first word looks like a quantity (starts with digit or fraction)
        guard let first = words.first,
              first.first?.isNumber == true || first.first?.isWholeNumber == true else {
            return text
        }

        // Check if second word is a modifier and third word is a known unit
        let potentialModifier = words[1].lowercased()
        guard measurementModifiers.contains(potentialModifier) else { return text }

        let potentialUnit = words[2].lowercased()
        guard knownUnitSet.contains(potentialUnit) else { return text }

        // Strip the modifier: keep word[0], skip word[1], keep word[2...]
        var result = [words[0]]
        result.append(contentsOf: words[2...])
        return result.joined(separator: " ")
    }

    // MARK: - Helper: Known Unit Check

    /// All recognized units as a static set (used by both isKnownUnit and stripMeasurementModifiers)
    private static let knownUnitSet: Set<String> = {
        let volume: Set<String> = ["cup", "cups", "c", "tablespoon", "tablespoons", "tbsp", "tbs", "t",
                      "teaspoon", "teaspoons", "tsp", "ts", "ml", "milliliter", "milliliters",
                      "l", "liter", "liters", "oz", "fl oz", "fluid ounce", "fluid ounces",
                      "pint", "pints", "pt", "quart", "quarts", "qt", "gallon", "gallons", "gal"]
        let weight: Set<String> = ["lb", "lbs", "pound", "pounds", "oz", "ounce", "ounces",
                      "g", "gram", "grams", "kg", "kilogram", "kilograms"]
        let count: Set<String> = ["piece", "pieces", "pc", "clove", "cloves", "slice", "slices",
                     "can", "cans", "package", "packages", "pkg", "bunch", "bunches",
                     "head", "heads", "stick", "sticks", "bag", "bags", "bottle", "bottles",
                     "box", "boxes", "jar", "jars", "sprig", "sprigs"]
        return volume.union(weight).union(count)
    }()

    func isKnownUnit(_ unit: String) -> Bool {
        Self.knownUnitSet.contains(unit.lowercased())
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

        // Handle mixed fractions: "1 1/2", "2 3/4", "2-1/2" (Fix 6: hyphen separator)
        let mixedPattern = #"^(\d+)[-\s]+(\d+)/(\d+)$"#
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
