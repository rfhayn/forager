//
//  CustomBottomNavigation.swift
//  forager
//
//  M7.4: Apple Music-style bottom navigation with inline search
//  Grouped pill for main tabs + separate search button
//  Search expands inline when tapped
//

import SwiftUI

// M7.4: Custom bottom navigation container
struct CustomBottomNavigationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    // Tab selection and search state
    @State private var selectedTab: NavigationTab = .lists
    @State private var isSearchActive = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    // Pop-to-root triggers for each tab
    @State private var listsPopToRoot = false
    @State private var ingredientsPopToRoot = false
    @State private var recipesPopToRoot = false
    @State private var mealPlansPopToRoot = false

    var body: some View {
        ZStack {
            // Main content area
            contentView

            // Custom bottom navigation bar
            VStack {
                Spacer()
                bottomNavigationBar
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Content View

    // Shows the appropriate view based on selected tab
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .lists:
            NavigationStack {
                WeeklyListsView(popToRoot: $listsPopToRoot)
            }
        case .ingredients:
            NavigationStack {
                IngredientsView(popToRoot: $ingredientsPopToRoot)
            }
        case .recipes:
            NavigationStack {
                RecipeListView(popToRoot: $recipesPopToRoot)
            }
        case .mealPlans:
            NavigationStack {
                MealPlansListView(popToRoot: $mealPlansPopToRoot)
            }
        }
    }

    // MARK: - Bottom Navigation Bar

    private var bottomNavigationBar: some View {
        HStack(spacing: 12) {
            if !isSearchActive {
                // Pill-shaped container with 4 main tabs
                tabPillContainer
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer()

            if isSearchActive {
                // Expanded search bar
                expandedSearchBar
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Circular search button
                searchButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchActive)
    }

    // MARK: - Tab Pill Container

    private var tabPillContainer: some View {
        HStack(spacing: 0) {
            ForEach(NavigationTab.mainTabs, id: \.self) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.title)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ? Color.accentColor : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }
        }
        .padding(4)
        .background(
            Color(.secondarySystemBackground),
            in: Capsule()
        )
    }

    // MARK: - Search Button

    private var searchButton: some View {
        Button {
            withAnimation {
                isSearchActive = true
                isSearchFocused = true
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 50, height: 50)
                .background(
                    Color(.secondarySystemBackground),
                    in: Circle()
                )
        }
    }

    // MARK: - Expanded Search Bar

    private var expandedSearchBar: some View {
        HStack(spacing: 12) {
            // Home/back button
            Button {
                withAnimation {
                    searchText = ""
                    isSearchActive = false
                    isSearchFocused = false
                }
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }

            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search everything...", text: $searchText)
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
            .padding(10)
            .background(
                Color(.tertiarySystemBackground),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
    }
}

// MARK: - Navigation Tab Enum

enum NavigationTab: String, CaseIterable {
    case lists
    case ingredients
    case recipes
    case mealPlans

    static var mainTabs: [NavigationTab] {
        [.lists, .ingredients, .recipes, .mealPlans]
    }

    var title: String {
        switch self {
        case .lists: return "Lists"
        case .ingredients: return "Ingredients"
        case .recipes: return "Recipes"
        case .mealPlans: return "Meal Plans"
        }
    }

    var icon: String {
        switch self {
        case .lists: return "list.clipboard.fill"
        case .ingredients: return "leaf.circle.fill"
        case .recipes: return "book.pages.fill"
        case .mealPlans: return "calendar"
        }
    }
}

// MARK: - Preview

#Preview {
    CustomBottomNavigationView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HouseholdService(context: PersistenceController.preview.container.viewContext))
}
