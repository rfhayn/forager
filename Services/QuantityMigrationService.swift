//
//  QuantityMigrationService.swift
//  forager
//
//  Created for M3 Phase 3: Data Migration
//  Converts existing string-based quantities to structured format
//

import Foundation
import CoreData

// MARK: - Migration Results

struct MigrationSummary {
    let totalIngredients: Int
    let ingredientsSuccessful: Int
    let ingredientsFailed: Int
    
    let totalGroceryItems: Int
    let groceryItemsSuccessful: Int
    let groceryItemsFailed: Int
    
    var totalItems: Int {
        totalIngredients + totalGroceryItems
    }
    
    var totalSuccessful: Int {
        ingredientsSuccessful + groceryItemsSuccessful
    }
    
    var totalFailed: Int {
        ingredientsFailed + groceryItemsFailed
    }
    
    var successRate: Double {
        guard totalItems > 0 else { return 0.0 }
        return Double(totalSuccessful) / Double(totalItems)
    }
    
    var displaySummary: String {
        """
        Migration Summary:
        
        Total Items: \(totalItems)
        ✅ Successful: \(totalSuccessful) (\(Int(successRate * 100))%)
        ❌ Failed: \(totalFailed)
        
        Ingredients: \(ingredientsSuccessful)/\(totalIngredients)
        Grocery Items: \(groceryItemsSuccessful)/\(totalGroceryItems)
        """
    }
}

struct MigrationPreview {
    let sampleIngredients: [(original: String, parsed: StructuredQuantity)]
    let sampleGroceryItems: [(original: String, parsed: StructuredQuantity)]
    let estimatedSuccessRate: Double
    let totalToMigrate: Int
}

// MARK: - Migration Service

class QuantityMigrationService: ObservableObject {
    private let context: NSManagedObjectContext
    private let parsingService: IngredientParsingService
    
    @Published var migrationProgress: Double = 0.0
    @Published var currentStatus: String = "Ready to migrate"
    @Published var isComplete: Bool = false
    
    // M9.5: Accept parsing service via init for testability
    init(context: NSManagedObjectContext, parsingService: IngredientParsingService? = nil) {
        self.context = context
        if let parsingService {
            self.parsingService = parsingService
        } else {
            let templateService = IngredientTemplateService(context: context)
            self.parsingService = IngredientParsingService(
                context: context,
                templateService: templateService
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get text to migrate from Ingredient (displayText or name fallback)
    private func getTextToMigrate(from ingredient: Ingredient) -> String {
        // Check displayText first - but skip if it's literally the string `""`
        if let displayText = ingredient.displayText,
           !displayText.isEmpty,
           displayText != "\"\"" {
            return displayText
        }
        // Fallback to name
        return ingredient.name ?? ""
    }
    
    /// Get text to migrate from GroceryListItem (displayText or name fallback)
    private func getTextToMigrate(from item: GroceryListItem) -> String {
        // Check displayText first - but skip if it's literally the string `""`
        if let displayText = item.displayText,
           !displayText.isEmpty,
           displayText != "\"\"" {
            return displayText
        }
        // Fallback to name
        return item.name ?? ""
    }
    
    // MARK: - Migration Preview
    
    /// Generate preview of what migration will do
    func getMigrationPreview() -> MigrationPreview {
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        ingredientRequest.fetchLimit = 10
        
        let groceryItemRequest: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
        groceryItemRequest.fetchLimit = 10
        
        do {
            let sampleIngredients = try context.fetch(ingredientRequest)
            let sampleGroceryItems = try context.fetch(groceryItemRequest)
            
            // Use the helper method to get text
            let ingredientPreviews = sampleIngredients.compactMap { ingredient -> (String, StructuredQuantity)? in
                let textToMigrate = getTextToMigrate(from: ingredient)
                guard !textToMigrate.isEmpty else { return nil }
                
                let structured = parsingService.parseToStructured(text: textToMigrate)
                return (textToMigrate, structured)
            }
            
            let groceryItemPreviews = sampleGroceryItems.compactMap { item -> (String, StructuredQuantity)? in
                let textToMigrate = getTextToMigrate(from: item)
                guard !textToMigrate.isEmpty else { return nil }
                
                let structured = parsingService.parseToStructured(text: textToMigrate)
                return (textToMigrate, structured)
            }
            
            // Count total items to migrate
            let totalIngredients = try context.count(for: Ingredient.fetchRequest())
            let totalGroceryItems = try context.count(for: GroceryListItem.fetchRequest())
            
            // Estimate success rate from samples
            let successfulSamples = ingredientPreviews.filter { $0.1.isParseable }.count +
                                   groceryItemPreviews.filter { $0.1.isParseable }.count
            let totalSamples = ingredientPreviews.count + groceryItemPreviews.count
            
            let estimatedRate = totalSamples > 0 ? Double(successfulSamples) / Double(totalSamples) : 0.0
            
            return MigrationPreview(
                sampleIngredients: ingredientPreviews,
                sampleGroceryItems: groceryItemPreviews,
                estimatedSuccessRate: estimatedRate,
                totalToMigrate: totalIngredients + totalGroceryItems
            )
        } catch {
            #if DEBUG
            print("Error generating migration preview: \(error)")
            #endif
            return MigrationPreview(
                sampleIngredients: [],
                sampleGroceryItems: [],
                estimatedSuccessRate: 0.0,
                totalToMigrate: 0
            )
        }
    }
    
    // MARK: - Migration Execution
    
    /// Execute the migration
    func migrateAllQuantities() async -> MigrationSummary {
        await MainActor.run {
            currentStatus = "Starting migration..."
            migrationProgress = 0.0
            isComplete = false
        }
        
        // Migrate ingredients
        let ingredientResult = await migrateIngredients()
        
        await MainActor.run {
            migrationProgress = 0.5
            currentStatus = "Migrating grocery items..."
        }
        
        // Migrate grocery list items
        let groceryItemResult = await migrateGroceryListItems()
        
        await MainActor.run {
            migrationProgress = 1.0
            currentStatus = "Migration complete!"
            isComplete = true
        }
        
        // Save context
        do {
            try context.save()
            #if DEBUG
            print("✅ Migration saved successfully")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error saving migration: \(error)")
            #endif
        }
        
        return MigrationSummary(
            totalIngredients: ingredientResult.total,
            ingredientsSuccessful: ingredientResult.successful,
            ingredientsFailed: ingredientResult.failed,
            totalGroceryItems: groceryItemResult.total,
            groceryItemsSuccessful: groceryItemResult.successful,
            groceryItemsFailed: groceryItemResult.failed
        )
    }
    
    // MARK: - Private Migration Methods
    
    private func migrateIngredients() async -> (total: Int, successful: Int, failed: Int) {
        let request: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        
        do {
            let ingredients = try context.fetch(request)
            var successful = 0
            var failed = 0
            
            for ingredient in ingredients {
                // Use helper method to get text (name fallback if displayText empty)
                let textToMigrate = getTextToMigrate(from: ingredient)
                
                guard !textToMigrate.isEmpty else {
                    #if DEBUG
                    print("⚠️ Ingredient \(ingredient.id?.uuidString.prefix(8) ?? "?") has no text to migrate")
                    #endif
                    failed += 1
                    continue
                }
                
                // Parse the text to get structured data
                let structured = parsingService.parseToStructured(text: textToMigrate)
                
                // Update structured fields
                ingredient.numericValue = structured.numericValue ?? 0.0
                ingredient.standardUnit = structured.standardUnit
                ingredient.isParseable = structured.isParseable
                ingredient.parseConfidence = structured.parseConfidence
                
                // Ensure displayText is populated
                if ingredient.displayText == nil || ingredient.displayText!.isEmpty {
                    ingredient.displayText = textToMigrate
                }
                
                if structured.isParseable {
                    successful += 1
                    #if DEBUG
                    print("✅ Migrated ingredient: '\(textToMigrate)' -> \(structured.numericValue ?? 0) \(structured.standardUnit ?? "")")
                    #endif
                } else {
                    failed += 1
                    #if DEBUG
                    print("❌ FAILED ingredient: '\(textToMigrate)' - confidence: \(structured.parseConfidence)")
                    #endif
                }
            }
            
            #if DEBUG
            print("📊 Ingredients: \(successful) successful, \(failed) failed out of \(ingredients.count)")
            #endif
            return (total: ingredients.count, successful: successful, failed: failed)
            
        } catch {
            #if DEBUG
            print("❌ Error fetching ingredients for migration: \(error)")
            #endif
            return (total: 0, successful: 0, failed: 0)
        }
    }
    
    private func migrateGroceryListItems() async -> (total: Int, successful: Int, failed: Int) {
        let request: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
        
        do {
            let items = try context.fetch(request)
            var successful = 0
            var failed = 0
            
            for item in items {
                // Use helper method to get text (name fallback if displayText empty)
                let textToMigrate = getTextToMigrate(from: item)
                
                guard !textToMigrate.isEmpty else {
                    #if DEBUG
                    print("⚠️ GroceryListItem \(item.id?.uuidString.prefix(8) ?? "?") has no text to migrate")
                    #endif
                    failed += 1
                    continue
                }
                
                // Parse the text to get structured data
                let structured = parsingService.parseToStructured(text: textToMigrate)
                
                // Update structured fields
                item.numericValue = structured.numericValue ?? 0.0
                item.standardUnit = structured.standardUnit
                item.isParseable = structured.isParseable
                item.parseConfidence = structured.parseConfidence
                
                // Ensure displayText is populated
                if item.displayText == nil || item.displayText!.isEmpty {
                    item.displayText = textToMigrate
                }
                
                if structured.isParseable {
                    successful += 1
                    #if DEBUG
                    print("✅ Migrated item: '\(textToMigrate)' -> \(structured.numericValue ?? 0) \(structured.standardUnit ?? "")")
                    #endif
                } else {
                    failed += 1
                    #if DEBUG
                    print("❌ FAILED item: '\(textToMigrate)' - confidence: \(structured.parseConfidence)")
                    #endif
                }
            }
            
            #if DEBUG
            print("📊 Grocery Items: \(successful) successful, \(failed) failed out of \(items.count)")
            #endif
            return (total: items.count, successful: successful, failed: failed)
            
        } catch {
            #if DEBUG
            print("❌ Error fetching grocery items for migration: \(error)")
            #endif
            return (total: 0, successful: 0, failed: 0)
        }
    }
    
    // MARK: - Validation
    
    /// Validate migration results
    func validateMigration() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check ingredients
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        do {
            let ingredients = try context.fetch(ingredientRequest)
            
            for ingredient in ingredients {
                // Check if we have text but no structured data
                let textToMigrate = getTextToMigrate(from: ingredient)
                if !textToMigrate.isEmpty {
                    if ingredient.numericValue == 0.0 && ingredient.standardUnit == nil && !ingredient.isParseable {
                        issues.append("Ingredient '\(ingredient.name ?? "Unknown")' has text but no structured data")
                    }
                }
            }
        } catch {
            issues.append("Error validating ingredients: \(error.localizedDescription)")
        }
        
        // Check grocery list items
        let itemRequest: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
        do {
            let items = try context.fetch(itemRequest)
            
            for item in items {
                // Check if we have text but no structured data
                let textToMigrate = getTextToMigrate(from: item)
                if !textToMigrate.isEmpty {
                    if item.numericValue == 0.0 && item.standardUnit == nil && !item.isParseable {
                        issues.append("Grocery item '\(item.name ?? "Unknown")' has text but no structured data")
                    }
                }
            }
        } catch {
            issues.append("Error validating grocery items: \(error.localizedDescription)")
        }
        
        return (isValid: issues.isEmpty, issues: issues)
    }
    
    // MARK: - Rollback (if needed)
    
    /// Rollback migration (reset structured fields)
    func rollbackMigration() {
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        let itemRequest: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
        
        do {
            // Reset ingredients
            let ingredients = try context.fetch(ingredientRequest)
            for ingredient in ingredients {
                ingredient.numericValue = 0.0
                ingredient.standardUnit = nil
                ingredient.isParseable = false
                ingredient.parseConfidence = 0.0
            }
            
            // Reset grocery items
            let items = try context.fetch(itemRequest)
            for item in items {
                item.numericValue = 0.0
                item.standardUnit = nil
                item.isParseable = false
                item.parseConfidence = 0.0
            }
            
            try context.save()
            #if DEBUG
            print("✅ Migration rolled back successfully")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ Error during rollback: \(error)")
            #endif
        }
    }
}
