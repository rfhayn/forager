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

        let now = Date()
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

    private var hasContent: Bool {
        nextMeal != nil || activeGroceryList != nil || mealPlanService.activeMealPlan != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                // Date subtitle
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .padding(.top, ForagerTheme.Spacing.xs)

                if !hasContent {
                    welcomeCard
                } else {
                    // 1. Next Meal (most actionable)
                    if let meal = nextMeal {
                        nextMealCard(meal: meal)
                    }

                    // 2. Grocery Snapshot
                    if let list = activeGroceryList {
                        groceryRunCard(list: list)
                    }

                    // 3. Meal Plan Overview
                    if let plan = mealPlanService.activeMealPlan {
                        mealPlanOverviewCard(plan: plan)
                    }
                }

                quickActionsBar
            }
            .padding(.horizontal, ForagerTheme.Spacing.md)
            .padding(.bottom, ForagerTheme.Spacing.xl)
        }
        .background(ForagerTheme.backgroundCanvas)
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
        // 1. Cached display name from household creation (UserDefaults — lost on reinstall)
        if let cached = UserDefaults.standard.string(forKey: "cachedOwnerDisplayName"),
           !cached.isEmpty, cached != "Me", cached != "You", cached != "User" {
            return cached.components(separatedBy: " ").first
        }

        // 2. Household ownerDisplayName (synced via CloudKit — survives reinstall)
        if let household = householdService.currentHousehold,
           let ownerName = household.ownerDisplayName,
           !ownerName.isEmpty, !ownerName.hasPrefix("_") {
            let firstName = ownerName.components(separatedBy: " ").first ?? ownerName
            if firstName != "Me" && firstName != "You" && firstName != "User" {
                return firstName
            }
        }

        // 3. Extract from device name ("Rich's iPhone" → "Rich")
        let deviceName = UIDevice.current.name
        if let range = deviceName.range(of: "'s ", options: .caseInsensitive) {
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

        return nil
    }

    // MARK: - Welcome Card (nothing to show)

    private var welcomeCard: some View {
        VStack(spacing: ForagerTheme.Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(ForagerTheme.accentPrimary)

            Text("Welcome to forager")
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)

            Text("Import a recipe, create a grocery list, or plan your meals to get started.")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(ForagerTheme.Spacing.xl)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg))
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
                Button {
                    selectedTab = .mealPlans
                } label: {
                    Text("View Plan")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
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
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg))
    }

    // MARK: - Grocery Run Card

    private func groceryRunCard(list: WeeklyList) -> some View {
        let items = (list.items?.allObjects as? [GroceryListItem]) ?? []
        let total = items.count
        let completed = items.filter { $0.isCompleted }.count
        let progress: Double = total > 0 ? Double(completed) / Double(total) : 0
        let remaining = total - completed

        return VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            HStack {
                Image(systemName: "cart")
                    .foregroundStyle(ForagerTheme.accentSecondary)
                Text(list.name ?? "Grocery List")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                Spacer()
                Button {
                    selectedTab = .lists
                } label: {
                    Text("Open")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
            }

            HStack(spacing: ForagerTheme.Spacing.md) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(ForagerTheme.backgroundTertiary, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ForagerTheme.accentSecondary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(completed)/\(total)")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                    if remaining > 0 {
                        Text("\(remaining) item\(remaining == 1 ? "" : "s") remaining")
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textPrimary)
                    } else {
                        Text("All done!")
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.accentSecondary)
                    }

                    // Show first few unchecked items
                    let unchecked = items.filter { !$0.isCompleted }.prefix(3)
                    ForEach(Array(unchecked), id: \.objectID) { item in
                        Text("· \(item.name ?? item.displayText ?? "Item")")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg))
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
                Button {
                    selectedTab = .mealPlans
                } label: {
                    Text("View")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
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

            // Day indicators
            if let indicators = planDayIndicators {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    ForEach(Array(indicators.enumerated()), id: \.offset) { _, indicator in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(indicator.hasMeal ? ForagerTheme.accentPrimary : ForagerTheme.backgroundTertiary)
                                .frame(width: 28, height: 6)
                            Text(indicator.dayLetter)
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(indicator.hasMeal ? ForagerTheme.textPrimary : ForagerTheme.textTertiary)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg))
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            quickActionButton(title: "New List", icon: "list.bullet.rectangle.portrait", tab: .lists)
            quickActionButton(title: "Add Recipe", icon: "book", tab: .recipes)
            quickActionButton(title: "Plan Meals", icon: "calendar", tab: .mealPlans)
        }
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
