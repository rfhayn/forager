// IngredientsView.swift
// CRITICAL FIX: Use data-driven .sheet(item:) to prevent empty-first-render bug

import SwiftUI
import CoreData

// MARK: - CategoryChangePayload for Data-Driven Sheet
struct CategoryChangePayload: Identifiable {
    let id = UUID()
    let ingredientTemplates: [IngredientTemplate]
    
    init(ingredientTemplates: [IngredientTemplate]) {
        self.ingredientTemplates = ingredientTemplates
    }
}

struct IngredientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    // MARK: - Core Data Fetch
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \IngredientTemplate.isStaple, ascending: false),
            NSSortDescriptor(keyPath: \IngredientTemplate.category, ascending: true),
            NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)
        ],
        animation: .default
    ) private var allIngredients: FetchedResults<IngredientTemplate>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default
    ) private var allCategories: FetchedResults<Category>

    // M7.3.2: Filter based on current household context
    // M7.2.2 FIX: Use currentHouseholdKey which has fallback for nil household.id
    private var ingredients: [IngredientTemplate] {
        let currentHouseholdKey = householdService.currentHouseholdKey

        #if DEBUG
        print("🔍 M7.3.2 Ingredients Filter Debug:")
        print("   Total ingredients in fetch: \(allIngredients.count)")
        print("   Current household key: \(currentHouseholdKey ?? "nil")")
        if !allIngredients.isEmpty {
            let first5 = allIngredients.prefix(5)
            for template in first5 {
                print("   Template '\(template.name ?? "untitled")': householdKey=\(template.householdKey ?? "nil")")
            }
            if allIngredients.count > 5 {
                print("   ... and \(allIngredients.count - 5) more")
            }
        }
        #endif

        return allIngredients.filter { template in
            if let householdKey = currentHouseholdKey {
                return template.householdKey == householdKey
            } else {
                return template.householdKey == nil
            }
        }
    }

    // M7.2.2 FIX: Use currentHouseholdKey which has fallback for nil household.id
    private var categories: [Category] {
        let currentHouseholdKey = householdService.currentHouseholdKey

        #if DEBUG
        print("🔍 M7.3.2 Categories Filter Debug:")
        print("   Total categories in fetch: \(allCategories.count)")
        print("   Current household key: \(currentHouseholdKey ?? "nil")")
        if !allCategories.isEmpty {
            for category in allCategories {
                print("   Category '\(category.name ?? "untitled")': householdKey=\(category.householdKey ?? "nil")")
            }
        }
        #endif

        return allCategories.filter { category in
            if let householdKey = currentHouseholdKey {
                return category.householdKey == householdKey
            } else {
                return category.householdKey == nil
            }
        }
    }

    // MARK: - State Variables
    @State private var searchText = ""
    @State private var selectedCategory = "All Categories"
    @State private var showStaplesOnly = false
    @State private var sortOption: SortOption = .staplesFirst
    @State private var isEditMode = false
    @State private var selectedIngredients: Set<IngredientTemplate> = []
    @State private var showingAddForm = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - FIXED: Data-driven sheet presentation (no more empty-first-render!)
    @State private var categoryChangePayload: CategoryChangePayload?

    var body: some View {
        VStack(spacing: 0) {
            // M7.4: Removed search bar, now using .searchable() for Apple Music pattern
            // Filter Section
            filterSection

            // Main Content
            if filteredIngredients.isEmpty {
                emptyStateView
            } else {
                ingredientsListView
            }
        }
        .navigationTitle("Ingredients")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Enhanced toolbar with bulk category assignment
                if isEditMode && !selectedIngredients.isEmpty {
                    // Show bulk operations menu when items are selected in edit mode
                    Menu {
                        Button("Change Category", systemImage: "folder") {
                            // FIXED: Use data-driven payload approach
                            categoryChangePayload = CategoryChangePayload(
                                ingredientTemplates: Array(selectedIngredients)
                            )
                        }
                        
                        Divider()
                        
                        Button("Mark as Staples", systemImage: "pin.fill") {
                            markSelectedAsStaples(true)
                        }
                        
                        Button("Remove Staple Status", systemImage: "pin.slash") {
                            markSelectedAsStaples(false)
                        }
                        
                        Divider()
                        
                        Button("Delete Selected", systemImage: "trash", role: .destructive) {
                            bulkDeleteSelected()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(.blue)
                    }
                } else {
                    Button(action: {
                        showingAddForm = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    if isEditMode {
                        Button("Done") {
                            withAnimation {
                                isEditMode = false
                                selectedIngredients.removeAll()
                            }
                        }
                    } else {
                        Button("Edit") {
                            withAnimation {
                                isEditMode = true
                            }
                        }
                        .disabled(ingredients.isEmpty)
                    }
                    
                    if isEditMode {
                        Text("(\(ingredients.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddForm) {
            AddIngredientView()
        }
        // FIXED: Data-driven sheet with CategoryChangePayload (prevents empty-first-render!)
        .sheet(item: $categoryChangePayload) { payload in
            CategoryChangeModal(
                ingredientTemplates: payload.ingredientTemplates,
                onAssignmentsComplete: {
                    // Clear selections and exit edit mode after change
                    selectedIngredients.removeAll()
                    isEditMode = false
                    // Clear the payload to close the sheet
                    categoryChangePayload = nil
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: popToRoot) { _, _ in
            if showingAddForm { showingAddForm = false }
            if categoryChangePayload != nil { categoryChangePayload = nil }
            if showingError { showingError = false }
            if isEditMode {
                isEditMode = false
                selectedIngredients.removeAll()
            }
        }
    }
    
    // MARK: - M7.4: Filter Section (search moved to .searchable())
    private var filterSection: some View {
        VStack(spacing: 16) {
            // FIXED: Single-line filter layout that's clean and organized
            HStack(spacing: 8) {
                // Category Filter
                Menu {
                    Button("All Categories") {
                        selectedCategory = "All Categories"
                    }
                    
                    Divider()
                    
                    ForEach(Array(Set(ingredients.compactMap { $0.category ?? "Uncategorized" })).sorted(), id: \.self) { category in
                        Button(category) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    FilterPill(
                        text: selectedCategory == "All Categories" ? "All Categories" : selectedCategory,
                        isSelected: selectedCategory != "All Categories",
                        systemImage: "folder"
                    )
                }
                
                // Staples Filter
                Button(action: {
                    showStaplesOnly.toggle()
                }) {
                    FilterPill(
                        text: "Staples",
                        isSelected: showStaplesOnly,
                        systemImage: "pin.fill"
                    )
                }
                
                // Sort Options
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            sortOption = option
                        }
                    }
                } label: {
                    FilterPill(
                        text: sortOption.displayName,
                        isSelected: false, // Keep sort neutral since it's always active
                        systemImage: "arrow.up.arrow.down"
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Ingredients List View
    private var ingredientsListView: some View {
        List {
            ForEach(sortedCategoryNames, id: \.self) { categoryName in
                let items = groupedIngredients[categoryName] ?? []
                
                Section(header: categoryHeader(categoryName: categoryName, count: items.count)) {
                    ForEach(items, id: \.objectID) { ingredient in
                        IngredientRowView(
                            ingredient: ingredient,
                            isSelected: selectedIngredients.contains(ingredient),
                            isEditMode: isEditMode,
                            onSelectionChanged: { isSelected in
                                if isSelected {
                                    selectedIngredients.insert(ingredient)
                                } else {
                                    selectedIngredients.remove(ingredient)
                                }
                            },
                            onStapleToggle: {
                                toggleStapleStatus(for: ingredient)
                            },
                            onCategoryAssign: {
                                // FIXED: Single ingredient category change with data-driven payload
                                categoryChangePayload = CategoryChangePayload(
                                    ingredientTemplates: [ingredient]
                                )
                            }
                        )
                    }
                    .onDelete { indexSet in
                        deleteIngredients(from: items, at: indexSet)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Category Header
    private func categoryHeader(categoryName: String, count: Int) -> some View {
        HStack {
            Circle()
                .fill(categoryColor(for: categoryName))
                .frame(width: 16, height: 16)
                .overlay(
                    Text(categoryEmoji(for: categoryName))
                        .font(.system(size: 10))
                )
            
            Text(categoryName.uppercased())
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
        .background(Color(.systemGroupedBackground))
        .listRowInsets(EdgeInsets())
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        StandardEmptyStateView(
            iconName: "leaf.circle",
            title: "No Ingredients Found",
            subtitle: "Start adding ingredients to your collection!",
            buttonIcon: "plus.circle.fill",
            buttonText: "Add First Ingredient",
            buttonAction: { showingAddForm = true }
        )
    }
    
    // MARK: - Computed Properties
    private var filteredIngredients: [IngredientTemplate] {
        var filtered = Array(ingredients)
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { ingredient in
                ingredient.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply category filter
        if selectedCategory != "All Categories" {
            filtered = filtered.filter { ingredient in
                (ingredient.category ?? "Uncategorized") == selectedCategory
            }
        }
        
        // Apply staples filter
        if showStaplesOnly {
            filtered = filtered.filter { $0.isStaple }
        }
        
        // Apply sorting
        return applySorting(to: filtered)
    }
    
    private var groupedIngredients: [String: [IngredientTemplate]] {
        Dictionary(grouping: filteredIngredients) { ingredient in
            ingredient.category ?? "Uncategorized"
        }
    }
    
    // FIXED: Sort categories by custom sort order from Category entities
    // M7.2.3 Phase 3.6: Handle duplicate categories gracefully (use first occurrence)
    private var sortedCategoryNames: [String] {
        let grouped = groupedIngredients
        // Use uniquingKeysWith to handle duplicate category names (keep first occurrence)
        let categoryMap = Dictionary(
            categories.map { ($0.displayName, $0.sortOrder) },
            uniquingKeysWith: { first, _ in first }
        )
        
        return grouped.keys.sorted { category1, category2 in
            // Handle "Uncategorized" - put it at the end
            if category1 == "Uncategorized" && category2 != "Uncategorized" { return false }
            if category2 == "Uncategorized" && category1 != "Uncategorized" { return true }
            if category1 == "Uncategorized" && category2 == "Uncategorized" { return false }
            
            // Use custom sort order for real categories
            let order1 = categoryMap[category1] ?? Int16.max
            let order2 = categoryMap[category2] ?? Int16.max
            
            if order1 == order2 {
                return category1 < category2 // Fallback to alphabetical
            }
            return order1 < order2
        }
    }
    
    // MARK: - Actions
    private func toggleStapleStatus(for ingredient: IngredientTemplate) {
        ingredient.isStaple.toggle()
        
        do {
            try viewContext.save()
        } catch {
            // Revert on error
            ingredient.isStaple.toggle()
            errorMessage = "Failed to update staple status: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func markSelectedAsStaples(_ isStaple: Bool) {
        for ingredient in selectedIngredients {
            ingredient.isStaple = isStaple
        }
        
        do {
            try viewContext.save()
            selectedIngredients.removeAll()
            isEditMode = false
        } catch {
            // Revert changes on error
            for ingredient in selectedIngredients {
                ingredient.isStaple = !isStaple
            }
            errorMessage = "Failed to update staple status: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func bulkDeleteSelected() {
        for ingredient in selectedIngredients {
            viewContext.delete(ingredient)
        }
        
        do {
            try viewContext.save()
            selectedIngredients.removeAll()
            isEditMode = false
        } catch {
            errorMessage = "Failed to delete ingredients: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteIngredients(from items: [IngredientTemplate], at indexSet: IndexSet) {
        for index in indexSet {
            let ingredient = items[index]
            viewContext.delete(ingredient)
        }
        
        do {
            try viewContext.save()
        } catch {
            errorMessage = "Failed to delete ingredient: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func applySorting(to ingredients: [IngredientTemplate]) -> [IngredientTemplate] {
        switch sortOption {
        case .alphabetical:
            return ingredients.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .category:
            return ingredients.sorted {
                let cat1 = $0.category ?? "Uncategorized"
                let cat2 = $1.category ?? "Uncategorized"
                if cat1 == cat2 {
                    return ($0.name ?? "") < ($1.name ?? "")
                }
                return cat1 < cat2
            }
        case .usage:
            return ingredients.sorted {
                // Sort by usage frequency (would require tracking usage)
                // For now, sort by name as fallback
                ($0.name ?? "") < ($1.name ?? "")
            }
        case .staplesFirst:
            return ingredients.sorted {
                if $0.isStaple == $1.isStaple {
                    return ($0.name ?? "") < ($1.name ?? "")
                }
                return $0.isStaple && !$1.isStaple
            }
        }
    }
    
    // MARK: - Helper Methods
    private func categoryColor(for categoryName: String) -> Color {
        switch categoryName.lowercased() {
        case "produce": return .green
        case "deli & meat": return .red
        case "dairy & fridge": return .blue
        case "bread & frozen": return .orange
        case "boxed & canned": return .brown
        case "snacks, drinks, & other": return .purple
        default: return .gray
        }
    }
    
    private func categoryEmoji(for categoryName: String) -> String {
        switch categoryName.lowercased() {
        case "produce": return "🥬"
        case "deli & meat": return "🥩"
        case "dairy & fridge": return "🥛"
        case "bread & frozen": return "🍞"
        case "boxed & canned": return "📦"
        case "snacks, drinks, & other": return "🥤"
        default: return "📦"
        }
    }
}

// MARK: - Sort Options
enum SortOption: CaseIterable {
    case alphabetical, category, usage, staplesFirst
    
    var displayName: String {
        switch self {
        case .alphabetical: return "A-Z"
        case .category: return "Category"
        case .usage: return "Usage"
        case .staplesFirst: return "Staples First"
        }
    }
}

// MARK: - Filter Pill Component - OPTIMIZED for single line layout
struct FilterPill: View {
    let text: String
    let isSelected: Bool
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
                .fontWeight(.medium)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
        )
        .foregroundColor(isSelected ? .white : .primary)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: isSelected ? 0 : 0.5)
        )
    }
}

// MARK: - Ingredient Row View
struct IngredientRowView: View {
    let ingredient: IngredientTemplate
    let isSelected: Bool
    let isEditMode: Bool
    let onSelectionChanged: (Bool) -> Void
    let onStapleToggle: () -> Void
    let onCategoryAssign: () -> Void

    @Environment(\.managedObjectContext) private var viewContext
    // M7.3.4: Household service for filtering duplicate checks by householdKey
    @EnvironmentObject private var householdService: HouseholdService
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack {
            if isEditMode {
                Button(action: { onSelectionChanged(!isSelected) }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Category indicator
            Circle()
                .fill(categoryColor(for: ingredient.category ?? "Uncategorized"))
                .frame(width: 12, height: 12)
            
            // INLINE EDITING: Ingredient name with tap-to-edit functionality
            if isEditingName {
                TextField("Ingredient name", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                    .onSubmit {
                        saveNameEdit()
                    }
                    .onAppear {
                        editedName = ingredient.name ?? ""
                    }
            } else {
                Text(ingredient.name ?? "Unknown ingredient")
                    .font(.body)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        if !isEditMode { // Only allow name editing when not in selection mode
                            startNameEdit()
                        }
                    }
            }
            
            Spacer()
            
            // Actions - conditional based on editing state
            if isEditingName {
                // Edit mode actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        cancelNameEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Button("Save") {
                        saveNameEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                // Normal actions
                HStack(spacing: 16) {
                    // Category assignment button
                    Button(action: onCategoryAssign) {
                        Image(systemName: "folder")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Staple toggle button - FIXED: Filled pin for staples, outline for non-staples
                    Button(action: onStapleToggle) {
                        Image(systemName: ingredient.isStaple ? "pin.fill" : "pin")
                            .font(.body)
                            .foregroundColor(ingredient.isStaple ? .orange : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Inline Editing Functions
    
    private func startNameEdit() {
        editedName = ingredient.name ?? ""
        isEditingName = true
    }
    
    private func cancelNameEdit() {
        editedName = ingredient.name ?? ""
        isEditingName = false
    }
    
    private func saveNameEdit() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Ingredient name cannot be empty"
            showingError = true
            return
        }
        
        // M7.3.4: Check for duplicates within current household scope only (excluding current ingredient)
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        if let householdKey = householdService.currentHouseholdKey {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@ AND householdKey == %@", trimmedName, ingredient, householdKey)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@ AND householdKey == nil", trimmedName, ingredient)
        }
        
        do {
            let existingIngredients = try viewContext.fetch(request)
            if !existingIngredients.isEmpty {
                errorMessage = "An ingredient with this name already exists"
                showingError = true
                return
            }
            
            // Save the new name
            ingredient.name = trimmedName
            try viewContext.save()
            isEditingName = false
            
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func categoryColor(for categoryName: String) -> Color {
        switch categoryName.lowercased() {
        case "produce": return .green
        case "deli & meat": return .red
        case "dairy & fridge": return .blue
        case "bread & frozen": return .orange
        case "boxed & canned": return .brown
        case "snacks, drinks, & other": return .purple
        default: return .gray
        }
    }
}

#Preview {
    NavigationView {
        IngredientsView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
