//
//  NLPIngredientParser.swift
//  forager
//
//  Created for M8.3: Hybrid NLP Parser
//  Fallback parser using Apple's NaturalLanguage framework
//  Used when regex confidence is below threshold
//

import Foundation
import NaturalLanguage

// MARK: - NLPIngredientParser

/// Fallback ingredient parser using Apple NaturalLanguage for part-of-speech tagging
/// Confidence capped at 0.75 since NLP is less precise than regex for structured formats
class NLPIngredientParser: IngredientParser {

    let parserName = "nlp"

    /// Maximum confidence for NLP results (lower ceiling than regex)
    private static let maxConfidence: Float = 0.75

    /// Known unit words for NLP token classification
    private static let unitWords: Set<String> = [
        "cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp",
        "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs",
        "gram", "grams", "g", "kilogram", "kilograms", "kg",
        "liter", "liters", "l", "milliliter", "milliliters", "ml",
        "pint", "pints", "quart", "quarts", "gallon", "gallons",
        "can", "cans", "package", "packages", "pkg",
        "piece", "pieces", "clove", "cloves", "slice", "slices",
        "bunch", "bunches", "head", "heads", "stick", "sticks",
        "bag", "bags", "bottle", "bottles", "box", "boxes",
        "jar", "jars", "sprig", "sprigs"
    ]

    /// Words that indicate preparation/qualifier (not ingredient name)
    private static let qualifierWords: Set<String> = [
        "minced", "diced", "chopped", "sliced", "crushed", "grated",
        "shredded", "julienned", "peeled", "seeded", "trimmed",
        "halved", "quartered", "torn", "fresh", "dried", "frozen",
        "thawed", "softened", "melted", "packed", "optional",
        "large", "medium", "small", "thin", "thick"
    ]

    /// Qualifier phrases to strip from name and move to notes
    private static let qualifierPhrases: Set<String> = [
        "to taste", "as needed", "as desired", "for garnish", "for serving",
        "or more", "or less", "approximately", "about", "roughly"
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

        // Tokenize with NLTagger
        let tokens = tokenize(trimmed)

        // Extract components from tokens
        let quantity = extractQuantity(from: tokens)
        let unit = extractUnit(from: tokens)
        let (name, notes) = extractNameAndNotes(from: tokens, text: trimmed)

        // Calculate confidence
        let confidence = calculateConfidence(
            quantity: quantity, unit: unit, name: name, notes: notes
        )

        return ParserResult(
            name: name.isEmpty ? trimmed : name,
            quantity: quantity,
            unit: standardizeUnit(unit),
            notes: notes,
            confidence: confidence,
            originalText: input,
            parserUsed: parserName
        )
    }

    // MARK: - Tokenization

    /// Token with its lexical class tag
    private struct TaggedToken {
        let text: String
        let tag: NLTag?
        let range: Range<String.Index>

        var isNumber: Bool {
            tag == .number || Double(text) != nil
        }

        var isNoun: Bool {
            tag == .noun
        }

        var isAdjective: Bool {
            tag == .adjective
        }

        var isUnitWord: Bool {
            NLPIngredientParser.unitWords.contains(text.lowercased())
        }

        var isQualifier: Bool {
            NLPIngredientParser.qualifierWords.contains(text.lowercased())
        }
    }

    private func tokenize(_ text: String) -> [TaggedToken] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var tokens: [TaggedToken] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass) { tag, range in
            let word = String(text[range])
            tokens.append(TaggedToken(text: word, tag: tag, range: range))
            return true
        }

        return tokens
    }

    // MARK: - Component Extraction

    /// Extract numeric quantity from tokens
    private func extractQuantity(from tokens: [TaggedToken]) -> Double? {
        // Look for the first numeric token
        for (index, token) in tokens.enumerated() {
            if token.isNumber {
                if let value = Double(token.text) {
                    // Check for mixed fraction: "1 1/2" pattern
                    if index + 2 < tokens.count {
                        let next = tokens[index + 1]
                        // Check if next tokens form a fraction
                        if next.text == "/" && index + 2 < tokens.count {
                            if let denom = Double(tokens[index + 2].text), denom != 0 {
                                return value / denom
                            }
                        }
                    }
                    return value
                }
            }

            // Check for fraction tokens: "1/2"
            if token.text.contains("/") {
                let parts = token.text.split(separator: "/")
                if parts.count == 2,
                   let num = Double(parts[0]),
                   let denom = Double(parts[1]),
                   denom != 0 {
                    return num / denom
                }
            }
        }

        return nil
    }

    /// Extract unit from tokens (must be adjacent to or near a number)
    private func extractUnit(from tokens: [TaggedToken]) -> String? {
        // Find the first number token index
        guard let numIndex = tokens.firstIndex(where: { $0.isNumber || $0.text.contains("/") }) else {
            return nil
        }

        // Look at the token right after the number for a unit
        let unitIndex = numIndex + 1
        if unitIndex < tokens.count && tokens[unitIndex].isUnitWord {
            return tokens[unitIndex].text
        }

        // Also check one more token ahead (for "1 1/2 cups" where fraction is between)
        let nextUnitIndex = numIndex + 2
        if nextUnitIndex < tokens.count && tokens[nextUnitIndex].isUnitWord {
            return tokens[nextUnitIndex].text
        }

        return nil
    }

    /// Extract ingredient name and notes from remaining tokens
    private func extractNameAndNotes(from tokens: [TaggedToken], text: String) -> (name: String, notes: String?) {
        // Find where the "name" portion starts (after qty and unit)
        var nameStartIndex = 0

        // Skip past number tokens
        for (index, token) in tokens.enumerated() {
            if token.isNumber || token.text.contains("/") || token.isUnitWord {
                nameStartIndex = index + 1
            } else {
                break
            }
        }

        // Collect name tokens (nouns + adjectives before nouns)
        var nameTokens: [String] = []
        var noteTokens: [String] = []

        for index in nameStartIndex..<tokens.count {
            let token = tokens[index]

            if token.isQualifier {
                noteTokens.append(token.text)
            } else if token.isNoun || token.isAdjective || token.tag == .otherWord {
                nameTokens.append(token.text)
            } else if token.tag == .conjunction || token.tag == .preposition {
                // "of", "and" — include in name if between nouns
                nameTokens.append(token.text)
            } else {
                nameTokens.append(token.text)
            }
        }

        // Check for qualifier phrases in the full text
        let lowered = text.lowercased()
        var detectedNotes: String? = nil
        for phrase in Self.qualifierPhrases {
            if lowered.hasSuffix(phrase) {
                detectedNotes = phrase
                // Remove the phrase from name tokens
                let phraseWords = phrase.split(separator: " ").map(String.init)
                if nameTokens.count >= phraseWords.count {
                    let suffix = nameTokens.suffix(phraseWords.count).map { $0.lowercased() }
                    if suffix == phraseWords {
                        nameTokens.removeLast(phraseWords.count)
                    }
                }
                break
            }
        }

        // Normalize multi-space artifacts from NLP tokenization
        let rawName = nameTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = rawName.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        let notes = detectedNotes ?? (noteTokens.isEmpty ? nil : noteTokens.joined(separator: ", "))

        return (name, notes)
    }

    // MARK: - Confidence Calculation

    private func calculateConfidence(quantity: Double?, unit: String?, name: String, notes: String?) -> Float {
        var confidence: Float = 0.0

        if quantity != nil && unit != nil && !name.isEmpty {
            confidence = 0.75  // Full parse via NLP
        } else if quantity != nil && !name.isEmpty {
            confidence = 0.60  // Qty + name, no unit
        } else if !name.isEmpty && notes != nil {
            confidence = 0.50  // Name + notes (qualifier)
        } else if !name.isEmpty {
            confidence = 0.30  // Name only
        }

        // Cap at NLP maximum
        return min(confidence, Self.maxConfidence)
    }

    // MARK: - Unit Standardization

    /// Reuse the same standardization logic as RegexIngredientParser
    private func standardizeUnit(_ unit: String?) -> String? {
        guard let unit = unit?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
              !unit.isEmpty else {
            return nil
        }

        let unitMap: [String: String] = [
            "cup": "cup", "cups": "cup",
            "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp",
            "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp",
            "ounce": "oz", "ounces": "oz", "oz": "oz",
            "pound": "lb", "pounds": "lb", "lb": "lb", "lbs": "lb",
            "gram": "g", "grams": "g", "g": "g",
            "kilogram": "kg", "kilograms": "kg", "kg": "kg",
            "liter": "l", "liters": "l", "l": "l",
            "milliliter": "ml", "milliliters": "ml", "ml": "ml",
            "pint": "pint", "pints": "pint",
            "quart": "quart", "quarts": "quart",
            "gallon": "gallon", "gallons": "gallon",
            "can": "can", "cans": "can",
            "package": "package", "packages": "package", "pkg": "package",
            "clove": "clove", "cloves": "clove",
            "slice": "slice", "slices": "slice",
            "piece": "piece", "pieces": "piece",
            "bunch": "bunch", "bunches": "bunch",
            "head": "head", "heads": "head",
            "stick": "stick", "sticks": "stick",
            "sprig": "sprig", "sprigs": "sprig"
        ]

        return unitMap[unit] ?? unit
    }
}
