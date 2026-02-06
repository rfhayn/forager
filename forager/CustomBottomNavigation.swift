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
    }

    // MARK: - Content View

    // Shows the appropriate view based on selected tab
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .lists:
            NavigationStack {
                WeeklyListsView(popToRoot: $listsPopToRoot)
                    .hamburgerMenu()
            }
        case .ingredients:
            NavigationStack {
                IngredientsView(popToRoot: $ingredientsPopToRoot)
                    .hamburgerMenu()
            }
        case .recipes:
            NavigationStack {
                RecipeListView(popToRoot: $recipesPopToRoot)
                    .hamburgerMenu()
            }
        case .mealPlans:
            NavigationStack {
                MealPlansListView(popToRoot: $mealPlansPopToRoot)
                    .hamburgerMenu()
            }
        }
    }

    // MARK: - Bottom Navigation Bar

    private var bottomNavigationBar: some View {
        HStack(spacing: 12) {
            if !isSearchActive {
                // Pill-shaped container with 4 main tabs
                tabPillContainer
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            Spacer()

            if isSearchActive {
                // Expanded search bar
                expandedSearchBar
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                // Circular search button
                searchButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchActive)
    }

    // MARK: - Tab Pill Container

    private var tabPillContainer: some View {
        HStack(spacing: 0) {
            ForEach(NavigationTab.mainTabs, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundColor(selectedTab == tab ? .primary : .primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    @Namespace private var tabAnimation

    // MARK: - Search Button

    private var searchButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSearchActive = true
                // Don't focus yet - let user tap the field to show keyboard
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.primary.opacity(0.5))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Search Bar

    private var expandedSearchBar: some View {
        HStack(spacing: 12) {
            // Home/back button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    searchText = ""
                    isSearchActive = false
                    isSearchFocused = false
                }
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)

            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
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
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
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
