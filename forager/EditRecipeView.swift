//
//  EditRecipeView.swift
//  forager
//
//  Created for M2.3: Recipe Creation & Editing
//  Edit existing recipes while maintaining data integrity
//

import SwiftUI
import CoreData

struct EditRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // M7.3.4: Household service for filtering autocomplete by householdKey
    @EnvironmentObject private var householdService: HouseholdService

    @ObservedObject var recipe: Recipe

    // Services
    @StateObject private var parsingService: IngredientParsingService
    @StateObject private var autocompleteService: IngredientAutocompleteService
    @StateObject private var templateService: IngredientTemplateService
    
    // Form data
    @State private var formData = RecipeFormData()
    @State private var currentIngredientText = ""
    @State private var showingAutocomplete = false
    @State private var showingPrepTimePicker = false
    @State private var showingCookTimePicker = false
    
    // UI state
    @State private var hasUnsavedChanges = false
    @State private var showingDiscardAlert = false
    @State private var showingCategoryModal = false
    @State private var showingValidationErrors = false
    @State private var validationErrors: [ValidationError] = []
    @State private var isSaving = false
    
    init(recipe: Recipe, context: NSManagedObjectContext) {
        self.recipe = recipe
        
        let templateSvc = IngredientTemplateService(context: context)
        let parsingSvc = IngredientParsingService(context: context, templateService: templateSvc)
        let autocompleteSvc = IngredientAutocompleteService(context: context, parsingService: parsingSvc)
        
        _templateService = StateObject(wrappedValue: templateSvc)
        _parsingService = StateObject(wrappedValue: parsingSvc)
        _autocompleteService = StateObject(wrappedValue: autocompleteSvc)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    basicInfoSection
                    timingSection
                    ingredientsSection
                    instructionsSection
                    tagsSection
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    hasUnsavedChanges = false
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Validation Errors", isPresented: $showingValidationErrors) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationErrors.map { $0.localizedDescription }.joined(separator: "\n"))
            }
            .sheet(isPresented: $showingCategoryModal) {
                if !formData.uncategorizedTemplates.isEmpty {
                    CategoryAssignmentModal(
                        uncategorizedTemplates: formData.uncategorizedTemplates,
                        onAssignmentsComplete: {
                            showingCategoryModal = false
                            completeSave()
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $showingPrepTimePicker) {
                TimePickerSheet(
                    title: "Prep Time",
                    hours: Binding(
                        get: { formData.prepTime / 60 },
                        set: { formData.prepTime = $0 * 60 + (formData.prepTime % 60) }
                    ),
                    minutes: Binding(
                        get: { formData.prepTime % 60 },
                        set: { formData.prepTime = (formData.prepTime / 60) * 60 + $0 }
                    ),
                    onDismiss: { showingPrepTimePicker = false }
                )
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCookTimePicker) {
                TimePickerSheet(
                    title: "Cook Time",
                    hours: Binding(
                        get: { formData.cookTime / 60 },
                        set: { formData.cookTime = $0 * 60 + (formData.cookTime % 60) }
                    ),
                    minutes: Binding(
                        get: { formData.cookTime % 60 },
                        set: { formData.cookTime = (formData.cookTime / 60) * 60 + $0 }
                    ),
                    onDismiss: { showingCookTimePicker = false }
                )
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                // M7.3.4: Configure autocomplete service with current householdKey
                autocompleteService.configure(householdKey: householdService.currentHouseholdKey)
                loadRecipeData()
            }
        }
    }
    
    private func loadRecipeData() {
        formData.name = recipe.title ?? ""
        formData.prepTime = Int(recipe.prepTime)
        formData.cookTime = Int(recipe.cookTime)
        formData.servings = Int(recipe.servings)
        formData.instructions = recipe.instructions ?? ""
        formData.isFavorite = recipe.isFavorite
        
        if let tags = recipe.tags, !tags.isEmpty {
            formData.tags = tags
        }
        
        if let ingredientsSet = recipe.ingredients as? Set<Ingredient> {
            let sortedIngredients = ingredientsSet.sorted { $0.sortOrder < $1.sortOrder }
            
            formData.ingredients = sortedIngredients.map { ingredient in
                IngredientInput(
                    fullText: ingredient.name ?? "",
                    template: ingredient.ingredientTemplate,
                    matchedViaAutocomplete: ingredient.ingredientTemplate != nil
                )
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("Recipe Name", text: $formData.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: formData.name) { oldValue, newValue in
                        hasUnsavedChanges = true
                    }
                
                HStack {
                    Text("Servings")
                        .foregroundColor(.secondary)
                    Spacer()
                    Stepper(value: $formData.servings, in: 1...99) {
                        Text("\(formData.servings)")
                            .frame(minWidth: 30)
                    }
                }
                .onChange(of: formData.servings) { oldValue, newValue in
                    hasUnsavedChanges = true
                }
                
                HStack {
                    Image(systemName: formData.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(formData.isFavorite ? .red : .gray)
                    
                    Toggle("Mark as Favorite", isOn: $formData.isFavorite)
                }
                .onChange(of: formData.isFavorite) { oldValue, newValue in
                    hasUnsavedChanges = true
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timing")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: { showingPrepTimePicker = true }) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Prep Time")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatTime(formData.prepTime))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                Button(action: { showingCookTimePicker = true }) {
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text("Cook Time")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatTime(formData.cookTime))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                
                if formData.totalTime > 0 {
                    Divider()
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Total Time")
                        Spacer()
                        Text(formatTime(formData.totalTime))
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .onChange(of: formData.prepTime) { oldValue, newValue in
            hasUnsavedChanges = true
        }
        .onChange(of: formData.cookTime) { oldValue, newValue in
            hasUnsavedChanges = true
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes == 0 {
            return "Not set"
        }
        
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.headline)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        TextField("Add ingredient (e.g., \"2 cups flour\")", text: $currentIngredientText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: currentIngredientText) { oldValue, newValue in
                                if newValue.count >= 2 {
                                    autocompleteService.debouncedSearch(fullText: newValue)
                                    showingAutocomplete = true
                                } else {
                                    showingAutocomplete = false
                                }
                            }
                            .onSubmit {
                                addIngredientManually()
                            }
                        
                        Button(action: addIngredientManually) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(currentIngredientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if showingAutocomplete && !autocompleteService.suggestions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(autocompleteService.suggestions, id: \.objectID) { template in
                                Button(action: {
                                    selectAutocompleteTemplate(template)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name ?? "")
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            
                                            if let category = template.category, !category.isEmpty {
                                                Text(category)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if template.usageCount > 0 {
                                            Text("\(template.usageCount)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if template != autocompleteService.suggestions.last {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(.top, 4)
                    }
                }
                
                if !formData.ingredients.isEmpty {
                    List {
                        ForEach(Array(formData.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                            ingredientRow(ingredient: ingredient, index: index)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                        .onMove { source, destination in
                            formData.ingredients.move(fromOffsets: source, toOffset: destination)
                            hasUnsavedChanges = true
                        }
                        .onDelete { indexSet in
                            formData.ingredients.remove(atOffsets: indexSet)
                            hasUnsavedChanges = true
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(height: CGFloat(formData.ingredients.count * 60))
                    .environment(\.editMode, .constant(.active))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func ingredientRow(ingredient: IngredientInput, index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(ingredient.statusIndicator.indicator)
                .font(.caption)
                .foregroundColor(statusColor(ingredient.statusIndicator))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                TextField("Ingredient", text: Binding(
                    get: { ingredient.fullText },
                    set: { newValue in
                        if let index = formData.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                            formData.ingredients[index].fullText = newValue
                            hasUnsavedChanges = true
                            
                            if newValue.count >= 2 {
                                let parsed = parsingService.parseIngredient(text: newValue)
                                let existingTemplate = templateService.searchTemplates(query: parsed.name, limit: 1)
                                    .first(where: { $0.name?.lowercased() == parsed.name.lowercased() })
                                formData.ingredients[index].template = existingTemplate
                            }
                        }
                    }
                ))
                .font(.body)
                .textFieldStyle(PlainTextFieldStyle())
                
                if let template = ingredient.template {
                    HStack(spacing: 4) {
                        if let category = template.category, !category.isEmpty {
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(ingredient.statusIndicator.description)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    Text("New ingredient - needs category")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.headline)
            
            TextEditor(text: $formData.instructions)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .onChange(of: formData.instructions) { oldValue, newValue in
                    hasUnsavedChanges = true
                }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.headline)
            
            TextField("Enter tags separated by commas", text: $formData.tags)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: formData.tags) { oldValue, newValue in
                    hasUnsavedChanges = true
                }
            
            Text("Example: quick and easy, leftovers, family favorite")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func statusColor(_ status: IngredientStatus) -> Color {
        switch status {
        case .ready: return .green
        case .needsCategory: return .orange
        case .needsTemplate: return .gray
        }
    }
    
    private func handleCancel() {
        if hasUnsavedChanges {
            showingDiscardAlert = true
        } else {
            dismiss()
        }
    }
    
    private func selectAutocompleteTemplate(_ template: IngredientTemplate) {
        let parsed = parsingService.parseIngredient(text: currentIngredientText)
        
        var rebuiltText = ""
        if let quantity = parsed.quantity {
            rebuiltText += quantity + " "
        }
        if let unit = parsed.unit {
            rebuiltText += unit + " "
        }
        rebuiltText += template.name ?? ""
        
        let ingredientInput = IngredientInput(
            fullText: rebuiltText,
            template: template,
            matchedViaAutocomplete: true
        )
        
        formData.ingredients.append(ingredientInput)
        currentIngredientText = ""
        showingAutocomplete = false
        hasUnsavedChanges = true
    }
    
    private func addIngredientManually() {
        let trimmed = currentIngredientText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let parsed = parsingService.parseIngredient(text: trimmed)
        let existingTemplate = templateService.searchTemplates(query: parsed.name, limit: 1)
            .first(where: { $0.name?.lowercased() == parsed.name.lowercased() })
        
        let ingredientInput = IngredientInput(
            fullText: trimmed,
            template: existingTemplate,
            matchedViaAutocomplete: false
        )
        
        formData.ingredients.append(ingredientInput)
        currentIngredientText = ""
        showingAutocomplete = false
        hasUnsavedChanges = true
    }
    
    private func saveRecipe() {
        let errors = formData.validate()
        if !errors.isEmpty {
            validationErrors = errors
            showingValidationErrors = true
            return
        }
        
        isSaving = true
        
        for (index, ingredientInput) in formData.ingredients.enumerated() {
            if ingredientInput.template == nil {
                // M8.3.1: Route through findOrCreateTemplate for normalization & dedup
                let parsed = parsingService.parseIngredient(text: ingredientInput.fullText)
                let newTemplate = templateService.findOrCreateTemplate(name: parsed.name)
                formData.ingredients[index].template = newTemplate
            }
        }
        
        let uncategorized = formData.uncategorizedTemplates
        if !uncategorized.isEmpty {
            isSaving = false
            showingCategoryModal = true
            return
        }
        
        completeSave()
    }
    
    private func completeSave() {
        do {
            recipe.title = formData.name.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.prepTime = Int16(formData.prepTime)
            recipe.cookTime = Int16(formData.cookTime)
            recipe.servings = Int16(formData.servings)
            recipe.instructions = formData.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.isFavorite = formData.isFavorite
            
            let tagsString = formData.tags.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tagsString.isEmpty {
                recipe.tags = tagsString
            } else {
                recipe.tags = nil
            }
            
            if let existingIngredients = recipe.ingredients as? Set<Ingredient> {
                for ingredient in existingIngredients {
                    viewContext.delete(ingredient)
                }
            }
            
            for (index, ingredientInput) in formData.ingredients.enumerated() {
                let trimmed = ingredientInput.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                
                let ingredient = Ingredient(context: viewContext)
                ingredient.id = UUID()
                ingredient.name = trimmed
                ingredient.sortOrder = Int16(index)
                ingredient.recipe = recipe
                
                if let template = ingredientInput.template {
                    ingredient.ingredientTemplate = template
                }
            }
            
            try viewContext.save()
            
            hasUnsavedChanges = false
            isSaving = false
            dismiss()
            
        } catch {
            isSaving = false
            validationErrors = [ValidationError.noInstructions]
            showingValidationErrors = true
            #if DEBUG
            print("Error updating recipe: \(error)")
            #endif
        }
    }
}

struct EditRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let recipe = Recipe(context: context)
        recipe.title = "Test Recipe"
        recipe.prepTime = 15
        recipe.cookTime = 30
        recipe.servings = 4
        recipe.instructions = "Test instructions"
        
        return EditRecipeView(recipe: recipe, context: context)
    }
}
