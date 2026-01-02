//
//  UserPreferences+CoreDataProperties.swift
//  forager
//
//  M7.2.3 Phase 2.5: Manual property file
//  Created on January 2, 2026
//

import Foundation
import CoreData

extension UserPreferences {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPreferences> {
        return NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
    @NSManaged public var autoNameMealPlans: Bool
    @NSManaged public var mealPlanDuration: Int16
    @NSManaged public var mealPlanStartDay: Int16
    @NSManaged public var showRecipeSources: Bool
    @NSManaged public var household: Household?
}

extension UserPreferences: Identifiable {
}
