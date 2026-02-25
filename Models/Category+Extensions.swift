//
//  Category+Extensions.swift
//  forager
//
//  Created by Richard Hayn on 12/18/25.
//

import Foundation
import CoreData

extension Category {
    
    // MARK: - M7.2.3 Phase 4.3: Household Auto-Assignment
    
    /// Automatically assigns new categories to existing household
    /// Called when a new Category entity is inserted into the context
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // M7.2.3 Phase 4.3: Auto-assign to household if one exists
        if household == nil, let context = managedObjectContext {
            let fetchRequest: NSFetchRequest<Household> = Household.fetchRequest()
            fetchRequest.fetchLimit = 1
            
            if let existingHousehold = try? context.fetch(fetchRequest).first {
                household = existingHousehold
                householdKey = existingHousehold.id?.uuidString
                #if DEBUG
                print("🏠 M7.2.3 Phase 4.3: Auto-assigned Category '\(name ?? "untitled")' to household '\(existingHousehold.name ?? "unknown")'")
                #endif
            }
        }
    }
    
    // MARK: - M7.1.3 Semantic Key Helpers
    
    /// Generates normalized category name for semantic uniqueness
    /// - Parameter name: The display name of the category
    /// - Returns: Lowercase, trimmed version of the name
    static func normalizedName(from name: String) -> String {
        return name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
