//
//  RecipeScalingService.swift
//  forager
//
//  Created for M3 Phase 4: Recipe Scaling Service
//  Mathematical recipe scaling with graceful handling of parseable and unparseable quantities
//

import Foundation
import CoreData

// MARK: - Data Structures

struct ScaledRecipe {
    let originalRecipe: Recipe
    let scaleFactor: Double
    let scaledServings: Int
    let scaledIngredients: [ScaledIngredient]
    let autoScaledCount: Int
    let manualAdjustCount: Int
    
    var summary: String {
        if manualAdjustCount == 0 {
            return "All \(autoScaledCount) ingredients auto-scaled"
        } else {
            return "\(autoScaledCount) ingredients auto-scaled, \(manualAdjustCount) require manual adjustment"
        }
    }
}

struct ScaledIngredient: Identifiable {
    let id = UUID()
    let name: String
    let displayText: String
    let wasScaled: Bool
    let originalText: String?
    let category: String
}

// MARK: - Recipe Scaling Service

class RecipeScalingService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Main Scaling Function
    
    /// Scale recipe by given factor, handling both parseable and unparseable quantities
    func scale(recipe: Recipe, scaleFactor: Double) -> ScaledRecipe {
        var scaledIngredients: [ScaledIngredient] = []
        var autoScaledCount = 0
        var manualAdjustCount = 0
        
        // Get ingredients from the recipe relationship
        guard let ingredientsSet = recipe.ingredients else {
            return ScaledRecipe(
                originalRecipe: recipe,
                scaleFactor: scaleFactor,
                scaledServings: Int(round(Double(recipe.servings) * scaleFactor)),
                scaledIngredients: [],
                autoScaledCount: 0,
                manualAdjustCount: 0
            )
        }
        
        let ingredients = (Array(ingredientsSet) as? [Ingredient] ?? [])
            .sorted { ($0.sortOrder) < ($1.sortOrder) }
        
        for ingredient in ingredients {
            let category = ingredient.ingredientTemplate?.categoryEntity?.name ?? "Uncategorized"
            
            // Check if ingredient has a valid numeric value for scaling
            // Note: numericValue is non-optional Double (0.0 default for unparseable)
            if ingredient.isParseable && ingredient.numericValue > 0 {
                // Scale parseable quantities mathematically
                let scaledValue = ingredient.numericValue * scaleFactor
                let displayText = formatScaled(
                    value: scaledValue,
                    unit: ingredient.standardUnit
                )
                
                scaledIngredients.append(ScaledIngredient(
                    name: ingredient.name ?? "Unknown",
                    displayText: displayText,
                    wasScaled: true,
                    originalText: ingredient.displayText,
                    category: category
                ))
                autoScaledCount += 1
            } else {
                // Keep unparseable with helpful note
                let adjustmentNote = "adjust to taste for \(formatServings(recipe.servings, scaleFactor)) servings"
                let displayText = ingredient.displayText ?? "Unknown quantity"
                
                scaledIngredients.append(ScaledIngredient(
                    name: ingredient.name ?? "Unknown",
                    displayText: "\(displayText) (\(adjustmentNote))",
                    wasScaled: false,
                    originalText: ingredient.displayText,
                    category: category
                ))
                manualAdjustCount += 1
            }
        }
        
        let scaledServings = Int(round(Double(recipe.servings) * scaleFactor))
        
        return ScaledRecipe(
            originalRecipe: recipe,
            scaleFactor: scaleFactor,
            scaledServings: scaledServings,
            scaledIngredients: scaledIngredients,
            autoScaledCount: autoScaledCount,
            manualAdjustCount: manualAdjustCount
        )
    }
    
    // MARK: - Formatting
    
    /// Format scaled values with kitchen-friendly fractions
    private func formatScaled(value: Double, unit: String?) -> String {
        let fractionString = formatToFraction(value)
        
        if let unit = unit, !unit.isEmpty {
            return "\(fractionString) \(unit)"
        } else {
            return fractionString
        }
    }
    
    /// Convert decimal to fraction for kitchen-friendly display
    private func formatToFraction(_ value: Double) -> String {
        let whole = Int(value)
        let fractional = value - Double(whole)
        
        // Common kitchen fractions with tolerance
        let fractions: [(value: Double, display: String)] = [
            (0.125, "1/8"),
            (0.166, "1/6"),
            (0.25, "1/4"),
            (0.333, "1/3"),
            (0.375, "3/8"),
            (0.5, "1/2"),
            (0.625, "5/8"),
            (0.666, "2/3"),
            (0.75, "3/4"),
            (0.833, "5/6"),
            (0.875, "7/8")
        ]
        
        let tolerance = 0.05
        
        // Find matching fraction
        for (fValue, fDisplay) in fractions {
            if abs(fractional - fValue) < tolerance {
                if whole > 0 {
                    return "\(whole) \(fDisplay)"
                } else {
                    return fDisplay
                }
            }
        }
        
        // No close fraction match, use decimal
        if whole > 0 {
            if fractional < 0.01 {
                // Very close to whole number
                return "\(whole)"
            }
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    /// Format servings count
    private func formatServings(_ servings: Int16, _ factor: Double) -> String {
        let scaled = Int(round(Double(servings) * factor))
        return "\(scaled)"
    }
}
