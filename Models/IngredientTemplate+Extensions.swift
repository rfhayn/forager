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

        // M10.6.17: Household assignment removed from awakeFromInsert (ADR 013).
        // Callers (IngredientTemplateService, ManagedObjectFactory) set household +
        // householdKey explicitly. The unscoped fetch here found ghost Household
        // entities from previous memberships, causing invisible templates.
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
