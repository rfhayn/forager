//
//  StoreIdentityLogger.swift
//  forager
//
//  M7.2.3 Prep Phase: Store Identity Logging Utility
//  Created on January 2, 2026
//
//  DEBUG-only utility for identifying which CloudKit store (Private/Shared)
//  a managed object belongs to. Essential for debugging Phase 4's
//  "attach-then-share" migration pattern.
//

import Foundation
import CoreData

#if DEBUG

extension NSManagedObject {
    
    // MARK: - M7.2.3: Store Identity Logging
    
    /// Logs which CloudKit store this managed object belongs to
    /// Prints: "EntityName [objectID] → Private Store" or "→ Shared Store"
    /// Used during Phase 4 migration debugging to confirm objects moved correctly
    func logStoreIdentity() {
        guard let persistentStore = self.objectID.persistentStore else {
            print("⚠️ \(type(of: self)) [\(objectID)] → No persistent store found")
            return
        }
        
        let storeName = identifyStore(persistentStore)
        let emoji = storeName.contains("Private") ? "🔒" : storeName.contains("Shared") ? "👥" : "❓"
        
        print("\(emoji) \(type(of: self)) [\(objectID)] → \(storeName)")
    }
    
    /// Identifies the store type from a persistent store
    /// Returns: "Private Store", "Shared Store", or "Unknown Store"
    private func identifyStore(_ store: NSPersistentStore) -> String {
        // Check store configuration name
        if let configurationName = store.configurationName {
            if configurationName.contains("Private") {
                return "Private Store"
            } else if configurationName.contains("Shared") {
                return "Shared Store"
            }
        }
        
        // Check store URL for clues
        if let url = store.url?.absoluteString {
            if url.contains("private") || url.contains("Private") {
                return "Private Store"
            } else if url.contains("shared") || url.contains("Shared") {
                return "Shared Store"
            }
        }
        
        // Fallback: Check store type
        if store.type == NSSQLiteStoreType {
            return "SQLite Store (Unknown Scope)"
        } else if store.type == NSInMemoryStoreType {
            return "In-Memory Store"
        }
        
        return "Unknown Store"
    }
}

#endif
