//
//  IngredientTemplate+Extensions.swift
//  forager
//
//  Created by Richard Hayn on 12/18/25.
//

import Foundation
import CoreData

extension IngredientTemplate {
    
    // MARK: - M7.2.3 Phase 4.3: Household Auto-Assignment
    
    /// Automatically assigns new ingredient templates to existing household
    /// Called when a new IngredientTemplate entity is inserted into the context
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // M7.2.3 Phase 4.3: Auto-assign to household if one exists
        if household == nil, let context = managedObjectContext {
            let fetchRequest: NSFetchRequest<Household> = Household.fetchRequest()
            fetchRequest.fetchLimit = 1
            
            if let existingHousehold = try? context.fetch(fetchRequest).first {
                household = existingHousehold
                householdKey = existingHousehold.id?.uuidString
                print("🏠 M7.2.3 Phase 4.3: Auto-assigned IngredientTemplate '\(name ?? "untitled")' to household '\(existingHousehold.name ?? "unknown")'")
            }
        }
    }
    
    // MARK: - M7.1.3 Semantic Key Helpers
    
    /// Generates canonical ingredient name for semantic uniqueness
    /// - Parameter name: The display name of the ingredient
    /// - Returns: Lowercase, trimmed version of the name
    static func canonicalName(from name: String) -> String {
        return name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
