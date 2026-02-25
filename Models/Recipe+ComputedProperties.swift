//
//  Recipe+ComputedProperties.swift
//  forager
//
//  Created for M3.5 Phase 1 Task 4: Computed Properties
//  Date: October 22, 2025
//
//  Purpose: Add convenience computed properties for common Recipe queries and UI display
//  Note: Recipe uses Manual/None codegen, so this is a standard extension
//

import Foundation
import CoreData

extension Recipe {
    
    // MARK: - Validation Properties
    
    /// Returns true if recipe has all required basic information
    var hasBasicRecipeInfo: Bool {
        guard let recipeTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !recipeTitle.isEmpty && servings > 0
    }
    
    /// Returns true if recipe has valid ingredients
    var hasValidRecipeIngredients: Bool {
        guard let ingredientsSet = ingredients as? Set<Ingredient> else {
            return false
        }
        return !ingredientsSet.isEmpty
    }
    
    /// Returns true if recipe has instructions
    var hasRecipeInstructions: Bool {
        guard let recipeInstructions = instructions?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !recipeInstructions.isEmpty
    }
    
    /// Returns true if recipe is complete and ready to use
    var isCompleteRecipe: Bool {
        return hasBasicRecipeInfo && hasValidRecipeIngredients && hasRecipeInstructions
    }
    
    /// Returns true if recipe has any timing information
    var hasRecipeTiming: Bool {
        return prepTime > 0 || cookTime > 0
    }
    
    // MARK: - Timing Properties
    
    /// Total time in minutes (prep + cook)
    var recipeTotalTime: Int {
        return Int(prepTime) + Int(cookTime)
    }
    
    /// Formatted prep time string (e.g., "15 min" or "1 hr 30 min")
    var recipeFormattedPrepTime: String {
        return formatRecipeMinutes(Int(prepTime))
    }
    
    /// Formatted cook time string (e.g., "30 min" or "2 hrs")
    var recipeFormattedCookTime: String {
        return formatRecipeMinutes(Int(cookTime))
    }
    
    /// Formatted total time string (e.g., "45 min" or "1 hr 45 min")
    var recipeFormattedTotalTime: String {
        return formatRecipeMinutes(recipeTotalTime)
    }
    
    // MARK: - Display Properties
    
    /// Returns recipe title with fallback
    var recipeDisplayTitle: String {
        if let recipeTitle = title {
            return recipeTitle
        }
        return "Untitled Recipe"
    }
    
    /// Returns recipe title for list display (truncated if needed)
    var recipeListDisplayTitle: String {
        let recipeTitle: String = recipeDisplayTitle
        return recipeTitle.count > 50 ? String(recipeTitle.prefix(47)) + "..." : recipeTitle
    }
    
    /// Returns servings as formatted string (e.g., "4 servings")
    var recipeServingsDescription: String {
        let count: Int = Int(servings)
        return count == 1 ? "1 serving" : "\(count) servings"
    }
    
    /// Returns usage count as formatted string (e.g., "Made 5 times")
    var recipeUsageDescription: String {
        let count: Int = Int(usageCount)
        switch count {
        case 0:
            return "Never made"
        case 1:
            return "Made once"
        default:
            return "Made \(count) times"
        }
    }
    
    /// Returns last used date as formatted string
    var recipeLastUsedDescription: String {
        guard let date = lastUsed else {
            return "Never used"
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Used today"
        } else if calendar.isDateInYesterday(date) {
            return "Used yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day {
            if daysAgo < 7 {
                return "Used \(daysAgo) days ago"
            } else if daysAgo < 30 {
                let weeksAgo: Int = daysAgo / 7
                return weeksAgo == 1 ? "Used 1 week ago" : "Used \(weeksAgo) weeks ago"
            } else if daysAgo < 365 {
                let monthsAgo: Int = daysAgo / 30
                return monthsAgo == 1 ? "Used 1 month ago" : "Used \(monthsAgo) months ago"
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Used on \(formatter.string(from: date))"
    }
    
    // MARK: - Ingredient Properties
    
    /// Returns sorted array of ingredients
    var recipeSortedIngredients: [Ingredient] {
        guard let ingredientsSet = ingredients as? Set<Ingredient> else {
            return []
        }
        return ingredientsSet.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Returns count of ingredients
    var recipeIngredientCount: Int {
        return (ingredients as? Set<Ingredient>)?.count ?? 0
    }
    
    /// Returns formatted ingredient count (e.g., "8 ingredients")
    var recipeIngredientCountDescription: String {
        let count: Int = recipeIngredientCount
        return count == 1 ? "1 ingredient" : "\(count) ingredients"
    }
    
    /// Returns true if all ingredients have templates assigned
    var recipeAllIngredientsHaveTemplates: Bool {
        guard let ingredientsSet = ingredients as? Set<Ingredient> else {
            return false
        }
        return ingredientsSet.allSatisfy { $0.ingredientTemplate != nil }
    }
    
    /// Returns array of ingredients without templates
    var recipeIngredientsWithoutTemplates: [Ingredient] {
        return recipeSortedIngredients.filter { $0.ingredientTemplate == nil }
    }
    
    /// Returns array of ingredients without categories
    var recipeIngredientsWithoutCategories: [Ingredient] {
        return recipeSortedIngredients.filter {
            guard let template = $0.ingredientTemplate else { return true }
            return template.category == nil || template.category?.isEmpty == true
        }
    }
    
    // MARK: - Usage Tracking Properties
    
    /// Returns true if recipe is frequently used (5+ uses)
    var isFrequentlyUsedRecipe: Bool {
        return usageCount >= 5
    }
    
    /// Returns true if recipe was used recently (within 30 days)
    var wasRecipeUsedRecently: Bool {
        guard let lastUsedDate = lastUsed else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return lastUsedDate > thirtyDaysAgo
    }
    
    /// Returns true if recipe is new (never used)
    var isNewRecipe: Bool {
        return usageCount == 0
    }
    
    // MARK: - Tags Properties

    /// Returns array of tags from dedicated tags attribute
    var recipeTags: [String] {
        return tagsList
    }

    /// Returns formatted tags string for display
    var recipeTagsDescription: String {
        let tagArray: [String] = recipeTags
        return tagArray.isEmpty ? "No tags" : tagArray.joined(separator: ", ")
    }

    /// Returns true if recipe has any tags
    var hasRecipeTags: Bool {
        return !recipeTags.isEmpty
    }
    
    // MARK: - Search/Filter Properties
    
    /// Returns searchable text combining title, instructions, and ingredients
    var recipeSearchableText: String {
        var text: String = recipeDisplayTitle + " "
        
        if let recipeInstructions = instructions {
            text += recipeInstructions + " "
        }
        
        for ingredient in recipeSortedIngredients {
            if let ingredientName = ingredient.name {
                text += ingredientName + " "
            }
        }
        
        return text.lowercased()
    }
    
    /// Returns true if recipe matches search query
    func matchesRecipeSearchQuery(_ searchQuery: String) -> Bool {
        let query: String = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return recipeSearchableText.contains(query)
    }
    
    // MARK: - Helper Methods
    
    private func formatRecipeMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0 min" }
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours: Int = minutes / 60
            let remainingMinutes: Int = minutes % 60
            
            if remainingMinutes == 0 {
                return hours == 1 ? "1 hr" : "\(hours) hrs"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Increment usage count and update last used date
    func recordRecipeUsage() {
        usageCount += 1
        lastUsed = Date()
    }
    
    /// Toggle favorite status
    func toggleRecipeFavorite() {
        isFavorite.toggle()
    }
}
