//
//  Persistence.swift
//  forager
//
//  M7.2.3 Phase 3.6: LEGACY FILE - Most code moved to Services/Persistence/
//  
//  This file now contains ONLY:
//  - DateFormatter extensions (used throughout app)
//  - Legacy migration extensions (kept for backward compatibility)
//
//  Core Data container management moved to: Services/Persistence/PersistenceController.swift
//  Default seeding moved to: Services/Persistence/DefaultSeeder.swift
//  CloudKit diagnostics moved to: Services/Persistence/CloudKitDiagnostics.swift
//

import CoreData
import CloudKit

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - IngredientTemplate Migration Support (Legacy - May be removed in future)

extension IngredientTemplate {
    
    /// Safely toggles staple status with error handling
    func toggleStapleStatus() -> Bool {
        guard let context = managedObjectContext else {
            print("❌ Cannot toggle staple status - no managed object context")
            return false
        }
        
        isStaple.toggle()
        
        do {
            if context.hasChanges {
                try context.save()
                print("✅ Staple status updated for: \(name ?? "Unknown")")
                return true
            }
            return true // No changes needed
        } catch {
            print("❌ Failed to save staple status change: \(error)")
            isStaple.toggle() // Revert the change
            return false
        }
    }

    /// Updates category assignment with validation
    func assignCategory(_ newCategory: String?) -> Bool {
        guard let context = managedObjectContext else {
            print("❌ Cannot assign category - no managed object context")
            return false
        }
        
        let oldCategory = category
        category = newCategory
        
        do {
            if context.hasChanges {
                try context.save()
                print("✅ Category updated for \(name ?? "Unknown"): \(oldCategory ?? "None") → \(newCategory ?? "None")")
                return true
            }
            return true // No changes needed
        } catch {
            print("❌ Failed to save category assignment: \(error)")
            category = oldCategory // Revert the change
            return false
        }
    }
}

// MARK: - Category Extensions (Legacy - May be removed in future)

extension Category {
    
    /// Ensures Uncategorized category always appears last in sort order
    static func updateSortOrderForUncategorized(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        
        do {
            let categories = try context.fetch(request)
            var sortOrder: Int16 = 0
            
            // Assign sort orders, skipping Uncategorized
            for category in categories {
                if category.displayName.lowercased() != "uncategorized" {
                    category.sortOrder = sortOrder
                    sortOrder += 1
                }
            }
            
            // Always put Uncategorized last
            if let uncategorized = categories.first(where: { $0.displayName.lowercased() == "uncategorized" }) {
                uncategorized.sortOrder = sortOrder
                print("✅ Uncategorized category moved to position \(sortOrder)")
            }
            
        } catch {
            print("❌ Error updating sort order for Uncategorized: \(error)")
        }
    }
}
