//
//  PlannedMealRepository.swift
//  forager
//
//  Created for M7.1.3 Phase 1.2
//  Repository pattern to prevent duplicate PlannedMeal creation across devices
//

import Foundation
import CoreData

/// Repository for managing PlannedMeal entities with slot-based uniqueness
///
/// Enforces one meal per date/mealType combination (slot).
/// This is the ONLY way planned meals should be created in the app.
///
/// Usage:
/// ```swift
/// let meal = PlannedMealRepository.getOrCreate(
///     date: Date(),
///     mealType: "dinner",
///     recipe: myRecipe,
///     mealPlan: myMealPlan,
///     in: context
/// )
/// ```
struct PlannedMealRepository {
    
    // MARK: - Get or Create
    
    /// Get existing planned meal by slot key, or create new one
    ///
    /// Enforces one meal per date/mealType combination. If a meal already exists
    /// for the slot, updates its recipe instead of creating a duplicate.
    ///
    /// - Parameters:
    ///   - date: Date of the meal
    ///   - mealType: Type of meal (breakfast/lunch/dinner/snack)
    ///   - recipe: Recipe to plan (can be nil)
    ///   - mealPlan: Parent meal plan (can be nil)
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Existing or newly created PlannedMeal
    /// M9.13: Factory parameter for correct store assignment (ADR 014)
    /// M19: Factory is required — no fallback to direct Entity(context:)
    static func getOrCreate(
        date: Date,
        mealType: String,
        recipe: Recipe?,
        mealPlan: MealPlan?,
        in context: NSManagedObjectContext,
        factory: ManagedObjectFactory
    ) -> PlannedMeal? {
        // Validate meal type
        guard PlannedMeal.isValidMealType(mealType) else {
            #if DEBUG
            print("⚠️ PlannedMealRepository: Invalid meal type '\(mealType)', defaulting to 'dinner'")
            #endif
            return getOrCreate(
                date: date,
                mealType: "dinner",
                recipe: recipe,
                mealPlan: mealPlan,
                in: context,
                factory: factory
            )
        }

        let slotKey = PlannedMeal.slotKey(date: date, mealType: mealType)

        // Query by semantic key first
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "slotKey == %@", slotKey)
        request.fetchLimit = 1

        // Return existing if found (update recipe if different)
        if let existing = try? context.fetch(request).first {
            #if DEBUG
            print("📦 PlannedMealRepository: Found existing meal for slot '\(slotKey)'")
            #endif

            // Update recipe if changed
            if existing.recipe != recipe {
                #if DEBUG
                print("🔄 PlannedMealRepository: Updating recipe for slot '\(slotKey)'")
                #endif
                existing.recipe = recipe
            }

            // Update meal plan if changed
            if existing.mealPlan != mealPlan {
                existing.mealPlan = mealPlan
            }

            return existing
        }

        // Create new if doesn't exist
        #if DEBUG
        print("✨ PlannedMealRepository: Creating new meal for slot '\(slotKey)'")
        #endif
        do {
            return try factory.make(PlannedMeal.self, configure: { m in
                m.date = date
                m.mealType = mealType.lowercased()
                m.slotKey = slotKey
                m.recipe = recipe
                m.mealPlan = mealPlan
                m.createdDate = Date()
            })
        } catch {
            #if DEBUG
            print("⚠️ Factory error creating PlannedMeal: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Query Helpers
    
    /// Find planned meal by exact slot key
    /// - Parameters:
    ///   - slotKey: Slot key to search for (format: "YYYY-MM-DD-mealtype")
    ///   - context: NSManagedObjectContext to use
    /// - Returns: PlannedMeal if found, nil otherwise
    static func find(bySlotKey slotKey: String, in context: NSManagedObjectContext) -> PlannedMeal? {
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "slotKey == %@", slotKey)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Find planned meal by date and meal type
    /// - Parameters:
    ///   - date: Date to search for
    ///   - mealType: Meal type to search for
    ///   - context: NSManagedObjectContext to use
    /// - Returns: PlannedMeal if found, nil otherwise
    static func find(date: Date, mealType: String, in context: NSManagedObjectContext) -> PlannedMeal? {
        let slotKey = PlannedMeal.slotKey(date: date, mealType: mealType)
        return find(bySlotKey: slotKey, in: context)
    }
    
    /// Find all planned meals for a specific date
    /// - Parameters:
    ///   - date: Date to search for
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Array of PlannedMeal objects for that date
    static func findAll(forDate date: Date, in context: NSManagedObjectContext) -> [PlannedMeal] {
        // Get date string prefix (YYYY-MM-DD)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = Calendar.current.timeZone
        let datePrefix = formatter.string(from: date)
        
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "slotKey BEGINSWITH %@", datePrefix)
        request.sortDescriptors = [NSSortDescriptor(key: "mealType", ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
}
