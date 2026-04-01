//
//  Store+CoreDataProperties.swift
//  forager
//
//  M18.1.0: Store entity properties for store-aware shopping
//

import Foundation
import CoreData

extension Store {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Store> {
        return NSFetchRequest<Store>(entityName: "Store")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var householdKey: String?
    @NSManaged public var household: Household?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var ingredientTemplates: NSSet?
    @NSManaged public var groceryListItems: NSSet?
}

// MARK: Generated accessors for ingredientTemplates
extension Store {

    @objc(addIngredientTemplatesObject:)
    @NSManaged public func addToIngredientTemplates(_ value: IngredientTemplate)

    @objc(removeIngredientTemplatesObject:)
    @NSManaged public func removeFromIngredientTemplates(_ value: IngredientTemplate)

    @objc(addIngredientTemplates:)
    @NSManaged public func addToIngredientTemplates(_ values: NSSet)

    @objc(removeIngredientTemplates:)
    @NSManaged public func removeFromIngredientTemplates(_ values: NSSet)
}

// MARK: Generated accessors for groceryListItems
extension Store {

    @objc(addGroceryListItemsObject:)
    @NSManaged public func addToGroceryListItems(_ value: GroceryListItem)

    @objc(removeGroceryListItemsObject:)
    @NSManaged public func removeFromGroceryListItems(_ value: GroceryListItem)

    @objc(addGroceryListItems:)
    @NSManaged public func addToGroceryListItems(_ values: NSSet)

    @objc(removeGroceryListItems:)
    @NSManaged public func removeFromGroceryListItems(_ values: NSSet)
}

extension Store: Identifiable {
}
