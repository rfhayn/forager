//
//  GroceryListDetailView.swift - INLINE ADD (SIMPLIFIED) + PROGRESS BAR FIX + M3 PHASE 6
//  forager
//
//  Added inline TextField for quick item entry without modal
//  PHASE 3: New ingredient tracking with template creation
//  FIX: Added @FetchRequest for live progress bar updates
//  M3 PHASE 6: Consolidation button with badge + visual indicators
//

import SwiftUI
import CoreData

struct GroceryListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // M7.3.4: Household service for filtering autocomplete by householdKey
    @EnvironmentObject private var householdService: HouseholdService

    @ObservedObject var weeklyList: WeeklyList
    
    // INLINE ADD: Services
    @StateObject private var templateService: IngredientTemplateService
    @StateObject private var parsingService: IngredientParsingService
    @StateObject private var autocompleteService: IngredientAutocompleteService
    
    // INLINE ADD: State
    @State private var quickAddText = ""
    @State private var showingAutocomplete = false
    @State private var selectedTemplate: IngredientTemplate? = nil
    @State private var defaultCategory = "Uncategorized"
    
    // Modal state
    @State private var showingAddItem = false
    
    // PHASE 3: New ingredient tracking
    @State private var showingAddToTemplates = false
    @State private var newIngredientName = ""
    @State private var newIngredientCategory = ""
    @State private var markAsStaple = false
    
    // FIX: Use @FetchRequest instead of relationship for live progress updates
    @FetchRequest private var listItemsFetch: FetchedResults<GroceryListItem>
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)
        ]
    ) private var categories: FetchedResults<Category>
    
    // INLINE ADD: Initialize services AND configure FetchRequest for live updates
    init(weeklyList: WeeklyList) {
        self.weeklyList = weeklyList
        
        let context = PersistenceController.shared.container.viewContext
        let templateSvc = IngredientTemplateService(context: context)
        let parsingSvc = IngredientParsingService(context: context, templateService: templateSvc)
        let autocompleteSvc = IngredientAutocompleteService(context: context, parsingService: parsingSvc)
        
        _templateService = StateObject(wrappedValue: templateSvc)
        _parsingService = StateObject(wrappedValue: parsingSvc)
        _autocompleteService = StateObject(wrappedValue: autocompleteSvc)
        
        // FIX: Configure FetchRequest for this specific list's items
        let listID = weeklyList.id ?? UUID()
        _listItemsFetch = FetchRequest<GroceryListItem>(
            sortDescriptors: [NSSortDescriptor(keyPath: \GroceryListItem.sortOrder, ascending: true)],
            predicate: NSPredicate(format: "weeklyList.id == %@", listID as CVarArg),
            animation: .default
        )
    }
    
    var body: some View {
        ZStack {
            if listItems.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    progressHeader
                    
                    // INLINE ADD: Quick add section at top
                    quickAddSection
                    
                    shoppingListView
                }
            }
        }
        .navigationTitle(weeklyList.name ?? "Grocery List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddItem) {
            AddListItemView(weeklyList: weeklyList)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingAddToTemplates) {
            addToTemplatesSheet
        }
        .onAppear {
            // M7.3.4: Configure autocomplete service with current householdKey
            autocompleteService.configure(householdKey: householdService.currentHouseholdKey)

            if let firstCategory = categories.first {
                defaultCategory = firstCategory.displayName
            }
        }
    }
    
    // MARK: - INLINE ADD: Quick Add Section
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                TextField("Quick add (e.g., \"2 cups flour\")", text: $quickAddText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: quickAddText) { oldValue, newValue in
                        if newValue.count >= 2 {
                            autocompleteService.debouncedSearch(fullText: newValue)
                            showingAutocomplete = true
                        } else {
                            showingAutocomplete = false
                            selectedTemplate = nil
                        }
                    }
                    .onSubmit {
                        quickAddItem()
                    }
                
                Button(action: quickAddItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Autocomplete dropdown
            if showingAutocomplete && !autocompleteService.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(autocompleteService.suggestions.prefix(5), id: \.objectID) { template in
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
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if template != autocompleteService.suggestions.prefix(5).last {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 4)
            }

            Divider()
                .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - INLINE ADD: Template Selection
    
    private func selectAutocompleteTemplate(_ template: IngredientTemplate) {
        selectedTemplate = template
        
        let parsed = parsingService.parseIngredient(text: quickAddText)
        
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
        
        quickAddText = rebuiltText
        showingAutocomplete = false
        
        // Update default category from template
        if let category = template.category, !category.isEmpty {
            defaultCategory = category
        }
    }
    
    // MARK: - INLINE ADD: Quick Add Item
    
    private func quickAddItem() {
        let trimmedText = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let parsed = parsingService.parseIngredient(text: trimmedText)
        let structured = parsingService.parseToStructured(text: trimmedText)
        
        // Try to find template if not already selected
        if selectedTemplate == nil {
            selectedTemplate = templateService.searchTemplates(query: parsed.name, limit: 1)
                .first(where: { $0.name?.lowercased() == parsed.name.lowercased() })
        }
        
        // Determine category
        let categoryToUse: String
        if let template = selectedTemplate, let category = template.category, !category.isEmpty {
            categoryToUse = category
        } else {
            categoryToUse = defaultCategory
        }
        
        // Create list item
        let listItem = GroceryListItem(context: viewContext)
        listItem.id = UUID()
        listItem.name = parsed.name
        listItem.displayText = structured.displayText
        listItem.numericValue = structured.numericValue ?? 0.0
        listItem.standardUnit = structured.standardUnit
        listItem.isParseable = structured.isParseable
        listItem.parseConfidence = structured.parseConfidence
        listItem.categoryName = categoryToUse
        listItem.source = "manual"
        listItem.isCompleted = false
        listItem.weeklyList = weeklyList
        listItem.sortOrder = Int16(weeklyList.items?.count ?? 0)
        
        do {
            try viewContext.save()
            print("✅ Quick added: \(parsed.name) to \(categoryToUse)")
            print("   🔍 Template search result: \(selectedTemplate?.name ?? "nil")")
            
            // PHASE 3: Check if this is a new ingredient
            if selectedTemplate == nil {
                print("   ⚠️ NEW INGREDIENT DETECTED - Should show modal")
                print("   📝 Ingredient name: \(parsed.name)")
                
                // Prepare data for template creation prompt
                newIngredientName = parsed.name
                newIngredientCategory = categoryToUse
                markAsStaple = false
                
                // Show the add to templates sheet
                DispatchQueue.main.async {
                    self.showingAddToTemplates = true
                    print("   📲 Modal trigger set to true")
                }
            } else {
                print("   ✓ Matched to existing template: \(selectedTemplate?.name ?? "unknown")")
            }
            
            // Clear the field
            quickAddText = ""
            selectedTemplate = nil
            showingAutocomplete = false
            
        } catch {
            print("❌ Failed to quick add item: \(error)")
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
                    }
                }
            }
        }
    }
    
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

        } catch {
            print("❌ Failed to save ingredient: \(error)")
            showingAddToTemplates = false
        }
    }
    
    // MARK: - Computed Properties
    
    // FIX: Use FetchRequest results instead of relationship access
    private var listItems: [GroceryListItem] {
        Array(listItemsFetch)
    }
    
    private var groupedItems: [(key: String, value: [GroceryListItem])] {
        let grouped = Dictionary(grouping: listItems) { item in
            item.categoryName ?? "Uncategorized"
        }
        return grouped.sorted { lhs, rhs in
            if let lhsCategory = categories.first(where: { $0.displayName == lhs.key }),
               let rhsCategory = categories.first(where: { $0.displayName == rhs.key }) {
                return lhsCategory.sortOrder < rhsCategory.sortOrder
            }
            return lhs.key < rhs.key
        }
    }
    
    private var totalItemsCount: Int {
        listItems.count
    }
    
    private var completedItemsCount: Int {
        listItems.filter { $0.isCompleted }.count
    }
    
    private var completionPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Empty List")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add some items to get started shopping!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddItem = true }) {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Shopping List View
    
    private var shoppingListView: some View {
        List {
            ForEach(groupedItems, id: \.key) { categoryName, items in
                Section(header: categoryHeader(for: categoryName, items: items)) {
                    ForEach(items, id: \.self) { item in
                        GroceryListItemRow(item: item) {
                            toggleItemCompletion(item)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleItemCompletion(item)
                            } label: {
                                Label(item.isCompleted ? "Undo" : "Complete",
                                      systemImage: item.isCompleted ? "arrow.uturn.left" : "checkmark")
                            }
                            .tint(item.isCompleted ? .orange : .green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingAddItem = true }) {
                Label("Add with Options", systemImage: "plus.square")
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func categoryHeader(for categoryName: String, items: [GroceryListItem]) -> some View {
        HStack {
            Text(categoryName)
                .font(.headline)
                .textCase(nil)
            
            Spacer()
            
            let completedCount = items.filter { $0.isCompleted }.count
            Text("\(completedCount)/\(items.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(completedItemsCount) of \(totalItemsCount) items")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("\(Int(completionPercentage * 100))% complete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !listItems.isEmpty && completedItemsCount < totalItemsCount {
                    Button("Complete All") {
                        markAllItemsComplete()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 8)
                        .foregroundColor(.gray.opacity(0.3))
                        .cornerRadius(4)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * completionPercentage, height: 8)
                        .foregroundColor(completionPercentage >= 1.0 ? .green : .blue)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: completionPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Actions
    
    private func toggleItemCompletion(_ item: GroceryListItem) {
        item.isCompleted.toggle()
        item.dateCompleted = item.isCompleted ? Date() : nil
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to toggle completion: \(error)")
        }
    }
    
    private func deleteItem(_ item: GroceryListItem) {
        viewContext.delete(item)
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to delete item: \(error)")
        }
    }
    
    private func markAllItemsComplete() {
        for item in listItems where !item.isCompleted {
            item.isCompleted = true
            item.dateCompleted = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to mark all complete: \(error)")
        }
    }
    
}

// MARK: - List Item Row Component

struct GroceryListItemRow: View {
    @ObservedObject var item: GroceryListItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                // M3 PHASE 6: Enhanced with visual indicators
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HStack(spacing: 6) {
                        // M4.3.1: Show item name without recipe tags
                        Text(item.name ?? "Unknown Item")
                            .font(.body)
                            .fontWeight(.medium)
                            .strikethrough(item.isCompleted)
                            .foregroundColor(item.isCompleted ? .secondary : (item.isParseable ? .primary : .primary.opacity(0.85)))
                            .lineLimit(2)
                        
                        // M8.3.1: Raised threshold from 0.5 to 0.7 for medium-confidence visibility
                        if !item.isCompleted && item.parseConfidence < 0.7 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .help("Low parsing confidence - tap to review")
                        }
                    }
                    
                    if let displayText = item.displayText, !displayText.isEmpty, displayText != "1" {
                        Text("(\(displayText))")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .strikethrough(item.isCompleted)
                    }
                    
                    Spacer()
                }
                
                // M4.3.1: Recipe source badges
                if !item.sourceRecipeNames.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.sourceRecipeNames, id: \.self) { recipeName in
                            Text(recipeName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // M4.3.1 FIX: Only show source text for MERGED items, not regular recipes
                // Recipe items now show badges above, so don't duplicate with text
                if let source = item.source, source.hasPrefix("merged") {
                    Text(sourceDisplayText(source))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // M3 PHASE 6: Enhanced source display with merge info
    private func sourceDisplayText(_ source: String) -> String {
        if source.hasPrefix("merged") {
            if source.contains("converted") {
                if let countStr = extractCount(from: source) {
                    return "Merged from \(countStr) items (converted)"
                }
                return "Merged (converted)"
            } else {
                if let countStr = extractCount(from: source) {
                    return "Merged from \(countStr) items"
                }
                return "Merged"
            }
        }
        
        switch source {
        case "staples": return "From Staples"
        case "manual": return "Added"
        case "recipe": return "From Recipe"
        default: return source.capitalized
        }
    }
    
    private func extractCount(from source: String) -> String? {
        if let startIdx = source.firstIndex(of: "("),
           let endIdx = source.firstIndex(of: ")") {
            return String(source[source.index(after: startIdx)..<endIdx])
        }
        return nil
    }
}
