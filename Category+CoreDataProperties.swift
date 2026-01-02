//
//  Category+CoreDataProperties.swift
//  forager
//
//  Created by Rich Hayn on 8/20/25.
//
//

import Foundation
import CoreData

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var isDefault: Bool
    @NSManaged public var dateCreated: Date?
    @NSManaged public var normalizedName: String?  // M7.1.3: Semantic key for uniqueness
    @NSManaged public var updatedAt: Date?        // M7.1.3: Conflict resolution
    @NSManaged public var household: Household?
    @NSManaged public var householdKey: String?
    @NSManaged public var groceryItems: NSSet?
}

// MARK: - Generated accessors for groceryItems
extension Category {

    @objc(addGroceryItemsObject:)
    @NSManaged public func addToGroceryItems(_ value: GroceryItem)

    @objc(removeGroceryItemsObject:)
    @NSManaged public func removeFromGroceryItems(_ value: GroceryItem)

    @objc(addGroceryItems:)
    @NSManaged public func addToGroceryItems(_ values: NSSet)

    @objc(removeGroceryItems:)
    @NSManaged public func removeFromGroceryItems(_ values: NSSet)
}

extension Category: Identifiable {
}

// MARK: - Convenience Methods
extension Category {
    var displayName: String {
        return name ?? "Unknown Category"
    }
    
    var displayColor: String {
        return color ?? "#757575"
    }
    
    var groceryItemsArray: [GroceryItem] {
        let set = groceryItems as? Set<GroceryItem> ?? []
        return set.sorted {
            ($0.name ?? "") < ($1.name ?? "")
        }
    }
}
