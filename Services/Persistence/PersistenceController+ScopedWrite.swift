//
//  PersistenceController+ScopedWrite.swift
//  forager
//
//  M7.2.3 Phase 2.6: Background factory pattern with automatic save
//  Created on January 3, 2026
//
//  Provides ergonomic helper for background writes with factory support.
//  Prevents "save fatigue" and repetitive boilerplate code.
//
//  Implementation from ChatGPT + Gemini feedback.
//

import Foundation
import CoreData

// MARK: - Scoped Write Helper

extension PersistenceController {
    
    /// M7.2.3 Phase 2.6: Perform background write with factory support
    ///
    /// ## Purpose
    /// Eliminates repetitive boilerplate for background operations:
    /// - Creates background context automatically
    /// - Provides factory with explicit scope
    /// - Handles save + error handling
    /// - Prevents "save fatigue" (ChatGPT feedback)
    ///
    /// ## Usage
    /// ```swift
    /// let scope = DataScope.household(id: householdID, storeID: .shared)
    ///
    /// persistence.performScopedWrite(scope: scope) { context, factory in
    ///     _ = try factory.make(Category.self, in: scope) { category in
    ///         category.id = UUID()
    ///         category.name = "Produce"
    ///     }
    /// }
    /// // Automatically saves, rolls back on error
    /// ```
    ///
    /// ## Parameters
    /// - scope: DataScope for this write operation
    /// - block: Work block with context + factory
    ///
    /// ## Threading
    /// - Always runs on background thread (via performBackgroundTask)
    /// - Factory created with background context
    /// - scopeProvider = nil (explicit scope used instead)
    ///
    /// Source: ChatGPT - "wrap Option A inside a lightweight version of Option B"
    func performScopedWrite(
        scope: DataScope,
        block: @escaping (NSManagedObjectContext, ManagedObjectFactory) throws -> Void
    ) {
        container.performBackgroundTask { bgContext in
            // Create factory for background context (no scopeProvider needed)
            let factory = ManagedObjectFactory(
                context: bgContext,
                scopeProvider: nil,  // ← Background doesn't use provider
                persistence: self
            )
            
            do {
                // Execute work block
                try block(bgContext, factory)
                
                // Save if changes were made
                if bgContext.hasChanges {
                    try bgContext.save()
                    
                    #if DEBUG
                    let insertedCount = bgContext.insertedObjects.count
                    let updatedCount = bgContext.updatedObjects.count
                    print("✅ M7.2.3 ScopedWrite: Saved \(insertedCount) inserted, \(updatedCount) updated")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ M7.2.3 ScopedWrite Failed: \(error)")
                #endif
                
                // Rollback on error
                bgContext.rollback()
            }
        }
    }
}
