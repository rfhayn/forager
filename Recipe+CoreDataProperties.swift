//
//  Recipe+CoreDataProperties.swift
//  forager
//
//  Created by Richard Hayn on 11/13/25.
//
//

public import Foundation
public import CoreData


public typealias RecipeCoreDataPropertiesSet = NSSet

extension Recipe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
        return NSFetchRequest<Recipe>(entityName: "Recipe")
    }

    @NSManaged public var cookTime: Int16
    @NSManaged public var dateCreated: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var instructions: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var lastUsed: Date?
    @NSManaged public var prepTime: Int16
    @NSManaged public var servings: Int16
    @NSManaged public var sourceURL: String?
    @NSManaged public var title: String?
    @NSManaged public var usageCount: Int32
    @NSManaged public var household: Household?
    @NSManaged public var householdKey: String?
    @NSManaged public var groceryListItems: NSSet?
    @NSManaged public var ingredients: NSSet?
    @NSManaged public var plannedMeals: NSSet?

}

// MARK: Generated accessors for plannedMeals
extension Recipe {

    @objc(addPlannedMealsObject:)
    @NSManaged public func addToPlannedMeals(_ value: PlannedMeal)

    @objc(removePlannedMealsObject:)
    @NSManaged public func removeFromPlannedMeals(_ value: PlannedMeal)

    @objc(addPlannedMeals:)
    @NSManaged public func addToPlannedMeals(_ values: NSSet)

    @objc(removePlannedMeals:)
    @NSManaged public func removeFromPlannedMeals(_ values: NSSet)

}

// MARK: Generated accessors for groceryListItems
extension Recipe {

    @objc(addGroceryListItemsObject:)
    @NSManaged public func addToGroceryListItems(_ value: GroceryListItem)

    @objc(removeGroceryListItemsObject:)
    @NSManaged public func removeFromGroceryListItems(_ value: GroceryListItem)

    @objc(addGroceryListItems:)
    @NSManaged public func addToGroceryListItems(_ values: NSSet)

    @objc(removeGroceryListItems:)
    @NSManaged public func removeFromGroceryListItems(_ values: NSSet)

}

// MARK: Generated accessors for ingredients
extension Recipe {

    @objc(addIngredientsObject:)
    @NSManaged public func addToIngredients(_ value: Ingredient)

    @objc(removeIngredientsObject:)
    @NSManaged public func removeFromIngredients(_ value: Ingredient)

    @objc(addIngredients:)
    @NSManaged public func addToIngredients(_ values: NSSet)

    @objc(removeIngredients:)
    @NSManaged public func removeFromIngredients(_ values: NSSet)

}

extension Recipe : Identifiable {

}
