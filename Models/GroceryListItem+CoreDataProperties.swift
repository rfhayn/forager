//
//  GroceryListItem+CoreDataProperties.swift
//  forager
//
//  Created by Rich Hayn on 11/18/25.
//
//

public import Foundation
public import CoreData


public typealias GroceryListItemCoreDataPropertiesSet = NSSet

extension GroceryListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryListItem> {
        return NSFetchRequest<GroceryListItem>(entityName: "GroceryListItem")
    }

    @NSManaged public var categoryName: String?
    @NSManaged public var dateCompleted: Date?
    @NSManaged public var displayText: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isParseable: Bool
    @NSManaged public var name: String?
    @NSManaged public var numericValue: Double
    @NSManaged public var parseConfidence: Float
    @NSManaged public var sortOrder: Int16
    @NSManaged public var source: String?
    @NSManaged public var standardUnit: String?
    @NSManaged public var householdKey: String?
    @NSManaged public var categoryEntity: Category?
    @NSManaged public var household: Household?
    @NSManaged public var store: Store?
    @NSManaged public var sourceRecipes: NSSet?
    @NSManaged public var weeklyList: WeeklyList?

}

// MARK: Generated accessors for sourceRecipes
extension GroceryListItem {

    @objc(addSourceRecipesObject:)
    @NSManaged public func addToSourceRecipes(_ value: Recipe)

    @objc(removeSourceRecipesObject:)
    @NSManaged public func removeFromSourceRecipes(_ value: Recipe)

    @objc(addSourceRecipes:)
    @NSManaged public func addToSourceRecipes(_ values: NSSet)

    @objc(removeSourceRecipes:)
    @NSManaged public func removeFromSourceRecipes(_ values: NSSet)

}

extension GroceryListItem : Identifiable {

}
