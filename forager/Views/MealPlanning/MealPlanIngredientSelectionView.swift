//
//  MealPlanIngredientSelectionView.swift
//  forager
//
//  M9.16: Recipe-by-recipe ingredient selection wizard for meal plan → grocery list flow.
//  Cycles through each recipe's ingredients with checkboxes, servings adjustment,
//  and an "Add All Remaining" escape hatch.
//

import SwiftUI
import CoreData

struct MealPlanIngredientSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var groceryListItemService: GroceryListItemService

    let targetList: WeeklyList
    let recipes: [(recipe: Recipe, servings: Int16)]

    // Wizard state
    @State private var currentRecipeIndex = 0
    @State private var selectedIngredients: [Int: Set<UUID>] = [:]  // recipeIndex -> ingredient IDs
    @State private var adjustedServings: [Int: Int] = [:]           // recipeIndex -> servings
    @State private var isAdding = false
    @State private var addingMessage = ""
    @State private var totalAdded = 0

    private var currentEntry: (recipe: Recipe, servings: Int16)? {
        guard currentRecipeIndex < recipes.count else { return nil }
        return recipes[currentRecipeIndex]
    }

    private var isLastRecipe: Bool {
        currentRecipeIndex >= recipes.count - 1
    }

    var body: some View {
        NavigationStack {
            Group {
                if isAdding {
                    addingOverlay
                } else if let entry = currentEntry {
                    recipeSelectionView(recipe: entry.recipe, defaultServings: entry.servings)
                } else {
                    completionView
                }
            }
            .navigationTitle("Select Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .onAppear {
            initializeSelections()
        }
        .interactiveDismissDisabled(isAdding && !ProcessInfo.processInfo.isiOSAppOnMac)
    }

    // MARK: - Recipe Selection View

    private func recipeSelectionView(recipe: Recipe, defaultServings: Int16) -> some View {
        let recipeIngredients = sortedIngredients(for: recipe)
        let servings = adjustedServings[currentRecipeIndex] ?? Int(defaultServings)
        let selected = selectedIngredients[currentRecipeIndex] ?? Set()

        return VStack(spacing: 0) {
            // Progress indicator
            progressBar

            // Recipe header with servings
            recipeHeader(recipe: recipe, servings: servings)

            // Ingredient list
            List {
                Section {
                    ForEach(recipeIngredients, id: \.objectID) { ingredient in
                        ingredientRow(ingredient: ingredient, isSelected: selected.contains(ingredient.id ?? UUID()))
                    }
                } header: {
                    HStack {
                        Text("\(selected.count) of \(recipeIngredients.count) selected")
                            .font(ForagerTheme.captionFont)
                        Spacer()
                        Button(selected.count == recipeIngredients.count ? "Deselect All" : "Select All") {
                            toggleSelectAll(ingredients: recipeIngredients)
                        }
                        .font(ForagerTheme.captionFont)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(ForagerTheme.backgroundCanvas)

            // Bottom actions
            bottomActions
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: ForagerTheme.Spacing.xs) {
            ProgressView(value: Double(currentRecipeIndex + 1), total: Double(recipes.count))
                .tint(ForagerTheme.accentPrimary)
            Text("Recipe \(currentRecipeIndex + 1) of \(recipes.count)")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.sm)
    }

    // MARK: - Recipe Header

    private func recipeHeader(recipe: Recipe, servings: Int) -> some View {
        VStack(spacing: ForagerTheme.Spacing.sm) {
            Text(recipe.title ?? "Untitled Recipe")
                .font(ForagerTheme.cardTitle)
                .lineLimit(2)

            if recipe.servings > 0 {
                HStack {
                    Text("Servings:")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Stepper("\(servings)", value: Binding(
                        get: { adjustedServings[currentRecipeIndex] ?? Int(recipe.servings) },
                        set: { adjustedServings[currentRecipeIndex] = $0 }
                    ), in: 1...20)
                    .font(ForagerTheme.bodyFont)
                }
            }
        }
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(ForagerTheme.surfacePrimary)
    }

    // MARK: - Ingredient Row

    private func ingredientRow(ingredient: Ingredient, isSelected: Bool) -> some View {
        Button {
            toggleIngredient(ingredient)
        } label: {
            HStack {
                // reskin-provisions-press: square print checkbox (matches GroceryListItemRow)
                ZStack {
                    RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : ForagerTheme.textPrimary, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                .fill(isSelected ? ForagerTheme.accentPrimary : Color.clear)
                        )
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(ForagerTheme.buttonPrimaryText)
                    }
                }
                .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    // Shared ingredient render: mono quantity + body name
                    IngredientText(
                        text: ingredient.name ?? "Unknown",
                        parsedName: IngredientParsingService.extractCleanIngredientName(from: ingredient.name ?? "")
                    )

                    if let template = ingredient.ingredientTemplate,
                       let catName = template.categoryEntity?.name,
                       catName.lowercased() != "uncategorized" {
                        Text(catName)
                            .font(ForagerTheme.metaFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: ForagerTheme.Spacing.sm) {
            // Primary action: Next recipe or Add to list
            Button {
                if isLastRecipe {
                    addSelectedToList()
                } else {
                    withAnimation { currentRecipeIndex += 1 }
                }
            } label: {
                Text(isLastRecipe ? "Add to List" : "Next Recipe")
                    .font(ForagerTheme.bodyFont.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForagerTheme.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(ForagerTheme.accentPrimary)

            // Secondary: Add All Remaining (skip wizard for remaining recipes)
            if !isLastRecipe {
                Button {
                    addAllRemainingAndFinish()
                } label: {
                    Text("Add All Remaining (\(remainingIngredientCount) items)")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .background(ForagerTheme.surfacePrimary)
    }

    // MARK: - Adding Overlay

    private var addingOverlay: some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text(addingMessage)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(ForagerTheme.statusSuccessFG)
            Text("Added \(totalAdded) items")
                .font(ForagerTheme.cardTitle)
            Text("to \(targetList.name ?? "grocery list")")
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textSecondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logic

    private func initializeSelections() {
        for (index, entry) in recipes.enumerated() {
            guard let ingredients = entry.recipe.ingredients?.allObjects as? [Ingredient] else { continue }
            // Pre-select all ingredients
            selectedIngredients[index] = Set(ingredients.compactMap { $0.id })
            adjustedServings[index] = Int(entry.servings)
        }
    }

    private func toggleIngredient(_ ingredient: Ingredient) {
        guard let id = ingredient.id else { return }
        var selected = selectedIngredients[currentRecipeIndex] ?? Set()
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
        selectedIngredients[currentRecipeIndex] = selected
    }

    private func toggleSelectAll(ingredients: [Ingredient]) {
        let selected = selectedIngredients[currentRecipeIndex] ?? Set()
        if selected.count == ingredients.count {
            selectedIngredients[currentRecipeIndex] = Set()
        } else {
            selectedIngredients[currentRecipeIndex] = Set(ingredients.compactMap { $0.id })
        }
    }

    private func sortedIngredients(for recipe: Recipe) -> [Ingredient] {
        guard let set = recipe.ingredients?.allObjects as? [Ingredient] else { return [] }
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var remainingIngredientCount: Int {
        var count = 0
        for index in (currentRecipeIndex + 1)..<recipes.count {
            guard let ingredients = recipes[index].recipe.ingredients else { continue }
            count += ingredients.count
        }
        return count
    }

    private func addSelectedToList() {
        isAdding = true
        addingMessage = "Adding ingredients..."

        // Run in Task so SwiftUI renders the loading overlay before blocking work begins
        Task { @MainActor in
            // Yield to let SwiftUI render the isAdding state change
            try? await Task.sleep(nanoseconds: 50_000_000)

            var total = 0
            for (index, entry) in recipes.enumerated() {
                let selected = selectedIngredients[index] ?? Set()
                guard !selected.isEmpty else { continue }

                let ingredients = sortedIngredients(for: entry.recipe)
                    .filter { selected.contains($0.id ?? UUID()) }

                let servings = adjustedServings[index] ?? Int(entry.servings)
                let scaleFactor = entry.recipe.servings > 0
                    ? Double(servings) / Double(entry.recipe.servings) : 1.0

                let added = groceryListItemService.addIngredients(
                    ingredients,
                    to: targetList,
                    scaleFactor: scaleFactor,
                    sourceRecipe: entry.recipe,
                    mergeWithExisting: true
                )
                total += added.count
            }

            totalAdded = total
            isAdding = false
            // Move past last recipe to show completion view
            currentRecipeIndex = recipes.count
        }
    }

    private func addAllRemainingAndFinish() {
        // Include current recipe's selections + all remaining recipes (fully selected)
        for index in (currentRecipeIndex + 1)..<recipes.count {
            let ingredients = sortedIngredients(for: recipes[index].recipe)
            selectedIngredients[index] = Set(ingredients.compactMap { $0.id })
        }
        addSelectedToList()
    }
}
