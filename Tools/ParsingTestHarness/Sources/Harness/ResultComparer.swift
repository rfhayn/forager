import Foundation

// MARK: - Result Comparer

/// Compares local vs AI parsing results and identifies issues.
struct ResultComparer {

    enum Agreement: String, Codable {
        case fullMatch = "full_match"           // Exact match on name, qty, unit
        case coreMatch = "core_match"           // AI canonical name found within local name (descriptor difference)
        case localLikelyWrong = "local_likely_wrong"  // Real parsing issue in local
        case aiLikelyWrong = "ai_likely_wrong"
        case ambiguous
    }

    struct ComparisonResult: Codable {
        let raw: String
        let agreement: Agreement
        let issues: [String]
        let localName: String
        let aiName: String?
        let localQty: Double?
        let aiQty: Double?
        let localUnit: String?
        let aiUnit: String?
        let localNotes: String?
        let aiNotes: String?
    }

    struct IssuePattern: Codable {
        let pattern: String
        let count: Int
        let examples: [String]
    }

    // MARK: - Unit Normalization

    private static let unitAliases: [String: String] = [
        "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp", "tbs": "tbsp",
        "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp",
        "cup": "cup", "cups": "cup", "c": "cup",
        "ounce": "oz", "ounces": "oz", "oz": "oz",
        "pound": "lb", "pounds": "lb", "lb": "lb", "lbs": "lb",
        "gram": "g", "grams": "g", "g": "g",
        "kilogram": "kg", "kilograms": "kg", "kg": "kg",
        "liter": "l", "liters": "l", "l": "l",
        "milliliter": "ml", "milliliters": "ml", "ml": "ml",
        "pinch": "pinch", "dash": "dash", "clove": "clove", "cloves": "clove",
        "can": "can", "cans": "can", "package": "package", "packages": "package",
        "slice": "slice", "slices": "slice", "piece": "piece", "pieces": "piece",
        "bunch": "bunch", "head": "head", "stalk": "stalk", "stalks": "stalk",
        "sprig": "sprig", "sprigs": "sprig",
        "inch": "inch", "inches": "inch",
        "jar": "jar", "jars": "jar",
        "bottle": "bottle", "bottles": "bottle",
        "box": "box", "boxes": "box",
        "bag": "bag", "bags": "bag",
        "container": "container", "containers": "container",
        "loaf": "loaf", "loaves": "loaf",
        "stick": "stick", "sticks": "stick",
        "serving": "serving", "servings": "serving",
        "handful": "handful",
    ]

    static func normalizeUnit(_ unit: String?) -> String? {
        guard let unit = unit?.lowercased().trimmingCharacters(in: .whitespaces) else { return nil }
        return unitAliases[unit] ?? unit
    }

    // MARK: - Core Name Matching

    /// Checks if the AI canonical name is semantically contained in the local name.
    /// Accounts for descriptors (size, prep, state), pluralization, and comma-separated qualifiers.
    /// "small onion, diced" vs "onion" → true (descriptor difference)
    /// "chicken broth" vs "vegetable broth" → false (different ingredient)
    private static func coreNameMatch(local: String, ai: String) -> Bool {
        guard !ai.isEmpty, !local.isEmpty else { return false }

        // Direct containment: AI name found within local name
        if local.contains(ai) { return true }

        // Handle pluralization: "eggs" vs "egg", "tomatoes" vs "tomato"
        let aiSingular = depluralize(ai)
        let localSingular = depluralize(local)
        if local.contains(aiSingular) || localSingular.contains(ai) || localSingular.contains(aiSingular) {
            return true
        }

        // Strip comma-qualifier from local: "garlic, minced" → "garlic"
        let localBase = local.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? local

        // Strip known descriptors from local base and compare
        let localStripped = stripDescriptors(localBase)
        if localStripped == ai || localStripped == aiSingular {
            return true
        }
        if localStripped.contains(ai) || localStripped.contains(aiSingular) {
            return true
        }

        // Normalize slashes as "or" and parens-with-or: "stock/broth" ↔ "stock or broth"
        // "(or basil)" → "or basil", "heavy/thickened" → "heavy or thickened"
        let localNormalized = normalizeAlternatives(local)
        let aiNormalized = normalizeAlternatives(ai)
        if localNormalized == aiNormalized ||
           localNormalized.contains(aiNormalized) ||
           aiNormalized.contains(localNormalized) {
            return true
        }
        // Also try with depluralization
        let aiNormalizedSingular = depluralize(aiNormalized)
        let localNormalizedSingular = depluralize(localNormalized)
        if localNormalized.contains(aiNormalizedSingular) ||
           localNormalizedSingular.contains(aiNormalized) ||
           localNormalizedSingular.contains(aiNormalizedSingular) {
            return true
        }

        return false
    }

    /// Normalize alternative expressions: slash to "or", strip "(or ...)" parens
    private static func normalizeAlternatives(_ name: String) -> String {
        var result = name
        // "(or basil)" → "or basil", "(OR Mirin)" → "or mirin"
        result = result.replacingOccurrences(
            of: #"\((?:or\s+)([^)]+)\)"#,
            with: "or $1",
            options: [.regularExpression, .caseInsensitive]
        )
        // "stock/broth" → "stock or broth"
        result = result.replacingOccurrences(of: "/", with: " or ")
        // Collapse multiple spaces
        result = result.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        return result.lowercased().trimmingCharacters(in: .whitespaces)
    }

    /// Common descriptor words that local parser keeps but AI strips.
    private static let descriptorWords: Set<String> = [
        // Size
        "small", "medium", "large", "thin", "thick", "whole", "half",
        // State
        "fresh", "frozen", "cold", "hot", "warm", "chilled", "room-temperature",
        "dried", "dry", "raw", "cooked", "uncooked", "canned",
        // Quality
        "good-quality", "high-quality", "organic", "extra-virgin",
        // Cut/Form
        "boneless", "skinless", "bone-in", "skin-on",
        "diced", "minced", "chopped", "sliced", "grated", "shredded",
        "crushed", "ground", "sifted", "melted", "softened",
        "finely", "roughly", "thinly", "freshly",
    ]

    private static func stripDescriptors(_ name: String) -> String {
        let words = name.split(separator: " ").map(String.init)
        let stripped = words.filter { !descriptorWords.contains($0.lowercased()) }
        return stripped.joined(separator: " ")
    }

    private static func depluralize(_ text: String) -> String {
        // Apply word-level depluralization so multi-word phrases work:
        // "collard greens or kale" → "collard green or kale"
        let words = text.split(separator: " ").map(String.init)
        let depluralized = words.map { depluralizeWord($0) }
        return depluralized.joined(separator: " ")
    }

    private static func depluralizeWord(_ word: String) -> String {
        if word.hasSuffix("ies") && word.count > 4 {
            return String(word.dropLast(3)) + "y"  // berries → berry
        }
        if word.hasSuffix("ves") && word.count > 4 {
            return String(word.dropLast(3)) + "f"  // loaves → loaf, halves → half
        }
        if word.hasSuffix("oes") && word.count > 4 {
            return String(word.dropLast(2))  // tomatoes → tomato, potatoes → potato
        }
        if word.hasSuffix("es") && word.count > 3 {
            return String(word.dropLast(2))  // cloves → clov (imperfect but catches most)
        }
        if word.hasSuffix("s") && !word.hasSuffix("ss") && word.count > 2 {
            return String(word.dropLast())  // eggs → egg, cups → cup
        }
        return word
    }

    // MARK: - Comparison

    /// Compare a single ingredient's local vs AI results.
    static func compare(ingredient: ParsingEvaluator.IngredientResult) -> ComparisonResult {
        guard let ai = ingredient.ai else {
            // No AI result — can't compare, check for obvious local issues
            var issues: [String] = []
            issues.append(contentsOf: detectLocalIssues(ingredient))
            return ComparisonResult(
                raw: ingredient.raw,
                agreement: .ambiguous,
                issues: issues,
                localName: ingredient.hybrid.name,
                aiName: nil,
                localQty: ingredient.hybrid.quantity,
                aiQty: nil,
                localUnit: ingredient.hybrid.unit,
                aiUnit: nil,
                localNotes: ingredient.hybrid.notes,
                aiNotes: nil
            )
        }

        let local = ingredient.hybrid
        var issues: [String] = []

        // Compare names — two tiers
        let localNameNorm = local.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let aiNameNorm = ai.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let nameExactMatch = localNameNorm == aiNameNorm
        let nameCoreMatch = nameExactMatch || coreNameMatch(local: localNameNorm, ai: aiNameNorm)

        // Compare quantities — with tolerance for ranges and precision
        let qtyMatch: Bool
        if let lq = local.quantity, let aq = ai.quantity {
            // Allow tolerance for range strategy (local takes high, AI takes mid) and float precision
            let tolerance = max(0.51, aq * 0.01)  // 0.51 covers range midpoint diffs, 1% covers floats
            qtyMatch = abs(lq - aq) < tolerance
        } else if local.quantity == nil && ai.quantity == nil {
            qtyMatch = true
        } else {
            qtyMatch = false
        }

        // Compare units (normalized)
        let localUnitNorm = normalizeUnit(local.unit)
        let aiUnitNorm = normalizeUnit(ai.unit)
        let unitMatch = localUnitNorm == aiUnitNorm

        // Compare notes (fuzzy)
        let notesMatch: Bool
        if let ln = local.notes?.lowercased(), let an = ai.notes?.lowercased() {
            notesMatch = ln.contains(an) || an.contains(ln) || ln == an
        } else {
            notesMatch = local.notes == nil && ai.notes == nil
        }

        // Detect specific issues (local-only checks, no AI needed)
        issues.append(contentsOf: detectLocalIssues(ingredient))

        // Only flag as issues when they're REAL mismatches, not descriptor differences
        if !nameCoreMatch {
            issues.append("name_mismatch: local=\"\(local.name)\" ai=\"\(ai.name)\"")
        } else if !nameExactMatch {
            // Descriptor difference — informational, not an issue
            issues.append("name_descriptor_diff: local=\"\(local.name)\" ai=\"\(ai.name)\"")
        }

        if !qtyMatch {
            let localQtyStr = local.quantity.map { String($0) } ?? "nil"
            let aiQtyStr = ai.quantity.map { String($0) } ?? "nil"
            issues.append("qty_mismatch: local=\(localQtyStr) ai=\(aiQtyStr)")
        }
        if !unitMatch {
            issues.append("unit_mismatch: local=\"\(local.unit ?? "nil")\" ai=\"\(ai.unit ?? "nil")\"")
        }

        // Classify agreement — two tiers
        let agreement: Agreement
        if nameExactMatch && qtyMatch && unitMatch {
            // Full match — everything agrees exactly
            agreement = .fullMatch
        } else if nameCoreMatch && qtyMatch && unitMatch {
            // Core match — name has descriptors but core ingredient is the same
            agreement = .coreMatch
        } else if nameCoreMatch {
            // Core name matches but qty or unit differs — possible real issue
            if !qtyMatch || !unitMatch {
                agreement = .localLikelyWrong
            } else {
                agreement = .coreMatch
            }
        } else {
            // Name doesn't even core-match — classify further
            if aiNameNorm.count > 2 && localNameNorm.contains(aiNameNorm) {
                agreement = .coreMatch  // AI name is within local name — descriptor diff we missed
            } else if aiNameNorm.count > 2 && aiNameNorm.contains(localNameNorm) {
                agreement = .aiLikelyWrong
            } else {
                agreement = .ambiguous
            }
        }

        return ComparisonResult(
            raw: ingredient.raw,
            agreement: agreement,
            issues: issues,
            localName: local.name,
            aiName: ai.name,
            localQty: local.quantity,
            aiQty: ai.quantity,
            localUnit: local.unit,
            aiUnit: ai.unit,
            localNotes: local.notes,
            aiNotes: ai.notes
        )
    }

    // MARK: - Issue Detection (local-only, no AI needed)

    private static func detectLocalIssues(_ ingredient: ParsingEvaluator.IngredientResult) -> [String] {
        var issues: [String] = []
        let local = ingredient.hybrid

        // Leading comma in qualifier
        if local.name.contains("(,") || (local.notes?.hasPrefix(",") ?? false) {
            issues.append("leading_comma_qualifier")
        }

        // Word merge (no space between words that should be separate)
        // Exclude hyphenated words (e.g. "Italian-American") — those are valid compound words
        let nameWords = local.name.split(separator: " ")
        for word in nameWords where word.count > 15 && !word.contains("-") {
            issues.append("possible_word_merge: \"\(word)\"")
        }

        // Unparsed raw text (name equals raw input, nothing extracted)
        // Exclude short single-word ingredient names (e.g. "Avocado", "Pesto") — these are valid
        // name-only ingredients, not parsing failures
        if local.name == ingredient.sanitized && local.quantity == nil && local.unit == nil {
            let wordCount = ingredient.sanitized.split(separator: " ").count
            let hasDigit = ingredient.sanitized.contains(where: { $0.isNumber })
            if wordCount > 2 || hasDigit {
                issues.append("unparsed_raw_text")
            }
        }

        // Very low confidence
        if local.confidence < 0.5 {
            issues.append("low_confidence: \(local.confidence)")
        }

        // Sanitizer didn't clean something
        if ingredient.raw != ingredient.sanitized {
            // Check if sanitized still has issues
            if ingredient.sanitized.contains("(,") {
                issues.append("sanitizer_missed_leading_comma")
            }
        }

        return issues
    }

    // MARK: - Pattern Detection

    /// Group issues across all ingredients into patterns.
    static func detectPatterns(from comparisons: [ComparisonResult]) -> [IssuePattern] {
        var patternCounts: [String: [String]] = [:]

        for comp in comparisons {
            for issue in comp.issues {
                // Extract pattern name (before the colon)
                let pattern = issue.components(separatedBy: ":").first ?? issue
                let trimmed = pattern.trimmingCharacters(in: .whitespaces)
                patternCounts[trimmed, default: []].append(comp.raw)
            }
        }

        return patternCounts
            .map { IssuePattern(pattern: $0.key, count: $0.value.count, examples: Array($0.value.prefix(3))) }
            .sorted { $0.count > $1.count }
    }
}
