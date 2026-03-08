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
    
    /// M10.6.17: awakeFromInsert no longer auto-assigns household (ADR 013).
    /// Callers (DefaultSeeder, ManagedObjectFactory) set household + householdKey explicitly.
    public override func awakeFromInsert() {
        super.awakeFromInsert()
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
