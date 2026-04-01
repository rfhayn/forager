//
//  IngredientTemplate+CoreDataProperties.swift
//  forager
//
//  M7.2.3 Phase 2.5: Added household and householdKey properties
//  Created on January 2, 2026
//

import Foundation
import CoreData

extension IngredientTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<IngredientTemplate> {
        return NSFetchRequest<IngredientTemplate>(entityName: "IngredientTemplate")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var canonicalName: String?
    @NSManaged public var category: String?
    @NSManaged public var usageCount: Int32
    @NSManaged public var dateCreated: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isStaple: Bool
    @NSManaged public var categoryEntity: Category?
    @NSManaged public var household: Household?
    @NSManaged public var householdKey: String?
    @NSManaged public var preferredStore: Store?
    @NSManaged public var ingredients: NSSet?
}

// MARK: Generated accessors for ingredients
extension IngredientTemplate {

    @objc(addIngredientsObject:)
    @NSManaged public func addToIngredients(_ value: Ingredient)

    @objc(removeIngredientsObject:)
    @NSManaged public func removeFromIngredients(_ value: Ingredient)

    @objc(addIngredients:)
    @NSManaged public func addToIngredients(_ values: NSSet)

    @objc(removeIngredients:)
    @NSManaged public func removeFromIngredients(_ values: NSSet)
}

extension IngredientTemplate: Identifiable {
}
