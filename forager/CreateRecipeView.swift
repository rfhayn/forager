//
//  CreateRecipeView.swift
//  forager
//
//  Created for M2.3: Recipe Creation & Editing
//  Professional recipe creation with parse-then-autocomplete ingredient management
//

import SwiftUI
import CoreData

struct CreateRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // M7.3.4: Household service for filtering autocomplete by householdKey
    @EnvironmentObject private var householdService: HouseholdService

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
    
    init(context: NSManagedObjectContext) {
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
                    // Basic Information Section
                    basicInfoSection
                    
                    // Timing Section
                    timingSection
                    
                    // Ingredients Section
                    ingredientsSection
                    
                    // Instructions Section
                    instructionsSection
                    
                    // Tags Section
                    tagsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("New Recipe")
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
                            // After category assignment, complete the save
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
            // M7.3.4: Configure autocomplete service with current householdKey
            .onAppear {
                autocompleteService.configure(householdKey: householdService.currentHouseholdKey)
            }
        }
    }
    
    // MARK: - Basic Information Section
    
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
    
    // MARK: - Timing Section
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timing")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Prep Time Button
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
                
                // Cook Time Button
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
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Add ingredient field with autocomplete - NOW WITH OVERLAY
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
                    
                    // Autocomplete dropdown - positioned directly below text field
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
                
                // Ingredient list with proper List wrapper for drag and drop
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
            // Status indicator
            Text(ingredient.statusIndicator.indicator)
                .font(.caption)
                .foregroundColor(statusColor(ingredient.statusIndicator))
                .frame(width: 20)
            
            // Editable ingredient text
            VStack(alignment: .leading, spacing: 2) {
                TextField("Ingredient", text: Binding(
                    get: { ingredient.fullText },
                    set: { newValue in
                        if let index = formData.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                            formData.ingredients[index].fullText = newValue
                            hasUnsavedChanges = true
                            
                            // Re-search for template match when text changes
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
    
    // MARK: - Instructions Section
    
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
    
    // MARK: - Tags Section
    
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
    
    // MARK: - Helper Methods
    
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
        // Parse to extract quantity/unit
        let parsed = parsingService.parseIngredient(text: currentIngredientText)
        
        // Rebuild text with template name
        var rebuiltText = ""
        if let quantity = parsed.quantity {
            rebuiltText += quantity + " "
        }
        if let unit = parsed.unit {
            rebuiltText += unit + " "
        }
        rebuiltText += template.name ?? ""
        
        // Create ingredient input with template link (READ-ONLY)
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
        
        // Parse ingredient
        let parsed = parsingService.parseIngredient(text: trimmed)
        
        // Try to find exact match in existing templates
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
    
    // MARK: - Save Recipe
    
    private func saveRecipe() {
        // Validate
        let errors = formData.validate()
        if !errors.isEmpty {
            validationErrors = errors
            showingValidationErrors = true
            return
        }
        
        isSaving = true
        
        // First, ensure all ingredients have templates created
        for (index, ingredientInput) in formData.ingredients.enumerated() {
            if ingredientInput.template == nil {
                // M8.3.1: Route through findOrCreateTemplate for normalization & dedup
                let parsed = parsingService.parseIngredient(text: ingredientInput.fullText)
                let newTemplate = templateService.findOrCreateTemplate(name: parsed.name)
                formData.ingredients[index].template = newTemplate
            }
        }
        
        // Now check for uncategorized templates
        let uncategorized = formData.uncategorizedTemplates
        if !uncategorized.isEmpty {
            // Show category assignment modal
            isSaving = false
            showingCategoryModal = true
            return
        }
        
        // No uncategorized templates, proceed with save
        completeSave()
    }
    
    private func completeSave() {
        do {
            // CRITICAL: Transaction order - Templates already created, now create Ingredients and Recipe
            
            // Step 1: Create Recipe
            let recipe = Recipe(context: viewContext)
            recipe.id = UUID()
            recipe.title = formData.name.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.prepTime = Int16(formData.prepTime)
            recipe.cookTime = Int16(formData.cookTime)
            recipe.servings = Int16(formData.servings)
            recipe.instructions = formData.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.isFavorite = formData.isFavorite
            recipe.dateCreated = Date()
            recipe.usageCount = 0
            recipe.lastUsed = nil
            
            // Parse and store tags (simple comma-separated string storage)
            let tagsString = formData.tags.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tagsString.isEmpty {
                // Store tags as comma-separated string in sourceURL field for now
                // (In production, you'd have a proper Tag entity)
                recipe.sourceURL = "tags:" + tagsString
            }
            
            // Step 2: Create Ingredients with Template links
            for (index, ingredientInput) in formData.ingredients.enumerated() {
                let trimmed = ingredientInput.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                
                // M4.3.1 FIX: Parse ingredient to get structured quantity fields
                let parsed = parsingService.parseToStructured(text: trimmed)
                
                let ingredient = Ingredient(context: viewContext)
                ingredient.id = UUID()
                ingredient.name = trimmed // Full text with quantity
                ingredient.sortOrder = Int16(index)
                ingredient.recipe = recipe
                
                // M4.3.1 FIX: Populate structured quantity fields from parsing
                ingredient.displayText = parsed.displayText
                ingredient.numericValue = parsed.numericValue ?? 0.0
                ingredient.standardUnit = parsed.standardUnit
                ingredient.isParseable = parsed.isParseable
                ingredient.parseConfidence = parsed.parseConfidence
                
                // Link to template (READ-ONLY reference)
                if let template = ingredientInput.template {
                    ingredient.ingredientTemplate = template
                    template.usageCount += 1
                }
            }
            
            // Single save for entire transaction
            try viewContext.save()
            
            // M7.2.3 Phase 4.3: Verify household auto-assignment
            print("✅ M7.2.3 Phase 4.3: Recipe saved - '\(recipe.title ?? "")'")
            print("   Household: \(recipe.household?.name ?? "nil")")
            print("   Household Key: \(recipe.householdKey ?? "nil")")
            
            hasUnsavedChanges = false
            isSaving = false
            dismiss()
            
        } catch {
            isSaving = false
            validationErrors = [ValidationError.noInstructions] // Reuse for generic error
            showingValidationErrors = true
            print("Error saving recipe: \(error)")
        }
    }
}

// MARK: - Time Picker Sheet Component

struct TimePickerSheet: View {
    let title: String
    @Binding var hours: Int
    @Binding var minutes: Int
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    // Hours Picker
                    VStack {
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    
                    // Minutes Picker
                    VStack {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct CreateRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRecipeView(context: PersistenceController.preview.container.viewContext)
    }
}
