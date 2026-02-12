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
    static let defaultCategories: [(name: String, color: String, sortOrder: Int16)] = [
        ("Produce", "#4CAF50", 0),              // Green - Store entrance
        ("Deli & Meat", "#F44336", 1),          // Red - Back perimeter
        ("Dairy & Fridge", "#2196F3", 2),       // Blue - Back wall
        ("Bread & Frozen", "#FF9800", 3),       // Orange - Side aisles
        ("Boxed & Canned", "#795548", 4),       // Brown - Center aisles
        ("Snacks, Drinks, & Other", "#9C27B0", 5) // Purple - Checkout area
    ]
    
    // MARK: - M7.2.3 Phase 3.2: Category Management (Using Repository)
    
    /// M7.2.3 Phase 3.2: Create default categories using HouseholdCategoryRepository
    /// Prevents duplicate categories in CloudKit shared zones
    static func createDefaultCategories(in context: NSManagedObjectContext) {
        let repository = HouseholdCategoryRepository(context: context)
        
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
    static func ensureDefaultCategories(in context: NSManagedObjectContext) {
        let repository = HouseholdCategoryRepository(context: context)
        
        do {
            let allCategories = try repository.findAll()
            if allCategories.isEmpty {
                #if DEBUG
                print("🏷️ M7.2.3: No categories found, creating defaults...")
                #endif
                createDefaultCategories(in: context)
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
            createDefaultCategories(in: context)
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
