// AddIngredientView.swift
// Standalone component for adding new ingredients

import SwiftUI
import CoreData

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService

    @State private var name = ""
    @State private var selectedCategory = "Uncategorized"
    @State private var isStaple = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
    ) private var allCategories: FetchedResults<Category>

    // M7.6.8: Filter categories by household scope to prevent duplicates
    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Ingredient Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Uncategorized").tag("Uncategorized")
                        ForEach(categories, id: \.objectID) { category in
                            Text(category.displayName).tag(category.displayName)
                        }
                    }
                    
                    Toggle("Is Staple", isOn: $isStaple)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveIngredient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveIngredient() {
        // M7.1.3: Use repository pattern to prevent duplicates
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ingredient = IngredientTemplateRepository.getOrCreate(
            displayName: trimmedName,
            in: viewContext
        )

        // Update properties (repository handles displayName and canonicalName)
        let category = selectedCategory == "Uncategorized" ? nil : selectedCategory
        ingredientTemplateService.updateTemplate(ingredient, name: trimmedName,
            category: category, isStaple: isStaple)

        if ingredientTemplateService.errorMessage == nil {
            dismiss()
        }
    }
}
