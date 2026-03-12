//
//  HouseholdCategoryRepository.swift
//  forager
//
//  M7.2.3 Phase 2.1: Household-scoped category repository
//  Single responsibility: Semantic uniqueness for categories in shared household zone
//
//  Created on December 31, 2025.
//

import CoreData
import Foundation

/// M7.2.3 Phase 2.1: Household-scoped category repository
///
/// Responsibilities:
/// - Prevent duplicate categories in household shared zone
/// - Query-before-create using normalizedName (semantic uniqueness)
/// - Idempotent operations (safe to call multiple times)
/// - Clear console logging for debugging
///
/// Pattern: Always query by normalized name before creating
final class HouseholdCategoryRepository {
    
    private let context: NSManagedObjectContext

    // M9.13: Optional factory for correct store assignment (ADR 014)
    private(set) var factory: ManagedObjectFactory?

    // MARK: - Initialization

    init(context: NSManagedObjectContext, factory: ManagedObjectFactory? = nil) {
        self.context = context
        self.factory = factory
    }
    
    // MARK: - Public Repository Methods
    
    /// M7.2.3: Find or create category using semantic uniqueness
    /// Prevents duplicate categories when multiple household members create same category
    ///
    /// - Parameters:
    ///   - name: Display name of category (e.g., "Produce")
    ///   - color: Color hex string (e.g., "#4CAF50")
    ///   - sortOrder: Display sort order
    ///   - isDefault: Whether this is a default category
    /// - Returns: Existing category if found, or newly created category
    /// - Throws: Core Data errors during fetch or save
    func findOrCreate(
        name: String,
        color: String,
        sortOrder: Int16,
        isDefault: Bool
    ) throws -> Category {
        // Query using semantic uniqueness (normalizedName)
        let normalizedName = Category.normalizedName(from: name)
        
        if let existing = try findByNormalizedName(normalizedName) {
            #if DEBUG
            print("ℹ️ M7.2.3: Category '\(name)' already exists (normalized: '\(normalizedName)')")
            #endif
            return existing
        }
        
        // M9.13: Use factory when available for correct store assignment (ADR 014)
        let category: Category
        if let factory = factory {
            category = try factory.make(Category.self, configure: { c in
                c.id = UUID()
                c.name = name
                c.normalizedName = normalizedName
                c.color = color
                c.sortOrder = sortOrder
                c.isDefault = isDefault
                c.dateCreated = Date()
                c.updatedAt = Date()
            })
        } else {
            category = Category(context: context)
            category.id = UUID()
            category.name = name
            category.normalizedName = normalizedName
            category.color = color
            category.sortOrder = sortOrder
            category.isDefault = isDefault
            category.dateCreated = Date()
            category.updatedAt = Date()
        }
        
        #if DEBUG
        print("✅ M7.2.3: Created category '\(name)' (normalized: '\(normalizedName)')")
        #endif
        
        return category
    }
    
    /// M7.2.3: Check if category exists using semantic uniqueness
    ///
    /// - Parameter name: Display name of category
    /// - Returns: True if category exists, false otherwise
    /// - Throws: Core Data errors during fetch
    func exists(name: String) throws -> Bool {
        let normalizedName = Category.normalizedName(from: name)
        let category = try findByNormalizedName(normalizedName)
        return category != nil
    }
    
    /// M7.2.3: Find category by display name using semantic uniqueness
    ///
    /// - Parameter name: Display name of category
    /// - Returns: Category if found, nil otherwise
    /// - Throws: Core Data errors during fetch
    func findByName(_ name: String) throws -> Category? {
        let normalizedName = Category.normalizedName(from: name)
        return try findByNormalizedName(normalizedName)
    }
    
    /// M7.2.3: Get all categories sorted by sortOrder
    ///
    /// - Returns: Array of all categories
    /// - Throws: Core Data errors during fetch
    func findAll() throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        
        return try context.fetch(request)
    }
    
    // MARK: - Private Helper Methods
    
    /// Find category by normalized name (semantic uniqueness key)
    private func findByNormalizedName(_ normalizedName: String) throws -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "normalizedName ==[c] %@", normalizedName)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
}
