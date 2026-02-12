//
//  HouseholdIngredientTemplateRepository.swift
//  forager
//
//  M7.2.3 Phase 2.2: Household-scoped ingredient template repository
//  Single responsibility: Semantic uniqueness for templates in shared household zone
//
//  Created on December 31, 2025.
//

import CoreData
import Foundation

/// M7.2.3 Phase 2.2: Household-scoped ingredient template repository
///
/// Responsibilities:
/// - Prevent duplicate ingredient templates in household shared zone
/// - Query-before-create using canonicalName (semantic uniqueness)
/// - Idempotent operations (safe to call multiple times)
/// - Clear console logging for debugging
///
/// Pattern: Always query by canonical name before creating
final class HouseholdIngredientTemplateRepository {
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Public Repository Methods
    
    /// M7.2.3: Find or create ingredient template using semantic uniqueness
    /// Prevents duplicate templates when multiple household members create same ingredient
    ///
    /// - Parameters:
    ///   - name: Display name of ingredient (e.g., "Milk")
    ///   - category: Category assignment (e.g., "Dairy & Fridge")
    ///   - isStaple: Whether this is a staple item
    /// - Returns: Existing template if found, or newly created template
    /// - Throws: Core Data errors during fetch or save
    func findOrCreate(
        name: String,
        category: String?,
        isStaple: Bool
    ) throws -> IngredientTemplate {
        // Query using semantic uniqueness (canonicalName)
        let canonicalName = IngredientTemplate.canonicalName(from: name)
        
        if let existing = try findByCanonicalName(canonicalName) {
            #if DEBUG
            print("ℹ️ M7.2.3: Template '\(name)' already exists (canonical: '\(canonicalName)')")
            #endif
            
            // Update category if provided and different
            if let newCategory = category, newCategory != existing.category {
                existing.category = newCategory
                existing.updatedAt = Date()
                #if DEBUG
                print("   Updated category: '\(existing.category ?? "nil")' → '\(newCategory)'")
                #endif
            }
            
            // Update staple status if different
            if isStaple != existing.isStaple {
                existing.isStaple = isStaple
                existing.updatedAt = Date()
                #if DEBUG
                print("   Updated staple status: \(isStaple)")
                #endif
            }
            
            return existing
        }
        
        // Create new template
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.canonicalName = canonicalName
        template.category = category
        template.isStaple = isStaple
        template.usageCount = 0
        template.dateCreated = Date()
        template.updatedAt = Date()
        
        #if DEBUG
        print("✅ M7.2.3: Created template '\(name)' (canonical: '\(canonicalName)')")
        #endif
        
        return template
    }
    
    /// M7.2.3: Check if ingredient template exists using semantic uniqueness
    ///
    /// - Parameter name: Display name of ingredient
    /// - Returns: True if template exists, false otherwise
    /// - Throws: Core Data errors during fetch
    func exists(name: String) throws -> Bool {
        let canonicalName = IngredientTemplate.canonicalName(from: name)
        let template = try findByCanonicalName(canonicalName)
        return template != nil
    }
    
    /// M7.2.3: Find ingredient template by display name using semantic uniqueness
    ///
    /// - Parameter name: Display name of ingredient
    /// - Returns: Template if found, nil otherwise
    /// - Throws: Core Data errors during fetch
    func findByName(_ name: String) throws -> IngredientTemplate? {
        let canonicalName = IngredientTemplate.canonicalName(from: name)
        return try findByCanonicalName(canonicalName)
    }
    
    /// M7.2.3: Get all ingredient templates sorted by name
    ///
    /// - Returns: Array of all templates
    /// - Throws: Core Data errors during fetch
    func findAll() throws -> [IngredientTemplate] {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)]
        
        return try context.fetch(request)
    }
    
    /// M7.2.3: Get all staple templates
    ///
    /// - Returns: Array of staple templates
    /// - Throws: Core Data errors during fetch
    func findAllStaples() throws -> [IngredientTemplate] {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isStaple == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)]
        
        return try context.fetch(request)
    }
    
    /// M7.2.3: Get templates by category
    ///
    /// - Parameter category: Category name
    /// - Returns: Array of templates in category
    /// - Throws: Core Data errors during fetch
    func findByCategory(_ category: String) throws -> [IngredientTemplate] {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "category ==[c] %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)]
        
        return try context.fetch(request)
    }
    
    // MARK: - Private Helper Methods
    
    /// Find template by canonical name (semantic uniqueness key)
    private func findByCanonicalName(_ canonicalName: String) throws -> IngredientTemplate? {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "canonicalName ==[c] %@", canonicalName)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
}
