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

    let weeklyList: WeeklyList
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ],
        animation: .default
    ) private var categories: FetchedResults<Category>
    
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
    
    // PHASE 3: New ingredient tracking
    @State private var showingAddToTemplates = false
    @State private var newIngredientName = ""
    @State private var newIngredientCategory = ""
    @State private var markAsStaple = false
    
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
                                                    .foregroundColor(.primary)
                                                
                                                if let category = template.category, !category.isEmpty {
                                                    Text(category)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if template.isStaple {
                                                Image(systemName: "star.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
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
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.top, 4)
                        }
                    }
                    
                    Text("Enter with quantity (e.g., \"2 cups flour\") or just the item name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let template = selectedTemplate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text("Using ingredient: \(template.name ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
                
                Section(header: Text("Category")) {
                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.displayName) { category in
                                Text("\(categoryEmoji(for: category.displayName)) \(category.displayName)")
                                    .tag(category.displayName)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text("Loading categories...")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Add to List") {
                        addItemToList()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid)
                }
                
                Section {
                    Text("Items added manually will be marked as 'Added' items.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                // M7.3.4: Configure autocomplete service with current householdKey
                autocompleteService.configure(householdKey: householdService.currentHouseholdKey)

                if selectedCategory.isEmpty, let firstCategory = categories.first {
                    selectedCategory = firstCategory.displayName
                }
            }
        }
    }
    
    // MARK: - PHASE 3: Add to Templates Sheet
    
    private var addToTemplatesSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("New Ingredient")) {
                    HStack {
                        Text("Name:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(newIngredientName)
                            .fontWeight(.medium)
                    }
                    
                    Picker("Category", selection: $newIngredientCategory) {
                        ForEach(categories, id: \.displayName) { category in
                            Text("\(categoryEmoji(for: category.displayName)) \(category.displayName)")
                                .tag(category.displayName)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Toggle("Mark as Staple", isOn: $markAsStaple)
                    
                    Text("Staple items automatically appear when generating new grocery lists.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        
        if let category = template.category, !category.isEmpty {
            selectedCategory = category
            print("📋 Auto-populated category: \(category)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func categoryEmoji(for categoryName: String) -> String {
        switch categoryName {
        case "Produce": return "🥬"
        case "Deli & Meat": return "🥩"
        case "Dairy & Fridge": return "🥛"
        case "Bread & Frozen": return "🍞"
        case "Boxed & Canned": return "📦"
        case "Snacks, Drinks, & Other": return "🥤"
        default: return "📋"
        }
    }
    
    private func addItemToList() {
        let trimmedText = ingredientText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let parsed = parsingService.parseIngredient(text: trimmedText)
        let structured = parsingService.parseToStructured(text: trimmedText)
        
        // Try to find exact match if no template selected
        if selectedTemplate == nil {
            selectedTemplate = templateService.searchTemplates(query: parsed.name, limit: 1)
                .first(where: { $0.name?.lowercased() == parsed.name.lowercased() })
        }
        
        let listItem = GroceryListItem(context: viewContext)
        listItem.id = UUID()
        listItem.name = parsed.displayName
        listItem.displayText = structured.displayText
        listItem.numericValue = structured.numericValue ?? 0.0
        listItem.standardUnit = structured.standardUnit
        listItem.isParseable = structured.isParseable
        listItem.parseConfidence = structured.parseConfidence
        listItem.categoryName = selectedCategory
        listItem.source = "manual"
        listItem.isCompleted = false
        listItem.weeklyList = weeklyList
        listItem.sortOrder = Int16(weeklyList.items?.count ?? 0)
        
        do {
            try viewContext.save()
            print("✅ Added item to list: \(parsed.displayName)")
            
            // PHASE 3: Check if this is a new ingredient
            if selectedTemplate == nil {
                print("   ℹ️ New ingredient detected: \(parsed.name)")
                
                // Prepare data for template creation prompt
                newIngredientName = parsed.name
                newIngredientCategory = selectedCategory
                markAsStaple = false
                
                // Show the add to templates sheet
                showingAddToTemplates = true
            } else {
                print("   ✓ Matched to existing template: \(selectedTemplate?.name ?? "unknown")")
                dismiss() // Close immediately if template exists
            }
            
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // PHASE 3: Save new ingredient to templates
    // M8.3.1: Route through findOrCreateTemplate for normalization & dedup
    private func saveToTemplates() {
        let newTemplate = templateService.findOrCreateTemplate(name: newIngredientName, category: newIngredientCategory)
        newTemplate.isStaple = markAsStaple

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
            print("✅ Created new ingredient template: \(newIngredientName)")

            showingAddToTemplates = false
            dismiss()

        } catch {
            errorMessage = "Failed to save ingredient: \(error.localizedDescription)"
            showingError = true
            showingAddToTemplates = false
        }
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
