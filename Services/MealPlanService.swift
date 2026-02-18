//
//  MealPlanService.swift
//  forager
//
//  Created for M4.2: Calendar-Based Meal Planning Core
//  Manages meal plans and recipe assignments to dates
//  Updated for M4.2.4: Multiple meal plans support with validation
//

import Foundation
import CoreData
import Combine

// M4.2.4: Result type for meal plan date validation
// Provides specific feedback about why validation failed
enum ValidationResult: Equatable {
    case valid
    case overlapsWithPlan(name: String, startDate: Date, endDate: Date)
    case invalidDuration
    case invalidDate
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .overlapsWithPlan(let name, let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Dates overlap with '\(name)' (\(formatter.string(from: start)) - \(formatter.string(from: end)))"
        case .invalidDuration:
            return "Duration must be between 3 and 14 days"
        case .invalidDate:
            return "Invalid date selected"
        }
    }
}

// M4.2: Meal plan management service
// Handles creation, retrieval, and management of meal plans
// Integrates with UserPreferencesService for user-configured defaults
@MainActor
class MealPlanService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = MealPlanService()
    
    // MARK: - Published Properties
    
    // M4.2: Current active meal plan
    // Published for real-time UI updates when plan changes
    @Published var activeMealPlan: MealPlan?
    
    // M4.2: All planned meals in the active plan
    // Used by calendar view for displaying recipe assignments
    @Published var plannedMeals: [PlannedMeal] = []
    
    // M4.2: Performance tracking for service operations
    // Monitors operation duration to ensure < 0.1s target
    @Published var lastOperationDuration: TimeInterval = 0
    
    // M4.2: Error state for UI display
    // Published to allow views to show error messages
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    // M4.2: Private initializer for singleton pattern
    // Loads active meal plan on initialization
    private init() {
        self.context = PersistenceController.shared.container.viewContext
        loadActiveMealPlan()
    }
    
    // MARK: - Meal Plan Management
    
    // M4.2: Loads the currently active meal plan
    // Only one meal plan should be active at a time
    // Performance target: < 0.1s
    func loadActiveMealPlan() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let plans = try context.fetch(fetchRequest)
            activeMealPlan = plans.first
            
            // Load planned meals if we have an active plan
            if let plan = activeMealPlan {
                loadPlannedMeals(for: plan)
            } else {
                plannedMeals = []
            }
            
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
        } catch {
            lastError = error
            #if DEBUG
            print("Error loading active meal plan: \(error)")
            #endif
        }
    }
    
    // M4.2: Creates a new meal plan using user preferences
    // Automatically sets as active and deactivates any existing active plans
    // Uses UserPreferencesService for duration and start day defaults
    func createMealPlan(startDate: Date? = nil) -> MealPlan? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Deactivate any existing active plans
        deactivateAllPlans()
        
        let plan = MealPlan(context: context)
        plan.id = UUID()
        plan.createdDate = Date()
        plan.isActive = true
        
        // Use provided start date or calculate from user preferences
        let prefs = UserPreferencesService.shared
        let calculatedStartDate = startDate ?? calculateStartDate(using: prefs.mealPlanStartDay)
        plan.startDate = calculatedStartDate
        plan.duration = Int16(prefs.mealPlanDuration)
        
        // Auto-generate name if enabled in preferences
        if prefs.autoNameMealPlans {
            plan.name = generateMealPlanName(for: calculatedStartDate)
        }
        
        do {
            try context.save()
            activeMealPlan = plan
            plannedMeals = [] // New plan has no meals yet
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
            return plan
        } catch {
            lastError = error
            #if DEBUG
            print("Error creating meal plan: \(error)")
            #endif
            context.rollback()
            return nil
        }
    }
    
    // M4.2: Archives the current active meal plan
    // Sets isActive to false and records completion date
    // Useful when starting a new planning period
    func archiveActiveMealPlan() {
        guard let plan = activeMealPlan else { return }
        
        plan.isActive = false
        plan.completedDate = Date()
        
        do {
            try context.save()
            activeMealPlan = nil
            plannedMeals = []
        } catch {
            lastError = error
            #if DEBUG
            print("Error archiving meal plan: \(error)")
            #endif
            context.rollback()
        }
    }
    
    // M4.2: Deletes a meal plan and all its planned meals
    // Cascade delete rule automatically removes associated PlannedMeal records
    func deleteMealPlan(_ plan: MealPlan) {
        context.delete(plan)
        
        do {
            try context.save()
            if plan == activeMealPlan {
                activeMealPlan = nil
                plannedMeals = []
            }
        } catch {
            lastError = error
            #if DEBUG
            print("Error deleting meal plan: \(error)")
            #endif
            context.rollback()
        }
    }
    
    // MARK: - M4.2.4: Date Validation
    
    // M4.2.4: Validates that proposed meal plan dates don't overlap with existing plans
    // Checks all existing plans except the one being edited (if provided)
    // Returns validation result with specific overlap information
    // Performance target: < 0.1s
    func validatePlanDates(
        startDate: Date,
        duration: Int,
        excludingPlan: MealPlan? = nil
    ) -> ValidationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Validate duration
        guard duration >= 3 && duration <= 14 else {
            return .invalidDuration
        }
        
        // Calculate end date
        guard let endDate = Calendar.current.date(byAdding: .day, value: duration - 1, to: startDate) else {
            return .invalidDate
        }
        
        // Fetch all existing plans
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        
        do {
            let existingPlans = try context.fetch(fetchRequest)
            
            // Check each plan for overlap
            for plan in existingPlans {
                // Skip the plan being edited
                if let excludingPlan = excludingPlan, plan.id == excludingPlan.id {
                    continue
                }
                
                guard let planStart = plan.startDate else { continue }
                guard let planEnd = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: planStart) else { continue }
                
                // Check for overlap: (StartA <= EndB) and (EndA >= StartB)
                let hasOverlap = (startDate <= planEnd) && (endDate >= planStart)
                
                if hasOverlap {
                    lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
                    return .overlapsWithPlan(
                        name: plan.name ?? "Unnamed Plan",
                        startDate: planStart,
                        endDate: planEnd
                    )
                }
            }
            
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
            return .valid
        } catch {
            lastError = error
            #if DEBUG
            print("Error validating plan dates: \(error)")
            #endif
            return .invalidDate
        }
    }
    
    // MARK: - M4.2.4: Status Management
    
    // M4.2.4: Updates active plan status based on current date
    // Only one plan should be active at a time - the one containing today's date
    // Run on app launch and when plans are modified
    // Performance target: < 0.1s
    func updateActivePlanStatus() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let today = Calendar.current.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        do {
            let allPlans = try context.fetch(fetchRequest)
            var foundActivePlan = false
            
            for plan in allPlans {
                guard let startDate = plan.startDate else { continue }
                let startDay = Calendar.current.startOfDay(for: startDate)
                
                guard let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDay) else { continue }
                
                // Check if plan contains today and is not completed
                let containsToday = (startDay <= today) && (today <= endDate)
                let shouldBeActive = containsToday && !plan.isCompleted
                
                if shouldBeActive && !foundActivePlan {
                    // This is the active plan
                    plan.isActive = true
                    foundActivePlan = true
                } else {
                    // Deactivate this plan
                    plan.isActive = false
                }
            }
            
            try context.save()
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Reload active plan if status changed
            loadActiveMealPlan()
        } catch {
            lastError = error
            #if DEBUG
            print("Error updating active plan status: \(error)")
            #endif
        }
    }
    
    // M4.2.4: Auto-completes plans where end date has passed
    // Updates isCompleted flag and sets completedDate
    // Run on app launch and periodically
    // Performance target: < 0.1s
    func updateCompletedStatus() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let today = Calendar.current.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == NO")
        
        do {
            let incompletePlans = try context.fetch(fetchRequest)
            
            for plan in incompletePlans {
                guard let startDate = plan.startDate else { continue }
                let startDay = Calendar.current.startOfDay(for: startDate)
                
                guard let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDay) else { continue }
                
                // If end date is before today, mark as completed
                if endDate < today {
                    plan.isCompleted = true
                    plan.completedDate = endDate
                    plan.isActive = false
                }
            }
            
            try context.save()
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
        } catch {
            lastError = error
            #if DEBUG
            print("Error updating completed status: \(error)")
            #endif
        }
    }
    
    // MARK: - M4.2.4: Query Helpers
    
    // M4.2.4: Returns the currently active meal plan (if any)
    // Only one plan should be active at a time
    // Performance target: < 0.1s
    func getActivePlan() -> MealPlan? {
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES AND isCompleted == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let plans = try context.fetch(fetchRequest)
            return plans.first
        } catch {
            lastError = error
            #if DEBUG
            print("Error fetching active plan: \(error)")
            #endif
            return nil
        }
    }
    
    // M4.2.4: Returns all upcoming meal plans (start date in the future)
    // Sorted by start date ascending
    // Performance target: < 0.1s
    func getUpcomingPlans() -> [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startDate > %@ AND isCompleted == NO", today as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            lastError = error
            #if DEBUG
            print("Error fetching upcoming plans: \(error)")
            #endif
            return []
        }
    }
    
    // M4.2.4: Returns all completed meal plans
    // Sorted by completion date descending (most recent first)
    // Performance target: < 0.1s
    func getCompletedPlans() -> [MealPlan] {
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == YES")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "completedDate", ascending: false),
            NSSortDescriptor(key: "startDate", ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            lastError = error
            #if DEBUG
            print("Error fetching completed plans: \(error)")
            #endif
            return []
        }
    }
    
    // MARK: - Planned Meal Management
    
    // M4.2: Loads all planned meals for a specific meal plan
    // Sorted by date ascending for calendar display
    // Performance target: < 0.1s
    private func loadPlannedMeals(for plan: MealPlan) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let fetchRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mealPlan == %@", plan)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.relationshipKeyPathsForPrefetching = ["recipe"] // Optimize for calendar display
        
        do {
            plannedMeals = try context.fetch(fetchRequest)
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
        } catch {
            lastError = error
            #if DEBUG
            print("Error loading planned meals: \(error)")
            #endif
        }
    }
    
    // M4.2.4: Adds a recipe to a specific date in a meal plan
    // NOW accepts mealPlan parameter for multi-plan support
    // Includes recipe usage tracking (usageCount and lastUsed)
    // Enforces one-recipe-per-day constraint by checking for existing meals
    // Returns the created PlannedMeal or nil if date already has a meal
    // Performance target: < 0.1s
    func addRecipeToMealPlan(recipe: Recipe, date: Date, mealPlan: MealPlan, servings: Int16? = nil) -> PlannedMeal? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check if date already has a planned meal in this specific plan
        let startOfDay = Calendar.current.startOfDay(for: date)
        let fetchRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "mealPlan == %@ AND date >= %@ AND date < %@",
            mealPlan,
            startOfDay as NSDate,
            Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! as NSDate
        )
        fetchRequest.fetchLimit = 1
        
        do {
            let existingMeals = try context.fetch(fetchRequest)
            if !existingMeals.isEmpty {
                #if DEBUG
                print("Date \(date) already has a planned meal in this plan")
                #endif
                return nil
            }
        } catch {
            lastError = error
            #if DEBUG
            print("Error checking for existing meal: \(error)")
            #endif
            return nil
        }
        
        // M7.2.3 Phase 3.4: Create planned meal using HouseholdPlannedMealRepository
        // Default mealType to "dinner" - future enhancement: allow user to select
        let repository = HouseholdPlannedMealRepository(context: context)
        
        do {
            let plannedMeal = try repository.findOrCreate(
                date: startOfDay,
                mealType: "dinner",
                recipe: recipe
            )
            plannedMeal.id = UUID()
            plannedMeal.mealPlan = mealPlan
            plannedMeal.servings = servings ?? Int16(recipe.servings)
            plannedMeal.scaleFactor = Double(plannedMeal.servings) / Double(recipe.servings)
            plannedMeal.isCompleted = false
            
            // M4.2.4: Update recipe usage tracking
            // Track when added to meal plan (better signal than grocery list)
            // Use the planned meal date, not today
            recipe.usageCount += 1
            recipe.lastUsed = startOfDay
            
            // Save all changes
            try context.save()
            
            // Update published plannedMeals if this is for the active plan
            if mealPlan == activeMealPlan {
                loadPlannedMeals(for: mealPlan)
            }
            
            lastOperationDuration = CFAbsoluteTimeGetCurrent() - startTime
            return plannedMeal
            
        } catch {
            lastError = error
            #if DEBUG
            print("❌ M7.2.3 Phase 3.4: Error adding recipe to meal plan: \(error)")
            #endif
            context.rollback()
            return nil
        }
    }
    
    // M4.2: Removes a planned meal from the meal plan
    // Updates plannedMeals array to reflect removal in UI
    func removePlannedMeal(_ meal: PlannedMeal) {
        guard let plan = activeMealPlan else { return }
        
        context.delete(meal)
        
        do {
            try context.save()
            loadPlannedMeals(for: plan) // Reload to update published array
        } catch {
            lastError = error
            #if DEBUG
            print("Error removing planned meal: \(error)")
            #endif
            context.rollback()
        }
    }
    
    // M4.2: Marks a planned meal as completed
    // Records completion date for tracking purposes
    func markMealAsCompleted(_ meal: PlannedMeal) {
        meal.isCompleted = true
        meal.completedDate = Date()
        
        do {
            try context.save()
        } catch {
            lastError = error
            #if DEBUG
            print("Error marking meal as completed: \(error)")
            #endif
            context.rollback()
        }
    }
    
    // M4.2: Updates the servings for a planned meal
    // Recalculates scale factor based on original recipe servings
    func updateServings(for meal: PlannedMeal, servings: Int16) {
        guard let recipe = meal.recipe else { return }
        
        meal.servings = servings
        meal.scaleFactor = Double(servings) / Double(recipe.servings)
        
        do {
            try context.save()
        } catch {
            lastError = error
            #if DEBUG
            print("Error updating servings: \(error)")
            #endif
            context.rollback()
        }
    }
    
    // MARK: - Query Helpers
    
    // M4.2: Checks if a specific date already has a planned meal
    // Used to enforce one-recipe-per-day constraint
    func hasPlannedMeal(on date: Date) -> Bool {
        // Compare dates by day, ignoring time
        let calendar = Calendar.current
        return plannedMeals.contains { meal in
            guard let mealDate = meal.date else { return false }
            return calendar.isDate(mealDate, inSameDayAs: date)
        }
    }
    
    // M4.2: Gets the planned meal for a specific date
    // Returns nil if no meal planned for that date
    func getPlannedMeal(for date: Date) -> PlannedMeal? {
        let calendar = Calendar.current
        return plannedMeals.first { meal in
            guard let mealDate = meal.date else { return false }
            return calendar.isDate(mealDate, inSameDayAs: date)
        }
    }
    
    // M4.2: Gets all dates that are within the current meal plan period
    // Used by calendar view to display the planning period
    func getDatesInMealPlan() -> [Date] {
        guard let plan = activeMealPlan,
              let startDate = plan.startDate else {
            return []
        }
        
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for day in 0..<Int(plan.duration) {
            if let date = calendar.date(byAdding: .day, value: day, to: startDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // MARK: - Private Helpers
    
    // M4.2: Deactivates all currently active meal plans
    // Ensures only one plan is active at a time
    private func deactivateAllPlans() {
        let fetchRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        
        do {
            let plans = try context.fetch(fetchRequest)
            for plan in plans {
                plan.isActive = false
            }
            try context.save()
        } catch {
            #if DEBUG
            print("Error deactivating plans: \(error)")
            #endif
        }
    }
    
    // M4.2: Calculates the start date for a new meal plan
    // Uses the user's preferred start day (0=Sunday, 6=Saturday)
    // Finds the next occurrence of that day from today
    private func calculateStartDate(using preferredStartDay: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Get today's weekday (1=Sunday, 7=Saturday)
        let todayWeekday = calendar.component(.weekday, from: today)
        
        // Convert our 0-based index (0=Sunday) to Calendar's 1-based (1=Sunday)
        let targetWeekday = preferredStartDay + 1
        
        // Calculate days to add to reach the target weekday
        var daysToAdd = targetWeekday - todayWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7 // Move to next week if target day has passed
        }
        
        // Return the calculated start date
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    // M4.2: Generates a user-friendly name for a meal plan
    // Format: "Week of Oct 27" or "Week of Oct 27 - Nov 2"
    private func generateMealPlanName(for startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        
        // If plan is 7 days, show single week format
        // Otherwise show date range
        let prefs = UserPreferencesService.shared
        if prefs.mealPlanDuration == 7 {
            return "Week of \(formatter.string(from: startDate))"
        } else {
            if let endDate = calendar.date(byAdding: .day, value: prefs.mealPlanDuration - 1, to: startDate) {
                return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
            }
            return "Week of \(formatter.string(from: startDate))"
        }
    }
    
    // MARK: - M15.5: Quick Option Support

    // M15.5: Sets a quick option (Takeout/Dining Out/Leftovers/No Meal) for a date
    // Creates a PlannedMeal with no recipe relationship
    // Replaces any existing meal on that date
    func setQuickOption(_ option: PlannedMeal.QuickOption, for date: Date, in plan: MealPlan) -> PlannedMeal? {
        let startOfDay = Calendar.current.startOfDay(for: date)

        // Remove existing meal on this date if any
        let fetchRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "mealPlan == %@ AND date >= %@ AND date < %@",
            plan,
            startOfDay as NSDate,
            Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! as NSDate
        )

        do {
            let existing = try context.fetch(fetchRequest)
            for meal in existing {
                context.delete(meal)
            }

            let meal = PlannedMeal(context: context)
            meal.id = UUID()
            meal.date = startOfDay
            meal.quickOption = option.rawValue
            meal.recipe = nil
            meal.mealPlan = plan
            meal.createdDate = Date()
            meal.isCompleted = option == .noMeal

            try context.save()

            if plan == activeMealPlan {
                loadPlannedMeals(for: plan)
            }

            return meal
        } catch {
            lastError = error
            #if DEBUG
            print("Error setting quick option: \(error)")
            #endif
            context.rollback()
            return nil
        }
    }

    // MARK: - M15.3: Grocery List Generation

    // M15.3: Generates a grocery list from a meal plan's recipes.
    // Fetches all planned meals' recipes, extracts ingredients,
    // and creates a WeeklyList + GroceryListItems grouped by category.
    @discardableResult
    func generateGroceryList(from plan: MealPlan) -> WeeklyList? {
        let fetchRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mealPlan == %@", plan)
        fetchRequest.relationshipKeyPathsForPrefetching = ["recipe", "recipe.ingredients"]

        do {
            let meals = try context.fetch(fetchRequest)

            let newList = WeeklyList(context: context)
            newList.id = UUID()
            newList.name = "From Plan - \(plan.name ?? DateFormatter.shortDate.string(from: Date()))"
            newList.dateCreated = Date()
            newList.isCompleted = false
            newList.notes = "Generated from meal plan: \(plan.name ?? "Unnamed")"

            var sortIndex: Int16 = 0

            for meal in meals {
                guard let recipe = meal.recipe,
                      let ingredients = recipe.ingredients?.allObjects as? [Ingredient] else { continue }

                for ingredient in ingredients {
                    let listItem = GroceryListItem(context: context)
                    listItem.id = UUID()
                    listItem.name = ingredient.name
                    listItem.displayText = ingredient.displayText ?? "1"
                    listItem.numericValue = ingredient.numericValue
                    listItem.standardUnit = ingredient.standardUnit
                    listItem.isParseable = ingredient.isParseable
                    listItem.parseConfidence = ingredient.parseConfidence
                    listItem.isCompleted = false
                    listItem.source = "recipe"
                    listItem.addToSourceRecipes(recipe)
                    listItem.sortOrder = sortIndex
                    sortIndex += 1

                    // Category from ingredient template or default
                    if let template = ingredient.ingredientTemplate,
                       let category = template.category, !category.isEmpty {
                        listItem.categoryName = category
                    } else {
                        listItem.categoryName = "Uncategorized"
                    }

                    newList.addToItems(listItem)
                }
            }

            try context.save()
            return newList
        } catch {
            lastError = error
            #if DEBUG
            print("Error generating grocery list from meal plan: \(error)")
            #endif
            context.rollback()
            return nil
        }
    }

    // MARK: - Performance Validation

    // M4.2: Validates service performance meets targets
    // Target: < 0.1s for all operations
    func validatePerformance() -> Bool {
        return lastOperationDuration < 0.1
    }
}
