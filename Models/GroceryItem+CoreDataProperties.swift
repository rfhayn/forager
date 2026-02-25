//
//  GroceryItem+CoreDataProperties.swift
//  forager
//
//  Created by Richard Hayn on 11/13/25.
//
//

public import Foundation
public import CoreData


public typealias GroceryItemCoreDataPropertiesSet = NSSet

extension GroceryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItem> {
        return NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
    }

    @NSManaged public var category: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isStaple: Bool
    @NSManaged public var lastPurchased: Date?
    @NSManaged public var name: String?
    @NSManaged public var categoryEntity: Category?

}

extension GroceryItem : Identifiable {

}
