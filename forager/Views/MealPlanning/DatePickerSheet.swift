//
//  DatePickerSheet.swift
//  forager
//
//  Created for M4.2: Calendar-Based Meal Planning Core
//  Modal sheet for selecting a date to add a recipe to the meal plan
//  Updated for M4.2.4: Multi-plan support
//

import SwiftUI

// M4.2: Date picker sheet for adding recipes to meal plan
// Shows available dates and indicates which already have meals planned
// Enforces one-recipe-per-day constraint by disabling occupied dates
struct DatePickerSheet: View {
    
    // MARK: - Properties
    
    // M4.2: Recipe being added to meal plan
    let recipe: Recipe
    
    // M4.2: Closure called when date is selected
    let onDateSelected: (Date) -> Void
    
    // M4.2: Controls sheet dismissal
    @Environment(\.dismiss) private var dismiss
    
    // M4.2: Meal plan service for checking available dates
    @StateObject private var mealPlanService = MealPlanService.shared
    
    // M4.2: Selected servings (defaults to recipe servings)
    @State private var servings: Int
    
    // MARK: - Initialization
    
    init(recipe: Recipe, onDateSelected: @escaping (Date) -> Void) {
        self.recipe = recipe
        self.onDateSelected = onDateSelected
        self._servings = State(initialValue: Int(recipe.servings))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe info
                    recipeInfoSection
                    
                    // Servings picker
                    servingsSection
                    
                    // Date selection
                    dateSelectionSection
                }
                .padding()
            }
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("Add to Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Recipe Info Section
    
    // M4.2: Displays recipe details being added
    @ViewBuilder
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // reskin-provisions-press: condensed uppercase eyebrow
            Text("RECIPE")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .tracking(0.5)
                .foregroundStyle(ForagerTheme.textTertiary)

            HStack(spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ForagerTheme.accentPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.title ?? "Untitled Recipe")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let source = recipe.sourceURL, !source.isEmpty {
                        Text(source)
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(12)
            .background(ForagerTheme.surfacePrimary)
            .cornerRadius(ForagerTheme.Radius.sm)
        }
    }

    // MARK: - Servings Section
    
    // M4.2: Allows user to adjust servings for this meal
    @ViewBuilder
    private var servingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // reskin-provisions-press: condensed uppercase eyebrow
            Text("SERVINGS")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .tracking(0.5)
                .foregroundStyle(ForagerTheme.textTertiary)

            HStack {
                Text("\(servings) servings")
                    .font(.body)
                
                Spacer()
                
                Stepper("", value: $servings, in: 1...20)
                    .labelsHidden()
            }
            .padding(12)
            .background(ForagerTheme.surfacePrimary)
            .cornerRadius(ForagerTheme.Radius.sm)
            
            if servings != Int(recipe.servings) {
                let scale = Double(servings) / Double(recipe.servings)
                Text("Recipe will be scaled \(scale, specifier: "%.1f")x")
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
        }
    }
    
    // MARK: - Date Selection Section
    
    // M4.2: Grid of available dates for meal planning
    @ViewBuilder
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // reskin-provisions-press: condensed uppercase eyebrow
            Text("SELECT DATE")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .tracking(0.5)
                .foregroundStyle(ForagerTheme.textTertiary)

            if mealPlanService.activeMealPlan != nil {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(mealPlanService.getDatesInMealPlan(), id: \.self) { date in
                        DateButton(
                            date: date,
                            isOccupied: mealPlanService.hasPlannedMeal(on: date),
                            onSelect: {
                                handleDateSelection(date)
                            }
                        )
                    }
                }
            } else {
                // No active plan - prompt to create one
                VStack(spacing: 12) {
                    Text("No active meal plan")
                        .font(.body)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    
                    Button {
                        createMealPlanAndAdd()
                    } label: {
                        Label("Create Meal Plan", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ForagerTheme.surfacePrimary)
                .cornerRadius(ForagerTheme.Radius.sm)
            }
        }
    }

    // MARK: - Actions
    
    // M4.2.4: Handles date selection
    // Adds recipe to selected date with chosen servings
    // Updated to pass mealPlan parameter for multi-plan support
    private func handleDateSelection(_ date: Date) {
        // Ensure we have an active meal plan
        guard let activePlan = mealPlanService.activeMealPlan else {
            #if DEBUG
            print("No active meal plan available")
            #endif
            return
        }
        
        // Add recipe to meal plan with selected servings
        // M4.2.4: Now passes mealPlan parameter
        if mealPlanService.addRecipeToMealPlan(
            recipe: recipe,
            date: date,
            mealPlan: activePlan,
            servings: Int16(servings)
        ) != nil {
            onDateSelected(date)
            dismiss()
        }
    }
    
    // M4.2: Creates meal plan if none exists, then adds recipe
    private func createMealPlanAndAdd() {
        if let _ = mealPlanService.createMealPlan() {
            // Meal plan created - sheet will reload to show dates
            // User can then select a date
        }
    }
}

// MARK: - Date Button

// M4.2: Individual date button in the date picker grid
struct DateButton: View {
    let date: Date
    let isOccupied: Bool
    let onSelect: () -> Void
    
    // MARK: - Date Formatting
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, etc.
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Oct 27
        return formatter
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // reskin-provisions-press: condensed day label, mono date
                Text(dayFormatter.string(from: date).uppercased())
                    .font(ForagerTheme.captionFont)

                Text(dateFormatter.string(from: date))
                    .font(ForagerTheme.quantityFont)

                if isOccupied {
                    Image(systemName: "checkmark.square.fill")
                        .font(.caption2)
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isOccupied ? ForagerTheme.textTertiary.opacity(0.2) : ForagerTheme.accentPrimary.opacity(0.1))
            .foregroundStyle(isOccupied ? ForagerTheme.textSecondary : ForagerTheme.accentPrimary)
            .cornerRadius(ForagerTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                    .stroke(isToday ? ForagerTheme.accentPrimary : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isOccupied)
    }
    
    // MARK: - Helpers
    
    // M4.2: Checks if this date is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Preview

#Preview {
    // Create a sample recipe for preview
    let context = PersistenceController.preview.container.viewContext
    let recipe = Recipe(context: context)
    recipe.id = UUID()
    recipe.title = "Spaghetti Carbonara"
    recipe.servings = 4
    recipe.sourceURL = "example.com"
    
    return DatePickerSheet(recipe: recipe) { date in
        print("Selected date: \(date)")
    }
}
