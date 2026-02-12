// AddIngredientView.swift
// Standalone component for adding new ingredients

import SwiftUI
import CoreData

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name = ""
    @State private var selectedCategory = "Uncategorized"
    @State private var isStaple = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
    ) private var categories: FetchedResults<Category>
    
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
        ingredient.category = selectedCategory == "Uncategorized" ? nil : selectedCategory
        ingredient.isStaple = isStaple
        
        // If this was an existing template, update its metadata
        if ingredient.dateCreated == nil {
            ingredient.dateCreated = Date()
        }
        ingredient.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Error saving ingredient: \(error)")
            #endif
        }
    }
}
