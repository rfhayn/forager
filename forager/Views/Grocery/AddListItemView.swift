//
//  AddListItemView.swift
//  forager
//
//  PHASE 3 UPDATE: Added new ingredient to template system with category assignment
//

import SwiftUI
import CoreData

struct AddListItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // M7.3.4: Household service for filtering autocomplete by householdKey
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var weeklyListService: WeeklyListService

    let weeklyList: WeeklyList
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ],
        animation: .default
    ) private var allCategories: FetchedResults<Category>

    // M7.6.8: Filter categories by household scope to prevent duplicates
    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }

    // Services for autocomplete
    @StateObject private var templateService: IngredientTemplateService
    @StateObject private var parsingService: IngredientParsingService
    @StateObject private var autocompleteService: IngredientAutocompleteService
    
    @State private var ingredientText = ""
    @State private var selectedCategory = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Autocomplete state
    @State private var showingAutocomplete = false
    @State private var selectedTemplate: IngredientTemplate? = nil
    
    // M10.6.6: LLM parsing state
    @State private var isLLMAdding = false
    @State private var llmToastMessage: String?

    // PHASE 3: New ingredient tracking
    @State private var showingAddToTemplates = false
    @State private var newIngredientName = ""
    @State private var newIngredientCategory = ""
    @State private var markAsStaple = false
    @State private var lastAddedItem: GroceryListItem?
    
    private var isFormValid: Bool {
        !ingredientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(weeklyList: WeeklyList) {
        self.weeklyList = weeklyList
        
        let context = PersistenceController.shared.container.viewContext
        let templateSvc = IngredientTemplateService(context: context)
        let parsingSvc = IngredientParsingService(context: context, templateService: templateSvc)
        let autocompleteSvc = IngredientAutocompleteService(context: context, parsingService: parsingSvc)
        
        _templateService = StateObject(wrappedValue: templateSvc)
        _parsingService = StateObject(wrappedValue: parsingSvc)
        _autocompleteService = StateObject(wrappedValue: autocompleteSvc)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Item Name (e.g., \"2 cups flour\")", text: $ingredientText)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .onChange(of: ingredientText) { oldValue, newValue in
                                if newValue.count >= 2 {
                                    autocompleteService.debouncedSearch(fullText: newValue)
                                    showingAutocomplete = true
                                } else {
                                    showingAutocomplete = false
                                    selectedTemplate = nil
                                }
                            }
                        
                        // Autocomplete dropdown
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
                                                
                                                if let category = template.categoryEntity?.name, !category.isEmpty {
                                                    Text(category)
                                                        .font(.caption)
                                                        .foregroundStyle(ForagerTheme.textSecondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if template.isStaple {
                                                Image(systemName: "star.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(ForagerTheme.statusWarningFG)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle())
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
                    
                    Text("Enter with quantity (e.g., \"2 cups flour\") or just the item name")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    
                    if let template = selectedTemplate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ForagerTheme.statusSuccessFG)
                                .font(.caption)
                            
                            Text("Using ingredient: \(template.name ?? "")")
                                .font(.caption)
                                .foregroundStyle(ForagerTheme.textSecondary)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
                
                Section(header: Text("Category")) {
                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.displayName) { category in
                                Text(category.displayName)
                                    .tag(category.displayName)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text("Loading categories...")
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
                
                Section {
                    HStack {
                        Button("Add to List") {
                            addItemToList()
                        }
                        .disabled(!isFormValid)

                        Spacer()

                        // M10.6.6: LLM-enhanced add button
                        if parsingService.isLLMAvailable {
                            if isLLMAdding {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button {
                                    Task { await addItemWithLLM() }
                                } label: {
                                    ClaudeParseLabel(text: "AI Add")
                                        .font(ForagerTheme.secondaryFont)
                                }
                                .disabled(!isFormValid)
                            }
                        }
                    }
                }
                
                Section {
                    Text("Items added manually will be marked as 'Added' items.")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            // PHASE 3: Add to ingredient list prompt
            .sheet(isPresented: $showingAddToTemplates) {
                addToTemplatesSheet
            }
            .onAppear {
                // M9.12: Scope template lookups to household to prevent cross-store failures
                templateService.householdKey = householdService.currentHouseholdKey
                // M7.3.4: Configure autocomplete service with current householdKey
                autocompleteService.configure(householdKey: householdService.currentHouseholdKey)

                if selectedCategory.isEmpty, let firstCategory = categories.first {
                    selectedCategory = firstCategory.displayName
                }
            }
            .llmParsingToast(message: $llmToastMessage)
        }
    }
    
    // MARK: - PHASE 3: Add to Templates Sheet
    
    private var addToTemplatesSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("New Ingredient")) {
                    HStack {
                        Text("Name:")
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Spacer()
                        Text(newIngredientName)
                            .fontWeight(.medium)
                    }
                    
                    Picker("Category", selection: $newIngredientCategory) {
                        ForEach(categories, id: \.displayName) { category in
                            Text(category.displayName)
                                .tag(category.displayName)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Toggle("Mark as Staple", isOn: $markAsStaple)
                    
                    Text("Staple items automatically appear when generating new grocery lists.")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                
                Section {
                    Button("Add to Ingredient List") {
                        saveToTemplates()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add to Ingredients?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        showingAddToTemplates = false
                        dismiss() // Dismiss the main view too
                    }
                }
            }
        }
    }
    
    // MARK: - Autocomplete Selection
    
    private func selectAutocompleteTemplate(_ template: IngredientTemplate) {
        selectedTemplate = template
        
        let parsed = parsingService.parseIngredient(text: ingredientText)
        
        let quantityPart = parsed.quantity ?? ""
        let unitPart = parsed.unit ?? ""
        
        var rebuiltText = ""
        if !quantityPart.isEmpty {
            rebuiltText += quantityPart + " "
        }
        if !unitPart.isEmpty {
            rebuiltText += unitPart + " "
        }
        rebuiltText += template.name ?? ""
        
        ingredientText = rebuiltText
        showingAutocomplete = false
        
        if let category = template.categoryEntity?.name, !category.isEmpty {
            selectedCategory = category
            #if DEBUG
            print("📋 Auto-populated category: \(category)")
            #endif
        }
    }
    
    // MARK: - Helper Functions
    
    
    // MARK: - M10.6.6: LLM-Enhanced Add

    private func addItemWithLLM() async {
        let trimmedText = ingredientText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        isLLMAdding = true

        if let (parsed, structured, _) = await parsingService.parseSingleWithLLM(text: trimmedText, source: .groceryListItem) {
            let cleanName = parsed.displayName
            let matchedTemplate = selectedTemplate ?? templateService.searchTemplates(query: cleanName, limit: 1)
                .first(where: { $0.name?.lowercased() == cleanName.lowercased() })

            // M9.12: Resolve category entity from template or selected category
            let categoryEntity: Category?
            if let template = matchedTemplate, let catEntity = template.categoryEntity {
                categoryEntity = catEntity
            } else {
                categoryEntity = categories.first { $0.displayName == selectedCategory }
            }

            let confidence = matchedTemplate != nil
                ? max(structured.parseConfidence, 0.8)
                : structured.parseConfidence

            let listItem = weeklyListService.addItem(
                to: weeklyList, name: parsed.displayName,
                category: categoryEntity,
                numericValue: structured.numericValue ?? 0.0,
                standardUnit: structured.standardUnit,
                displayText: structured.displayText,
                isParseable: structured.isParseable,
                parseConfidence: confidence, source: "manual"
            )

            if let listItem = listItem {
                if matchedTemplate == nil {
                    lastAddedItem = listItem
                    newIngredientName = cleanName
                    newIngredientCategory = categoryEntity?.displayName ?? selectedCategory
                    markAsStaple = false
                    showingAddToTemplates = true
                } else {
                    dismiss()
                }
            } else {
                errorMessage = weeklyListService.errorMessage ?? "Failed to add item"
                showingError = true
            }
        } else {
            // LLM failed — fall through to local parse
            isLLMAdding = false
            addItemToList()
            return
        }

        isLLMAdding = false
    }

    private func addItemToList() {
        let trimmedText = ingredientText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // M8.4: Single parse via parseUnified (was double-parse)
        let (parsed, structured) = parsingService.parseUnified(text: trimmedText, source: .groceryListItem)
        
        // Try to find exact match if no template selected
        if selectedTemplate == nil {
            selectedTemplate = templateService.searchTemplates(query: parsed.name, limit: 1)
                .first(where: { $0.name?.lowercased() == parsed.name.lowercased() })
        }
        
        let confidence = selectedTemplate != nil
            ? max(structured.parseConfidence, 0.8)
            : structured.parseConfidence

        // M9.12: Resolve category entity from selected category name
        let categoryEntity = categories.first { $0.displayName == selectedCategory }
        let listItem = weeklyListService.addItem(
            to: weeklyList, name: parsed.displayName,
            category: categoryEntity,
            numericValue: structured.numericValue ?? 0.0,
            standardUnit: structured.standardUnit,
            displayText: structured.displayText,
            isParseable: structured.isParseable,
            parseConfidence: confidence, source: "manual"
        )

        if let listItem = listItem {
            #if DEBUG
            print("✅ Added item to list: \(parsed.displayName)")
            #endif

            if selectedTemplate == nil {
                #if DEBUG
                print("   ℹ️ New ingredient detected: \(parsed.name)")
                #endif
                lastAddedItem = listItem
                newIngredientName = parsed.name
                newIngredientCategory = selectedCategory
                markAsStaple = false
                showingAddToTemplates = true
            } else {
                #if DEBUG
                print("   ✓ Matched to existing template: \(selectedTemplate?.name ?? "unknown")")
                #endif
                dismiss()
            }
        } else {
            errorMessage = weeklyListService.errorMessage ?? "Failed to add item"
            showingError = true
        }
    }
    
    // PHASE 3: Save new ingredient to templates
    // M8.3.1: Route through findOrCreateTemplate for normalization & dedup
    private func saveToTemplates() {
        // M9.12: Look up Category entity for the selected category name
        let categoryEntity = categories.first { $0.displayName == newIngredientCategory }
        let newTemplate = templateService.findOrCreateTemplate(name: newIngredientName, category: categoryEntity)
        newTemplate.isStaple = markAsStaple

        // Propagate the user's category choice to the grocery list item
        if let item = lastAddedItem {
            item.categoryEntity = categoryEntity
            lastAddedItem = nil
        }

        weeklyListService.saveContext()
        #if DEBUG
        print("✅ Created new ingredient template: \(newIngredientName)")
        #endif

        if let error = weeklyListService.errorMessage {
            errorMessage = error
            showingError = true
        }
        showingAddToTemplates = false
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleList = WeeklyList(context: context)
    sampleList.id = UUID()
    sampleList.name = "Sample List"
    sampleList.dateCreated = Date()
    sampleList.isCompleted = false
    
    return AddListItemView(weeklyList: sampleList)
        .environment(\.managedObjectContext, context)
}
