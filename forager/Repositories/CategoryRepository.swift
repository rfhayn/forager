//
//  CategoryRepository.swift
//  forager
//
//  Created for M7.1.3 Phase 1.2
//  Repository pattern to prevent duplicate Category creation across devices
//

import Foundation
import CoreData

/// Repository for managing Category entities with semantic uniqueness
/// 
/// This is the ONLY way categories should be created in the app.
/// Prevents CloudKit from creating duplicate categories across devices.
///
/// Usage:
/// ```swift
/// let category = CategoryRepository.getOrCreate(displayName: "Produce", in: context)
/// ```
struct CategoryRepository {
    
    // MARK: - Get or Create
    
    /// Get existing category by normalized name, or create new one
    ///
    /// This method enforces semantic uniqueness: "Produce", "produce", and "PRODUCE"
    /// all return the same Category object.
    ///
    /// - Parameters:
    ///   - displayName: User-facing category name (e.g., "Produce")
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Existing or newly created Category
    static func getOrCreate(displayName: String, in context: NSManagedObjectContext) -> Category {
        let normalized = Category.normalizedName(from: displayName)
        
        // Query by semantic key first
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "normalizedName == %@", normalized)
        request.fetchLimit = 1
        
        // Return existing if found
        if let existing = try? context.fetch(request).first {
            #if DEBUG
            print("📦 CategoryRepository: Found existing '\(displayName)' (normalized: '\(normalized)')")
            #endif
            return existing
        }
        
        // Create new if doesn't exist
        #if DEBUG
        print("✨ CategoryRepository: Creating new '\(displayName)' (normalized: '\(normalized)')")
        #endif
        let category = Category(context: context)
        category.name = displayName
        category.normalizedName = normalized
        category.updatedAt = Date()
        
        return category
    }
    
    // MARK: - Query Helpers
    
    /// Find category by exact normalized name
    /// - Parameters:
    ///   - normalizedName: Normalized category name to search for
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Category if found, nil otherwise
    static func find(byNormalizedName normalizedName: String, in context: NSManagedObjectContext) -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "normalizedName == %@", normalizedName)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Find category by display name (uses normalization)
    /// - Parameters:
    ///   - displayName: Display name to search for
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Category if found, nil otherwise
    static func find(byDisplayName displayName: String, in context: NSManagedObjectContext) -> Category? {
        let normalized = Category.normalizedName(from: displayName)
        return find(byNormalizedName: normalized, in: context)
    }
}
