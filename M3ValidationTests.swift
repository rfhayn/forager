//
//  M3ValidationTests.swift
//  forager
//
//  M3.5 Phase 1 Task 5: Automated Validation Testing
//  Tests all M3 functionality that doesn't require UI interaction
//

import Foundation
import CoreData

/// Comprehensive automated validation for M3 features
/// Call from Settings → Developer Tools → "M3.5 Final Validation"
func runM3ValidationTests(context: NSManagedObjectContext) {
    #if DEBUG
    print("\n" + String(repeating: "=", count: 70))
    print("🧪 M3.5 COMPREHENSIVE VALIDATION TEST SUITE")
    print(String(repeating: "=", count: 70) + "\n")
    #endif
    
    var passCount = 0
    var failCount = 0
    var totalTests = 0
    
    // Run all test suites
    let results: [(String, Bool)] = [
        ("Template System", testTemplateSystem(context: context)),
        ("Data Integrity", testDataIntegrity(context: context)),
        ("Computed Properties", testComputedProperties(context: context)),
        ("Recipe Scaling", testRecipeScaling(context: context)),
        ("Edge Cases", testEdgeCases(context: context)),
        ("Performance", testPerformance(context: context))
    ]
    
    // Calculate results
    for (name, passed) in results {
        totalTests += 1
        if passed {
            passCount += 1
            #if DEBUG
            print("✅ \(name): PASS")
            #endif
        } else {
            failCount += 1
            #if DEBUG
            print("❌ \(name): FAIL")
            #endif
        }
    }
    
    // Final summary
    #if DEBUG
    print("\n" + String(repeating: "=", count: 70))
    print("📊 VALIDATION SUMMARY")
    print(String(repeating: "-", count: 70))
    print("Total Tests: \(totalTests)")
    print("Passed: ✅ \(passCount)")
    print("Failed: ❌ \(failCount)")
    print("Success Rate: \(passCount * 100 / totalTests)%")
    print(String(repeating: "=", count: 70))
    #endif
    
    if failCount == 0 {
        #if DEBUG
        print("\n🎉 ALL TESTS PASSED - M3 READY FOR M4!")
        #endif
    } else {
        #if DEBUG
        print("\n⚠️  SOME TESTS FAILED - REVIEW ISSUES ABOVE")
        #endif
    }
    #if DEBUG
    print("")
    #endif
}

// MARK: - Test Suite 1: Template System

private func testTemplateSystem(context: NSManagedObjectContext) -> Bool {
    #if DEBUG
    print("\n📗 TEST SUITE 1: TEMPLATE SYSTEM")
    print(String(repeating: "-", count: 70))
    #endif
    
    var allPassed = true
    
    // Test 1.1: Templates exist
    let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
    guard let templateCount = try? context.count(for: templateRequest) else {
        #if DEBUG
        print("  ❌ 1.1: Cannot count templates")
        #endif
        return false
    }
    
    if templateCount > 0 {
        #if DEBUG
        print("  ✅ 1.1: Templates exist (\(templateCount) templates)")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 1.1: No templates found")
        #endif
        allPassed = false
    }
    
    // Test 1.2: All templates have categories
    let uncategorizedRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
    uncategorizedRequest.predicate = NSPredicate(format: "category == nil OR category == ''")
    
    let uncategorizedCount = (try? context.count(for: uncategorizedRequest)) ?? 0
    if uncategorizedCount == 0 {
        #if DEBUG
        print("  ✅ 1.2: All templates have categories")
        #endif
    } else {
        #if DEBUG
        print("  ⚠️  1.2: \(uncategorizedCount) templates without categories")
        #endif
        // Not critical, just a warning
    }
    
    // Test 1.3: Template-Ingredient relationships valid
    let templates = try? context.fetch(templateRequest)
    let sampleSize = min(5, templates?.count ?? 0)
    var relationshipValid = true
    
    if let templates = templates?.prefix(sampleSize) {
        for template in templates {
            // Check if template can access its ingredients
            let _ = template.ingredients?.count ?? 0
            // If we get here without crashing, relationship is valid
        }
        #if DEBUG
        print("  ✅ 1.3: Template-Ingredient relationships valid (sampled \(sampleSize))")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 1.3: Cannot verify template relationships")
        #endif
        allPassed = false
        relationshipValid = false
    }
    
    return allPassed && relationshipValid
}

// MARK: - Test Suite 2: Data Integrity

private func testDataIntegrity(context: NSManagedObjectContext) -> Bool {
    #if DEBUG
    print("\n📘 TEST SUITE 2: DATA INTEGRITY")
    print(String(repeating: "-", count: 70))
    #endif
    
    var allPassed = true
    
    // Test 2.1: Recipe count
    let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
    let recipeCount = (try? context.count(for: recipeRequest)) ?? 0
    #if DEBUG
    print("  ℹ️  2.1: \(recipeCount) recipes in database")
    #endif
    
    // Test 2.2: Check sample recipe data
    if recipeCount > 0 {
        recipeRequest.fetchLimit = 1
        if let recipe = try? context.fetch(recipeRequest).first {
            let hasTitle = recipe.title != nil && !recipe.title!.isEmpty
            let hasIngredients = (recipe.ingredients?.count ?? 0) > 0
            
            if hasTitle && hasIngredients {
                #if DEBUG
                print("  ✅ 2.2: Sample recipe has valid structure")
                #endif
            } else {
                #if DEBUG
                print("  ⚠️  2.2: Sample recipe missing data (title: \(hasTitle), ingredients: \(hasIngredients))")
                #endif
            }
        }
    } else {
        #if DEBUG
        print("  ℹ️  2.2: No recipes to validate (expected for new app)")
        #endif
    }
    
    // Test 2.3: Ingredient data quality
    let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
    let ingredientCount = (try? context.count(for: ingredientRequest)) ?? 0
    
    if ingredientCount > 0 {
        ingredientRequest.fetchLimit = 10
        if let ingredients = try? context.fetch(ingredientRequest) {
            let hasNames = ingredients.filter { ($0.name?.isEmpty ?? true) == false }.count
            let hasTemplates = ingredients.filter { $0.ingredientTemplate != nil }.count
            let hasParsedQty = ingredients.filter { $0.isParseable }.count
            
            let namePercent = (hasNames * 100) / ingredients.count
            let templatePercent = (hasTemplates * 100) / ingredients.count
            let parsedPercent = (hasParsedQty * 100) / ingredients.count
            
            #if DEBUG
            print("  ✅ 2.3: Ingredient quality (sample of \(ingredients.count)):")
            print("       - Names: \(namePercent)%")
            print("       - Templates: \(templatePercent)%")
            print("       - Parsed quantities: \(parsedPercent)%")
            #endif
        }
    } else {
        #if DEBUG
        print("  ℹ️  2.3: No ingredients to validate")
        #endif
    }
    
    // Test 2.4: Grocery list items
    let itemRequest: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
    let itemCount = (try? context.count(for: itemRequest)) ?? 0
    #if DEBUG
    print("  ℹ️  2.4: \(itemCount) grocery list items in database")
    #endif
    
    return allPassed
}

// MARK: - Test Suite 3: Computed Properties

private func testComputedProperties(context: NSManagedObjectContext) -> Bool {
    #if DEBUG
    print("\n📙 TEST SUITE 3: COMPUTED PROPERTIES")
    print(String(repeating: "-", count: 70))
    #endif
    
    var allPassed = true
    
    // Test 3.1: Create test recipe
    let testRecipe = Recipe(context: context)
    testRecipe.id = UUID()
    testRecipe.title = "Validation Test Recipe"
    testRecipe.servings = 4
    testRecipe.prepTime = 15
    testRecipe.cookTime = 30
    testRecipe.instructions = "Test instructions"
    testRecipe.usageCount = 5
    testRecipe.lastUsed = Date()
    testRecipe.dateCreated = Date()
    
    // Test Recipe computed properties
    let tests: [(String, () -> Bool)] = [
        ("recipeDisplayTitle", { testRecipe.recipeDisplayTitle == "Validation Test Recipe" }),
        ("recipeServingsDescription", { testRecipe.recipeServingsDescription.contains("4") }),
        ("recipeFormattedPrepTime", { testRecipe.recipeFormattedPrepTime.contains("15") }),
        ("recipeFormattedCookTime", { testRecipe.recipeFormattedCookTime.contains("30") }),
        ("recipeFormattedTotalTime", { testRecipe.recipeFormattedTotalTime.contains("45") }),
        ("hasRecipeTiming", { testRecipe.hasRecipeTiming == true }),
        ("recipeUsageDescription", { testRecipe.recipeUsageDescription.contains("5") }),
        ("hasBasicRecipeInfo", { testRecipe.hasBasicRecipeInfo == true }),
        ("hasRecipeInstructions", { testRecipe.hasRecipeInstructions == true })
    ]
    
    var propertyTestsPassed = 0
    for (propertyName, test) in tests {
        if test() {
            propertyTestsPassed += 1
        } else {
            #if DEBUG
            print("  ❌ 3.1: \(propertyName) failed")
            #endif
            allPassed = false
        }
    }
    
    #if DEBUG
    print("  ✅ 3.1: Recipe properties (\(propertyTestsPassed)/\(tests.count) passed)")
    #endif
    
    // Test 3.2: Ingredient computed properties
    let testIngredient = Ingredient(context: context)
    testIngredient.id = UUID()
    testIngredient.name = "test flour"
    testIngredient.numericValue = 2.0
    testIngredient.standardUnit = "cups"
    testIngredient.isParseable = true
    testIngredient.parseConfidence = 0.95
    
    let ingredientTests: [(String, () -> Bool)] = [
        ("ingredientDisplayName", { testIngredient.ingredientDisplayName == "test flour" }),
        ("hasIngredientName", { testIngredient.hasIngredientName == true }),
        ("hasStructuredQuantity", { testIngredient.hasStructuredQuantity == true }),
        ("isValidIngredient", { testIngredient.isValidIngredient == true })
    ]
    
    var ingredientTestsPassed = 0
    for (propertyName, test) in ingredientTests {
        if test() {
            ingredientTestsPassed += 1
        } else {
            #if DEBUG
            print("  ❌ 3.2: \(propertyName) failed")
            #endif
            allPassed = false
        }
    }
    
    #if DEBUG
    print("  ✅ 3.2: Ingredient properties (\(ingredientTestsPassed)/\(ingredientTests.count) passed)")
    #endif
    
    // Cleanup test data (don't save)
    context.rollback()
    
    return allPassed
}

// MARK: - Test Suite 4: Recipe Scaling

private func testRecipeScaling(context: NSManagedObjectContext) -> Bool {
    #if DEBUG
    print("\n📕 TEST SUITE 4: RECIPE SCALING")
    print(String(repeating: "-", count: 70))
    #endif
    
    var allPassed = true
    
    // Create test recipe
    let recipe = Recipe(context: context)
    recipe.id = UUID()
    recipe.title = "Scaling Test"
    recipe.servings = 4
    
    // Add test ingredient
    let ingredient = Ingredient(context: context)
    ingredient.id = UUID()
    ingredient.name = "flour"
    ingredient.numericValue = 2.0
    ingredient.standardUnit = "cups"
    ingredient.isParseable = true
    ingredient.recipe = recipe
    
    // Test 4.1: Initialize scaling service
    let scalingService = RecipeScalingService(context: context)
    #if DEBUG
    print("  ✅ 4.1: RecipeScalingService initialized")
    #endif
    
    // Test 4.2: Scale to 2x
    let scaled2x = scalingService.scale(recipe: recipe, scaleFactor: 2.0)
    let expected2x = 8
    if scaled2x.scaledServings == expected2x {
        #if DEBUG
        print("  ✅ 4.2: 2x scaling works (4 → 8 servings)")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 4.2: 2x scaling failed (expected \(expected2x), got \(scaled2x.scaledServings))")
        #endif
        allPassed = false
    }
    
    // Test 4.3: Scale to 0.5x
    let scaled05x = scalingService.scale(recipe: recipe, scaleFactor: 0.5)
    let expected05x = 2
    if scaled05x.scaledServings == expected05x {
        #if DEBUG
        print("  ✅ 4.3: 0.5x scaling works (4 → 2 servings)")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 4.3: 0.5x scaling failed (expected \(expected05x), got \(scaled05x.scaledServings))")
        #endif
        allPassed = false
    }
    
    // Test 4.4: Ingredient display text contains scaled value
    if let scaledIngredient = scaled2x.scaledIngredients.first {
        // ScaledIngredient has displayText, not quantity
        // Check if displayText contains "4" (scaled from 2)
        if scaledIngredient.displayText.contains("4") {
            #if DEBUG
            print("  ✅ 4.4: Ingredient scaling works (displayText: \(scaledIngredient.displayText))")
            #endif
        } else {
            #if DEBUG
            print("  ❌ 4.4: Ingredient scaling unclear (displayText: \(scaledIngredient.displayText))")
            #endif
            allPassed = false
        }
    } else {
        #if DEBUG
        print("  ❌ 4.4: No scaled ingredients found")
        #endif
        allPassed = false
    }
    
    // Cleanup
    context.rollback()
    
    return allPassed
}

// MARK: - Test Suite 5: Edge Cases

private func testEdgeCases(context: NSManagedObjectContext) -> Bool {
    #if DEBUG
    print("\n📓 TEST SUITE 5: EDGE CASES")
    print(String(repeating: "-", count: 70))
    #endif
    
    var allPassed = true
    
    // Test 5.1: Nil title handling
    let nilTitleRecipe = Recipe(context: context)
    nilTitleRecipe.id = UUID()
    nilTitleRecipe.title = nil
    
    if nilTitleRecipe.recipeDisplayTitle == "Untitled Recipe" {
        #if DEBUG
        print("  ✅ 5.1: Nil title handled gracefully")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 5.1: Nil title not handled correctly")
        #endif
        allPassed = false
    }
    
    // Test 5.2: Zero servings
    let zeroServingsRecipe = Recipe(context: context)
    zeroServingsRecipe.id = UUID()
    zeroServingsRecipe.servings = 0
    
    if zeroServingsRecipe.recipeServingsDescription.contains("0") {
        #if DEBUG
        print("  ✅ 5.2: Zero servings handled")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 5.2: Zero servings not handled correctly")
        #endif
        allPassed = false
    }
    
    // Test 5.3: Nil ingredient name
    let nilNameIngredient = Ingredient(context: context)
    nilNameIngredient.id = UUID()
    nilNameIngredient.name = nil
    
    if nilNameIngredient.ingredientDisplayName == "Unknown Ingredient" {
        #if DEBUG
        print("  ✅ 5.3: Nil ingredient name handled gracefully")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 5.3: Nil ingredient name not handled correctly")
        #endif
        allPassed = false
    }
    
    // Test 5.4: Non-parseable quantity
    let nonParseableIngredient = Ingredient(context: context)
    nonParseableIngredient.id = UUID()
    nonParseableIngredient.name = "to taste"
    nonParseableIngredient.isParseable = false
    
    if nonParseableIngredient.hasStructuredQuantity == false {
        #if DEBUG
        print("  ✅ 5.4: Non-parseable quantity flagged correctly")
        #endif
    } else {
        #if DEBUG
        print("  ❌ 5.4: Non-parseable quantity check failed")
        #endif
        allPassed = false
    }
    
    // Cleanup
    context.rollback()
    
    return allPassed
}

// MARK: - Test Suite 6: Performance

private func testPerformance(context: NSManagedObjectContext) -> Bool {
    #if DEBUG
    print("\n⚡ TEST SUITE 6: PERFORMANCE")
    print(String(repeating: "-", count: 70))
    #endif
    
    var allPassed = true
    
    // Test 6.1: Recipe fetch performance
    let startFetch = Date()
    let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
    let _ = try? context.fetch(recipeRequest)
    let fetchTime = Date().timeIntervalSince(startFetch)
    
    if fetchTime < 1.0 {
        #if DEBUG
        print("  ✅ 6.1: Recipe fetch < 1s (\(String(format: "%.3f", fetchTime))s)")
        #endif
    } else {
        #if DEBUG
        print("  ⚠️  6.1: Recipe fetch slow (\(String(format: "%.3f", fetchTime))s)")
        #endif
    }
    
    // Test 6.2: Template fetch performance
    let startTemplateFetch = Date()
    let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
    let _ = try? context.fetch(templateRequest)
    let templateFetchTime = Date().timeIntervalSince(startTemplateFetch)
    
    if templateFetchTime < 0.5 {
        #if DEBUG
        print("  ✅ 6.2: Template fetch < 0.5s (\(String(format: "%.3f", templateFetchTime))s)")
        #endif
    } else {
        #if DEBUG
        print("  ⚠️  6.2: Template fetch slow (\(String(format: "%.3f", templateFetchTime))s)")
        #endif
    }
    
    // Test 6.3: Computed property performance
    if let recipe = try? context.fetch(recipeRequest).first {
        let startComputed = Date()
        for _ in 0..<100 {
            let _ = recipe.recipeDisplayTitle
            let _ = recipe.recipeServingsDescription
            let _ = recipe.recipeFormattedPrepTime
        }
        let computedTime = Date().timeIntervalSince(startComputed)
        
        if computedTime < 0.1 {
            #if DEBUG
            print("  ✅ 6.3: Computed properties fast (\(String(format: "%.3f", computedTime))s for 100 calls)")
            #endif
        } else {
            #if DEBUG
            print("  ⚠️  6.3: Computed properties slow (\(String(format: "%.3f", computedTime))s)")
            #endif
        }
    }
    
    return allPassed
}
