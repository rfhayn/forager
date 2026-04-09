//
//  SelectMealPlanSheet.swift
//  forager
//
//  Created for M4.2.4: Multiple Meal Plans List View
//  Modal sheet for selecting which meal plan to add a recipe to
//  Follows proven SelectListSheet pattern from M1
//

import SwiftUI
import CoreData

// M4.2.4: Modal sheet for meal plan selection when adding recipes
// Pre-selects active plan for convenience
// Allows inline plan creation for flexibility
// Validates date selection within chosen plan's range
struct SelectMealPlanSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // M4.2.4: Recipe to be added to the selected plan
    let recipe: Recipe
    
    // M4.2.4: Callback when user confirms selection
    // Passes selected plan and date back to caller
    var onSelect: (MealPlan, Date) -> Void
    
    // M4.2.4: Fetch all non-completed meal plans
    // Sorted with newest first to show active plan at top
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MealPlan.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default
    ) private var availablePlans: FetchedResults<MealPlan>
    
    // M4.2.4: Currently selected plan (pre-select active if available)
    @State private var selectedPlan: MealPlan?
    
    // M4.2.4: Selected date within the plan
    @State private var selectedDate = Date()
    
    // M4.2.4: Show inline plan creation form
    @State private var showingCreatePlan = false
    
    // M4.2.4: Error message if date already has a recipe
    @State private var errorMessage: String?
    
    // M4.2.4: Check if selected date already has a meal
    @State private var dateHasRecipe = false
    
    var body: some View {
        NavigationStack {
            Form {
                recipeSection
                
                if availablePlans.isEmpty && !showingCreatePlan {
                    emptyStateSection
                } else {
                    planSelectionSection
                    dateSelectionSection
                    
                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
            }
            .navigationTitle("Add to Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRecipeToPlan()
                    }
                    .disabled(selectedPlan == nil || dateHasRecipe)
                }
            }
        }
        .onAppear {
            initializeSelection()
        }
    }
    
    // MARK: - View Components
    
    // M4.2.4: Display recipe being added with basic info
    private var recipeSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(ForagerTheme.accentSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title ?? "Unnamed Recipe")
                        .font(.headline)
                    
                    if recipe.servings > 0 {
                        Text("\(recipe.servings) servings")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Recipe")
        }
    }
    
    // M4.2.4: Empty state when no plans exist
    // Prompts user to create their first plan
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(ForagerTheme.textSecondary)
                
                Text("No Meal Plans Available")
                    .font(.headline)
                
                Text("Create your first meal plan to start organizing your recipes")
                    .font(.subheadline)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingCreatePlan = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Meal Plan")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ForagerTheme.accentPrimary)
                    .cornerRadius(ForagerTheme.Radius.sm)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
    
    // M4.2.4: Plan picker with active plan pre-selected
    // Shows plan name and date range for clarity
    private var planSelectionSection: some View {
        Section {
            if !showingCreatePlan {
                Picker("Meal Plan", selection: $selectedPlan) {
                    Text("Select a plan").tag(nil as MealPlan?)
                    
                    ForEach(availablePlans, id: \.id) { plan in
                        HStack {
                            Text(planDisplayName(plan))
                            if plan.isActive {
                                Text("(Active)")
                                    .font(.caption)
                                    .foregroundStyle(ForagerTheme.statusSuccessFG)
                            }
                        }
                        .tag(plan as MealPlan?)
                    }
                }
                .onChange(of: selectedPlan) { oldValue, newValue in
                    if let plan = newValue {
                        // Set default date to first day of plan
                        selectedDate = plan.startDate ?? Date()
                        checkDateAvailability()
                    }
                }
                
                Button(action: { showingCreatePlan = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Meal Plan")
                    }
                }
            } else {
                // Inline plan creation
                CreateMealPlanSheet(
                    isInline: true,
                    onCreated: { newPlan in
                        selectedPlan = newPlan
                        selectedDate = newPlan.startDate ?? Date()
                        showingCreatePlan = false
                        checkDateAvailability()
                    },
                    onCancel: {
                        showingCreatePlan = false
                    }
                )
            }
        } header: {
            Text("Select Plan")
        }
    }
    
    // M4.2.4: Date picker constrained to selected plan's date range
    // Shows warning if date already has a recipe
    private var dateSelectionSection: some View {
        Section {
            if let plan = selectedPlan {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: dateRange(for: plan),
                    displayedComponents: .date
                )
                .onChange(of: selectedDate) { oldValue, newValue in
                    checkDateAvailability()
                }
                
                if dateHasRecipe {
                    Label("This date already has a recipe assigned", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                }
            }
        } header: {
            Text("Select Date")
        } footer: {
            if let plan = selectedPlan {
                Text("Select a date within \(planDisplayName(plan))")
            }
        }
    }
    
    // M4.2.4: Display validation error messages
    private func errorSection(_ message: String) -> some View {
        Section {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(ForagerTheme.statusDangerFG)
        }
    }
    
    // MARK: - Helper Functions
    
    // M4.2.4: Initialize with active plan pre-selected if available
    private func initializeSelection() {
        // Find active plan
        if let activePlan = availablePlans.first(where: { $0.isActive }) {
            selectedPlan = activePlan
            selectedDate = activePlan.startDate ?? Date()
        } else if let firstPlan = availablePlans.first {
            // Fall back to first plan if no active plan
            selectedPlan = firstPlan
            selectedDate = firstPlan.startDate ?? Date()
        }
        
        checkDateAvailability()
    }
    
    // M4.2.4: Generate display name for meal plan
    // Shows custom name or auto-generated date range
    private func planDisplayName(_ plan: MealPlan) -> String {
        if let name = plan.name, !name.isEmpty {
            return name
        }
        
        guard let startDate = plan.startDate else {
            return "Unnamed Plan"
        }
        
        let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDate) ?? startDate
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    // M4.2.4: Calculate valid date range for plan
    private func dateRange(for plan: MealPlan) -> ClosedRange<Date> {
        guard let startDate = plan.startDate else {
            return Date()...Date()
        }
        
        let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDate) ?? startDate
        return startDate...endDate
    }
    
    // M4.2.4: Check if selected date already has a recipe
    // Used to disable Add button and show warning
    private func checkDateAvailability() {
        guard let plan = selectedPlan else {
            dateHasRecipe = false
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let fetchRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "mealPlan == %@ AND date >= %@ AND date < %@",
            plan,
            startOfDay as NSDate,
            Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)! as NSDate
        )
        fetchRequest.fetchLimit = 1
        
        do {
            let existingMeals = try viewContext.fetch(fetchRequest)
            dateHasRecipe = !existingMeals.isEmpty
            
            if dateHasRecipe {
                errorMessage = "This date already has a recipe. Choose a different date or replace the existing one."
            } else {
                errorMessage = nil
            }
        } catch {
            #if DEBUG
            print("Error checking date availability: \(error)")
            #endif
            dateHasRecipe = false
            errorMessage = nil
        }
    }
    
    // M4.2.4: Add recipe to selected plan and date
    // Calls back to parent with selection
    private func addRecipeToPlan() {
        guard let plan = selectedPlan else { return }
        
        onSelect(plan, selectedDate)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create a sample recipe
    let recipe = Recipe(context: context)
    recipe.id = UUID()
    recipe.title = "Sample Tacos"
    recipe.servings = 4
    
    // Create sample meal plans
    let activePlan = MealPlan(context: context)
    activePlan.id = UUID()
    activePlan.name = "Week of Oct 28"
    activePlan.startDate = Date()
    activePlan.duration = 7
    activePlan.isActive = true
    
    let upcomingPlan = MealPlan(context: context)
    upcomingPlan.id = UUID()
    upcomingPlan.name = "Week of Nov 4"
    upcomingPlan.startDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
    upcomingPlan.duration = 7
    upcomingPlan.isActive = false
    
    try? context.save()
    
    return SelectMealPlanSheet(recipe: recipe) { plan, date in
        print("Selected plan: \(plan.name ?? "unnamed"), date: \(date)")
    }
    .environment(\.managedObjectContext, context)
}
