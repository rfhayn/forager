//
//  IngredientPreprocessor.swift
//  forager
//
//  M9.35 Phase 1: Centralized ingredient text sanitization.
//  Called from HybridIngredientParser.parse() before any parser tier.
//  Strips site-specific junk, normalizes whitespace and fractions,
//  fixes punctuation artifacts from web scraping.
//

import Foundation

enum IngredientPreprocessor {

    // MARK: - Public API

    /// Sanitize ingredient text before parsing. Pure function, no side effects.
    static func sanitize(_ text: String) -> String {
        var result = text

        // Step 1: Strip price annotations (Budget Bytes "$0.50", "($2.00)")
        result = stripPriceAnnotations(result)

        // Step 2: Strip double-paren note references (RecipeTinEats "((Note 1))")
        result = stripDoubleParenNotes(result)

        // Step 3: Strip single-paren note/footnote references
        result = stripFootnoteReferences(result)

        // Step 4: Fix leading comma in parens (RecipeTinEats "(, minced)" → "(minced)")
        result = fixLeadingCommaInParens(result)

        // Step 5: Strip parenthetical metric measurements (SeriousEats/SallysBaking "(90g)", "(450g)")
        result = stripParentheticalMetric(result)

        // Step 6: Unicode fractions → slash fractions (⅔ → 2/3)
        result = convertUnicodeFractions(result)

        // Step 7: Decode HTML fraction entities (&frac12; → 1/2)
        result = decodeHTMLFractions(result)

        // Step 8: Strip trailing periods on units ("1 tsp." → "1 tsp")
        result = stripTrailingUnitPeriods(result)

        // Step 9: Fix space-before-punctuation ("avocado , sliced" → "avocado, sliced")
        result = fixSpaceBeforePunctuation(result)

        // Step 10: Normalize whitespace (Unicode spaces, multiple spaces, trim)
        result = normalizeWhitespace(result)

        return result
    }

    /// Detect if a line is an orphan fragment (only prep text, no ingredient name).
    /// Used by SchemaRecipeMapper to filter extraction noise.
    static func isOrphanFragment(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        // Very short text that's all prep/modifier words
        let words = trimmed.lowercased()
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        guard words.count <= 5 else { return false }

        // If it starts with a number, it's probably a real ingredient
        if let first = words.first, first.first?.isNumber == true { return false }

        let allPrep = words.allSatisfy { word in
            orphanPrepWords.contains(word) ||
            word.hasSuffix("ed") ||
            word.hasSuffix("ly") ||
            word.hasSuffix("ing")
        }

        return allPrep
    }

    // MARK: - Pipeline Steps

    /// Step 1: Strip "$X.XX" price annotations (Budget Bytes embeds per-ingredient costs)
    private static func stripPriceAnnotations(_ text: String) -> String {
        // "($ X.XX)" with parens
        var result = text.replacingOccurrences(
            of: #"\s*\(\s*\$[\d.]+\s*\)"#,
            with: "",
            options: .regularExpression
        )
        // Standalone "$X.XX" at end
        result = result.replacingOccurrences(
            of: #"\s*\$[\d.]+\s*$"#,
            with: "",
            options: .regularExpression
        )
        return result
    }

    /// Step 2: Strip "(( ))" double-paren notes (RecipeTinEats "((Note 1))", "((optional))")
    private static func stripDoubleParenNotes(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"\s*\(\([^)]*\)\)"#,
            with: "",
            options: .regularExpression
        )
    }

    /// Step 3: Strip footnote/note references ("[1]", "(Note 1)", "(see note)", trailing asterisks)
    private static func stripFootnoteReferences(_ text: String) -> String {
        var result = text
        // [1], [2], etc.
        result = result.replacingOccurrences(
            of: #"\s*\[\d+\]"#,
            with: "",
            options: .regularExpression
        )
        // (Note 1), (Note 2), etc.
        result = result.replacingOccurrences(
            of: #"\s*\(Note\s*\d+\)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // (see note), (see notes)
        result = result.replacingOccurrences(
            of: #"\s*\(see\s+notes?\)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // Trailing asterisks
        result = result.replacingOccurrences(
            of: #"\*+\s*$"#,
            with: "",
            options: .regularExpression
        )
        return result
    }

    /// Step 4: Fix "(, minced)" → "(minced)" — RecipeTinEats leading comma in parens
    private static func fixLeadingCommaInParens(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"\(\s*,\s*"#,
            with: "(",
            options: .regularExpression
        )
    }

    /// Step 5: Strip parenthetical metric measurements from dual-unit recipes
    /// "6 tablespoons (90g) butter" → "6 tablespoons butter"
    /// "3 pounds (1.4kg) onions" → "3 pounds onions"
    private static func stripParentheticalMetric(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"\s*\(\s*\d+\.?\d*\s*(?:g|kg|ml|l|cl|dl)\s*\)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    /// Step 6: Convert Unicode fraction characters to slash fractions for consistent parsing
    private static func convertUnicodeFractions(_ text: String) -> String {
        var result = text
        for (unicode, slash) in unicodeFractionToSlash {
            if result.contains(unicode) {
                // Handle mixed numbers: "1½" → "1 1/2" (insert space between digit and fraction)
                result = result.replacingOccurrences(
                    of: "([0-9])\(unicode)",
                    with: "$1 \(slash)",
                    options: .regularExpression
                )
                // Standalone fraction
                result = result.replacingOccurrences(of: String(unicode), with: slash)
            }
        }
        return result
    }

    /// Step 7: Decode HTML fraction entities that weren't caught during extraction
    /// "&frac12;" → "1/2", "&frac14;" → "1/4", etc.
    private static func decodeHTMLFractions(_ text: String) -> String {
        var result = text
        for (entity, slash) in htmlFractionEntities {
            result = result.replacingOccurrences(of: entity, with: slash, options: .caseInsensitive)
        }
        return result
    }

    /// Step 8: Strip trailing periods on abbreviated units ("1 tsp." → "1 tsp")
    private static func stripTrailingUnitPeriods(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"\b(tsp|tbsp|oz|lb|lbs|pt|qt|gal|ml|cl|dl|kg|mg)\."#,
            with: "$1",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    /// Step 7: Fix space-before-punctuation artifacts from web scraping
    private static func fixSpaceBeforePunctuation(_ text: String) -> String {
        var result = text
        // "avocado , sliced" → "avocado, sliced"
        result = result.replacingOccurrences(
            of: #"\s+,"#,
            with: ",",
            options: .regularExpression
        )
        // "taco -sized" → "taco-sized" (only when preceded by a letter)
        result = result.replacingOccurrences(
            of: #"([a-zA-Z])\s+-"#,
            with: "$1-",
            options: .regularExpression
        )
        return result
    }

    /// Step 8: Normalize all whitespace variants to single ASCII spaces
    private static func normalizeWhitespace(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"[\s\x{00A0}\x{200B}\x{FEFF}]+"#,
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Data

    /// Unicode fraction → slash fraction mapping
    private static let unicodeFractionToSlash: [(Character, String)] = [
        ("½", "1/2"), ("⅓", "1/3"), ("⅔", "2/3"),
        ("¼", "1/4"), ("¾", "3/4"),
        ("⅕", "1/5"), ("⅖", "2/5"), ("⅗", "3/5"), ("⅘", "4/5"),
        ("⅙", "1/6"), ("⅚", "5/6"),
        ("⅛", "1/8"), ("⅜", "3/8"), ("⅝", "5/8"), ("⅞", "7/8")
    ]

    /// HTML fraction entity → slash fraction mapping
    private static let htmlFractionEntities: [(String, String)] = [
        ("&frac12;", "1/2"), ("&frac13;", "1/3"), ("&frac23;", "2/3"),
        ("&frac14;", "1/4"), ("&frac34;", "3/4"),
        ("&frac15;", "1/5"), ("&frac16;", "1/6"), ("&frac18;", "1/8"),
        ("&frac38;", "3/8"), ("&frac58;", "5/8"), ("&frac78;", "7/8"),
        ("&#xBD;", "1/2"), ("&#xBC;", "1/4"), ("&#xBE;", "3/4"),
        ("&#189;", "1/2"), ("&#188;", "1/4"), ("&#190;", "3/4")
    ]

    /// Words that indicate a line is an orphan prep fragment (no ingredient name)
    private static let orphanPrepWords: Set<String> = [
        "diced", "chopped", "sliced", "minced", "crushed", "grated",
        "shredded", "halved", "quartered", "torn", "crumbled",
        "roughly", "finely", "thinly", "coarsely", "lightly",
        "freshly", "seeds", "removed", "divided", "separated",
        "stemmed", "seeded", "cored", "trimmed", "peeled"
    ]
}
