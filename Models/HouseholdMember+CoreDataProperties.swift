//
//  HouseholdMember+CoreDataProperties.swift
//  forager
//
//  M7.2.3 Phase 2.5: Manual property file to avoid codegen conflicts
//  Created on January 2, 2026
//

import Foundation
import CoreData

extension HouseholdMember {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HouseholdMember> {
        return NSFetchRequest<HouseholdMember>(entityName: "HouseholdMember")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var joinedDate: Date?
    @NSManaged public var role: String?
    @NSManaged public var status: String?
    @NSManaged public var household: Household?
}

extension HouseholdMember: Identifiable {
}
