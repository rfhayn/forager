// AddIngredientView.swift
// Standalone component for adding new ingredients

import SwiftUI
import CoreData

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.managedObjectFactory) private var factory
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService

    @EnvironmentObject private var storeService: StoreService

    @State private var name = ""
    @State private var selectedCategory = "Uncategorized"
    @State private var selectedStoreName = ""
    @State private var isStaple = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
    ) private var allCategories: FetchedResults<Category>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Store.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Store.name, ascending: true)
        ]
    ) private var allStores: FetchedResults<Store>

    // M7.6.8: Filter categories by household scope to prevent duplicates
    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }

    private var stores: [Store] {
        let key = householdService.currentHouseholdKey
        return allStores.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    // M18.1.5: Store picker
                    if !stores.isEmpty {
                        Picker("Store", selection: $selectedStoreName) {
                            Text("No Store").tag("")
                            ForEach(stores, id: \.self) { store in
                                HStack {
                                    StoreColorDot(hex: store.color, size: 12)
                                    Text(store.name ?? "Unnamed")
                                }
                                .tag(store.name ?? "")
                            }
                        }
                    }

                    Toggle("Is Staple", isOn: $isStaple)
                }
            }
                .scrollContentBackground(.hidden)
                .background(ForagerTheme.backgroundCanvas)
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
        guard let factory = factory else { return }
        guard let ingredient = IngredientTemplateRepository.getOrCreate(
            displayName: trimmedName,
            in: viewContext,
            factory: factory
        ) else { return }

        // M9.12: Look up Category entity by name, pass entity instead of String
        let categoryEntity: Category? = selectedCategory == "Uncategorized"
            ? nil
            : categories.first(where: { $0.displayName == selectedCategory })
        ingredientTemplateService.updateTemplate(ingredient, name: trimmedName,
            category: categoryEntity, isStaple: isStaple)

        // M18.1.5: Assign preferred store
        if !selectedStoreName.isEmpty,
           let store = stores.first(where: { $0.name == selectedStoreName }) {
            storeService.assignStore(store, toTemplate: ingredient)
        }

        if ingredientTemplateService.errorMessage == nil {
            dismiss()
        }
    }
}
