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

    static let dayAbbreviation: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static let fullDayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d"
        return formatter
    }()

    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - IngredientTemplate Migration Support (Legacy - May be removed in future)

extension IngredientTemplate {
    
    /// Safely toggles staple status with error handling
    func toggleStapleStatus() -> Bool {
        guard let context = managedObjectContext else {
            #if DEBUG
            print("❌ Cannot toggle staple status - no managed object context")
            #endif
            return false
        }
        
        isStaple.toggle()
        
        do {
            if context.hasChanges {
                try context.save()
                #if DEBUG
                print("✅ Staple status updated for: \(name ?? "Unknown")")
                #endif
                return true
            }
            return true // No changes needed
        } catch {
            #if DEBUG
            print("❌ Failed to save staple status change: \(error)")
            #endif
            isStaple.toggle() // Revert the change
            return false
        }
    }

    /// Updates category assignment with validation
    func assignCategory(_ newCategory: String?) -> Bool {
        guard let context = managedObjectContext else {
            #if DEBUG
            print("❌ Cannot assign category - no managed object context")
            #endif
            return false
        }
        
        let oldCategory = category
        category = newCategory
        
        do {
            if context.hasChanges {
                try context.save()
                #if DEBUG
                print("✅ Category updated for \(name ?? "Unknown"): \(oldCategory ?? "None") → \(newCategory ?? "None")")
                #endif
                return true
            }
            return true // No changes needed
        } catch {
            #if DEBUG
            print("❌ Failed to save category assignment: \(error)")
            #endif
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
                #if DEBUG
                print("✅ Uncategorized category moved to position \(sortOrder)")
                #endif
            }
            
        } catch {
            #if DEBUG
            print("❌ Error updating sort order for Uncategorized: \(error)")
            #endif
        }
    }
}
