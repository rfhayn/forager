//
//  MealPlanDetailView.swift
//  forager
//
//  Enhanced for M4.2.1-3 Enhancement: Inline Autocomplete Meal Planning
//  Each day has its own search field for quick recipe assignment
//  Type-to-filter workflow similar to ingredient autocomplete
//

import SwiftUI
import CoreData

// M4.2.1-3 Enhancement: Meal plan detail view with inline autocomplete per day
// Clean list format where each day has its own search field
// Type to filter recipes, tap to assign - no modals needed
struct MealPlanDetailView: View {

    // MARK: - Properties

    // M4.2.4: The meal plan to display
    @ObservedObject var mealPlan: MealPlan

    // M4.2.4: Core Data context
    @Environment(\.managedObjectContext) private var viewContext

    // M7.3.4: Household service for filtering by householdKey
    @EnvironmentObject private var householdService: HouseholdService
    
    // M4.2.4: Fetch planned meals for this meal plan
    @FetchRequest private var plannedMeals: FetchedResults<PlannedMeal>
    
    // M4.2.1-3 Enhancement: All recipes loaded for autocomplete
    @State private var allRecipes: [Recipe] = []
    
    // M4.3.4: Force UI refresh when meals change
    @State private var refreshID = UUID()
    
    // M4.3.3: Bulk add to shopping list
    @State private var showingBulkAddSheet = false
    @State private var isBulkAdding = false
    @State private var bulkAddProgress: Double = 0.0
    @State private var bulkAddMessage = "Processing recipes..."
    @State private var bulkAddResults: BulkAddResults?
    
    // MARK: - Supporting Types
    
    // M4.3.3: Results from bulk add operation
    struct BulkAddResults {
        let totalRecipes: Int
        let totalIngredients: Int
        let listName: String
    }
    
    // MARK: - Initialization
    
    init(mealPlan: MealPlan) {
        self.mealPlan = mealPlan
        
        // Configure FetchRequest for this specific meal plan
        let planID = mealPlan.id ?? UUID()
        _plannedMeals = FetchRequest<PlannedMeal>(
            sortDescriptors: [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)],
            predicate: NSPredicate(format: "mealPlan.id == %@", planID as CVarArg)
        )
    }
    
    // MARK: - Computed Properties
    
    // M4.2.1-3 Enhancement: Generate array of dates for the meal plan
    private var daysInPlan: [Date] {
        guard let startDate = mealPlan.startDate else { return [] }
        let duration = Int(mealPlan.duration)
        
        return (0..<duration).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: startDate)
        }
    }
    
    // M4.2.1-3 Enhancement: Get planned meal for a specific date
    private func plannedMeal(for date: Date) -> PlannedMeal? {
        plannedMeals.first { meal in
            guard let mealDate = meal.date else { return false }
            return Calendar.current.isDate(mealDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Plan header
                planHeaderView
                    .padding(.bottom, 16)
                
                // Days list with inline autocomplete
                VStack(spacing: 12) {
                    ForEach(daysInPlan, id: \.self) { date in
                        DayRowView(
                            date: date,
                            plannedMeal: plannedMeal(for: date),
                            allRecipes: allRecipes,
                            mealPlan: mealPlan,
                            onRecipeAdded: { recipe, servings in
                                addRecipeToDay(recipe: recipe, date: date, servings: servings)
                            },
                            onRecipeRemoved: { meal in
                                removePlannedMeal(meal)
                            },
                            onMealToggled: { meal in
                                toggleCompletion(for: meal)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .id(refreshID)  // M4.3.4: Force entire list to refresh when completion changes
            }
        }
        .navigationTitle(mealPlan.name ?? "Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAllRecipes()
        }
        // M4.3.3: Progress overlay during bulk add
        .overlay {
            if isBulkAdding {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView(value: bulkAddProgress) {
                            Text(bulkAddMessage)
                                .font(.headline)
                        }
                        .progressViewStyle(.linear)
                        .frame(width: 250)
                        .tint(.blue)
                        
                        Text("\(Int(bulkAddProgress * 100))% complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 20)
                    )
                }
            }
        }
        // M4.3.3: Bulk add to shopping list with servings adjustment
        .sheet(isPresented: $showingBulkAddSheet) {
            SelectListSheet(
                onSelect: { selectedList, adjustedServings in
                    Task {
                        await performBulkAdd(to: selectedList, adjustedServings: adjustedServings)
                    }
                },
                recipes: plannedMeals.compactMap { meal in
                    guard let recipe = meal.recipe else { return nil }
                    return (recipe: recipe, currentServings: meal.servings)
                }
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .alert("Success!", isPresented: .constant(bulkAddResults != nil)) {
            Button("OK") {
                bulkAddResults = nil
            }
        } message: {
            if let results = bulkAddResults {
                Text("Added \(results.totalIngredients) ingredients from \(results.totalRecipes) recipes to \(results.listName)")
            }
        }
    }
    
    // MARK: - Plan Header
    
    private var planHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date range
            if let startDate = mealPlan.startDate {
                Text(formatDateRange(startDate: startDate, duration: Int(mealPlan.duration)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            HStack(spacing: 16) {
                Label("\(plannedMeals.count) meals", systemImage: "fork.knife")
                Label("\(Int(mealPlan.duration)) days", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // M4.3.3: Add All to Shopping List button
            if !plannedMeals.isEmpty {
                Button {
                    showingBulkAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill.badge.plus")
                            .font(.body)
                        Text("Add All to Shopping List")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.green.opacity(0.3), radius: 4, y: 2)
                }
                .disabled(isBulkAdding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions

    // M4.2.1-3 Enhancement: Load all recipes for autocomplete
    // M7.3.4: Filter by householdKey to prevent ghost data from other households
    private func loadAllRecipes() {
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]

        // M7.3.4: Filter by current householdKey to prevent duplicates
        if let householdKey = householdService.currentHouseholdKey {
            fetchRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        } else {
            fetchRequest.predicate = NSPredicate(format: "householdKey == nil")
        }

        do {
            allRecipes = try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching recipes: \(error)")
            allRecipes = []
        }
    }
    
    // M4.2.1-3 Enhancement: Add recipe to specific day
    private func addRecipeToDay(recipe: Recipe, date: Date, servings: Int) {
        // Check if there's already a meal on this day
        if let existingMeal = plannedMeal(for: date) {
            // Remove existing meal first
            removePlannedMeal(existingMeal)
        }
        
        // Add new recipe
        if let _ = MealPlanService.shared.addRecipeToMealPlan(
            recipe: recipe,
            date: date,
            mealPlan: mealPlan,
            servings: Int16(servings)
        ) {
            // Success - meal added
        } else {
            print("Error adding recipe to meal plan")
        }
    }
    
    // M4.2.1-3: Remove planned meal
    private func removePlannedMeal(_ meal: PlannedMeal) {
        viewContext.delete(meal)
        
        do {
            try viewContext.save()
        } catch {
            print("Error removing planned meal: \(error)")
        }
    }
    
    // M4.2.1-3: Format date range for display
    private func formatDateRange(startDate: Date, duration: Int) -> String {
        let endDate = Calendar.current.date(byAdding: .day, value: duration - 1, to: startDate) ?? startDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let year = yearFormatter.string(from: startDate)
        
        return "\(startString) - \(endString), \(year)"
    }
    
    // MARK: - M4.3.3: Bulk Add Operations
    
    // M4.3.3: Process all recipes in meal plan and add to shopping list
    // M4.3.3: Perform bulk add with optional adjusted servings
    private func performBulkAdd(to weeklyList: WeeklyList, adjustedServings: [UUID: Int16] = [:]) async {
        // Count recipes that actually have ingredients
        let recipesWithIngredients = plannedMeals.filter { meal in
            guard let recipe = meal.recipe else { return false }
            guard let ingredients = recipe.ingredients else { return false }
            return ingredients.count > 0
        }
        
        guard !recipesWithIngredients.isEmpty else {
            // Show alert for empty meal plan
            await MainActor.run {
                showingBulkAddSheet = false
            }
            return
        }
        
        await MainActor.run {
            isBulkAdding = true
            bulkAddProgress = 0.0
        }
        
        // Services we'll need
        let templateService = IngredientTemplateService(context: viewContext)
        let scalingService = RecipeScalingService(context: viewContext)
        
        var totalIngredientsAdded = 0
        let totalMeals = recipesWithIngredients.count
        
        // Process each planned meal
        for (index, plannedMeal) in recipesWithIngredients.enumerated() {
            guard let recipe = plannedMeal.recipe else { continue }
            
            // Update progress
            await MainActor.run {
                bulkAddProgress = Double(index) / Double(totalMeals)
                bulkAddMessage = "Processing \(recipe.title ?? "recipe")..."
            }
            
            // M4.3.3: Get servings - use adjusted if available, otherwise use meal servings
            let targetServings: Int
            if let recipeID = recipe.id, let adjusted = adjustedServings[recipeID] {
                targetServings = Int(adjusted)
            } else {
                targetServings = Int(plannedMeal.servings)
            }
            let scaleFactor = recipe.servings > 0 ? Double(targetServings) / Double(recipe.servings) : 1.0
            
            // Get ingredients
            guard let ingredientsSet = recipe.ingredients else { continue }
            let ingredients = Array(ingredientsSet) as! [Ingredient]
            
            // Add each ingredient to the list
            for ingredient in ingredients {
                // Skip if no name
                guard let ingredientName = ingredient.name, !ingredientName.isEmpty else { continue }
                
                // Ensure template exists (for future normalization)
                let cleanName = extractCleanIngredientName(from: ingredientName)
                _ = templateService.findOrCreateTemplate(name: cleanName)
                
                // Create list item
                let listItem = GroceryListItem(context: viewContext)
                listItem.id = UUID()
                listItem.name = ingredientName
                listItem.isCompleted = false
                listItem.sortOrder = Int16(weeklyList.items?.count ?? 0)
                listItem.weeklyList = weeklyList
                
                // M4.3.2: Apply scaling to quantities
                if scaleFactor != 1.0 && ingredient.isParseable && ingredient.numericValue > 0 {
                    let scaledValue = ingredient.numericValue * scaleFactor
                    listItem.displayText = formatScaledQuantity(value: scaledValue, unit: ingredient.standardUnit)
                    listItem.numericValue = scaledValue
                    listItem.standardUnit = ingredient.standardUnit
                    listItem.isParseable = true
                    listItem.parseConfidence = ingredient.parseConfidence
                } else {
                    listItem.displayText = ingredient.displayText ?? ""
                    listItem.numericValue = ingredient.numericValue
                    listItem.standardUnit = ingredient.standardUnit
                    listItem.isParseable = ingredient.isParseable
                    listItem.parseConfidence = ingredient.parseConfidence
                }
                
                // M4.3.1: Establish recipe relationship
                listItem.addToSourceRecipes(recipe)
                
                totalIngredientsAdded += 1
            }
            
            // Small delay to show progress
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Save context
        do {
            try viewContext.save()
            
            // Show success
            await MainActor.run {
                isBulkAdding = false
                showingBulkAddSheet = false
                bulkAddResults = BulkAddResults(
                    totalRecipes: totalMeals,
                    totalIngredients: totalIngredientsAdded,
                    listName: weeklyList.name ?? "shopping list"
                )
            }
        } catch {
            print("Error saving bulk add: \(error)")
            await MainActor.run {
                isBulkAdding = false
            }
        }
    }
    
    // M4.3.3: Format scaled quantity for display
    private func formatScaledQuantity(value: Double, unit: String?) -> String {
        let fractionString = formatToFraction(value)
        
        if let unit = unit, !unit.isEmpty {
            return "\(fractionString) \(unit)"
        } else {
            return fractionString
        }
    }
    
    // M4.3.3: Convert decimal to fraction
    private func formatToFraction(_ value: Double) -> String {
        // Whole number check
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        
        // Common fractions
        let fractions: [(Double, String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.375, "⅜"),
            (0.5, "½"), (0.625, "⅝"), (0.666, "⅔"), (0.75, "¾"), (0.875, "⅞")
        ]
        
        let wholePart = Int(value)
        let fractionalPart = value - Double(wholePart)
        
        // Find closest fraction
        for (decimal, fraction) in fractions {
            if abs(fractionalPart - decimal) < 0.01 {
                if wholePart > 0 {
                    return "\(wholePart) \(fraction)"
                } else {
                    return fraction
                }
            }
        }
        
        // Default to decimal
        return String(format: "%.2f", value)
    }
    
    // MARK: - M4.3.4: Meal Completion
    
    // M4.3.4: Toggle completion status for a planned meal
    // Updates Core Data and persists automatically via context save
    // No date restrictions - users can mark any meal complete regardless of date
    private func toggleCompletion(for meal: PlannedMeal) {
        meal.isCompleted.toggle()
        
        // Update completed date when marking complete
        if meal.isCompleted {
            meal.completedDate = Date()
        } else {
            meal.completedDate = nil
        }
        
        // Save changes to Core Data
        do {
            try viewContext.save()
            print("M4.3.4: Meal completion toggled to: \(meal.isCompleted)")  // Debug logging
            
            // M4.3.4: Force UI refresh
            refreshID = UUID()
        } catch {
            print("M4.3.4: Error toggling meal completion: \(error)")
            // Revert the toggle on error
            meal.isCompleted.toggle()
            meal.completedDate = nil
        }
    }
    
    // M4.3.3: Extract clean ingredient name
    private func extractCleanIngredientName(from fullText: String) -> String {
        var cleaned = fullText
        
        // Remove quantities and measurements
        let measurementPattern = "\\b\\d+(?:\\.\\d+)?\\s*(?:cups?|tbsp|tsp|oz|lbs?|g|kg|ml|l)?\\b"
        if let regex = try? NSRegularExpression(pattern: measurementPattern, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                range: NSRange(cleaned.startIndex..., in: cleaned),
                withTemplate: ""
            )
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
}

// MARK: - Day Row View

// M4.2.1-3 Enhancement: Individual day row with inline autocomplete
// Each day has its own search field for quick recipe assignment
struct DayRowView: View {
    let date: Date
    let plannedMeal: PlannedMeal?
    let allRecipes: [Recipe]
    let mealPlan: MealPlan
    let onRecipeAdded: (Recipe, Int) -> Void
    let onRecipeRemoved: (PlannedMeal) -> Void
    let onMealToggled: (PlannedMeal) -> Void  // M4.3.4: Toggle completion callback
    
    // M4.2.1-3 Enhancement: Search text for this day's autocomplete
    @State private var searchText = ""
    
    // M4.2.1-3 Enhancement: Focus state for search field
    @FocusState private var isSearchFocused: Bool
    
    // M4.2.1-3 Enhancement: Servings for selected recipe
    @State private var selectedServings: Int = 4
    
    // M4.2.1-3 Enhancement: Show servings adjuster
    @State private var showServingsAdjuster = false
    @State private var pendingRecipe: Recipe?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            dayHeader
            
            // Assigned recipe (if exists)
            if let meal = plannedMeal {
                assignedRecipeView(meal: meal)
            } else {
                // Autocomplete search field
                autocompleteSearchField
                
                // Filtered recipe results (when typing)
                if !searchText.isEmpty && !filteredRecipes.isEmpty {
                    recipeResultsList
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - View Components
    
    // M4.2.1-3 Enhancement: Day header with formatted date
    private var dayHeader: some View {
        Text(formattedDate)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    // M4.2.1-3 Enhancement: Autocomplete search field (like ingredient input)
    private var autocompleteSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            TextField("Add recipe...", text: $searchText)
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    // M4.2.1-3 Enhancement: Filtered recipe results list
    private var recipeResultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(filteredRecipes.prefix(5), id: \.id) { recipe in
                Button {
                    handleRecipeSelection(recipe)
                } label: {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.title ?? "Untitled")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("\(recipe.ingredients?.count ?? 0) ingredients • Serves \(Int(recipe.servings))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if filteredRecipes.count > 5 {
                Text("+ \(filteredRecipes.count - 5) more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
            }
        }
    }
    
    // M4.2.1-3 Enhancement: Assigned recipe display
    // M4.3.4: Added completion checkbox and visual feedback
    private func assignedRecipeView(meal: PlannedMeal) -> some View {
        HStack(spacing: 12) {
            // M4.3.4: Completion checkbox - works for any date
            Button {
                onMealToggled(meal)
            } label: {
                Image(systemName: meal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(meal.isCompleted ? .green : .gray)
                    .frame(width: 44, height: 44)  // M4.3.4: Standard tap target size
                    .contentShape(Rectangle())  // M4.3.4: Entire frame is tappable
            }
            .buttonStyle(.borderless)  // M4.3.4: Prevents row tap interference
            
            Image(systemName: "fork.knife.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.recipe?.title ?? "Untitled Recipe")
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(meal.isCompleted, color: .secondary)  // M4.3.4: Strikethrough when completed
                
                Text("\(Int(meal.servings)) servings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough(meal.isCompleted, color: .secondary)  // M4.3.4: Strikethrough when completed
            }
            .opacity(meal.isCompleted ? 0.5 : 1.0)  // M4.3.4: Reduced opacity when completed
            
            Spacer()
            
            // Remove button
            Button {
                onRecipeRemoved(meal)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    
    // M4.2.1-3 Enhancement: Filter recipes based on search text
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return []
        }
        
        return allRecipes.filter { recipe in
            guard let title = recipe.title else { return false }
            return title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // M4.2.1-3 Enhancement: Handle recipe selection
    private func handleRecipeSelection(_ recipe: Recipe) {
        // Add with default servings
        let servings = Int(recipe.servings)
        onRecipeAdded(recipe, servings)
        
        // Clear search
        searchText = ""
        isSearchFocused = false
    }
    
    // M4.2.1-3 Enhancement: Format date for display
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"  // "Friday, Nov 7"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct MealPlanDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        // Create sample meal plan
        let plan = MealPlan(context: context)
        plan.id = UUID()
        plan.name = "This Week"
        plan.startDate = Date()
        plan.duration = 7

        // Create sample recipes
        let recipe1 = Recipe(context: context)
        recipe1.id = UUID()
        recipe1.title = "Hot Dog and Tortellini"
        recipe1.servings = 4

        let recipe2 = Recipe(context: context)
        recipe2.id = UUID()
        recipe2.title = "Chocolate Chip Cookies"
        recipe2.servings = 24

        try? context.save()

        // M7.3.4: Create HouseholdService for preview
        let householdService = HouseholdService(context: context)

        return NavigationStack {
            MealPlanDetailView(mealPlan: plan)
                .environment(\.managedObjectContext, context)
                .environmentObject(householdService)
        }
    }
}
