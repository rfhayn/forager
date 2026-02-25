//
//  GroceryItem+CoreDataClass.swift
//  forager
//
//  Created by Rich Hayn on 8/18/25.
//
//

import Foundation
import CoreData

@objc(GroceryItem)
public class GroceryItem: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Returns the effective category for this grocery item
    /// Priority: categoryEntity.name > category string > "Uncategorized"
    public var effectiveCategory: String {
        // First try the Category relationship
        if let categoryEntity = categoryEntity,
           let categoryName = categoryEntity.name {
            return categoryName
        }
        
        // Fall back to the category string
        if let category = category,
           !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return category
        }
        
        // Default to Uncategorized
        return "Uncategorized"
    }
}
