//
//  Household+CoreDataProperties.swift
//  forager
//
//  M7.2.3 Phase 2.5: Manual property file to avoid codegen conflicts
//  Created on January 2, 2026
//

import Foundation
import CoreData

extension Household {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Household> {
        return NSFetchRequest<Household>(entityName: "Household")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var ownerEmail: String?      // Repurposed M7.6.8: stores owner display name (was redundant copy of ownerRecordName)
    @NSManaged public var ownerRecordName: String?
    @NSManaged public var shareRecord: Data?
    @NSManaged public var members: NSSet?
    @NSManaged public var categories: NSSet?
    @NSManaged public var ingredientTemplates: NSSet?
    @NSManaged public var mealPlans: NSSet?
    @NSManaged public var plannedMeals: NSSet?
    @NSManaged public var recipes: NSSet?
    @NSManaged public var weeklyLists: NSSet?
}

// MARK: Generated accessors for members
extension Household {

    @objc(addMembersObject:)
    @NSManaged public func addToMembers(_ value: HouseholdMember)

    @objc(removeMembersObject:)
    @NSManaged public func removeFromMembers(_ value: HouseholdMember)

    @objc(addMembers:)
    @NSManaged public func addToMembers(_ values: NSSet)

    @objc(removeMembers:)
    @NSManaged public func removeFromMembers(_ values: NSSet)
}

// MARK: Generated accessors for categories
extension Household {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)
}

// MARK: Generated accessors for ingredientTemplates
extension Household {

    @objc(addIngredientTemplatesObject:)
    @NSManaged public func addToIngredientTemplates(_ value: IngredientTemplate)

    @objc(removeIngredientTemplatesObject:)
    @NSManaged public func removeFromIngredientTemplates(_ value: IngredientTemplate)

    @objc(addIngredientTemplates:)
    @NSManaged public func addToIngredientTemplates(_ values: NSSet)

    @objc(removeIngredientTemplates:)
    @NSManaged public func removeFromIngredientTemplates(_ values: NSSet)
}

// MARK: Generated accessors for mealPlans
extension Household {

    @objc(addMealPlansObject:)
    @NSManaged public func addToMealPlans(_ value: MealPlan)

    @objc(removeMealPlansObject:)
    @NSManaged public func removeFromMealPlans(_ value: MealPlan)

    @objc(addMealPlans:)
    @NSManaged public func addToMealPlans(_ values: NSSet)

    @objc(removeMealPlans:)
    @NSManaged public func removeFromMealPlans(_ values: NSSet)
}

// MARK: Generated accessors for plannedMeals
extension Household {

    @objc(addPlannedMealsObject:)
    @NSManaged public func addToPlannedMeals(_ value: PlannedMeal)

    @objc(removePlannedMealsObject:)
    @NSManaged public func removeFromPlannedMeals(_ value: PlannedMeal)

    @objc(addPlannedMeals:)
    @NSManaged public func addToPlannedMeals(_ values: NSSet)

    @objc(removePlannedMeals:)
    @NSManaged public func removeFromPlannedMeals(_ values: NSSet)
}

// MARK: Generated accessors for recipes
extension Household {

    @objc(addRecipesObject:)
    @NSManaged public func addToRecipes(_ value: Recipe)

    @objc(removeRecipesObject:)
    @NSManaged public func removeFromRecipes(_ value: Recipe)

    @objc(addRecipes:)
    @NSManaged public func addToRecipes(_ values: NSSet)

    @objc(removeRecipes:)
    @NSManaged public func removeFromRecipes(_ values: NSSet)
}

// MARK: Generated accessors for weeklyLists
extension Household {

    @objc(addWeeklyListsObject:)
    @NSManaged public func addToWeeklyLists(_ value: WeeklyList)

    @objc(removeWeeklyListsObject:)
    @NSManaged public func removeFromWeeklyLists(_ value: WeeklyList)

    @objc(addWeeklyLists:)
    @NSManaged public func addToWeeklyLists(_ values: NSSet)

    @objc(removeWeeklyLists:)
    @NSManaged public func removeFromWeeklyLists(_ values: NSSet)
}

extension Household: Identifiable {
}
