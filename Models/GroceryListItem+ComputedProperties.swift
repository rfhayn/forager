//
//  GroceryListItem+ComputedProperties.swift
//  forager
//
//  Created for M4.3.1 Phase 4: Recipe Source Display Logic
//  Date: November 13, 2025
//
//  Purpose: Add computed property for recipe source display with user preference support
//

import Foundation
import CoreData

extension GroceryListItem {
    
    // MARK: - M4.3.1: Recipe Source Display
    
    /// Returns formatted recipe source string for display
    /// Format: " [Recipe1] [Recipe2]" (alphabetically sorted)
    /// Returns empty string if no sources or user preference disabled
    ///
    /// Performance: < 0.05s (optimized for UI display)
    @MainActor
    var recipeSourceDisplay: String {
        // Check user preference first
        guard UserPreferencesService.shared.showRecipeSources else {
            return ""
        }
        
        // Get source recipes from relationship
        guard let recipes = sourceRecipes as? Set<Recipe>,
              !recipes.isEmpty else {
            return ""
        }
        
        // Extract and sort recipe names alphabetically
        let recipeNames = recipes
            .compactMap { $0.title }
            .sorted()
        
        // Format as " [Name1] [Name2]"
        guard !recipeNames.isEmpty else {
            return ""
        }
        
        let tags = recipeNames.map { "[\($0)]" }.joined(separator: " ")
        return " \(tags)"
    }
    
    // MARK: - M4.3.1: Recipe Source Names Array (for badge display)
    
    /// Returns array of recipe names for badge-style display
    /// Returns empty array if no sources or user preference disabled
    ///
    /// Performance: < 0.05s (optimized for UI display)
    @MainActor
    var sourceRecipeNames: [String] {
        // Check user preference first
        guard UserPreferencesService.shared.showRecipeSources else {
            return []
        }
        
        // Get source recipes from relationship
        guard let recipes = sourceRecipes as? Set<Recipe>,
              !recipes.isEmpty else {
            return []
        }
        
        // Extract and sort recipe names alphabetically
        return recipes
            .compactMap { $0.title }
            .sorted()
    }
}
