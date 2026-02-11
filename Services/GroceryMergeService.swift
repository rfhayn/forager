//
//  GroceryMergeService.swift
//  forager
//
//  M8.3.2: Automatic quantity merging for grocery list items.
//  Pure computation — no Core Data dependency. Fully unit-testable.
//

import Foundation

/// Input describing one side of a merge (existing item or incoming ingredient)
struct GroceryMergeInput {
    let numericValue: Double
    let standardUnit: String?
    let isParseable: Bool
    let parseConfidence: Double
}

/// Output of a merge operation
struct GroceryMergeResult {
    let numericValue: Double
    let standardUnit: String?
    let displayText: String
    let parseConfidence: Double
    let didMergeQuantity: Bool
}

class GroceryMergeService {
    private let conversionService: UnitConversionService

    init(conversionService: UnitConversionService = UnitConversionService()) {
        self.conversionService = conversionService
    }

    // MARK: - Merge

    /// Merge an incoming ingredient quantity into an existing grocery list item.
    /// Returns the merged result — caller applies it to the Core Data object.
    func merge(existing: GroceryMergeInput, incoming: GroceryMergeInput) -> GroceryMergeResult {
        let mergedConfidence = min(existing.parseConfidence, incoming.parseConfidence)

        // Both sides must be parseable with positive quantities to attempt numeric merge
        guard existing.isParseable, incoming.isParseable,
              existing.numericValue > 0 || incoming.numericValue > 0 else {
            return GroceryMergeResult(
                numericValue: existing.numericValue,
                standardUnit: existing.standardUnit,
                displayText: formatDisplayText(value: existing.numericValue, unit: existing.standardUnit),
                parseConfidence: mergedConfidence,
                didMergeQuantity: false
            )
        }

        // Existing is zero but incoming has value — adopt incoming
        if existing.numericValue <= 0 && incoming.numericValue > 0 {
            return GroceryMergeResult(
                numericValue: incoming.numericValue,
                standardUnit: incoming.standardUnit,
                displayText: formatDisplayText(value: incoming.numericValue, unit: incoming.standardUnit),
                parseConfidence: mergedConfidence,
                didMergeQuantity: true
            )
        }

        // Incoming is zero — keep existing unchanged
        if incoming.numericValue <= 0 {
            return GroceryMergeResult(
                numericValue: existing.numericValue,
                standardUnit: existing.standardUnit,
                displayText: formatDisplayText(value: existing.numericValue, unit: existing.standardUnit),
                parseConfidence: mergedConfidence,
                didMergeQuantity: false
            )
        }

        // Both have positive values — attempt addition
        let existingUnit = existing.standardUnit
        let incomingUnit = incoming.standardUnit

        // Both unitless — direct addition
        if existingUnit == nil && incomingUnit == nil {
            let total = existing.numericValue + incoming.numericValue
            return GroceryMergeResult(
                numericValue: total,
                standardUnit: nil,
                displayText: formatDisplayText(value: total, unit: nil),
                parseConfidence: mergedConfidence,
                didMergeQuantity: true
            )
        }

        // One has unit, other doesn't — can't merge
        guard let existUnit = existingUnit, let incUnit = incomingUnit else {
            return GroceryMergeResult(
                numericValue: existing.numericValue,
                standardUnit: existing.standardUnit,
                displayText: formatDisplayText(value: existing.numericValue, unit: existing.standardUnit),
                parseConfidence: mergedConfidence,
                didMergeQuantity: false
            )
        }

        // Same unit — direct addition
        if existUnit.lowercased() == incUnit.lowercased() {
            let total = existing.numericValue + incoming.numericValue
            return GroceryMergeResult(
                numericValue: total,
                standardUnit: existUnit,
                displayText: formatDisplayText(value: total, unit: existUnit),
                parseConfidence: mergedConfidence,
                didMergeQuantity: true
            )
        }

        // Different units — try conversion
        if let converted = conversionService.convert(value: incoming.numericValue, from: incUnit, to: existUnit) {
            let total = existing.numericValue + converted
            return GroceryMergeResult(
                numericValue: total,
                standardUnit: existUnit,
                displayText: formatDisplayText(value: total, unit: existUnit),
                parseConfidence: mergedConfidence,
                didMergeQuantity: true
            )
        }

        // Incompatible units — can't merge
        return GroceryMergeResult(
            numericValue: existing.numericValue,
            standardUnit: existing.standardUnit,
            displayText: formatDisplayText(value: existing.numericValue, unit: existing.standardUnit),
            parseConfidence: mergedConfidence,
            didMergeQuantity: false
        )
    }

    // MARK: - Display Formatting

    /// Format a numeric value + unit into user-facing display text.
    func formatDisplayText(value: Double, unit: String?) -> String {
        guard value > 0 else {
            if let unit = unit {
                return "0 \(unit)"
            }
            return ""
        }

        let formattedValue: String
        if value == value.rounded() && value < 10000 {
            // Whole number — no decimal
            formattedValue = String(Int(value))
        } else {
            // Fractional — show minimal decimals
            let rounded = (value * 100).rounded() / 100
            if rounded == (rounded * 10).rounded() / 10 {
                formattedValue = String(format: "%.1f", rounded)
            } else {
                formattedValue = String(format: "%.2f", rounded)
            }
        }

        if let unit = unit, !unit.isEmpty {
            return "\(formattedValue) \(unit)"
        }
        return formattedValue
    }
}
