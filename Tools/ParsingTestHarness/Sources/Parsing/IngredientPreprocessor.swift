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

        // Step 5b: Strip parenthetical can/package sizes ("(28 ounce) can" → "can")
        result = stripCanPackageSizes(result)

        // Step 5d: Strip leading "about" / "optional" qualifiers before quantities
        result = stripLeadingQualifiers(result)

        // Step 5g: Strip leading dual-unit metric prefix
        // "500g / 1lb peeled prawns" → "1lb peeled prawns"
        result = stripLeadingDualUnitMetric(result)

        // Step 5e: Normalize "X and Y/Z" fractions to "X Y/Z"
        // "2 and 1/4 cups flour" → "2 1/4 cups flour"
        result = normalizeAndFractions(result)

        // Step 5f: Convert leading number words to digits
        // "One 3-pound chuck roast" → "1 3-pound chuck roast"
        // "Six fillets salmon" → "6 fillets salmon"
        result = convertLeadingNumberWords(result)

        // Step 5c: Convert IEEE 754 float quantities to slash fractions
        // AllRecipes stores ⅓ as 0.33333334326744 in JSON-LD
        result = convertIEEE754FloatQuantities(result)

        // Step 6: Unicode fractions → slash fractions (⅔ → 2/3)
        result = convertUnicodeFractions(result)

        // Step 7: Decode HTML fraction entities (&frac12; → 1/2)
        result = decodeHTMLFractions(result)

        // Step 8: Strip trailing periods on units ("1 tsp." → "1 tsp")
        result = stripTrailingUnitPeriods(result)

        // Step 9: Fix space-before-punctuation ("avocado , sliced" → "avocado, sliced")
        result = fixSpaceBeforePunctuation(result)

        // Step 10: Normalize curly quotes/apostrophes to straight ASCII
        result = normalizeCurlyQuotes(result)

        // Step 11: Normalize whitespace (Unicode spaces, multiple spaces, trim)
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

    /// Step 5: Strip parenthetical metric/imperial measurements from dual-unit recipes
    /// "6 tablespoons (90g) butter" → "6 tablespoons butter"
    /// "3 pounds (1.4kg) onions" → "3 pounds onions"
    /// "2 cups chicken broth (16 oz)" → "2 cups chicken broth"
    private static func stripParentheticalMetric(_ text: String) -> String {
        var result = text.replacingOccurrences(
            of: #"\s*\(\s*\d+\.?\d*\s*(?:g|kg|ml|l|cl|dl)\s*\)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // Also strip parenthetical imperial when primary unit is already present
        // "(16 oz)", "(6 ounces)", "(281g)" — only when they appear mid-string or at end
        result = result.replacingOccurrences(
            of: #"\s*\(\s*\d+\.?\d*\s*(?:oz|ounce|ounces|lb|lbs|pound|pounds)\s*\)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return result
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

    /// Step 5b: Strip parenthetical can/package sizes
    /// "1 (28 ounce) can crushed tomatoes" → "1 can crushed tomatoes"
    /// "2 (8 oz) boxes cream cheese" → "2 boxes cream cheese"
    /// "1 (15-ounce) can chickpeas" → "1 can chickpeas" (hyphenated form)
    private static func stripCanPackageSizes(_ text: String) -> String {
        // Match "(28 ounce)", "(8 oz)", "(15-ounce)", "(14.5-ounce)" before container words
        var result = text.replacingOccurrences(
            of: #"\((\d+\.?\d*)\s*[-‐]?\s*(?:ounce|ounces|oz)\)\s*(can|cans|box|boxes|package|packages|jar|jars|bottle|bottles|bag|bags|carton|cartons|container|containers)"#,
            with: "$2",
            options: [.regularExpression, .caseInsensitive]
        )
        // Match "large can (28 ounces)" or "large jar (about 32 ounces)" — size AFTER container word
        result = result.replacingOccurrences(
            of: #"(can|cans|jar|jars|box|boxes|bottle|bottles|container|containers)\s+\((?:about\s+)?(\d+\.?\d*)\s*(?:ounce|ounces|oz)\)"#,
            with: "$1",
            options: [.regularExpression, .caseInsensitive]
        )
        return result
    }

    /// Step 5f: Convert leading number words (One, Two, Six, etc.) to digits
    /// "One 3-pound chuck roast" → "1 3-pound chuck roast"
    /// Only converts the FIRST word to avoid corrupting ingredient names
    private static func convertLeadingNumberWords(_ text: String) -> String {
        let numberWords: [String: String] = [
            "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
            "six": "6", "seven": "7", "eight": "8", "nine": "9", "ten": "10",
            "eleven": "11", "twelve": "12"
        ]
        let words = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard words.count == 2,
              let digit = numberWords[words[0].lowercased()] else {
            return text
        }
        return "\(digit) \(words[1])"
    }

    /// Step 5g: Strip leading dual-unit metric prefix before an imperial measurement
    /// "500g / 1lb peeled prawns" → "1lb peeled prawns"
    /// "500 g / 1 lb peeled prawns" → "1 lb peeled prawns"
    /// Only strips when the first measurement is metric (g/kg/ml/l) followed by "/" or "/"
    /// and the second measurement is imperial (lb/lbs/oz/ounce/pound/cup/etc.)
    private static func stripLeadingDualUnitMetric(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"^\d+\.?\d*\s*(?:g|kg|ml|l)\s*/\s*"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    /// Step 5e: Normalize "X and Y/Z" fractions to standard mixed fraction "X Y/Z"
    /// "2 and 1/4 cups flour" → "2 1/4 cups flour"
    private static func normalizeAndFractions(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"(\d+)\s+and\s+(\d+/\d+)"#,
            with: "$1 $2",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    /// Step 5d: Strip leading qualifier words that block quantity parsing
    /// "about 1/2 cup vegetable oil" → "1/2 cup vegetable oil"
    /// "optional 1/2 cup cheddar" → "1/2 cup cheddar"
    private static func stripLeadingQualifiers(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"^(?:about|approximately|optional|optionally|roughly)\s+"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    /// Step 5c: Convert IEEE 754 float quantities to slash fractions
    /// AllRecipes stores ⅓ as 0.33333334326744 in JSON-LD — detect by 8+ decimal digits
    private static func convertIEEE754FloatQuantities(_ text: String) -> String {
        // Match numbers with 8+ digits after decimal point (IEEE 754 artifacts)
        guard let regex = try? NSRegularExpression(
            pattern: #"(\d+)\.(\d{8,})"#
        ) else { return text }

        let nsText = text as NSString
        var result = text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        // Process matches in reverse to preserve string indices
        for match in matches.reversed() {
            guard let wholeRange = Range(match.range(at: 1), in: result),
                  let fullRange = Range(match.range(at: 0), in: result) else { continue }

            let wholePart = Int(result[wholeRange]) ?? 0
            let fullValue = Double(result[fullRange]) ?? 0

            let fractionalPart = fullValue - Double(wholePart)
            let fraction = closestFraction(fractionalPart)

            let replacement: String
            if wholePart == 0 {
                replacement = fraction
            } else if fraction == "0" {
                replacement = "\(wholePart)"
            } else {
                replacement = "\(wholePart) \(fraction)"
            }

            result = result.replacingCharacters(in: fullRange, with: replacement)
        }

        return result
    }

    /// Find the closest common fraction for a decimal value
    private static func closestFraction(_ value: Double) -> String {
        let fractions: [(Double, String)] = [
            (0.0, "0"),
            (1.0/8.0, "1/8"), (1.0/6.0, "1/6"), (1.0/4.0, "1/4"),
            (1.0/3.0, "1/3"), (3.0/8.0, "3/8"), (1.0/2.0, "1/2"),
            (5.0/8.0, "5/8"), (2.0/3.0, "2/3"), (3.0/4.0, "3/4"),
            (5.0/6.0, "5/6"), (7.0/8.0, "7/8"), (1.0, "1")
        ]

        var bestMatch = "0"
        var bestDelta = Double.greatestFiniteMagnitude

        for (fracValue, fracString) in fractions {
            let delta = abs(value - fracValue)
            if delta < bestDelta {
                bestDelta = delta
                bestMatch = fracString
            }
        }

        return bestMatch
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

    /// Step 10: Normalize curly/smart quotes and apostrophes to straight ASCII
    /// "confectioners\u{2019} sugar" → "confectioners' sugar"
    private static func normalizeCurlyQuotes(_ text: String) -> String {
        var result = text
        // Curly single quotes / apostrophes → straight apostrophe
        result = result.replacingOccurrences(of: "\u{2018}", with: "'") // left single quote
        result = result.replacingOccurrences(of: "\u{2019}", with: "'") // right single quote (apostrophe)
        result = result.replacingOccurrences(of: "\u{201A}", with: "'") // single low-9 quote
        // Curly double quotes → straight double quote
        result = result.replacingOccurrences(of: "\u{201C}", with: "\"") // left double quote
        result = result.replacingOccurrences(of: "\u{201D}", with: "\"") // right double quote
        result = result.replacingOccurrences(of: "\u{201E}", with: "\"") // double low-9 quote
        return result
    }

    /// Step 11: Normalize all whitespace variants to single ASCII spaces
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
    /// M9.35.2: Expanded with connecting words so multi-word phrases like
    /// "cut into wedges" are detected (previously "into" and "wedges" failed allSatisfy)
    private static let orphanPrepWords: Set<String> = [
        // Prep verbs/adjectives
        "diced", "chopped", "sliced", "minced", "crushed", "grated",
        "shredded", "halved", "quartered", "torn", "crumbled",
        "roughly", "finely", "thinly", "coarsely", "lightly",
        "freshly", "seeds", "removed", "divided", "separated",
        "stemmed", "seeded", "cored", "trimmed", "peeled",
        "pitted", "deveined", "deboned", "rinsed", "drained",
        "thawed", "softened", "melted", "warmed", "chilled",
        // Connecting words (allow multi-word phrases to match)
        "into", "of", "the", "and", "for", "with", "until", "to",
        "cut", "or", "about", "as", "at",
        // Common shape/size nouns in prep phrases
        "wedges", "pieces", "chunks", "strips", "rounds", "slices",
        "cubes", "rings", "halves", "quarters", "dice", "bits"
    ]
}
