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
    ///   - category: Category entity assignment (M9.12: relationship replaces string)
    ///   - isStaple: Whether this is a staple item
    /// - Returns: Existing template if found, or newly created template
    /// - Throws: Core Data errors during fetch or save
    func findOrCreate(
        name: String,
        category: Category?,
        isStaple: Bool,
        householdKey: String? = nil
    ) throws -> IngredientTemplate {
        // Query using semantic uniqueness (canonicalName)
        let canonicalName = IngredientTemplate.canonicalName(from: name)
        
        // M10.6.18: Scope lookup by householdKey (ADR 013) — prevents ghost templates
        // from previous households being reused when user is in personal scope
        if let existing = try findByCanonicalName(canonicalName, householdKey: householdKey) {
            Task { @MainActor in
                DebugLogService.shared.log("findOrCreate: canonical=\(canonicalName), found existing=yes, householdKey param=\(householdKey ?? "nil")", category: "Repo")
                DebugLogService.shared.log("existing template: householdKey=\(existing.householdKey ?? "nil"), category=\(existing.categoryEntity?.name ?? "nil")", category: "Repo")
            }
            #if DEBUG
            print("ℹ️ M7.2.3: Template '\(name)' already exists (canonical: '\(canonicalName)')")
            #endif

            // M9.12: Update categoryEntity if provided and different
            if let newCategory = category, newCategory !== existing.categoryEntity {
                existing.categoryEntity = newCategory
                existing.updatedAt = Date()
                #if DEBUG
                print("   Updated category: '\(existing.categoryEntity?.name ?? "nil")' → '\(newCategory.name ?? "nil")'")
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

            // M10.6.13: Ensure found templates have correct householdKey
            if let key = householdKey, existing.householdKey != key {
                existing.householdKey = key
                existing.updatedAt = Date()
            }

            return existing
        }
        
        // Create new template
        Task { @MainActor in DebugLogService.shared.log("findOrCreate: canonical=\(canonicalName), found existing=no, creating new, householdKey param=\(householdKey ?? "nil")", category: "Repo") }
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.canonicalName = canonicalName
        template.categoryEntity = category
        template.isStaple = isStaple
        template.usageCount = 0
        template.dateCreated = Date()
        template.updatedAt = Date()
        // M10.6.11: Scope to current household so IngredientsView filter sees it
        template.householdKey = householdKey

        Task { @MainActor in DebugLogService.shared.log("template created: name=\(name), householdKey=\(householdKey ?? "nil"), usageCount=0", category: "Import") }
        #if DEBUG
        print("✅ M7.2.3: Created template '\(name)' (canonical: '\(canonicalName)', householdKey: \(householdKey ?? "nil"))")
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
    /// M9.12: Find templates by Category entity relationship
    func findByCategory(_ category: Category) throws -> [IngredientTemplate] {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "categoryEntity == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)]

        return try context.fetch(request)
    }
    
    // MARK: - Private Helper Methods
    
    /// Find template by canonical name, scoped to householdKey (ADR 013).
    /// M10.6.18: Without householdKey scoping, ghost templates from previous households
    /// are found and reused, making new templates invisible in personal scope.
    private func findByCanonicalName(_ canonicalName: String, householdKey: String? = nil) throws -> IngredientTemplate? {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        if let key = householdKey {
            request.predicate = NSPredicate(format: "canonicalName ==[c] %@ AND householdKey == %@", canonicalName, key)
        } else {
            request.predicate = NSPredicate(format: "canonicalName ==[c] %@ AND householdKey == nil", canonicalName)
        }
        request.fetchLimit = 1

        return try context.fetch(request).first
    }
}
