//
//  UnifiedSearchView.swift
//  forager
//
//  M7.4: Unified search across all content types (Apple Music pattern)
//  Created: February 5, 2026
//

import SwiftUI
import CoreData

struct UnifiedSearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @AppStorage("recentSearches") private var recentSearchesData: String = "[]"

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(recentSearchesData.utf8))) ?? []
    }

    private func addRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > 8 { searches = Array(searches.prefix(8)) }
        if let data = try? JSONEncoder().encode(searches), let json = String(data: data, encoding: .utf8) {
            recentSearchesData = json
        }
    }

    // Fetch all data types
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyList.dateCreated, ascending: false)]
    ) private var allLists: FetchedResults<WeeklyList>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)]
    ) private var allIngredients: FetchedResults<IngredientTemplate>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]
    ) private var allRecipes: FetchedResults<Recipe>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MealPlan.startDate, ascending: false)]
    ) private var allMealPlans: FetchedResults<MealPlan>

    // Filter by household context
    private var lists: [WeeklyList] {
        filterByHousehold(allLists)
    }

    private var ingredients: [IngredientTemplate] {
        filterByHousehold(allIngredients)
    }

    private var recipes: [Recipe] {
        filterByHousehold(allRecipes)
    }

    private var mealPlans: [MealPlan] {
        filterByHousehold(allMealPlans)
    }

    // Search results
    private var filteredLists: [WeeklyList] {
        guard !searchText.isEmpty else { return [] }
        return lists.filter { list in
            (list.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredIngredients: [IngredientTemplate] {
        guard !searchText.isEmpty else { return [] }
        return ingredients.filter { ingredient in
            (ingredient.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return [] }
        return recipes.filter { recipe in
            (recipe.title ?? "").localizedCaseInsensitiveContains(searchText) ||
            (recipe.instructions ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredMealPlans: [MealPlan] {
        guard !searchText.isEmpty else { return [] }
        return mealPlans.filter { plan in
            (plan.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hasResults: Bool {
        !filteredLists.isEmpty || !filteredIngredients.isEmpty ||
        !filteredRecipes.isEmpty || !filteredMealPlans.isEmpty
    }

    var body: some View {
        // M15.1: NavigationView removed — UnifiedSearchView is inside NavigationStack from TabView
        VStack(spacing: 0) {
            // M7.4: Search bar with cancel button (Apple Music pattern)
            searchBarSection

            // Results or empty state
            if searchText.isEmpty && !isSearchFocused {
                emptyStateView
            } else if searchText.isEmpty && isSearchFocused {
                if recentSearches.isEmpty {
                    emptyStateView
                } else {
                    recentSearchesView
                }
            } else if hasResults {
                searchResultsView
            } else {
                noResultsView
            }
        }
        .navigationTitle(isSearchFocused ? "" : "Search")
        .navigationBarTitleDisplayMode(isSearchFocused ? .inline : .large)
        .animation(reduceMotion ? nil : .default, value: isSearchFocused)
        .onDisappear {
            if !searchText.isEmpty {
                addRecentSearch(searchText)
            }
        }
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .font(.body)

                TextField("Lists, Ingredients, Recipes, Meal Plans...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(ForagerTheme.surfaceSecondary)
            .cornerRadius(ForagerTheme.Radius.md)

            // Cancel button appears when search is active (Apple Music pattern)
            if isSearchFocused {
                Button("Cancel") {
                    searchText = ""
                    isSearchFocused = false
                }
                .foregroundStyle(ForagerTheme.accentPrimary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(reduceMotion ? nil : .default, value: isSearchFocused)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Search Everything", systemImage: "magnifyingglass")
        } description: {
            Text("Find lists, ingredients, recipes, and meal plans")
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Lists Section
                if !filteredLists.isEmpty {
                    resultSection(
                        title: "Lists",
                        icon: "list.clipboard",
                        color: ForagerTheme.statusSuccessFG,
                        count: filteredLists.count
                    ) {
                        ForEach(filteredLists.prefix(5), id: \.self) { list in
                            NavigationLink(destination: GroceryListDetailView(weeklyList: list)) {
                                HStack {
                                    Image(systemName: "list.clipboard")
                                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        highlightedText(list.name ?? "Unnamed List", highlight: searchText)
                                            .font(.body)

                                        if let date = list.dateCreated {
                                            Text(date, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(ForagerTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }

                // Ingredients Section
                if !filteredIngredients.isEmpty {
                    resultSection(
                        title: "Ingredients",
                        icon: "carrot",
                        color: ForagerTheme.statusWarningFG,
                        count: filteredIngredients.count
                    ) {
                        ForEach(filteredIngredients.prefix(5), id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "carrot")
                                    .foregroundStyle(ForagerTheme.statusWarningFG)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    highlightedText(ingredient.name ?? "Unnamed", highlight: searchText)
                                        .font(.body)

                                    if let category = ingredient.category {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundStyle(ForagerTheme.textSecondary)
                                    }
                                }

                                Spacer()

                                if ingredient.isStaple {
                                    Image(systemName: "pin.fill")
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.accentSecondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                // Recipes Section
                if !filteredRecipes.isEmpty {
                    resultSection(
                        title: "Recipes",
                        icon: "book.pages",
                        color: ForagerTheme.accentSecondary,
                        count: filteredRecipes.count
                    ) {
                        ForEach(filteredRecipes.prefix(5), id: \.self) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                HStack {
                                    Image(systemName: "book.pages")
                                        .foregroundStyle(ForagerTheme.accentSecondary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        highlightedText(recipe.title ?? "Untitled Recipe", highlight: searchText)
                                            .font(.body)

                                        HStack(spacing: 8) {
                                            Text("\(Int(recipe.servings)) servings")

                                            if recipe.totalTime > 0 {
                                                Text("• \(Int(recipe.totalTime)) min")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }

                // Meal Plans Section
                if !filteredMealPlans.isEmpty {
                    resultSection(
                        title: "Meal Plans",
                        icon: "calendar",
                        color: ForagerTheme.accentSecondary,
                        count: filteredMealPlans.count
                    ) {
                        ForEach(filteredMealPlans.prefix(5), id: \.self) { plan in
                            NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(ForagerTheme.accentSecondary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        highlightedText(plan.name ?? "Unnamed Plan", highlight: searchText)
                                            .font(.body)

                                        if let startDate = plan.startDate {
                                            Text(startDate, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(ForagerTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                Text("Recent Searches")
                    .font(ForagerTheme.footnoteFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .textCase(.uppercase)

                FlowLayout(spacing: ForagerTheme.Spacing.sm) {
                    ForEach(recentSearches, id: \.self) { term in
                        Button {
                            searchText = term
                        } label: {
                            Text(term)
                                .font(ForagerTheme.footnoteFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(ForagerTheme.surfaceSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Highlighted Text Helper

    private func highlightedText(_ text: String, highlight: String) -> Text {
        guard !highlight.isEmpty,
              let range = text.range(of: highlight, options: .caseInsensitive) else {
            return Text(text)
        }

        let before = String(text[text.startIndex..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound..<text.endIndex])

        return Text("\(Text(before))\(Text(match).bold().foregroundColor(ForagerTheme.accentPrimary))\(Text(after))")
    }

    // MARK: - Result Section Helper

    @ViewBuilder
    private func resultSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }

            VStack(spacing: 0) {
                content()
            }
        }
        .padding()
        .background(ForagerTheme.surfacePrimary)
        .cornerRadius(ForagerTheme.Radius.md)
    }

    // MARK: - Helper Methods

    private func filterByHousehold<T: NSManagedObject>(_ items: FetchedResults<T>) -> [T] {
        let currentHouseholdKey = householdService.currentHouseholdKey
        return items.filter { item in
            if let householdKey = currentHouseholdKey {
                return item.value(forKey: "householdKey") as? String == householdKey
            } else {
                return item.value(forKey: "householdKey") as? String == nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UnifiedSearchView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HouseholdService(context: PersistenceController.preview.container.viewContext))
}
