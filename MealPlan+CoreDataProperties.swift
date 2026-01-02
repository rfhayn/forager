//
//  MealPlan+CoreDataProperties.swift
//  forager
//
//  M7.2.3 Phase 2.5: Manual property file to avoid codegen conflicts
//  Created on January 2, 2026
//

import Foundation
import CoreData

extension MealPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealPlan> {
        return NSFetchRequest<MealPlan>(entityName: "MealPlan")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var createdDate: Date?
    @NSManaged public var completedDate: Date?
    @NSManaged public var duration: Int16
    @NSManaged public var isActive: Bool
    @NSManaged public var isCompleted: Bool
    @NSManaged public var household: Household?
    @NSManaged public var plannedMeals: NSSet?
}

// MARK: Generated accessors for plannedMeals
extension MealPlan {

    @objc(addPlannedMealsObject:)
    @NSManaged public func addToPlannedMeals(_ value: PlannedMeal)

    @objc(removePlannedMealsObject:)
    @NSManaged public func removeFromPlannedMeals(_ value: PlannedMeal)

    @objc(addPlannedMeals:)
    @NSManaged public func addToPlannedMeals(_ values: NSSet)

    @objc(removePlannedMeals:)
    @NSManaged public func removeFromPlannedMeals(_ values: NSSet)
}

extension MealPlan: Identifiable {
}
