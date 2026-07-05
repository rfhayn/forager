//
//  RecipePickerSheet.swift
//  forager
//
//  Created for M4.2.1-3: Calendar Recipe Assignment Enhancement
//  Autocomplete-style recipe picker with search-as-you-type
//  Modal sheet for selecting a recipe to add to a specific date in meal plan
//

import SwiftUI
import CoreData

// M4.2.1-3: Payload for data-driven sheet presentation
// Prevents blank sheet bug by using .sheet(item:) instead of .sheet(isPresented:)
struct RecipePickerPayload: Identifiable {
    let id = UUID()
    let date: Date
    let mealPlan: MealPlan
}

// M4.2.1-3: Autocomplete-style recipe picker for calendar tap-to-add
// Clean list with search-as-you-type filtering, similar to ingredient autocomplete
struct RecipePickerSheet: View {
    
    // MARK: - Properties
    
    // M4.2.1-3: Date to assign recipe to
    var date: Date
    
    // M4.2.1-3: Meal plan to add recipe to
    var mealPlan: MealPlan
    
    // M9.0.1: Closure called when recipe is selected (recipe + servings)
    // Parent handles mutation (save, swap removal) — this is a pure picker
    var onRecipeSelected: (Recipe, Int) -> Void
    
    // M4.2.1-3: Controls sheet dismissal
    @Environment(\.dismiss) private var dismiss
    
    // M4.2.1-3: Core Data context
    @Environment(\.managedObjectContext) private var viewContext

    // M7.2.2: Household scope filtering to prevent duplicate recipes in picker
    @EnvironmentObject private var householdService: HouseholdService
    
    // M4.2.1-3: All recipes - loaded manually
    @State private var recipes: [Recipe] = []
    
    // M4.2.1-3: Search text for autocomplete filtering
    @State private var searchText = ""
    
    // M4.2.1-3: Focus state for search field
    @FocusState private var isSearchFocused: Bool
    
    // M4.2.1-3: Selected servings (defaults to recipe servings)
    @State private var selectedServings: [UUID: Int] = [:]
    
    // MARK: - Computed Properties
    
    // M4.2.1-3: Filter recipes based on search text (autocomplete behavior)
    // Empty search = show all recipes, otherwise filter by title
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { recipe in
                guard let title = recipe.title else { return false }
                return title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // M4.2.1-3: Short date format for banner
    private var formattedShortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"  // "Fri, Nov 7"
        return formatter.string(from: date)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date context banner
                dateContextBanner
                
                // Search field at top (autocomplete pattern)
                searchField
                
                // Recipe list
                if filteredRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipeList
                }
            }
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadRecipes()
            // Auto-focus search field for quick typing
            isSearchFocused = true
        }
    }
    
    // MARK: - View Components
    
    // M4.2.1-3: Enhanced date context banner
    private var dateContextBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(ForagerTheme.accentPrimary)
            
            Text("Adding to \(formattedShortDate)")
                .font(.headline)
            
            Spacer()
        }
        .padding()
        .background(ForagerTheme.accentPrimary.opacity(0.1))
    }
    
    // M4.2.1-3: Search field with autocomplete behavior
    // Similar to ingredient input pattern - filters as you type
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ForagerTheme.textSecondary)
            
            TextField("Search recipes...", text: $searchText)
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
        .padding(12)
        .background(ForagerTheme.surfacePrimary)
        .cornerRadius(ForagerTheme.Radius.md)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // M4.2.1-3: Clean recipe list (autocomplete results)
    private var recipeList: some View {
        List {
            ForEach(filteredRecipes, id: \.id) { recipe in
                RecipeRowView(
                    recipe: recipe,
                    servings: getServings(for: recipe),
                    onServingsChange: { newServings in
                        setServings(newServings, for: recipe)
                    },
                    onSelect: {
                        handleRecipeSelection(recipe)
                    }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // M4.2.1-3: Empty state when no recipes or search returns nothing
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "fork.knife.circle" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(ForagerTheme.textTertiary)
            
            Text(searchText.isEmpty ? "No Recipes Yet" : "No Matching Recipes")
                .font(.headline)
            
            Text(searchText.isEmpty ?
                 "Create some recipes to add them to your meal plan" :
                 "Try a different search term")
                .font(.subheadline)
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Data Loading & Management
    
    // M4.2.1-3: Load recipes from Core Data
    // Uses manual fetch instead of @FetchRequest for better control in sheets
    private func loadRecipes() {
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)]

        // M7.2.2: Filter by household scope to prevent showing duplicates
        // (personal + shared copies of same recipe)
        if let householdKey = householdService.currentHouseholdKey {
            fetchRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        } else {
            fetchRequest.predicate = NSPredicate(format: "householdKey == nil")
        }

        do {
            recipes = try viewContext.fetch(fetchRequest)
        } catch {
            #if DEBUG
            print("Error fetching recipes: \(error)")
            #endif
            recipes = []
        }
    }
    
    // M4.2.1-3: Get servings for recipe (uses selected value or default)
    private func getServings(for recipe: Recipe) -> Int {
        guard let recipeID = recipe.id else { return Int(recipe.servings) }
        return selectedServings[recipeID] ?? Int(recipe.servings)
    }
    
    // M4.2.1-3: Set servings for recipe
    private func setServings(_ servings: Int, for recipe: Recipe) {
        guard let recipeID = recipe.id else { return }
        selectedServings[recipeID] = servings
    }
    
    // M9.0.1: Handle recipe selection — pure picker, parent handles mutation
    private func handleRecipeSelection(_ recipe: Recipe) {
        let servings = getServings(for: recipe)
        onRecipeSelected(recipe, servings)
        dismiss()
    }
}

// MARK: - Recipe Row View

// M4.2.1-3: Individual recipe row with inline servings adjuster
// Clean, compact design similar to ingredient autocomplete results
struct RecipeRowView: View {
    let recipe: Recipe
    let servings: Int
    let onServingsChange: (Int) -> Void
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundStyle(ForagerTheme.accentPrimary)
                    .font(.body)
                
                Text(recipe.title ?? "Untitled Recipe")
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Recipe metadata
            Text("\(recipe.ingredients?.count ?? 0) ingredients • Serves \(Int(recipe.servings))")
                .font(.caption)
                .foregroundStyle(ForagerTheme.textSecondary)
            
            // Servings adjuster
            HStack {
                Text("Servings:")
                    .font(.subheadline)
                    .foregroundStyle(ForagerTheme.textSecondary)
                
                Spacer()
                
                // Minus button
                Button {
                    if servings > 1 {
                        onServingsChange(servings - 1)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(servings > 1 ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(servings <= 1)
                
                // Current value
                Text("\(servings)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(minWidth: 30)
                
                // Plus button
                Button {
                    if servings < 99 {
                        onServingsChange(servings + 1)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(servings < 99 ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(servings >= 99)
            }
            
            // Add button
            Button(action: onSelect) {
                Text("Add to Plan")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(ForagerTheme.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ForagerTheme.accentPrimary)
                    .cornerRadius(ForagerTheme.Radius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct RecipePickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample meal plan
        let mealPlan = MealPlan(context: context)
        mealPlan.id = UUID()
        mealPlan.name = "Weekly Plan"
        mealPlan.startDate = Date()
        mealPlan.duration = 7
        
        // Create sample recipes
        let recipe1 = Recipe(context: context)
        recipe1.id = UUID()
        recipe1.title = "Chocolate Chip Cookies"
        recipe1.servings = 24
        
        let recipe2 = Recipe(context: context)
        recipe2.id = UUID()
        recipe2.title = "Pasta Carbonara"
        recipe2.servings = 4
        
        try? context.save()
        
        return RecipePickerSheet(
            date: Date(),
            mealPlan: mealPlan,
            onRecipeSelected: { _, _ in }
        )
        .environment(\.managedObjectContext, context)
    }
}
