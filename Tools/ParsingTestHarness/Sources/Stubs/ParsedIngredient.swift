import Foundation

// MARK: - Types from IngredientParsingService.swift (copied to avoid Core Data dependency)

struct StructuredQuantity {
    let numericValue: Double?
    let standardUnit: String?
    let displayText: String
    let isParseable: Bool
    let parseConfidence: Float
    let parserUsed: String?
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
