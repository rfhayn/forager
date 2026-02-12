//
//  ComputedPropertiesTests.swift
//  forager
//
//  Created for M3.5 Phase 1 Task 4: Computed Properties Testing
//  Date: October 22, 2025
//
//  Purpose: Test function for computed properties - call from Settings
//

import Foundation
import CoreData

/// Run comprehensive tests of Recipe and Ingredient computed properties
/// Call this from Settings → Developer Tools → "M3.5 Computed Properties"
func runComputedPropertiesTests(context: NSManagedObjectContext) {
    #if DEBUG
    print("\n" + String(repeating: "=", count: 60))
    print("🧪 M3.5 COMPUTED PROPERTIES TEST")
    print(String(repeating: "=", count: 60) + "\n")
    #endif
    
    // Test Recipe Properties
    testRecipeComputedProperties(context: context)
    
    // Test Ingredient Properties
    testIngredientComputedProperties(context: context)
    
    #if DEBUG
    print("\n" + String(repeating: "=", count: 60))
    print("✅ COMPUTED PROPERTIES TEST COMPLETE")
    print(String(repeating: "=", count: 60) + "\n")
    #endif
}

// MARK: - Recipe Computed Properties Tests

private func testRecipeComputedProperties(context: NSManagedObjectContext) {
    #if DEBUG
    print("📗 RECIPE COMPUTED PROPERTIES")
    print(String(repeating: "-", count: 60))
    #endif
    
    let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
    fetchRequest.fetchLimit = 3
    
    do {
        let recipes = try context.fetch(fetchRequest)
        
        if recipes.isEmpty {
            #if DEBUG
            print("⚠️  No recipes found - creating test recipe...")
            #endif
            let testRecipe = createTestRecipe(context: context)
            try context.save()
            testRecipeProperties(testRecipe)
        } else {
            #if DEBUG
            print("✅ Found \(recipes.count) recipe(s) to test\n")
            #endif
            for (index, recipe) in recipes.enumerated() {
                #if DEBUG
                print("Recipe \(index + 1):")
                #endif
                testRecipeProperties(recipe)
                #if DEBUG
                print("")
                #endif
            }
        }
    } catch {
        #if DEBUG
        print("❌ Error fetching recipes: \(error)")
        #endif
    }
}

private func testRecipeProperties(_ recipe: Recipe) {
    // Display Properties
    #if DEBUG
    print("  recipeDisplayTitle: '\(recipe.recipeDisplayTitle)'")
    print("  recipeListDisplayTitle: '\(recipe.recipeListDisplayTitle)'")
    print("  recipeServingsDescription: '\(recipe.recipeServingsDescription)'")
    #endif
    
    // Timing Properties
    if recipe.hasRecipeTiming {
        #if DEBUG
        print("  recipeFormattedPrepTime: '\(recipe.recipeFormattedPrepTime)'")
        print("  recipeFormattedCookTime: '\(recipe.recipeFormattedCookTime)'")
        print("  recipeFormattedTotalTime: '\(recipe.recipeFormattedTotalTime)'")
        print("  recipeTotalTime: \(recipe.recipeTotalTime) minutes")
        #endif
    } else {
        #if DEBUG
        print("  (No timing information)")
        #endif
    }
    
    // Usage Properties
    #if DEBUG
    print("  recipeUsageDescription: '\(recipe.recipeUsageDescription)'")
    print("  recipeLastUsedDescription: '\(recipe.recipeLastUsedDescription)'")
    print("  isFrequentlyUsedRecipe: \(recipe.isFrequentlyUsedRecipe)")
    print("  wasRecipeUsedRecently: \(recipe.wasRecipeUsedRecently)")
    print("  isNewRecipe: \(recipe.isNewRecipe)")
    #endif
    
    // Ingredient Properties
    #if DEBUG
    print("  recipeIngredientCount: \(recipe.recipeIngredientCount)")
    print("  recipeIngredientCountDescription: '\(recipe.recipeIngredientCountDescription)'")
    print("  recipeAllIngredientsHaveTemplates: \(recipe.recipeAllIngredientsHaveTemplates)")
    #endif
    
    // Validation Properties
    #if DEBUG
    print("  hasBasicRecipeInfo: \(recipe.hasBasicRecipeInfo)")
    print("  hasValidRecipeIngredients: \(recipe.hasValidRecipeIngredients)")
    print("  hasRecipeInstructions: \(recipe.hasRecipeInstructions)")
    print("  isCompleteRecipe: \(recipe.isCompleteRecipe)")
    #endif
    
    // Tags Properties
    if recipe.hasRecipeTags {
        #if DEBUG
        print("  recipeTags: \(recipe.recipeTags)")
        print("  recipeTagsDescription: '\(recipe.recipeTagsDescription)'")
        #endif
    }
    
    // Search
    let searchable = recipe.recipeSearchableText
    let preview = searchable.count > 50 ? String(searchable.prefix(50)) + "..." : searchable
    #if DEBUG
    print("  recipeSearchableText: '\(preview)'")
    #endif
}

private func createTestRecipe(context: NSManagedObjectContext) -> Recipe {
    let recipe = Recipe(context: context)
    recipe.id = UUID()
    recipe.title = "Test Chocolate Chip Cookies"
    recipe.servings = 24
    recipe.prepTime = 15
    recipe.cookTime = 10
    recipe.instructions = "1. Preheat oven\n2. Mix ingredients\n3. Bake"
    recipe.usageCount = 3
    recipe.lastUsed = Calendar.current.date(byAdding: .day, value: -5, to: Date())
    recipe.dateCreated = Date()
    recipe.isFavorite = false
    
    // Add test ingredient
    let ingredient = Ingredient(context: context)
    ingredient.id = UUID()
    ingredient.name = "all-purpose flour"
    ingredient.displayText = "2 cups"
    ingredient.sortOrder = 0
    ingredient.recipe = recipe
    ingredient.numericValue = 2.0
    ingredient.standardUnit = "cups"
    ingredient.isParseable = true
    ingredient.parseConfidence = 0.95
    
    return recipe
}

// MARK: - Ingredient Computed Properties Tests

private func testIngredientComputedProperties(context: NSManagedObjectContext) {
    #if DEBUG
    print("\n📘 INGREDIENT COMPUTED PROPERTIES")
    print(String(repeating: "-", count: 60))
    #endif
    
    let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
    fetchRequest.fetchLimit = 5
    
    do {
        let ingredients = try context.fetch(fetchRequest)
        
        if ingredients.isEmpty {
            #if DEBUG
            print("⚠️  No ingredients found")
            #endif
        } else {
            #if DEBUG
            print("✅ Found \(ingredients.count) ingredient(s) to test\n")
            #endif
            for (index, ingredient) in ingredients.enumerated() {
                #if DEBUG
                print("Ingredient \(index + 1):")
                #endif
                testIngredientProperties(ingredient)
                #if DEBUG
                print("")
                #endif
            }
        }
    } catch {
        #if DEBUG
        print("❌ Error fetching ingredients: \(error)")
        #endif
    }
}

private func testIngredientProperties(_ ingredient: Ingredient) {
    // Display Properties
    #if DEBUG
    print("  ingredientDisplayName: '\(ingredient.ingredientDisplayName)'")
    print("  bestIngredientDisplayText: '\(ingredient.bestIngredientDisplayText)'")
    print("  ingredientDisplayCategoryName: '\(ingredient.ingredientDisplayCategoryName)'")
    print("  ingredientDisplayTemplateName: '\(ingredient.ingredientDisplayTemplateName)'")
    #endif
    
    // Quantity Properties
    if ingredient.isParseable {
        #if DEBUG
        print("  ingredientFormattedQuantity: '\(ingredient.ingredientFormattedQuantity)'")
        print("  ingredientQuantityDescription: '\(ingredient.ingredientQuantityDescription)'")
        print("  ingredientConfidenceDescription: '\(ingredient.ingredientConfidenceDescription)'")
        print("  ingredientQuantityStatusEmoji: '\(ingredient.ingredientQuantityStatusEmoji)'")
        #endif
    } else {
        #if DEBUG
        print("  (Not parsed)")
        #endif
    }
    
    // Validation Properties
    #if DEBUG
    print("  hasIngredientName: \(ingredient.hasIngredientName)")
    print("  hasIngredientTemplate: \(ingredient.hasIngredientTemplate)")
    print("  hasIngredientCategory: \(ingredient.hasIngredientCategory)")
    print("  hasStructuredQuantity: \(ingredient.hasStructuredQuantity)")
    print("  isValidIngredient: \(ingredient.isValidIngredient)")
    #endif
    
    // Recipe Relationship
    if ingredient.ingredientRecipeTitle != nil {
        #if DEBUG
        print("  ingredientDisplayRecipeTitle: '\(ingredient.ingredientDisplayRecipeTitle)'")
        #endif
    }
    
    // Sorting
    #if DEBUG
    print("  ingredientCategorySortKey: '\(ingredient.ingredientCategorySortKey)'")
    print("  ingredientRecipeSortKey: '\(ingredient.ingredientRecipeSortKey)'")
    #endif
    
    // Search
    let searchable = ingredient.ingredientSearchableText
    let preview = searchable.count > 50 ? String(searchable.prefix(50)) + "..." : searchable
    #if DEBUG
    print("  ingredientSearchableText: '\(preview)'")
    #endif
}
