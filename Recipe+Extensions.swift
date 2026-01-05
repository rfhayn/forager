//
//  Recipe+Extensions.swift
//  forager
//
//  Created by Richard Hayn on 12/18/25.
//

import Foundation
import CoreData

extension Recipe {
    
    // MARK: - M7.1.3 Semantic Key Helpers
    
    /// Generates title key for duplicate detection (not prevention)
    /// Note: Recipes allow duplicates - this is only for warning users
    /// - Parameter title: The recipe title
    /// - Returns: Lowercase, trimmed version of the title
    static func titleKey(from title: String) -> String {
        return title
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
