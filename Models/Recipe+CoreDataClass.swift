//
//  Recipe+CoreDataClass.swift
//  forager
//
//  Created by Richard Hayn on 9/7/25.
//  Updated by Richard Hayn on 10/21/35 as part of M 3.5
//  Enhanced for M3.5: Foundation Hardening - Recipe Validation
//

import Foundation
import CoreData

@objc(Recipe)
public class Recipe: NSManagedObject {
    
    // MARK: - Lifecycle Hooks
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set default values for new recipes
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "dateCreated")
        setPrimitiveValue(Int16(0), forKey: "prepTime")
        setPrimitiveValue(Int16(0), forKey: "cookTime")
        setPrimitiveValue(Int16(4), forKey: "servings")  // Default 4 servings
        setPrimitiveValue(Int32(0), forKey: "usageCount")
        setPrimitiveValue(false, forKey: "isFavorite")
        
        // M10.6.17: Household assignment removed from awakeFromInsert (ADR 013).
        // Callers (saveImport, ManagedObjectFactory, migratePersonalDataToHousehold)
        // set household + householdKey explicitly. The unscoped fetch here found ghost
        // Household entities from previous memberships, causing invisible data.
    }
    
    // MARK: - Validation
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateRecipeData()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateRecipeData()
    }
    
    private func validateRecipeData() throws {
        // Validate title
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            throw NSError(
                domain: "RecipeValidation",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Recipe title cannot be empty"]
            )
        }
        
        if title.count < 3 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Recipe title must be at least 3 characters"]
            )
        }
        
        if title.count > 300 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Recipe title cannot exceed 300 characters"]
            )
        }
        
        // Validate servings
        if servings < 1 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "Servings must be at least 1"]
            )
        }
        
        if servings > 99 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1005,
                userInfo: [NSLocalizedDescriptionKey: "Servings cannot exceed 99"]
            )
        }
        
        // Validate times (cannot be negative)
        if prepTime < 0 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1006,
                userInfo: [NSLocalizedDescriptionKey: "Prep time cannot be negative"]
            )
        }
        
        if cookTime < 0 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1007,
                userInfo: [NSLocalizedDescriptionKey: "Cook time cannot be negative"]
            )
        }
        
        // Validate times (reasonable upper bounds - 24 hours max)
        if prepTime > 1440 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1008,
                userInfo: [NSLocalizedDescriptionKey: "Prep time cannot exceed 24 hours (1440 minutes)"]
            )
        }
        
        if cookTime > 1440 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1009,
                userInfo: [NSLocalizedDescriptionKey: "Cook time cannot exceed 24 hours (1440 minutes)"]
            )
        }
        
        // Validate instructions
        guard let instructions = instructions?.trimmingCharacters(in: .whitespacesAndNewlines),
              !instructions.isEmpty else {
            throw NSError(
                domain: "RecipeValidation",
                code: 1010,
                userInfo: [NSLocalizedDescriptionKey: "Recipe instructions cannot be empty"]
            )
        }
        
        if instructions.count > 5000 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1011,
                userInfo: [NSLocalizedDescriptionKey: "Instructions cannot exceed 5000 characters"]
            )
        }
        
        // Validate usage count (cannot be negative)
        if usageCount < 0 {
            throw NSError(
                domain: "RecipeValidation",
                code: 1012,
                userInfo: [NSLocalizedDescriptionKey: "Usage count cannot be negative"]
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total time (prep + cook) in minutes
    public var totalTime: Int {
        return Int(prepTime) + Int(cookTime)
    }
    
    /// Whether the recipe has valid ingredients
    public var hasValidIngredients: Bool {
        guard let ingredients = ingredients as? Set<Ingredient> else { return false }
        return !ingredients.isEmpty
    }
    
    /// Count of ingredients
    public var ingredientCount: Int {
        guard let ingredients = ingredients as? Set<Ingredient> else { return 0 }
        return ingredients.count
    }
    
    /// Formatted timing display (e.g., "15m prep, 30m cook")
    public var formattedTiming: String {
        let parts = [
            prepTime > 0 ? "\(prepTime)m prep" : nil,
            cookTime > 0 ? "\(cookTime)m cook" : nil
        ].compactMap { $0 }
        
        return parts.isEmpty ? "No timing set" : parts.joined(separator: ", ")
    }
    
    /// Formatted total time (e.g., "45m total")
    public var formattedTotalTime: String {
        let total = totalTime
        if total == 0 { return "No timing set" }
        
        if total < 60 {
            return "\(total)m total"
        } else {
            let hours = total / 60
            let minutes = total % 60
            if minutes == 0 {
                return "\(hours)h total"
            } else {
                return "\(hours)h \(minutes)m total"
            }
        }
    }
    
    /// Display title (handles optional with fallback)
    public var displayTitle: String {
        return title ?? "Untitled Recipe"
    }
    
    /// Tags parsed from the dedicated tags attribute (comma-separated)
    public var tagsList: [String] {
        guard let tagsString = tags, !tagsString.isEmpty else {
            return []
        }
        return tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Whether the recipe has been used before
    public var hasBeenUsed: Bool {
        return usageCount > 0
    }
    
    /// Days since last used (nil if never used)
    public var daysSinceLastUsed: Int? {
        guard let lastUsed = lastUsed else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastUsed, to: Date())
        return components.day
    }
    
    /// Is this a recently created recipe (within last 7 days)
    public var isRecentlyCreated: Bool {
        guard let dateCreated = dateCreated else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: dateCreated, to: Date())
        guard let days = components.day else { return false }
        return days <= 7
    }
    
    /// Recipe summary for display (e.g., "4 servings • 45m • 15 ingredients")
    public var summary: String {
        let servingsText = "\(servings) serving\(servings == 1 ? "" : "s")"
        let timeText = totalTime > 0 ? formattedTotalTime : nil
        let ingredientsText = hasValidIngredients ? "\(ingredientCount) ingredient\(ingredientCount == 1 ? "" : "s")" : nil
        
        return [servingsText, timeText, ingredientsText]
            .compactMap { $0 }
            .joined(separator: " • ")
    }
    
    // MARK: - Helper Methods
    
    /// Increment usage count and update lastUsed date
    public func recordUsage() {
        usageCount += 1
        lastUsed = Date()
    }
    
    /// Reset usage statistics (for testing or user-requested reset)
    public func resetUsageStats() {
        usageCount = 0
        lastUsed = nil
    }
}
