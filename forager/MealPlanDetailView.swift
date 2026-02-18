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

    @FetchRequest private var plannedMeals: FetchedResults<PlannedMeal>

    @State private var allRecipes: [Recipe] = []
    @State private var refreshID = UUID()

    // Bulk add state
    @State private var showingBulkAddSheet = false
    @State private var isBulkAdding = false
    @State private var bulkAddProgress: Double = 0.0
    @State private var bulkAddMessage = "Processing recipes..."
    @State private var bulkAddResults: BulkAddResults?

    // Remove confirmation
    @State private var mealToRemove: PlannedMeal?
    @State private var showRemoveAlert = false

    // Swap
    @State private var swapDate: Date?
    @State private var showSwapPicker = false

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
                }
            }
        }
        .background(ForagerTheme.backgroundCanvas)
        .safeAreaInset(edge: .bottom) {
            if !plannedMeals.isEmpty {
                addToListButton
            }
        }
        .navigationTitle(mealPlan.name ?? "Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAllRecipes() }
        .overlay {
            if isBulkAdding { bulkAddOverlay }
        }
        .sheet(isPresented: $showingBulkAddSheet) {
            SelectListSheet(
                onSelect: { selectedList, adjustedServings in
                    Task { await performBulkAdd(to: selectedList, adjustedServings: adjustedServings) }
                },
                recipes: plannedMeals.compactMap { meal in
                    guard let recipe = meal.recipe else { return nil }
                    return (recipe: recipe, currentServings: meal.servings)
                }
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showSwapPicker) {
            recipePickerSheet
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
    }

    // MARK: - Day Strip

    private var dayStripView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ForagerTheme.Spacing.md) {
                    ForEach(daysInPlan, id: \.self) { date in
                        Button {
                            // no-op: tapping strip circles is decorative
                        } label: {
                            VStack(spacing: ForagerTheme.Spacing.xs) {
                                Text(dayAbbreviation(date))
                                    .font(ForagerTheme.captionFont)
                                    .foregroundStyle(ForagerTheme.textTertiary)
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(ForagerTheme.bodyFont.bold())
                                    .foregroundStyle(isToday(date) ? .white : ForagerTheme.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(isToday(date) ? ForagerTheme.accentPrimary : .clear)
                                    )
                            }
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal, ForagerTheme.Spacing.lg)
                .padding(.vertical, ForagerTheme.Spacing.sm)
            }
            .background(ForagerTheme.surfacePrimary)
            .onAppear {
                if let today = daysInPlan.first(where: { Calendar.current.isDateInToday($0) }) {
                    proxy.scrollTo(today, anchor: .center)
                }
            }
        }
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
        .foragerGlassCard()
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
                    Text("TODAY")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                        .padding(.horizontal, ForagerTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(ForagerTheme.accentTint)
                        .clipShape(Capsule())
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
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Text(option.rawValue)
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                    Spacer()
                }
                .opacity(meal.isCompleted ? 0.5 : 1.0)
            } else if let recipe = meal.recipe {
                // Recipe display
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.title3)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                    VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                        Text(recipe.recipeDisplayTitle)
                            .font(ForagerTheme.bodyFont)
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
                    Image(systemName: meal.isCompleted ? "checkmark" : "circle")
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
                    swapDate = date
                    showSwapPicker = true
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
        VStack(spacing: ForagerTheme.Spacing.md) {
            // Recipe picker
            Menu {
                ForEach(allRecipes.prefix(20), id: \.objectID) { recipe in
                    Button {
                        addRecipeToDay(recipe: recipe, date: date, servings: Int(recipe.servings))
                    } label: {
                        Label(recipe.recipeDisplayTitle, systemImage: "fork.knife")
                    }
                }
            } label: {
                HStack {
                    Text("Choose Recipe")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }

            // Quick-select pills
            HStack(spacing: ForagerTheme.Spacing.sm) {
                ForEach(PlannedMeal.QuickOption.allCases, id: \.rawValue) { option in
                    Button {
                        assignQuickOption(option, to: date)
                    } label: {
                        HStack(spacing: ForagerTheme.Spacing.xs) {
                            Image(systemName: option.icon)
                                .font(.caption2)
                            Text(option.rawValue)
                        }
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .padding(.horizontal, ForagerTheme.Spacing.sm)
                        .padding(.vertical, ForagerTheme.Spacing.xs)
                        .background(ForagerTheme.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                    }
                    .accessibilityLabel(option.rawValue)
                    .accessibilityHint("Set this day to \(option.rawValue)")
                }
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous)
                .strokeBorder(ForagerTheme.borderDefault, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
    }

    // MARK: - Sticky Bottom Button

    private var addToListButton: some View {
        Button {
            showingBulkAddSheet = true
        } label: {
            Text("Add to Grocery List")
                .font(ForagerTheme.bodyFont.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForagerTheme.Spacing.md)
                .background(ForagerTheme.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        }
        .disabled(isBulkAdding)
        .padding(ForagerTheme.Spacing.lg)
        .background(.regularMaterial)
    }

    // MARK: - Recipe Picker Sheet

    private var recipePickerSheet: some View {
        NavigationStack {
            List(allRecipes.prefix(30), id: \.objectID) { recipe in
                Button {
                    if let date = swapDate {
                        // Remove existing meal first
                        if let existing = plannedMeal(for: date) {
                            removePlannedMeal(existing)
                        }
                        addRecipeToDay(recipe: recipe, date: date, servings: Int(recipe.servings))
                    }
                    showSwapPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                            Text(recipe.recipeDisplayTitle)
                                .font(ForagerTheme.bodyFont)
                                .foregroundStyle(ForagerTheme.textPrimary)
                            Text(recipe.recipeServingsDescription)
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Choose Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSwapPicker = false }
                }
            }
        }
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
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
        }
    }

    // MARK: - Computed Properties

    private var daysInPlan: [Date] {
        guard let startDate = mealPlan.startDate else { return [] }
        return (0..<Int(mealPlan.duration)).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: startDate)
        }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func fullDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func loadAllRecipes() {
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]
        if let householdKey = householdService.currentHouseholdKey {
            fetchRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        } else {
            fetchRequest.predicate = NSPredicate(format: "householdKey == nil")
        }
        do {
            allRecipes = try viewContext.fetch(fetchRequest)
        } catch {
            allRecipes = []
        }
    }

    private func addRecipeToDay(recipe: Recipe, date: Date, servings: Int) {
        if let existingMeal = plannedMeal(for: date) {
            removePlannedMeal(existingMeal)
        }
        _ = MealPlanService.shared.addRecipeToMealPlan(
            recipe: recipe, date: date, mealPlan: mealPlan, servings: Int16(servings)
        )
    }

    private func assignQuickOption(_ option: PlannedMeal.QuickOption, to date: Date) {
        _ = MealPlanService.shared.setQuickOption(option, for: date, in: mealPlan)
    }

    private func removePlannedMeal(_ meal: PlannedMeal) {
        viewContext.delete(meal)
        try? viewContext.save()
    }

    private func toggleCompletion(for meal: PlannedMeal) {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.7)) {
            meal.isCompleted.toggle()
            meal.completedDate = meal.isCompleted ? Date() : nil

            do {
                try viewContext.save()
                let generator = UIImpactFeedbackGenerator(style: meal.isCompleted ? .medium : .light)
                generator.impactOccurred()
                refreshID = UUID()
            } catch {
                meal.isCompleted.toggle()
                meal.completedDate = nil
            }
        }
    }

    // MARK: - Bulk Add

    private func performBulkAdd(to weeklyList: WeeklyList, adjustedServings: [UUID: Int16] = [:]) async {
        let recipesWithIngredients = plannedMeals.filter { meal in
            guard let recipe = meal.recipe,
                  let ingredients = recipe.ingredients else { return false }
            return ingredients.count > 0
        }

        guard !recipesWithIngredients.isEmpty else {
            await MainActor.run { showingBulkAddSheet = false }
            return
        }

        await MainActor.run {
            isBulkAdding = true
            bulkAddProgress = 0.0
        }

        let templateService = IngredientTemplateService(context: viewContext)
        var totalIngredientsAdded = 0
        let totalMeals = recipesWithIngredients.count

        for (index, plannedMeal) in recipesWithIngredients.enumerated() {
            guard let recipe = plannedMeal.recipe else { continue }

            await MainActor.run {
                bulkAddProgress = Double(index) / Double(totalMeals)
                bulkAddMessage = "Processing \(recipe.title ?? "recipe")..."
            }

            let targetServings: Int
            if let recipeID = recipe.id, let adjusted = adjustedServings[recipeID] {
                targetServings = Int(adjusted)
            } else {
                targetServings = Int(plannedMeal.servings)
            }
            let scaleFactor = recipe.servings > 0 ? Double(targetServings) / Double(recipe.servings) : 1.0

            guard let ingredientsSet = recipe.ingredients else { continue }
            let ingredients = Array(ingredientsSet) as! [Ingredient]

            for ingredient in ingredients {
                guard let ingredientName = ingredient.name, !ingredientName.isEmpty else { continue }

                let cleanName = extractCleanIngredientName(from: ingredientName)
                _ = templateService.findOrCreateTemplate(name: cleanName)

                let listItem = GroceryListItem(context: viewContext)
                listItem.id = UUID()
                listItem.name = ingredientName
                listItem.isCompleted = false
                listItem.sortOrder = Int16(weeklyList.items?.count ?? 0)
                listItem.weeklyList = weeklyList

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

                listItem.addToSourceRecipes(recipe)
                totalIngredientsAdded += 1
            }

            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        do {
            try viewContext.save()
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
            await MainActor.run { isBulkAdding = false }
        }
    }

    private func formatScaledQuantity(value: Double, unit: String?) -> String {
        let fractionString = formatToFraction(value)
        if let unit = unit, !unit.isEmpty {
            return "\(fractionString) \(unit)"
        }
        return fractionString
    }

    private func formatToFraction(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }

        let fractions: [(Double, String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.375, "⅜"),
            (0.5, "½"), (0.625, "⅝"), (0.666, "⅔"), (0.75, "¾"), (0.875, "⅞")
        ]

        let wholePart = Int(value)
        let fractionalPart = value - Double(wholePart)

        for (decimal, fraction) in fractions {
            if abs(fractionalPart - decimal) < 0.01 {
                return wholePart > 0 ? "\(wholePart) \(fraction)" : fraction
            }
        }

        return String(format: "%.2f", value)
    }

    private func extractCleanIngredientName(from fullText: String) -> String {
        var cleaned = fullText
        let measurementPattern = "\\b\\d+(?:\\.\\d+)?\\s*(?:cups?|tbsp|tsp|oz|lbs?|g|kg|ml|l)?\\b"
        if let regex = try? NSRegularExpression(pattern: measurementPattern, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: ""
            )
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
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
