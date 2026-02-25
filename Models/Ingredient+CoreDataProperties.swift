//
//  Ingredient+CoreDataProperties.swift
//  forager
//
//  Created by Rich Hayn on 10/10/25.
//
//

public import Foundation
public import CoreData


public typealias IngredientCoreDataPropertiesSet = NSSet

extension Ingredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ingredient> {
        return NSFetchRequest<Ingredient>(entityName: "Ingredient")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var numericValue: Double
    @NSManaged public var standardUnit: String?
    @NSManaged public var displayText: String?
    @NSManaged public var isParseable: Bool
    @NSManaged public var parseConfidence: Float
    @NSManaged public var ingredientTemplate: IngredientTemplate?
    @NSManaged public var recipe: Recipe?

}

extension Ingredient : Identifiable {

}
