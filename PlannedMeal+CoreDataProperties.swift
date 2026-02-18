//
//  PlannedMeal+CoreDataProperties.swift
//  forager
//
//  M7.2.3 Phase 2.5: Added household and householdKey properties
//  Created on January 2, 2026
//

import Foundation
import CoreData

extension PlannedMeal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlannedMeal> {
        return NSFetchRequest<PlannedMeal>(entityName: "PlannedMeal")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var createdDate: Date?
    @NSManaged public var completedDate: Date?
    @NSManaged public var mealType: String?
    @NSManaged public var notes: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var scaleFactor: Double
    @NSManaged public var servings: Int16
    @NSManaged public var quickOption: String?
    @NSManaged public var slotKey: String?
    @NSManaged public var household: Household?
    @NSManaged public var householdKey: String?
    @NSManaged public var mealPlan: MealPlan?
    @NSManaged public var recipe: Recipe?
}

extension PlannedMeal: Identifiable {
}
