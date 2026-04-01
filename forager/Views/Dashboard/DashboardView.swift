// DashboardView.swift
// FUI-1.7: Full dashboard — greeting, today's meals, grocery run, recipe spotlight, quick actions
// Data: MealPlanService (today's meals), @FetchRequest (grocery lists, recipes)

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

    // Recipes: for spotlight card
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.dateCreated, ascending: false)],
        animation: .default
    ) private var allRecipes: FetchedResults<Recipe>

    @StateObject private var mealPlanService = MealPlanService.shared

    private var weeklyLists: [WeeklyList] {
        let key = householdService.currentHouseholdKey
        return allWeeklyLists.filter { list in
            if let key { return list.householdKey == key }
            return list.householdKey == nil
        }
    }

    private var recipes: [Recipe] {
        let key = householdService.currentHouseholdKey
        return allRecipes.filter { recipe in
            if let key { return recipe.householdKey == key }
            return recipe.householdKey == nil
        }
    }

    private var activeGroceryList: WeeklyList? {
        weeklyLists.first { !$0.isCompleted }
    }

    private var todaysMeals: [PlannedMeal] {
        guard let plan = mealPlanService.activeMealPlan,
              let meals = plan.plannedMeals?.allObjects as? [PlannedMeal] else { return [] }
        return meals
            .filter { meal in
                guard let date = meal.date else { return false }
                return Calendar.current.isDateInToday(date)
            }
            .sorted { ($0.mealType ?? "") < ($1.mealType ?? "") }
    }

    private var spotlightRecipe: Recipe? {
        let candidates = recipes
        guard !candidates.isEmpty else { return nil }

        // Prefer favorites, then least-used, with date-seeded randomness
        let favorites = candidates.filter { $0.isFavorite }
        let pool = favorites.isEmpty ? candidates : Array(favorites)

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % pool.count
        return pool[index]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                // Date subtitle
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .padding(.top, ForagerTheme.Spacing.xs)

                if todaysMeals.isEmpty && activeGroceryList == nil && recipes.isEmpty {
                    welcomeCard
                } else {
                    if !todaysMeals.isEmpty {
                        todaysMealsCard
                    }

                    if let list = activeGroceryList {
                        groceryRunCard(list: list)
                    }

                    if let recipe = spotlightRecipe {
                        recipeSpotlightCard(recipe: recipe)
                    }
                }

                quickActionsBar
            }
            .padding(.horizontal, ForagerTheme.Spacing.md)
            .padding(.bottom, ForagerTheme.Spacing.xl)
        }
        .background(ForagerTheme.backgroundPrimary)
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
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Welcome Card (nothing to show)

    private var welcomeCard: some View {
        VStack(spacing: ForagerTheme.Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(ForagerTheme.accentPrimary)

            Text("Welcome to Forager")
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

    // MARK: - Today's Meals Card

    private var todaysMealsCard: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundStyle(ForagerTheme.accentPrimary)
                Text("Today's Meals")
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

            ForEach(todaysMeals, id: \.objectID) { meal in
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    Text(mealTypeLabel(meal.mealType))
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .frame(width: 70, alignment: .leading)

                    if let recipe = meal.recipe {
                        Text(recipe.recipeDisplayTitle)
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textPrimary)
                            .lineLimit(1)
                    } else if let quickOption = meal.quickOption {
                        Text(quickOption)
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if meal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ForagerTheme.accentSecondary)
                            .font(ForagerTheme.captionFont)
                    }
                }
            }
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg))
    }

    private func mealTypeLabel(_ type: String?) -> String {
        switch type?.lowercased() {
        case "breakfast": return "Breakfast"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        case "snack": return "Snack"
        default: return type?.capitalized ?? "Meal"
        }
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

    // MARK: - Recipe Spotlight Card

    private func recipeSpotlightCard(recipe: Recipe) -> some View {
        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                    Text("Recipe Spotlight")
                        .font(ForagerTheme.cardTitle)
                        .foregroundStyle(ForagerTheme.textPrimary)
                    Spacer()
                }

                if recipe.hasHeroImage, let urlString = recipe.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
                        case .failure:
                            EmptyView()
                        default:
                            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                                .fill(ForagerTheme.backgroundTertiary)
                                .frame(height: 160)
                        }
                    }
                }

                Text(recipe.recipeDisplayTitle)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .lineLimit(2)

                if let author = recipe.displayAuthor {
                    Text("by \(author)")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }
            .padding(ForagerTheme.Spacing.md)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg))
        }
        .buttonStyle(.plain)
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
