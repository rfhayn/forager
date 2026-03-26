import Foundation

// MARK: - Result Comparer

/// Compares local vs AI parsing results and identifies issues.
struct ResultComparer {

    enum Agreement: String, Codable {
        case match
        case localLikelyWrong = "local_likely_wrong"
        case aiLikelyWrong = "ai_likely_wrong"
        case bothWrong = "both_wrong"
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
    ]

    static func normalizeUnit(_ unit: String?) -> String? {
        guard let unit = unit?.lowercased().trimmingCharacters(in: .whitespaces) else { return nil }
        return unitAliases[unit] ?? unit
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

        // Compare names
        let localNameNorm = local.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let aiNameNorm = ai.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let nameMatch = localNameNorm == aiNameNorm

        // Compare quantities
        let qtyMatch: Bool
        if let lq = local.quantity, let aq = ai.quantity {
            qtyMatch = abs(lq - aq) < 0.01
        } else {
            qtyMatch = local.quantity == nil && ai.quantity == nil
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

        // Detect specific issues
        issues.append(contentsOf: detectLocalIssues(ingredient))

        if !nameMatch {
            issues.append("name_mismatch: local=\"\(local.name)\" ai=\"\(ai.name)\"")
        }
        if !qtyMatch {
            let localQtyStr = local.quantity.map { String($0) } ?? "nil"
            let aiQtyStr = ai.quantity.map { String($0) } ?? "nil"
            issues.append("qty_mismatch: local=\(localQtyStr) ai=\(aiQtyStr)")
        }
        if !unitMatch {
            issues.append("unit_mismatch: local=\"\(local.unit ?? "nil")\" ai=\"\(ai.unit ?? "nil")\"")
        }
        if !notesMatch && (local.notes != nil || ai.notes != nil) {
            issues.append("notes_mismatch: local=\"\(local.notes ?? "nil")\" ai=\"\(ai.notes ?? "nil")\"")
        }

        // Classify agreement
        let agreement: Agreement
        if nameMatch && qtyMatch && unitMatch {
            agreement = .match
        } else if issues.isEmpty {
            agreement = .match
        } else {
            // Heuristic: if AI name is a substring of local name or vice versa, likely local has extra junk
            if !nameMatch && aiNameNorm.count > 2 {
                if localNameNorm.contains(aiNameNorm) && localNameNorm.count > aiNameNorm.count + 5 {
                    agreement = .localLikelyWrong
                } else if aiNameNorm.contains(localNameNorm) && aiNameNorm.count > localNameNorm.count + 5 {
                    agreement = .aiLikelyWrong
                } else {
                    agreement = .ambiguous
                }
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
        let nameWords = local.name.split(separator: " ")
        for word in nameWords where word.count > 15 {
            issues.append("possible_word_merge: \"\(word)\"")
        }

        // Unparsed raw text (name equals raw input, nothing extracted)
        if local.name == ingredient.sanitized && local.quantity == nil && local.unit == nil {
            issues.append("unparsed_raw_text")
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
