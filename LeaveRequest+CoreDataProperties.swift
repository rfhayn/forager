//
//  LeaveRequest+CoreDataProperties.swift
//  forager
//
//  M7.2.2: Leave request properties for member-initiated household departures
//  Created on January 18, 2026
//

import Foundation
import CoreData

extension LeaveRequest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LeaveRequest> {
        return NSFetchRequest<LeaveRequest>(entityName: "LeaveRequest")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var householdID: String?
    @NSManaged public var userRecordID: String?
    @NSManaged public var displayName: String?
    @NSManaged public var requestedDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var household: Household?
}

extension LeaveRequest: Identifiable {
}
