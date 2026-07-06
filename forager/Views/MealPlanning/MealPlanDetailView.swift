//
//  MealPlanDetailView.swift
//  forager
//
//  Created for M4.2.1-3: Inline Autocomplete Meal Planning
//  M15.5: Rewritten with horizontal day strip, action buttons, quick-select pills
//

import SwiftUI
import CoreData

// MARK: - Main View

struct MealPlanDetailView: View {

    @ObservedObject var mealPlan: MealPlan
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var groceryListItemService: GroceryListItemService

    @FetchRequest private var plannedMeals: FetchedResults<PlannedMeal>

    @State private var refreshID = UUID()

    // M9.26: Editable title
    @State private var isEditingTitle = false
    @State private var editedTitle = ""

    // Bulk add state
    @State private var showingBulkAddSheet = false
    @State private var isBulkAdding = false
    @State private var bulkAddProgress: Double = 0.0
    @State private var bulkAddMessage = "Processing recipes..."
    @State private var bulkAddResults: BulkAddResults?

    // M9.16: Ingredient selection wizard state
    @State private var showingIngredientSelection = false
    @State private var selectedTargetList: WeeklyList?

    // Remove confirmation
    @State private var mealToRemove: PlannedMeal?
    @State private var showRemoveAlert = false

    // Error feedback
    @State private var showingError = false
    @State private var errorMessage = ""

    // M9.0.1: Inline recipe search (autocomplete in day card)
    @State private var recipeSearchText = ""
    @State private var allRecipes: [Recipe] = []
    @FocusState private var focusedSearchDate: Date?

    // M9.0.1: Sheet picker for swap flow only
    @State private var recipePickerPayload: RecipePickerPayload?

    struct BulkAddResults {
        let totalRecipes: Int
        let totalIngredients: Int
        let listName: String
    }

    init(mealPlan: MealPlan) {
        self.mealPlan = mealPlan
        let planID = mealPlan.id ?? UUID()
        _plannedMeals = FetchRequest<PlannedMeal>(
            sortDescriptors: [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)],
            predicate: NSPredicate(format: "mealPlan.id == %@", planID as CVarArg)
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Fixed day strip
            dayStripView

            Divider()

            // Scrollable day cards
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: ForagerTheme.Spacing.lg) {
                        ForEach(daysInPlan, id: \.self) { date in
                            dayCard(for: date)
                                .id(date)
                        }
                    }
                    .padding(ForagerTheme.Spacing.lg)
                }
                .onAppear {
                    if let today = daysInPlan.first(where: { Calendar.current.isDateInToday($0) }) {
                        proxy.scrollTo(today, anchor: .top)
                    }
                    loadRecipes()
                }
            }
        }
        .background(ForagerTheme.backgroundCanvas)
        .safeAreaInset(edge: .bottom) {
            if !plannedMeals.isEmpty {
                addToListButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isEditingTitle {
                    TextField("Plan name", text: $editedTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .submitLabel(.done)
                        .onSubmit { savePlanTitle() }
                } else {
                    Text(mealPlan.name ?? "Meal Plan")
                        .font(.headline)
                        .onLongPressGesture {
                            editedTitle = mealPlan.name ?? ""
                            isEditingTitle = true
                        }
                }
            }
        }
        .overlay {
            if isBulkAdding { bulkAddOverlay }
        }
        .sheet(isPresented: $showingBulkAddSheet, onDismiss: {
            // M9.16: After list selection sheet dismisses, present ingredient selection wizard
            if selectedTargetList != nil {
                showingIngredientSelection = true
            }
        }) {
            SelectListSheet(
                onSelect: { selectedList, _ in
                    selectedTargetList = selectedList
                    showingBulkAddSheet = false
                },
                recipes: plannedMeals.compactMap { meal in
                    guard let recipe = meal.recipe else { return nil }
                    return (recipe: recipe, currentServings: meal.servings)
                }
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingIngredientSelection) {
            if let list = selectedTargetList {
                MealPlanIngredientSelectionView(
                    targetList: list,
                    recipes: plannedMeals.compactMap { meal in
                        guard let recipe = meal.recipe else { return nil }
                        return (recipe: recipe, servings: meal.servings)
                    }
                )
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(groceryListItemService)
            }
        }
        .sheet(item: $recipePickerPayload) { payload in
            RecipePickerSheet(
                date: payload.date,
                mealPlan: payload.mealPlan,
                onRecipeSelected: { recipe, servings in
                    // M9.0.1: Remove existing meal first (swap case), then add new
                    if let existingMeal = plannedMeal(for: payload.date) {
                        removePlannedMeal(existingMeal)
                    }
                    _ = MealPlanService.shared.addRecipeToMealPlan(
                        recipe: recipe, date: payload.date,
                        mealPlan: mealPlan, servings: Int16(servings)
                    )
                }
            )
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(householdService)
        }
        .alert("Remove \(mealToRemove?.recipe?.title ?? mealToRemove?.quickOption ?? "meal")?",
               isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { mealToRemove = nil }
            Button("Remove", role: .destructive) {
                if let meal = mealToRemove { removePlannedMeal(meal) }
                mealToRemove = nil
            }
        } message: {
            if let meal = mealToRemove, let recipe = meal.recipe {
                Text("\(recipe.ingredients?.count ?? 0) ingredients from this recipe may be on your grocery list.")
            }
        }
        .alert("Success!", isPresented: .constant(bulkAddResults != nil)) {
            Button("OK") { bulkAddResults = nil }
        } message: {
            if let results = bulkAddResults {
                Text("Added \(results.totalIngredients) ingredients from \(results.totalRecipes) recipes to \(results.listName)")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Day Strip

    private var dayStripView: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            ForEach(daysInPlan, id: \.self) { date in
                VStack(spacing: ForagerTheme.Spacing.xs) {
                    Text(dayAbbreviation(date))
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(ForagerTheme.bodyFont.bold())
                        .foregroundStyle(isToday(date) ? ForagerTheme.buttonPrimaryText : ForagerTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            // reskin-provisions-press: square day indicator (matches MealPlanListView)
                            RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                                .fill(isToday(date) ? ForagerTheme.accentPrimary : .clear)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .background(ForagerTheme.surfacePrimary)
    }

    // MARK: - Day Card

    @ViewBuilder
    private func dayCard(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.md) {
            // Centered day header
            dayHeader(for: date)

            if let meal = plannedMeal(for: date) {
                plannedDayContent(meal)
            } else {
                unplannedDayContent(for: date)
            }
        }
        // reskin-provisions-press: broadsheet day block — hairline rule, no box
        .padding(.vertical, ForagerTheme.Spacing.md)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ForagerTheme.borderSubtle)
                .frame(height: 1.5)
        }
    }

    // MARK: - Day Header

    private func dayHeader(for date: Date) -> some View {
        HStack {
            Spacer()
            VStack(spacing: ForagerTheme.Spacing.xs) {
                Text(fullDayName(date))
                    .font(ForagerTheme.bodyFont.bold())
                    .foregroundStyle(ForagerTheme.textPrimary)
                if isToday(date) {
                    // reskin-provisions-press: printed tomato tag (matches ACTIVE tag)
                    Text("TODAY")
                        .font(.system(size: 10, weight: .bold).width(.condensed))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(ForagerTheme.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
                }
            }
            Spacer()
        }
    }

    // MARK: - Planned Day

    private func plannedDayContent(_ meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.md) {
            if meal.isQuickOption, let option = meal.quickOptionEnum {
                // Quick option display
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Image(systemName: option.icon)
                        .font(.title3)
                        .foregroundStyle(meal.isCompleted ? ForagerTheme.textDisabled : ForagerTheme.textSecondary)
                    Text(option.rawValue)
                        .font(ForagerTheme.bodyCondensed)
                        .fontWeight(.medium)
                        .foregroundStyle(meal.isCompleted ? ForagerTheme.textDisabled : ForagerTheme.textPrimary)
                        .strikethrough(meal.isCompleted)
                    Spacer()
                }
            } else if let recipe = meal.recipe {
                // Recipe display
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.title3)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                    VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                        Text(recipe.recipeDisplayTitle)
                            .font(ForagerTheme.bodyCondensed)
                            .fontWeight(.medium)
                            .foregroundStyle(ForagerTheme.textPrimary)
                            .strikethrough(meal.isCompleted)
                        Text(recipe.recipeServingsDescription)
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    Spacer()
                }
                .opacity(meal.isCompleted ? 0.5 : 1.0)
            }

            // Action buttons
            mealActionButtons(for: meal)
        }
    }

    // MARK: - Action Buttons

    private func mealActionButtons(for meal: PlannedMeal) -> some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            // Done toggle
            Button {
                toggleCompletion(for: meal)
            } label: {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    // reskin-provisions-press: square print-check vocabulary
                    Image(systemName: meal.isCompleted ? "checkmark.square.fill" : "square")
                    Text("Done")
                }
                .font(ForagerTheme.captionFont)
                .foregroundStyle(meal.isCompleted ? ForagerTheme.accentPrimary : ForagerTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForagerTheme.Spacing.xs)
                .background(meal.isCompleted ? ForagerTheme.accentTint : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                        .strokeBorder(meal.isCompleted ? ForagerTheme.accentPrimary : ForagerTheme.borderDefault)
                )
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
            }
            .accessibilityHint("Mark this meal as completed")

            // Swap
            Button {
                if let date = meal.date {
                    recipePickerPayload = RecipePickerPayload(date: date, mealPlan: mealPlan)
                }
            } label: {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Swap")
                }
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForagerTheme.Spacing.xs)
                .overlay(
                    RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                        .strokeBorder(ForagerTheme.borderDefault)
                )
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
            }
            .accessibilityHint("Change the recipe for this meal")

            // Remove
            Button {
                mealToRemove = meal
                showRemoveAlert = true
            } label: {
                Text("Remove")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.statusDangerFG)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForagerTheme.Spacing.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                            .strokeBorder(ForagerTheme.statusDangerFG.opacity(0.5))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
            }
            .accessibilityHint("Remove this meal from the plan")
        }
    }

    // MARK: - Unplanned Day

    private func unplannedDayContent(for date: Date) -> some View {
        let isActive = focusedSearchDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false

        return VStack(spacing: ForagerTheme.Spacing.md) {
            // M9.0.1: Inline recipe search field
            HStack(spacing: ForagerTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .font(ForagerTheme.captionFont)

                TextField("Search recipes…", text: $recipeSearchText)
                    .font(ForagerTheme.bodyFont)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($focusedSearchDate, equals: date)
                    .onChange(of: focusedSearchDate) {
                        // Clear search text when switching between day fields
                        recipeSearchText = ""
                    }

                if isActive && !recipeSearchText.isEmpty {
                    Button {
                        recipeSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                }
            }
            .padding(ForagerTheme.Spacing.sm)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))

            // M9.0.1: Inline search results
            if isActive && !recipeSearchText.isEmpty {
                if filteredRecipes.isEmpty {
                    Text("No matching recipes")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 0) {
                        ForEach(filteredRecipes.prefix(5), id: \.id) { recipe in
                            Button {
                                addRecipeToDate(recipe, date: date)
                            } label: {
                                HStack(spacing: ForagerTheme.Spacing.sm) {
                                    Image(systemName: "fork.knife")
                                        .font(ForagerTheme.captionFont)
                                        .foregroundStyle(ForagerTheme.accentPrimary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recipe.title ?? "Untitled")
                                            .font(ForagerTheme.bodyFont)
                                            .foregroundStyle(ForagerTheme.textPrimary)
                                        Text("\(recipe.ingredients?.count ?? 0) ingredients · Serves \(Int(recipe.servings))")
                                            .font(ForagerTheme.captionFont)
                                            .foregroundStyle(ForagerTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(ForagerTheme.accentPrimary)
                                }
                                .padding(.vertical, ForagerTheme.Spacing.sm)
                                .padding(.horizontal, ForagerTheme.Spacing.xs)
                            }

                            if recipe.id != filteredRecipes.prefix(5).last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(ForagerTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                }
            }

            // Quick-select pills — 2x2 grid
            let options = PlannedMeal.QuickOption.allCases
            VStack(spacing: ForagerTheme.Spacing.sm) {
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    ForEach(options.prefix(2), id: \.rawValue) { option in
                        quickOptionPill(option, date: date)
                    }
                }
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    ForEach(options.suffix(2), id: \.rawValue) { option in
                        quickOptionPill(option, date: date)
                    }
                }
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .background(ForagerTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
    }

    // MARK: - Quick Option Pill

    private func quickOptionPill(_ option: PlannedMeal.QuickOption, date: Date) -> some View {
        Button {
            assignQuickOption(option, to: date)
        } label: {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                Image(systemName: option.icon)
                    .font(ForagerTheme.captionFont)
                Text(option.rawValue)
            }
            .font(ForagerTheme.captionFont)
            .foregroundStyle(ForagerTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ForagerTheme.Spacing.sm)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        }
        .accessibilityLabel(option.rawValue)
        .accessibilityHint("Set this day to \(option.rawValue)")
    }

    // MARK: - Sticky Bottom Button

    private var addToListButton: some View {
        Button {
            showingBulkAddSheet = true
        } label: {
            Text("Add to Grocery List")
                .font(ForagerTheme.bodyFont.bold())
                .foregroundStyle(ForagerTheme.buttonPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForagerTheme.Spacing.md)
                .background(ForagerTheme.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        }
        .disabled(isBulkAdding)
        .padding(ForagerTheme.Spacing.lg)
        .background(.regularMaterial)
    }

    // MARK: - Bulk Add Overlay

    private var bulkAddOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView(value: bulkAddProgress) {
                    Text(bulkAddMessage)
                        .font(ForagerTheme.secondaryFont)
                }
                .progressViewStyle(.linear)
                .frame(width: 250)
                .tint(ForagerTheme.accentPrimary)

                Text("\(Int(bulkAddProgress * 100))% complete")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            .padding(30)
            // reskin-provisions-press: matte panel, no glass on content HUD
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous)
                    .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Computed Properties

    private var daysInPlan: [Date] {
        guard let startDate = mealPlan.startDate else { return [] }
        return (0..<Int(mealPlan.duration)).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: startDate)
        }
    }

    // M9.0.1: Filtered recipes for inline search
    private var filteredRecipes: [Recipe] {
        guard !recipeSearchText.isEmpty else { return [] }
        return allRecipes.filter { recipe in
            guard let title = recipe.title else { return false }
            return title.localizedCaseInsensitiveContains(recipeSearchText)
        }
    }

    private func loadRecipes() {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]
        if let key = householdService.currentHouseholdKey {
            request.predicate = NSPredicate(format: "householdKey == %@", key)
        } else {
            request.predicate = NSPredicate(format: "householdKey == nil")
        }
        allRecipes = (try? viewContext.fetch(request)) ?? []
    }

    private func plannedMeal(for date: Date) -> PlannedMeal? {
        plannedMeals.first { meal in
            guard let mealDate = meal.date else { return false }
            return Calendar.current.isDate(mealDate, inSameDayAs: date)
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func dayAbbreviation(_ date: Date) -> String {
        DateFormatter.dayAbbreviation.string(from: date).uppercased()
    }

    private func fullDayName(_ date: Date) -> String {
        DateFormatter.fullDayDate.string(from: date)
    }

    private func savePlanTitle() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            mealPlan.name = trimmed
            do {
                try mealPlan.managedObjectContext?.save()
            } catch {
                #if DEBUG
                print("⚠️ Failed to save meal plan title: \(error)")
                #endif
            }
        }
        isEditingTitle = false
    }

    // MARK: - Actions

    // M9.0.1: Add recipe from inline search results
    private func addRecipeToDate(_ recipe: Recipe, date: Date) {
        _ = MealPlanService.shared.addRecipeToMealPlan(
            recipe: recipe, date: date,
            mealPlan: mealPlan, servings: Int16(recipe.servings)
        )
        recipeSearchText = ""
        focusedSearchDate = nil
    }

    private func assignQuickOption(_ option: PlannedMeal.QuickOption, to date: Date) {
        _ = MealPlanService.shared.setQuickOption(option, for: date, in: mealPlan)
    }

    private func removePlannedMeal(_ meal: PlannedMeal) {
        MealPlanService.shared.deletePlannedMeal(meal)
        if let error = MealPlanService.shared.lastError {
            errorMessage = "Failed to remove meal: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func toggleCompletion(for meal: PlannedMeal) {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.7)) {
            MealPlanService.shared.toggleMealCompletion(meal)
            let generator = UIImpactFeedbackGenerator(style: meal.isCompleted ? .medium : .light)
            generator.impactOccurred()
            refreshID = UUID()
        }
    }

    // MARK: - Bulk Add

    @MainActor
    private func performBulkAdd(to weeklyList: WeeklyList, adjustedServings: [UUID: Int16] = [:]) async {
        let recipesWithIngredients = plannedMeals.filter { meal in
            guard let recipe = meal.recipe,
                  let ingredients = recipe.ingredients else { return false }
            return ingredients.count > 0
        }

        guard !recipesWithIngredients.isEmpty else {
            showingBulkAddSheet = false
            return
        }

        isBulkAdding = true
        bulkAddProgress = 0.0

        var totalIngredientsAdded = 0
        let totalMeals = recipesWithIngredients.count

        for (index, plannedMeal) in recipesWithIngredients.enumerated() {
            guard let recipe = plannedMeal.recipe else { continue }

            bulkAddProgress = Double(index) / Double(totalMeals)
            bulkAddMessage = "Processing \(recipe.title ?? "recipe")..."

            let targetServings: Int
            if let recipeID = recipe.id, let adjusted = adjustedServings[recipeID] {
                targetServings = Int(adjusted)
            } else {
                targetServings = Int(plannedMeal.servings)
            }
            let scaleFactor = recipe.servings > 0 ? Double(targetServings) / Double(recipe.servings) : 1.0

            guard let ingredientsSet = recipe.ingredients else { continue }
            let ingredients = Array(ingredientsSet) as! [Ingredient]

            // M9.16: Delegate to GroceryListItemService for consistent template,
            // category, cross-store safety, and merge logic
            let added = groceryListItemService.addIngredients(
                ingredients,
                to: weeklyList,
                scaleFactor: scaleFactor,
                sourceRecipe: recipe,
                mergeWithExisting: true
            )
            totalIngredientsAdded += added.count

            // Yield to allow UI updates between recipes
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        isBulkAdding = false
        showingBulkAddSheet = false
        bulkAddResults = BulkAddResults(
            totalRecipes: totalMeals,
            totalIngredients: totalIngredientsAdded,
            listName: weeklyList.name ?? "shopping list"
        )
    }


}

// MARK: - Preview

struct MealPlanDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let plan = MealPlan(context: context)
        plan.id = UUID()
        plan.name = "This Week"
        plan.startDate = Date()
        plan.duration = 7
        try? context.save()

        let householdService = HouseholdService(context: context)

        return NavigationStack {
            MealPlanDetailView(mealPlan: plan)
                .environment(\.managedObjectContext, context)
                .environmentObject(householdService)
        }
    }
}
