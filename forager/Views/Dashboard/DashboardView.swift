// DashboardView.swift
// FUI-1.8: Dashboard redesign — personalized greeting, next meal, grocery snapshot,
// meal plan overview, quick actions. Recipe Spotlight deferred to post-launch.

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var selectedTab: NavigationTab

    // Grocery lists: most recent incomplete list for grocery run card
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyList.dateCreated, ascending: false)],
        animation: .default
    ) private var allWeeklyLists: FetchedResults<WeeklyList>

    @StateObject private var mealPlanService = MealPlanService.shared

    private var weeklyLists: [WeeklyList] {
        let key = householdService.currentHouseholdKey
        return allWeeklyLists.filter { list in
            if let key { return list.householdKey == key }
            return list.householdKey == nil
        }
    }

    private var activeGroceryList: WeeklyList? {
        weeklyLists.first { !$0.isCompleted }
    }

    // MARK: - Meal Data

    private var nextMeal: PlannedMeal? {
        guard let plan = mealPlanService.activeMealPlan,
              let meals = plan.plannedMeals?.allObjects as? [PlannedMeal] else { return nil }

        let calendar = Calendar.current

        // Meal type ordering for same-day sorting
        let mealOrder: [String: Int] = ["breakfast": 0, "lunch": 1, "dinner": 2, "snack": 3]

        // Find next uncompleted meal today or tomorrow
        let upcoming = meals
            .filter { meal in
                guard let date = meal.date, !meal.isCompleted else { return false }
                return calendar.isDateInToday(date) || calendar.isDateInTomorrow(date)
            }
            .sorted { a, b in
                let dateA = a.date ?? .distantFuture
                let dateB = b.date ?? .distantFuture
                if !calendar.isDate(dateA, inSameDayAs: dateB) {
                    return dateA < dateB
                }
                let orderA = mealOrder[(a.mealType ?? "").lowercased()] ?? 99
                let orderB = mealOrder[(b.mealType ?? "").lowercased()] ?? 99
                return orderA < orderB
            }

        return upcoming.first
    }

    private var nextMealTimeLabel: String {
        guard let meal = nextMeal, let date = meal.date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "tonight"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        }
        return ""
    }

    // MARK: - Meal Plan Overview Data

    private var planDaysFilled: (filled: Int, total: Int)? {
        guard let plan = mealPlanService.activeMealPlan,
              let startDate = plan.startDate,
              let meals = plan.plannedMeals?.allObjects as? [PlannedMeal] else { return nil }

        let total = Int(plan.duration)
        let calendar = Calendar.current

        // Count days that have at least one meal
        var daysWithMeals = Set<Int>()
        for meal in meals {
            guard let date = meal.date else { continue }
            let dayOffset = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0
            if dayOffset >= 0 && dayOffset < total {
                daysWithMeals.insert(dayOffset)
            }
        }

        return (daysWithMeals.count, total)
    }

    private var planDayIndicators: [(dayLetter: String, hasMeal: Bool)]? {
        guard let plan = mealPlanService.activeMealPlan,
              let startDate = plan.startDate,
              let meals = plan.plannedMeals?.allObjects as? [PlannedMeal] else { return nil }

        let total = Int(plan.duration)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var daysWithMeals = Set<Int>()
        for meal in meals {
            guard let date = meal.date else { continue }
            let dayOffset = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0
            if dayOffset >= 0 && dayOffset < total {
                daysWithMeals.insert(dayOffset)
            }
        }

        var indicators: [(String, Bool)] = []
        for i in 0..<total {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let label = String(formatter.string(from: date).prefix(3))
                indicators.append((label, daysWithMeals.contains(i)))
            }
        }
        return indicators
    }

    // FUI-1.9: Dashboard sheet states for ghost card actions
    @State private var showingRecipePicker = false
    @State private var showingCreateListOptions = false
    @State private var showingCreateMealPlan = false
    @State private var showingMealPlanPicker = false

    // Tomorrow's meal
    private var tomorrowMeal: PlannedMeal? {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else { return nil }
        return mealPlanService.plannedMeals.first { meal in
            guard let mealDate = meal.date, !meal.isCompleted else { return false }
            return calendar.isDate(mealDate, inSameDayAs: tomorrow)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                // Date subtitle
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .padding(.top, ForagerTheme.Spacing.xs)

                // 1. Tonight's Meal (always visible)
                if let meal = nextMeal {
                    Button { selectedTab = .mealPlans } label: {
                        nextMealCard(meal: meal)
                    }
                    .buttonStyle(.plain)
                } else {
                    ghostCard(
                        icon: "fork.knife",
                        title: "Tonight's Meal",
                        message: "No recipe for today.",
                        action: "Tap to pick one."
                    ) { showingRecipePicker = true }
                }

                // 2. Shopping List (always visible)
                if let list = activeGroceryList {
                    NavigationLink(destination: GroceryListDetailView(weeklyList: list)) {
                        WeeklyListRowView(weeklyList: list)
                    }
                    .buttonStyle(.plain)
                } else {
                    ghostCard(
                        icon: "cart",
                        title: "Shopping List",
                        message: "No shopping list.",
                        action: "Tap to create one."
                    ) { showingCreateListOptions = true }
                }

                // 3. Meal Plan Overview (always visible)
                if let plan = mealPlanService.activeMealPlan {
                    Button { selectedTab = .mealPlans } label: {
                        mealPlanOverviewCard(plan: plan)
                    }
                    .buttonStyle(.plain)
                } else {
                    ghostCard(
                        icon: "calendar",
                        title: "Meal Plan",
                        message: "No meal plan this week.",
                        action: "Tap to create one."
                    ) { showingCreateMealPlan = true }
                }

                // 4. Tomorrow's Meal (only if data exists)
                if let meal = tomorrowMeal {
                    tomorrowMealCard(meal: meal)
                }

                quickActionsBar
            }
            .padding(.horizontal, ForagerTheme.Spacing.md)
            .padding(.bottom, ForagerTheme.Spacing.xl)
        }
        .background(ForagerTheme.backgroundCanvas)
        .sheet(isPresented: $showingRecipePicker) {
            NavigationStack {
                RecipeListView(popToRoot: .constant(false), onSelect: { recipe in
                    mealPlanService.assignRecipeToToday(recipe: recipe)
                    showingRecipePicker = false
                })
            }
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(householdService)
        }
        .sheet(isPresented: $showingCreateMealPlan) {
            CreateMealPlanSheet()
        }
        .confirmationDialog("New Grocery List", isPresented: $showingCreateListOptions) {
            Button("From Staples") { selectedTab = .lists }
            Button("From Meal Plan") { selectedTab = .lists }
            Button("Empty List") { selectedTab = .lists }
        }
        .navigationTitle(greeting)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Greeting

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Good night"
        }

        // Try to get user's first name
        if let name = resolvedFirstName, !name.isEmpty {
            return "\(timeGreeting), \(name)"
        }
        return timeGreeting
    }

    private var resolvedFirstName: String? {
        // 1. Extract from device name ("Mary's iPad" → "Mary", "Rich's iPhone" → "Rich")
        // M19.1: Device name is always the current user — works for both owner and member
        let deviceName = UIDevice.current.name
        if let range = deviceName.range(of: "\u{2019}s ", options: .caseInsensitive) ??
                        deviceName.range(of: "'s ", options: .caseInsensitive) {
            let name = String(deviceName[deviceName.startIndex..<range.lowerBound])
            if !name.isEmpty { return name }
        }
        // "Rich iPhone" pattern
        let deviceTypes = ["iPhone", "iPad", "iPod", "Mac", "MacBook", "iMac", "Mac mini", "Mac Pro", "Mac Studio"]
        for type in deviceTypes {
            if let range = deviceName.range(of: " \(type)", options: .caseInsensitive) {
                let name = String(deviceName[deviceName.startIndex..<range.lowerBound])
                if !name.isEmpty && name != type { return name }
            }
        }

        // 2. Cached display name from household creation (UserDefaults — owner only)
        if let cached = UserDefaults.standard.string(forKey: "cachedOwnerDisplayName"),
           !cached.isEmpty, cached != "Me", cached != "You", cached != "User" {
            return cached.components(separatedBy: " ").first
        }

        // 3. Household ownerDisplayName (fallback — only correct on owner's device)
        if let household = householdService.currentHousehold,
           let ownerName = household.ownerDisplayName,
           !ownerName.isEmpty, !ownerName.hasPrefix("_") {
            let firstName = ownerName.components(separatedBy: " ").first ?? ownerName
            if firstName != "Me" && firstName != "You" && firstName != "User" {
                return firstName
            }
        }

        return nil
    }

    // MARK: - Ghost Card (empty state with dashed border)

    private func ghostCard(icon: String, title: String, message: String, action: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text(title)
                        .font(ForagerTheme.cardTitle)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Spacer()
                }

                Text(message)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textTertiary)

                Text(action)
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.accentPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ForagerTheme.Spacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    .foregroundStyle(ForagerTheme.borderSubtle)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tomorrow's Meal Card

    private func tomorrowMealCard(meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundStyle(ForagerTheme.accentTertiary)
                Text("Tomorrow")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                Spacer()
            }

            if let recipe = meal.recipe {
                Text(recipe.recipeDisplayTitle)
                    .font(ForagerTheme.secondaryFont)
                    .fontWeight(.medium)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: ForagerTheme.Spacing.sm) {
                    if recipe.servings > 0 {
                        Text(recipe.recipeServingsDescription)
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    if recipe.recipeTotalTime > 0 {
                        Text("· \(recipe.recipeFormattedTotalTime)")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            } else if let quickOption = meal.quickOption {
                Text(quickOption)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
        }
        .foragerGlassCard()
    }

    // MARK: - Next Meal Card

    private func nextMealCard(meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundStyle(ForagerTheme.accentPrimary)
                Text("Next Up")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                Spacer()
            }

            // Meal type + timing
            let mealType = meal.mealType?.capitalized ?? "Meal"
            let timing = nextMealTimeLabel
            Text("\(mealType)\(timing.isEmpty ? "" : " \(timing)")")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textTertiary)

            // Recipe or quick option
            if let recipe = meal.recipe {
                Text(recipe.recipeDisplayTitle)
                    .font(ForagerTheme.secondaryFont)
                    .fontWeight(.medium)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: ForagerTheme.Spacing.sm) {
                    if recipe.servings > 0 {
                        Text(recipe.recipeServingsDescription)
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    if recipe.recipeTotalTime > 0 {
                        Text("· \(recipe.recipeFormattedTotalTime)")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            } else if let quickOption = meal.quickOption {
                Text(quickOption)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
        }
        .foragerGlassCard()
    }

    // MARK: - Meal Plan Overview Card

    private func mealPlanOverviewCard(plan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(ForagerTheme.accentPrimary)
                Text("Meal Plan")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                Spacer()
            }

            // Plan name + fill status
            if let dayData = planDaysFilled {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    Text(plan.name ?? "Current Plan")
                        .font(ForagerTheme.secondaryFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                    Text("·")
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text("\(dayData.filled) of \(dayData.total) days planned")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }

            // Day indicators — circles distributed full-width
            if let indicators = planDayIndicators {
                HStack {
                    ForEach(Array(indicators.enumerated()), id: \.offset) { _, indicator in
                        VStack(spacing: 4) {
                            Text(String(indicator.dayLetter.prefix(1)))
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(indicator.hasMeal ? ForagerTheme.buttonPrimaryText : ForagerTheme.textTertiary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(indicator.hasMeal ? ForagerTheme.accentPrimary : .clear)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(indicator.hasMeal ? .clear : ForagerTheme.borderDefault, lineWidth: 1)
                                )
                        }
                        if indicator.dayLetter != indicators.last?.dayLetter {
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .foragerGlassCard()
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            quickActionButton(title: "New List", icon: "list.bullet.rectangle.portrait", tab: .lists)
            quickActionButton(title: "Add Recipe", icon: "book", tab: .recipes)
            quickActionButton(title: "Plan Meals", icon: "calendar", tab: .mealPlans)
        }
        .frame(maxWidth: .infinity)
    }

    private func quickActionButton(title: String, icon: String, tab: NavigationTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(ForagerTheme.captionFont)
                Text(title)
                    .font(ForagerTheme.captionFont)
            }
            .foregroundStyle(ForagerTheme.accentPrimary)
            .padding(.horizontal, ForagerTheme.Spacing.md)
            .padding(.vertical, ForagerTheme.Spacing.sm)
            .background(ForagerTheme.accentPrimary.opacity(0.12))
            .clipShape(Capsule())
        }
    }
}
