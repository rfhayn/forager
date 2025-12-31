//
//  HouseholdPlannedMealRepository.swift
//  forager
//
//  M7.2.3 Phase 2.3: Household-scoped planned meal repository
//  Single responsibility: Semantic uniqueness for planned meals in shared household zone
//
//  Created on December 31, 2025.
//

import CoreData
import Foundation

/// M7.2.3 Phase 2.3: Household-scoped planned meal repository
///
/// Responsibilities:
/// - Prevent duplicate planned meals in household shared zone
/// - Query-before-create using slotKey (semantic uniqueness)
/// - Idempotent operations (safe to call multiple times)
/// - Clear console logging for debugging
///
/// Pattern: Always query by slotKey (date + mealType) before creating
final class HouseholdPlannedMealRepository {
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Public Repository Methods
    
    /// M7.2.3: Find or create planned meal using semantic uniqueness
    /// Prevents duplicate meal plans when multiple household members plan same date/slot
    ///
    /// - Parameters:
    ///   - date: Date of the planned meal
    ///   - mealType: Type of meal (e.g., "breakfast", "lunch", "dinner")
    ///   - recipe: Optional recipe for this meal
    /// - Returns: Existing planned meal if found, or newly created planned meal
    /// - Throws: Core Data errors during fetch or save
    func findOrCreate(
        date: Date,
        mealType: String,
        recipe: Recipe?
    ) throws -> PlannedMeal {
        // Query using semantic uniqueness (slotKey)
        let slotKey = PlannedMeal.generateSlotKey(date: date, mealType: mealType)
        
        if let existing = try findBySlotKey(slotKey) {
            print("ℹ️ M7.2.3: Planned meal for '\(slotKey)' already exists")
            
            // Update recipe if provided and different
            if let newRecipe = recipe, newRecipe != existing.recipe {
                existing.recipe = newRecipe
                print("   Updated recipe: '\(newRecipe.title ?? "Untitled")'")
            }
            
            return existing
        }
        
        // Create new planned meal
        let plannedMeal = PlannedMeal(context: context)
        plannedMeal.id = UUID()
        plannedMeal.date = date
        plannedMeal.mealType = mealType
        plannedMeal.slotKey = slotKey
        plannedMeal.recipe = recipe
        plannedMeal.createdDate = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        print("✅ M7.2.3: Created planned meal for '\(slotKey)' on \(dateFormatter.string(from: date))")
        
        return plannedMeal
    }
    
    /// M7.2.3: Check if planned meal exists for date/mealType using semantic uniqueness
    ///
    /// - Parameters:
    ///   - date: Date of the planned meal
    ///   - mealType: Type of meal
    /// - Returns: True if planned meal exists, false otherwise
    /// - Throws: Core Data errors during fetch
    func exists(date: Date, mealType: String) throws -> Bool {
        let slotKey = PlannedMeal.generateSlotKey(date: date, mealType: mealType)
        let meal = try findBySlotKey(slotKey)
        return meal != nil
    }
    
    /// M7.2.3: Find planned meal by date and mealType using semantic uniqueness
    ///
    /// - Parameters:
    ///   - date: Date of the planned meal
    ///   - mealType: Type of meal
    /// - Returns: Planned meal if found, nil otherwise
    /// - Throws: Core Data errors during fetch
    func findByDateAndType(date: Date, mealType: String) throws -> PlannedMeal? {
        let slotKey = PlannedMeal.generateSlotKey(date: date, mealType: mealType)
        return try findBySlotKey(slotKey)
    }
    
    /// M7.2.3: Get all planned meals for a specific date
    ///
    /// - Parameter date: Date to query
    /// - Returns: Array of planned meals for the date
    /// - Throws: Core Data errors during fetch
    func findByDate(_ date: Date) throws -> [PlannedMeal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)]
        
        return try context.fetch(request)
    }
    
    /// M7.2.3: Get planned meals in date range
    ///
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of planned meals in range
    /// - Throws: Core Data errors during fetch
    func findByDateRange(startDate: Date, endDate: Date) throws -> [PlannedMeal] {
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)]
        
        return try context.fetch(request)
    }
    
    /// M7.2.3: Get all planned meals sorted by date
    ///
    /// - Returns: Array of all planned meals
    /// - Throws: Core Data errors during fetch
    func findAll() throws -> [PlannedMeal] {
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)]
        
        return try context.fetch(request)
    }
    
    /// M7.2.3: Delete planned meal
    ///
    /// - Parameter plannedMeal: Planned meal to delete
    func delete(_ plannedMeal: PlannedMeal) {
        context.delete(plannedMeal)
        print("🗑️ M7.2.3: Deleted planned meal for '\(plannedMeal.slotKey ?? "unknown")'")
    }
    
    // MARK: - Private Helper Methods
    
    /// Find planned meal by slotKey (semantic uniqueness key)
    private func findBySlotKey(_ slotKey: String) throws -> PlannedMeal? {
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "slotKey ==[c] %@", slotKey)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
}
