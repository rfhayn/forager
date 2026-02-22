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
    @EnvironmentObject private var recipeService: RecipeService

    // M7.3.4: Household service for filtering autocomplete by householdKey
    @EnvironmentObject private var householdService: HouseholdService

    @ObservedObject var recipe: Recipe

    // Services
    @StateObject private var parsingService: IngredientParsingService
    @StateObject private var autocompleteService: IngredientAutocompleteService
    @StateObject private var templateService: IngredientTemplateService
    
    // MARK: - Enum-Based Sheet/Alert Routing (M7.5 Phase 2)
    private enum ActiveSheet: Identifiable {
        case categoryModal
        case prepTimePicker
        case cookTimePicker

        var id: String {
            switch self {
            case .categoryModal: return "categoryModal"
            case .prepTimePicker: return "prepTimePicker"
            case .cookTimePicker: return "cookTimePicker"
            }
        }
    }

    private enum ActiveAlert: Identifiable {
        case discard
        case validation([ValidationError])

        var id: String {
            switch self {
            case .discard: return "discard"
            case .validation: return "validation"
            }
        }

        var title: String {
            switch self {
            case .discard: return "Discard Changes?"
            case .validation: return "Validation Errors"
            }
        }
    }

    // Form data
    @State private var formData = RecipeFormData()
    @State private var currentIngredientText = ""
    @State private var showingAutocomplete = false
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?

    // UI state
    @State private var hasUnsavedChanges = false
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
            .alert(
                activeAlert?.title ?? "",
                isPresented: Binding(
                    get: { activeAlert != nil },
                    set: { if !$0 { activeAlert = nil } }
                ),
                presenting: activeAlert
            ) { alert in
                switch alert {
                case .discard:
                    Button("Cancel", role: .cancel) { }
                    Button("Discard", role: .destructive) {
                        hasUnsavedChanges = false
                        dismiss()
                    }
                case .validation:
                    Button("OK", role: .cancel) { }
                }
            } message: { alert in
                switch alert {
                case .discard:
                    Text("You have unsaved changes. Are you sure you want to discard them?")
                case .validation(let errors):
                    Text(errors.map { $0.localizedDescription }.joined(separator: "\n"))
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .categoryModal:
                    if !formData.uncategorizedTemplates.isEmpty {
                        CategoryAssignmentModal(
                            uncategorizedTemplates: formData.uncategorizedTemplates,
                            onAssignmentsComplete: {
                                activeSheet = nil
                                completeSave()
                            }
                        )
                        .environment(\.managedObjectContext, viewContext)
                    }
                case .prepTimePicker:
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
                        onDismiss: { activeSheet = nil }
                    )
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
                case .cookTimePicker:
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
                        onDismiss: { activeSheet = nil }
                    )
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
                }
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
                    matchedViaAutocomplete: ingredient.ingredientTemplate != nil,
                    // M8.4 Phase 7: Capture original state for correction telemetry
                    originalFullText: ingredient.name,
                    originalNumericValue: ingredient.numericValue != 0 ? ingredient.numericValue : nil,
                    originalStandardUnit: ingredient.standardUnit,
                    originalParseConfidence: ingredient.parseConfidence
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
                        .foregroundStyle(ForagerTheme.textSecondary)
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
                        .foregroundStyle(formData.isFavorite ? ForagerTheme.statusDangerFG : ForagerTheme.textTertiary)
                    
                    Toggle("Mark as Favorite", isOn: $formData.isFavorite)
                }
                .onChange(of: formData.isFavorite) { oldValue, newValue in
                    hasUnsavedChanges = true
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(ForagerTheme.Radius.md)
        }
    }
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timing")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: { activeSheet = .prepTimePicker }) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(ForagerTheme.accentPrimary)
                            .frame(width: 24)
                        Text("Prep Time")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formatTime(formData.prepTime))
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                Button(action: { activeSheet = .cookTimePicker }) {
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(ForagerTheme.statusWarningFG)
                            .frame(width: 24)
                        Text("Cook Time")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formatTime(formData.cookTime))
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                
                if formData.totalTime > 0 {
                    Divider()
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(ForagerTheme.statusSuccessFG)
                            .frame(width: 24)
                        Text("Total Time")
                        Spacer()
                        Text(formatTime(formData.totalTime))
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(ForagerTheme.Radius.md)
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
                                .foregroundStyle(ForagerTheme.accentPrimary)
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
                                                .foregroundStyle(.primary)
                                            
                                            if let category = template.category, !category.isEmpty {
                                                Text(category)
                                                    .font(.caption)
                                                    .foregroundStyle(ForagerTheme.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if template.usageCount > 0 {
                                            Text("\(template.usageCount)")
                                                .font(.caption2)
                                                .foregroundStyle(ForagerTheme.textSecondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(ForagerTheme.Radius.xs)
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
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
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
            .cornerRadius(ForagerTheme.Radius.md)
        }
    }
    
    private func ingredientRow(ingredient: IngredientInput, index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(ingredient.statusIndicator.indicator)
                .font(.caption)
                .foregroundStyle(statusColor(ingredient.statusIndicator))
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
                                .foregroundStyle(ForagerTheme.textSecondary)
                        } else {
                            Text(ingredient.statusIndicator.description)
                                .font(.caption)
                                .foregroundStyle(ForagerTheme.statusWarningFG)
                        }
                    }
                } else {
                    Text("New ingredient - needs category")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.statusWarningFG)
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
                .cornerRadius(ForagerTheme.Radius.sm)
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
                .foregroundStyle(ForagerTheme.textSecondary)
        }
    }
    
    private func statusColor(_ status: IngredientStatus) -> Color {
        switch status {
        case .ready: return ForagerTheme.statusSuccessFG
        case .needsCategory: return ForagerTheme.statusWarningFG
        case .needsTemplate: return ForagerTheme.textTertiary
        }
    }
    
    private func handleCancel() {
        if hasUnsavedChanges {
            activeAlert = .discard
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
            activeAlert = .validation(errors)
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
            activeSheet = .categoryModal
            return
        }
        
        completeSave()
    }
    
    private func completeSave() {
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

            // M8.4 Phase 7: Use parseUnified for both structured fields + correction detection
            let (parsedIngredient, structured) = parsingService.parseUnified(text: trimmed)
            ingredient.displayText = structured.displayText
            ingredient.numericValue = structured.numericValue ?? 0.0
            ingredient.standardUnit = structured.standardUnit
            ingredient.isParseable = structured.isParseable
            ingredient.parseConfidence = structured.parseConfidence

            if let template = ingredientInput.template {
                ingredient.ingredientTemplate = template
            }

            // M8.4 Phase 7: Log correction if user edited the ingredient text
            if let originalText = ingredientInput.originalFullText, trimmed != originalText {
                let originalParsed = parsingService.parseIngredient(text: originalText)
                let nameChanged = originalParsed.name.lowercased() != parsedIngredient.name.lowercased()
                let qtyChanged = ingredientInput.originalNumericValue != (structured.numericValue ?? 0.0)
                let unitChanged = ingredientInput.originalStandardUnit != structured.standardUnit

                if nameChanged || qtyChanged || unitChanged {
                    ParsingTelemetryService.shared.logCorrection(
                        originalName: originalParsed.name,
                        originalQuantity: ingredientInput.originalNumericValue,
                        originalUnit: ingredientInput.originalStandardUnit,
                        originalConfidence: ingredientInput.originalParseConfidence ?? 0,
                        correctedName: parsedIngredient.name,
                        correctedQuantity: structured.numericValue,
                        correctedUnit: structured.standardUnit,
                        source: .editRecipe
                    )
                }
            }
        }

        recipeService.saveContext()

        if let error = recipeService.errorMessage {
            isSaving = false
            activeAlert = .validation([ValidationError.noInstructions])
            #if DEBUG
            print("Error updating recipe: \(error)")
            #endif
        } else {
            hasUnsavedChanges = false
            isSaving = false
            dismiss()
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
