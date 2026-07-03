//
//  Category+CoreDataClass.swift
//  forager
//
//  Created by Rich Hayn on 8/20/25.
//  M7.2.3 Phase 3.2: Updated to use HouseholdCategoryRepository
//

import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject {
    
    // MARK: - Default Categories
    // reskin-provisions-press: seed colors in the print gamut (what a fresh
    // install sees). Hue families match ForagerTheme.categoryColor defaults;
    // existing users keep their persisted hexes (seeds only run at creation).
    static let defaultCategories: [(name: String, color: String, sortOrder: Int16)] = [
        ("Produce", "#2E7A52", 0),              // Print Green - Store entrance
        ("Deli & Meat", "#C8402E", 1),          // Tomato - Back perimeter
        ("Dairy & Fridge", "#34689A", 2),       // Label Blue - Back wall
        ("Bread & Frozen", "#B0762A", 3),       // Golden Brown - Side aisles
        ("Boxed & Canned", "#77563A", 4),       // Kraft Brown - Center aisles
        ("Snacks, Drinks, & Other", "#C2662C", 5) // Crate Orange - Checkout area
    ]
    
    // MARK: - M7.2.3 Phase 3.2: Category Management (Using Repository)
    
    /// M7.2.3 Phase 3.2: Create default categories using HouseholdCategoryRepository
    /// Prevents duplicate categories in CloudKit shared zones
    /// M19: Factory parameter required for household scope; pass factory from service
    static func createDefaultCategories(in context: NSManagedObjectContext, factory: ManagedObjectFactory) {
        let repository = HouseholdCategoryRepository(context: context, factory: factory)

        for (name, color, sortOrder) in defaultCategories {
            do {
                // Use repository's findOrCreate (handles semantic uniqueness)
                _ = try repository.findOrCreate(
                    name: name,
                    color: color,
                    sortOrder: sortOrder,
                    isDefault: true
                )
            } catch {
                #if DEBUG
                print("❌ M7.2.3: Error creating category '\(name)': \(error)")
                #endif
            }
        }
    }

    /// M7.2.3 Phase 3.2: Ensure default categories exist using HouseholdCategoryRepository
    /// Idempotent: safe to call multiple times
    /// M19: Factory parameter required for household scope; pass factory from service
    static func ensureDefaultCategories(in context: NSManagedObjectContext, factory: ManagedObjectFactory) {
        let repository = HouseholdCategoryRepository(context: context, factory: factory)

        do {
            let allCategories = try repository.findAll()
            if allCategories.isEmpty {
                #if DEBUG
                print("🏷️ M7.2.3: No categories found, creating defaults...")
                #endif
                createDefaultCategories(in: context, factory: factory)
            } else {
                #if DEBUG
                print("ℹ️ M7.2.3: Categories already exist (\(allCategories.count) found)")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ M7.2.3: Error checking for existing categories: \(error)")
            #endif
            // Fallback: try creating defaults anyway (repository will handle duplicates)
            createDefaultCategories(in: context, factory: factory)
        }
    }
    
    // MARK: - Sort Order Management
    static func updateSortOrder(categories: [Category], in context: NSManagedObjectContext) {
        for (index, category) in categories.enumerated() {
            category.sortOrder = Int16(index)
        }
    }
    
    static func resetToDefaultOrder(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let defaultCategories = try context.fetch(request)
            for category in defaultCategories {
                if let defaultData = Self.defaultCategories.first(where: { $0.name == category.name }) {
                    category.sortOrder = defaultData.sortOrder
                }
            }
        } catch {
            #if DEBUG
            print("Error resetting category order: \\(error)")
            #endif
        }
    }
}
