//
//  Ingredient+CoreDataClass.swift
//  forager
//
//  Created by Rich Hayn on 10/10/25.
//  Enhanced for M3.5: Foundation Hardening - Ingredient Validation
//

import Foundation
import CoreData

@objc(Ingredient)
public class Ingredient: NSManagedObject {
    
    // MARK: - Lifecycle Hooks
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set default values for new ingredients
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(0, forKey: "sortOrder")
        setPrimitiveValue(0.0, forKey: "numericValue")
        setPrimitiveValue(false, forKey: "isParseable")
        setPrimitiveValue(Float(0.0), forKey: "parseConfidence")
    }
    
    // MARK: - Validation
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateIngredientData()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateIngredientData()
    }
    
    private func validateIngredientData() throws {
        // Validate: At least ONE of name or displayText must exist
        let hasName = name != nil && !(name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasDisplayText = displayText != nil && !(displayText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        if !hasName && !hasDisplayText {
            throw NSError(
                domain: "IngredientValidation",
                code: 2001,
                userInfo: [NSLocalizedDescriptionKey: "Ingredient must have either name or displayText"]
            )
        }
        
        // Validate displayText length
        if let display = displayText, !display.isEmpty, display.count > 200 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2002,
                userInfo: [NSLocalizedDescriptionKey: "Display text cannot exceed 200 characters"]
            )
        }
        
        // Validate numericValue bounds
        if numericValue > 10000 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2004,
                userInfo: [NSLocalizedDescriptionKey: "Numeric value cannot exceed 10,000"]
            )
        }
        
        // Validate standardUnit length
        if let unit = standardUnit, !unit.isEmpty, unit.count > 20 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2005,
                userInfo: [NSLocalizedDescriptionKey: "Standard unit cannot exceed 20 characters"]
            )
        }
        
        // Validate parseConfidence range
        if parseConfidence < 0.0 || parseConfidence > 1.0 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2006,
                userInfo: [NSLocalizedDescriptionKey: "Parse confidence must be between 0.0 and 1.0"]
            )
        }
        
        // Validate sortOrder
        if sortOrder < 0 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2007,
                userInfo: [NSLocalizedDescriptionKey: "Sort order cannot be negative"]
            )
        }
        
        // Validate notes length
        if let notes = notes, !notes.isEmpty, notes.count > 500 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2008,
                userInfo: [NSLocalizedDescriptionKey: "Notes cannot exceed 500 characters"]
            )
        }
        
        // Validate consistency: isParseable implies numericValue present
        // M4.3.5 FIX: standardUnit is optional - ingredients like "2 eggs" are parseable without a unit
        if isParseable && numericValue <= 0 {
            throw NSError(
                domain: "IngredientValidation",
                code: 2009,
                userInfo: [NSLocalizedDescriptionKey: "Parseable ingredients must have numericValue > 0"]
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Primary display text for the ingredient
    public var primaryDisplayText: String {
        if let display = displayText, !display.isEmpty {
            return display
        }
        if let ingredientName = name, !ingredientName.isEmpty {
            return ingredientName
        }
        return "Unknown ingredient"
    }
    
    /// Whether this ingredient has structured quantity data
    public var hasStructuredQuantity: Bool {
        return isParseable && numericValue > 0 && standardUnit != nil
    }
    
    /// Formatted quantity display (e.g., "2.0 cups", "1.5 lbs")
    public var formattedQuantity: String {
        guard hasStructuredQuantity else {
            return displayText ?? name ?? ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        let formattedValue = formatter.string(from: NSNumber(value: numericValue)) ?? String(numericValue)
        return "\(formattedValue) \(standardUnit ?? "")".trimmingCharacters(in: .whitespaces)
    }
    
    /// Confidence level description (High, Medium, Low)
    public var confidenceLevelDescription: String {
        if parseConfidence >= 0.9 { return "High" }
        else if parseConfidence >= 0.7 { return "Medium" }
        else if parseConfidence > 0 { return "Low" }
        else { return "Not parsed" }
    }
    
    /// Confidence indicator (V for high, ~ for medium, ? for low, O for not parsed)
    public var confidenceIndicator: String {
        if parseConfidence >= 0.9 { return "V" }
        else if parseConfidence >= 0.7 { return "~" }
        else if parseConfidence > 0 { return "?" }
        else { return "O" }
    }
    
    /// Whether this ingredient has a template assigned
    public var hasTemplate: Bool {
        return ingredientTemplate != nil
    }
    
    /// Whether this ingredient has a category (via template)
    public var hasCategory: Bool {
        guard let template = ingredientTemplate else { return false }
        guard let category = template.category else { return false }
        return !category.isEmpty && category.lowercased() != "uncategorized"
    }
    
    /// Category name from template (or "Uncategorized")
    public var categoryName: String {
        return ingredientTemplate?.category ?? "Uncategorized"
    }
    
    /// Template name for display
    public var templateName: String? {
        return ingredientTemplate?.name
    }
    
    /// Whether this ingredient belongs to a recipe
    public var hasRecipe: Bool {
        return recipe != nil
    }
    
    /// Recipe title if this ingredient belongs to a recipe
    public var recipeTitle: String? {
        return recipe?.title
    }
    
    /// Whether this ingredient has any notes
    public var hasNotes: Bool {
        guard let notes = notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Status indicator for UI display
    public var statusDescription: String {
        if !isParseable { return "Text-only" }
        else if hasStructuredQuantity { return "Structured (\(confidenceLevelDescription))" }
        else { return "Parsed (no quantity)" }
    }
    
    /// Whether this ingredient can be scaled (requires structured quantity)
    public var isScalable: Bool {
        return isParseable && hasStructuredQuantity
    }
    
    /// Scaled quantity for given multiplier (e.g., 2.0 for doubling recipe)
    public func scaledQuantity(by multiplier: Double) -> Double? {
        guard isScalable else { return nil }
        return numericValue * multiplier
    }
    
    /// Formatted scaled quantity
    public func formattedScaledQuantity(by multiplier: Double) -> String? {
        guard let scaled = scaledQuantity(by: multiplier) else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        let formattedValue = formatter.string(from: NSNumber(value: scaled)) ?? String(scaled)
        return "\(formattedValue) \(standardUnit ?? "")".trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Helper Methods
    
    /// Update structured quantity data (used by parsing service)
    public func updateStructuredQuantity(
        numericValue: Double?,
        standardUnit: String?,
        displayText: String,
        isParseable: Bool,
        parseConfidence: Float
    ) {
        self.numericValue = numericValue ?? 0.0
        self.standardUnit = standardUnit
        self.displayText = displayText
        self.isParseable = isParseable
        self.parseConfidence = parseConfidence
    }
    
    /// Reset to unparsed state (preserves display text)
    public func resetToUnparsed() {
        self.numericValue = 0.0
        self.standardUnit = nil
        self.isParseable = false
        self.parseConfidence = 0.0
    }
    
    // MARK: - Debug Support
    
    /// Custom debug description for ingredient
    public override var debugDescription: String {
        var parts: [String] = []
        
        let idString = id?.uuidString.prefix(8) ?? "no-id"
        parts.append("Ingredient[\(idString)]")
        parts.append("display: '\(primaryDisplayText)'")
        
        if hasStructuredQuantity {
            parts.append("qty: \(formattedQuantity)")
        }
        
        parts.append("parseable: \(isParseable)")
        parts.append("confidence: \(parseConfidence)")
        
        if hasTemplate {
            parts.append("template: '\(templateName ?? "nil")'")
        }
        
        if hasRecipe {
            parts.append("recipe: '\(recipeTitle ?? "nil")'")
        }
        
        return parts.joined(separator: ", ")
    }
}
