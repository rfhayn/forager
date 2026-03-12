//
//  IngredientTemplateRepository.swift
//  forager
//
//  Created for M7.1.3 Phase 1.2
//  Repository pattern to prevent duplicate IngredientTemplate creation across devices
//

import Foundation
import CoreData

/// Repository for managing IngredientTemplate entities with semantic uniqueness
///
/// This is the ONLY way templates should be created in the app.
/// Prevents CloudKit from creating duplicate templates across devices.
///
/// Usage:
/// ```swift
/// let template = IngredientTemplateRepository.getOrCreate(displayName: "basil", in: context)
/// ```
struct IngredientTemplateRepository {
    
    // MARK: - Get or Create
    
    /// Get existing template by canonical name, or create new one
    ///
    /// This method enforces semantic uniqueness: "Basil", "basil", and "BASIL"
    /// all return the same IngredientTemplate object.
    ///
    /// - Parameters:
    ///   - displayName: User-facing ingredient name (e.g., "Basil")
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Existing or newly created IngredientTemplate
    /// M9.13: Optional factory parameter for correct store assignment (ADR 014)
    static func getOrCreate(displayName: String, in context: NSManagedObjectContext, factory: ManagedObjectFactory? = nil) -> IngredientTemplate {
        let canonical = IngredientTemplate.canonicalName(from: displayName)

        // Query by semantic key first
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "canonicalName == %@", canonical)
        request.fetchLimit = 1

        // Return existing if found
        if let existing = try? context.fetch(request).first {
            #if DEBUG
            print("📦 IngredientTemplateRepository: Found existing '\(displayName)' (canonical: '\(canonical)')")
            #endif
            return existing
        }

        // Create new if doesn't exist
        #if DEBUG
        print("✨ IngredientTemplateRepository: Creating new '\(displayName)' (canonical: '\(canonical)')")
        #endif
        // M9.13: Use factory when available for correct store assignment (ADR 014)
        if let factory = factory {
            do {
                return try factory.make(IngredientTemplate.self, configure: { t in
                    t.name = displayName
                    t.canonicalName = canonical
                    t.dateCreated = Date()
                    t.updatedAt = Date()
                })
            } catch {
                #if DEBUG
                print("⚠️ Factory error creating IngredientTemplate: \(error)")
                #endif
            }
        }

        let template = IngredientTemplate(context: context)
        template.name = displayName
        template.canonicalName = canonical
        template.dateCreated = Date()
        template.updatedAt = Date()

        return template
    }
    
    // MARK: - Query Helpers
    
    /// Find template by exact canonical name
    /// - Parameters:
    ///   - canonicalName: Canonical ingredient name to search for
    ///   - context: NSManagedObjectContext to use
    /// - Returns: IngredientTemplate if found, nil otherwise
    static func find(byCanonicalName canonicalName: String, in context: NSManagedObjectContext) -> IngredientTemplate? {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "canonicalName == %@", canonicalName)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Find template by display name (uses canonicalization)
    /// - Parameters:
    ///   - displayName: Display name to search for
    ///   - context: NSManagedObjectContext to use
    /// - Returns: IngredientTemplate if found, nil otherwise
    static func find(byDisplayName displayName: String, in context: NSManagedObjectContext) -> IngredientTemplate? {
        let canonical = IngredientTemplate.canonicalName(from: displayName)
        return find(byCanonicalName: canonical, in: context)
    }
}
