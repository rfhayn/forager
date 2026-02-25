//
//  Ingredient+ComputedProperties.swift
//  forager
//
//  Created for M3.5 Phase 1 Task 4: Computed Properties
//  Date: October 22, 2025
//
//  Purpose: Add convenience computed properties for common Ingredient queries and UI display
//  Note: Ingredient uses Manual/None codegen, so this is a standard extension
//

import Foundation
import CoreData

extension Ingredient {
    
    // MARK: - Validation Properties
    
    /// Returns true if ingredient has a name
    var hasIngredientName: Bool {
        guard let ingredientName = name?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !ingredientName.isEmpty
    }
    
    /// Returns true if ingredient has a template assigned
    var hasIngredientTemplate: Bool {
        return ingredientTemplate != nil
    }
    
    /// Returns true if ingredient has a category (through template)
    var hasIngredientCategory: Bool {
        guard let template = ingredientTemplate else { return false }
        guard let category = template.category else { return false }
        return !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // NOTE: hasStructuredQuantity already exists in Ingredient entity (from Core Data)
    // We don't redefine it here to avoid conflicts
    
    /// Returns true if ingredient is valid for use
    var isValidIngredient: Bool {
        return hasIngredientName
    }
    
    // MARK: - Display Properties
    
    /// Returns ingredient name with fallback
    var ingredientDisplayName: String {
        if let ingredientName = name {
            return ingredientName
        }
        return "Unknown Ingredient"
    }
    
    /// Returns best display text (uses displayText if available, falls back to name)
    var bestIngredientDisplayText: String {
        if let display = displayText, !display.isEmpty {
            return display
        }
        return ingredientDisplayName
    }
    
    /// Returns category name through template
    var ingredientCategoryName: String? {
        return ingredientTemplate?.category
    }
    
    /// Returns category display name with fallback
    var ingredientDisplayCategoryName: String {
        if let category = ingredientCategoryName {
            return category
        }
        return "Uncategorized"
    }
    
    /// Returns template name
    var ingredientTemplateName: String? {
        return ingredientTemplate?.name
    }
    
    /// Returns template display name with fallback
    var ingredientDisplayTemplateName: String {
        if let templateName = ingredientTemplateName {
            return templateName
        }
        return "No Template"
    }
    
    // MARK: - Quantity Properties
    
    /// Returns formatted quantity string (e.g., "2.5 cups")
    var ingredientFormattedQuantity: String {
        if !isParseable {
            return bestIngredientDisplayText
        }
        
        guard numericValue > 0 else {
            return bestIngredientDisplayText
        }
        
        var result = formatIngredientNumber(numericValue)
        
        if let unit = standardUnit, !unit.isEmpty {
            result += " \(unit)"
        }
        
        if let template = ingredientTemplateName {
            result += " \(template)"
        }
        
        return result
    }
    
    /// Returns short quantity description (just amount and unit, no ingredient name)
    var ingredientQuantityDescription: String {
        if !isParseable || numericValue == 0 {
            if let display = displayText {
                return display
            }
            return "Amount not specified"
        }
        
        var result = formatIngredientNumber(numericValue)
        
        if let unit = standardUnit, !unit.isEmpty {
            result += " \(unit)"
        }
        
        return result
    }
    
    /// Returns confidence level description
    var ingredientConfidenceDescription: String {
        let confidence: Float = parseConfidence
        
        if !isParseable {
            return "Not parsed"
        } else if confidence >= 0.9 {
            return "High confidence"
        } else if confidence >= 0.7 {
            return "Medium confidence"
        } else if confidence >= 0.5 {
            return "Low confidence"
        } else {
            return "Very low confidence"
        }
    }
    
    /// Returns quantity status emoji for UI
    var ingredientQuantityStatusEmoji: String {
        if !isParseable {
            return "📝" // Text only
        } else if parseConfidence >= 0.9 {
            return "✅" // High confidence
        } else if parseConfidence >= 0.7 {
            return "⚠️" // Medium confidence
        } else {
            return "❓" // Low confidence
        }
    }
    
    // MARK: - Recipe Relationship Properties
    
    /// Returns recipe title
    var ingredientRecipeTitle: String? {
        return recipe?.title
    }
    
    /// Returns recipe display title with fallback
    var ingredientDisplayRecipeTitle: String {
        if let recipeTitle = ingredientRecipeTitle {
            return recipeTitle
        }
        return "Unknown Recipe"
    }
    
    // MARK: - Comparison Properties
    
    /// Returns true if this ingredient can be consolidated with another
    func canConsolidateWith(_ other: Ingredient) -> Bool {
        // Must have same template
        guard let thisTemplate = self.ingredientTemplate,
              let otherTemplate = other.ingredientTemplate,
              thisTemplate == otherTemplate else {
            return false
        }
        
        // Must both be parseable
        guard self.isParseable && other.isParseable else {
            return false
        }
        
        // Must have same unit (or both nil)
        let thisUnit: String = self.standardUnit ?? ""
        let otherUnit: String = other.standardUnit ?? ""
        
        return thisUnit == otherUnit
    }
    
    /// Returns combined quantity with another ingredient (if compatible)
    func combinedQuantityWith(_ other: Ingredient) -> Double? {
        guard canConsolidateWith(other) else { return nil }
        return self.numericValue + other.numericValue
    }
    
    // MARK: - Sorting Properties
    
    /// Returns sort key for category-based sorting
    var ingredientCategorySortKey: String {
        let category: String = ingredientDisplayCategoryName
        let ingredientName: String = ingredientDisplayName
        return "\(category)|\(ingredientName)"
    }
    
    /// Returns sort key for recipe-based sorting
    var ingredientRecipeSortKey: String {
        let order: Int16 = sortOrder
        return String(format: "%05d", order)
    }
    
    // MARK: - Search Properties
    
    /// Returns searchable text for this ingredient
    var ingredientSearchableText: String {
        var text: String = ingredientDisplayName.lowercased() + " "
        
        if let template = ingredientTemplateName {
            text += template.lowercased() + " "
        }
        
        if let category = ingredientCategoryName {
            text += category.lowercased() + " "
        }
        
        if let ingredientNotes = notes {
            text += ingredientNotes.lowercased() + " "
        }
        
        return text
    }
    
    /// Returns true if ingredient matches search query
    func matchesSearchQuery(_ searchQuery: String) -> Bool {
        let query: String = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return ingredientSearchableText.contains(query)
    }
    
    // MARK: - Helper Methods
    
    private func formatIngredientNumber(_ value: Double) -> String {
        // Handle fractions
        let tolerance: Double = 0.01
        
        // Common fractions
        let fractions: [(Double, String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.375, "⅜"),
            (0.5, "½"), (0.625, "⅝"), (0.666, "⅔"), (0.75, "¾"), (0.875, "⅞")
        ]
        
        let wholeNumber: Int = Int(value)
        let fractionalPart: Double = value - Double(wholeNumber)
        
        // Check if fractional part matches a common fraction
        if fractionalPart > tolerance {
            for (decimal, fraction) in fractions {
                if abs(fractionalPart - decimal) < tolerance {
                    if wholeNumber > 0 {
                        return "\(wholeNumber) \(fraction)"
                    } else {
                        return fraction
                    }
                }
            }
        }
        
        // If no fraction match, format as decimal
        if fractionalPart < tolerance {
            return "\(wholeNumber)"
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Update ingredient with parsed quantity data
    func updateIngredientWithParsedQuantity(numericValue: Double, unit: String?, confidence: Float) {
        self.numericValue = numericValue
        self.standardUnit = unit
        self.isParseable = true
        self.parseConfidence = confidence
    }
    
    /// Clear parsed quantity data
    func clearIngredientParsedQuantity() {
        self.numericValue = 0
        self.standardUnit = nil
        self.isParseable = false
        self.parseConfidence = 0
    }
}

// MARK: - Comparable

extension Ingredient: Comparable {
    public static func < (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}
