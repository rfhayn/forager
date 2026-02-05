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
    @EnvironmentObject private var householdService: HouseholdService

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

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
        NavigationView {
            VStack(spacing: 0) {
                // M7.4: Persistent search bar at top (Apple Music pattern)
                searchBarSection

                // Results or empty state
                if searchText.isEmpty {
                    emptyStateView
                } else if hasResults {
                    searchResultsView
                } else {
                    noResultsView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .padding(.top, 60)

            Text("Search Everything")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Find lists, ingredients, recipes, and meal plans")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .padding(.top, 60)

            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
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
                        color: .green,
                        count: filteredLists.count
                    ) {
                        ForEach(filteredLists.prefix(5), id: \.self) { list in
                            NavigationLink(destination: GroceryListDetailView(weeklyList: list)) {
                                HStack {
                                    Image(systemName: "list.clipboard")
                                        .foregroundColor(.green)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(list.name ?? "Unnamed List")
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        if let date = list.dateCreated {
                                            Text(date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                        color: .orange,
                        count: filteredIngredients.count
                    ) {
                        ForEach(filteredIngredients.prefix(5), id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "carrot")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ingredient.name ?? "Unnamed")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    if let category = ingredient.category {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if ingredient.isStaple {
                                    Image(systemName: "pin.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
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
                        color: .blue,
                        count: filteredRecipes.count
                    ) {
                        ForEach(filteredRecipes.prefix(5), id: \.self) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                HStack {
                                    Image(systemName: "book.pages")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recipe.title ?? "Untitled Recipe")
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        HStack(spacing: 8) {
                                            Text("\(Int(recipe.servings)) servings")

                                            if recipe.totalTime > 0 {
                                                Text("• \(Int(recipe.totalTime)) min")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                        color: .purple,
                        count: filteredMealPlans.count
                    ) {
                        ForEach(filteredMealPlans.prefix(5), id: \.self) { plan in
                            NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.purple)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(plan.name ?? "Unnamed Plan")
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        if let startDate = plan.startDate {
                                            Text(startDate, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                content()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
