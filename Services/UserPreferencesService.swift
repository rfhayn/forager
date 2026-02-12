//
//  UserPreferencesService.swift
//  forager
//
//  Created by Rich Hayn on 10/23/25.
//


//
//  UserPreferencesService.swift
//  forager
//
//  Created for M4.1: Settings Infrastructure Foundation
//  Manages meal planning and app-wide user preferences
//

import Foundation
import CoreData
import Combine

// M4.1: User preferences management service
// Manages meal planning settings and app-wide configuration
// Singleton pattern for consistent access throughout app
@MainActor
class UserPreferencesService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = UserPreferencesService()
    
    // MARK: - Published Properties
    
    // M4.1: Meal plan duration in days (3-14)
    // Used by M4.2 for calendar length and M4.3 for list generation
    @Published var mealPlanDuration: Int = 7
    
    // M4.1: Meal plan start day (0=Sunday, 1=Monday, ..., 6=Saturday)
    // Determines first day of calendar in M4.2
    @Published var mealPlanStartDay: Int = 0
    
    // M4.1: Auto-generate meal plan names (e.g., "Week of Oct 23")
    // When false, user must manually name plans in M4.2
    @Published var autoNameMealPlans: Bool = true
    
    // M4.1: Show recipe source in meal plan displays
    // Controls whether "From: [Recipe Name]" appears in M4.2
    @Published var showRecipeSources: Bool = true
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    private var preferences: UserPreferences?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Use main context for UI integration
        self.context = PersistenceController.shared.container.viewContext
        
        // Load existing preferences or create defaults
        loadPreferences()
        
        // Setup auto-save when published properties change
        setupAutoSave()
    }
    
    // MARK: - Service Initialization
    
    // Loads existing preferences from Core Data or creates default preferences
    // Called automatically on service initialization
    private func loadPreferences() {
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existing = results.first {
                // Load from existing preferences
                preferences = existing
                mealPlanDuration = Int(existing.mealPlanDuration)
                mealPlanStartDay = Int(existing.mealPlanStartDay)
                autoNameMealPlans = existing.autoNameMealPlans
                showRecipeSources = existing.showRecipeSources
            } else {
                // Create default preferences on first launch
                createDefaultPreferences()
            }
        } catch {
            #if DEBUG
            print("❌ Error loading preferences: \(error.localizedDescription)")
            #endif
            // Create defaults on error
            createDefaultPreferences()
        }
    }
    
    // Creates default preferences with sensible values
    // Called on first app launch or if preferences are missing
    private func createDefaultPreferences() {
        let newPreferences = UserPreferences(context: context)
        newPreferences.id = UUID()
        newPreferences.mealPlanDuration = 7
        newPreferences.mealPlanStartDay = 0 // Sunday
        newPreferences.autoNameMealPlans = true
        newPreferences.showRecipeSources = true
        newPreferences.createdDate = Date()
        newPreferences.modifiedDate = Date()
        
        preferences = newPreferences
        
        // Save to Core Data
        saveContext()
    }
    
    // MARK: - Auto-Save Setup
    
    // Sets up automatic saving when any published property changes
    // Provides real-time persistence without manual save calls
    private func setupAutoSave() {
        // Combine all published property changes
        Publishers.CombineLatest4(
            $mealPlanDuration,
            $mealPlanStartDay,
            $autoNameMealPlans,
            $showRecipeSources
        )
        .dropFirst() // Ignore initial values from loadPreferences()
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Batch rapid changes
        .sink { [weak self] duration, startDay, autoName, showSource in
            self?.savePreferences(
                duration: duration,
                startDay: startDay,
                autoName: autoName,
                showSource: showSource
            )
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Preference Management
    
    // Saves current preference values to Core Data
    // Called automatically via setupAutoSave() when properties change
    private func savePreferences(duration: Int, startDay: Int, autoName: Bool, showSource: Bool) {
        guard let prefs = preferences else {
            #if DEBUG
            print("⚠️ No preferences object to save")
            #endif
            return
        }
        
        // Validate duration range (3-14 days)
        let validatedDuration = max(3, min(14, duration))
        
        // Validate start day (0-6 for Sunday-Saturday)
        let validatedStartDay = max(0, min(6, startDay))
        
        // Update Core Data entity
        prefs.mealPlanDuration = Int16(validatedDuration)
        prefs.mealPlanStartDay = Int16(validatedStartDay)
        prefs.autoNameMealPlans = autoName
        prefs.showRecipeSources = showSource
        prefs.modifiedDate = Date()
        
        // Persist to disk
        saveContext()
    }
    
    // Saves Core Data context with error handling
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                #if DEBUG
                print("❌ Error saving preferences: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Returns day name for current start day setting
    // Used in UI to display "Sunday", "Monday", etc.
    var startDayName: String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[mealPlanStartDay]
    }
    
    // Returns array of weekday names starting from user's preferred start day
    // Used in M4.2 for calendar header generation
    var weekdayNamesFromStartDay: [String] {
        let formatter = DateFormatter()
        let allDays = formatter.weekdaySymbols!
        let startIndex = mealPlanStartDay
        
        // Rotate array to start from user's preferred day
        return Array(allDays[startIndex...] + allDays[..<startIndex])
    }
    
    // MARK: - Public Methods
    
    // Returns current preferences as read-only values
    // Used by other services that need to read preferences
    func getPreferences() -> (duration: Int, startDay: Int, autoName: Bool, showSource: Bool) {
        return (
            duration: mealPlanDuration,
            startDay: mealPlanStartDay,
            autoName: autoNameMealPlans,
            showSource: showRecipeSources
        )
    }
    
    // Validates that duration is within acceptable range
    // Used by UI to prevent invalid values
    func isValidDuration(_ duration: Int) -> Bool {
        return duration >= 3 && duration <= 14
    }
    
    // Validates that start day is valid weekday index
    func isValidStartDay(_ day: Int) -> Bool {
        return day >= 0 && day <= 6
    }
}
