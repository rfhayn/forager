//
//  WeeklyList+CoreDataProperties.swift
//  forager
//
//  Created by Richard Hayn on 8/27/25.
//
//

import Foundation
import CoreData


extension WeeklyList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeeklyList> {
        return NSFetchRequest<WeeklyList>(entityName: "WeeklyList")
    }

    @NSManaged public var dateCreated: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var household: Household?
    @NSManaged public var householdKey: String?
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension WeeklyList {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: GroceryListItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: GroceryListItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension WeeklyList : Identifiable {

}
