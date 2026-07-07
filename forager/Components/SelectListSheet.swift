//
//  SelectListSheet.swift
//  forager
//
//  Created for M4.3.3: Bulk Add from Meal Plan
//  Sheet for selecting grocery list and adjusting recipe servings
//

import SwiftUI
import CoreData

// M4.3.3: Modal sheet for grocery list selection with servings adjustment
// Allows user to adjust recipe servings before adding to list
struct SelectListSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var weeklyListService: WeeklyListService
    @Environment(\.dismiss) private var dismiss
    
    // M4.3.3: Callback when user selects a list with adjusted servings
    var onSelect: (WeeklyList, [UUID: Int16]) -> Void
    
    // M4.3.3: Recipes from meal plan to show and adjust
    let recipes: [(recipe: Recipe, currentServings: Int16)]
    
    // M4.3.3: Fetch all grocery lists
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyList.dateCreated, ascending: false)],
        animation: .default
    ) private var weeklyLists: FetchedResults<WeeklyList>
    
    // M4.3.3: Track adjusted servings (recipe ID -> servings)
    @State private var adjustedServings: [UUID: Int16] = [:]
    
    // M4.3.3: Show/hide recipes section
    @State private var showingRecipes = true
    
    // M4.3.3: Show create new list form
    @State private var showingCreateList = false
    @State private var newListName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Recipes section with servings adjustment
                recipesSection
                
                Divider()
                
                // List selection
                if weeklyLists.isEmpty {
                    emptyStateView
                } else {
                    listSelectionView
                }
                
                // Create new list button
                createNewListButton
            }
            .navigationTitle("Add to Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                initializeServings()
            }
        }
    }
    
    // MARK: - View Components
    
    // M4.3.3: Recipes section with servings adjusters
    private var recipesSection: some View {
        VStack(spacing: 0) {
            // Section header
            Button {
                withAnimation {
                    showingRecipes.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recipes to Add")
                            .font(ForagerTheme.bodyCondensed.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("\(recipes.count) recipes")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingRecipes ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                .padding()
                .background(ForagerTheme.backgroundSecondary)
            }
            .buttonStyle(.plain)
            
            // Recipe list with servings adjusters
            if showingRecipes {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(recipes, id: \.recipe.id) { item in
                            recipeRow(recipe: item.recipe, defaultServings: item.currentServings)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    // M4.3.3: Individual recipe row with servings adjuster
    private func recipeRow(recipe: Recipe, defaultServings: Int16) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe name
            HStack {
                Text(recipe.title ?? "Untitled Recipe")
                    .font(ForagerTheme.bodyFont)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Servings adjuster
            HStack {
                Text("Servings:")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                
                Spacer()
                
                // Minus button
                Button {
                    adjustServings(for: recipe, delta: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(currentServings(for: recipe) > 1 ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(currentServings(for: recipe) <= 1)
                
                // Current servings
                Text("\(currentServings(for: recipe))")
                    .font(ForagerTheme.quantityFontLarge)
                    .frame(minWidth: 40)
                
                // Plus button
                Button {
                    adjustServings(for: recipe, delta: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(currentServings(for: recipe) < 99 ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(currentServings(for: recipe) >= 99)
            }
            
            // Show scale indicator if different from default
            if currentServings(for: recipe) != defaultServings {
                let scaleFactor = Double(currentServings(for: recipe)) / Double(defaultServings)
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                    Text(String(format: "%.1fx scale", scaleFactor))
                        .font(ForagerTheme.footnoteFont)
                }
                .foregroundStyle(ForagerTheme.statusWarningFG)
            }
        }
        .padding()
        .background(ForagerTheme.surfacePrimary)
        .cornerRadius(ForagerTheme.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("No existing lists")
                .font(.subheadline)
                .foregroundStyle(ForagerTheme.textSecondary)
            Text("Tap below to create one")
                .font(.caption)
                .foregroundStyle(ForagerTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ForagerTheme.Spacing.lg)
    }
    
    private var listSelectionView: some View {
        List {
            ForEach(weeklyLists) { list in
                Button {
                    onSelect(list, adjustedServings)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(list.name ?? "Unnamed List")
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            if let dateCreated = list.dateCreated {
                                Text(formatDate(dateCreated))
                                    .font(.caption)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                            
                            if let itemCount = list.items?.count, itemCount > 0 {
                                Text("\(itemCount) items")
                                    .font(.caption2)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }
    
    private var createNewListButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                createNewList()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New List")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ForagerTheme.accentPrimary)
                .foregroundStyle(.white)
                .cornerRadius(ForagerTheme.Radius.md)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func createNewList() {
        if let newList = weeklyListService.createList(name: "Shopping List - \(formatDate(Date()))") {
            onSelect(newList, adjustedServings)
            dismiss()
        }
    }
    
    // MARK: - Servings Management
    
    // M4.3.3: Initialize servings from meal plan defaults
    private func initializeServings() {
        for item in recipes {
            if let recipeID = item.recipe.id {
                adjustedServings[recipeID] = item.currentServings
            }
        }
    }
    
    // M4.3.3: Get current servings for recipe
    private func currentServings(for recipe: Recipe) -> Int16 {
        guard let recipeID = recipe.id else { return recipe.servings }
        return adjustedServings[recipeID] ?? recipe.servings
    }
    
    // M4.3.3: Adjust servings by delta
    private func adjustServings(for recipe: Recipe, delta: Int16) {
        guard let recipeID = recipe.id else { return }
        let current = currentServings(for: recipe)
        let new = max(1, min(99, current + delta))
        adjustedServings[recipeID] = new
    }
}

// MARK: - Preview

struct SelectListSheet_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample recipes
        let recipe1 = Recipe(context: context)
        recipe1.id = UUID()
        recipe1.title = "Pancakes"
        recipe1.servings = 8
        
        let recipe2 = Recipe(context: context)
        recipe2.id = UUID()
        recipe2.title = "Cookies"
        recipe2.servings = 24
        
        let sampleRecipes: [(recipe: Recipe, currentServings: Int16)] = [
            (recipe1, 8),
            (recipe2, 24)
        ]
        
        return SelectListSheet(
            onSelect: { list, servings in
                #if DEBUG
                print("Selected list: \(list.name ?? "Unnamed")")
                print("Adjusted servings: \(servings)")
                #endif
            },
            recipes: sampleRecipes
        )
        .environment(\.managedObjectContext, context)
    }
}
