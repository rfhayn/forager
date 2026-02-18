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
    @State private var selectedCategory: String? = nil
    @State private var showStaplesOnly = false
    @State private var showNeedsReviewOnly = false
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
                if isEditMode && !selectedIngredients.isEmpty {
                    Menu {
                        Button("Change Category", systemImage: "folder") {
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
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                } else {
                    Button(action: { showingAddForm = true }) {
                        Image(systemName: "plus")
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
                        // Sort menu
                        Menu {
                            Picker("Sort", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }

                    if isEditMode {
                        Text("(\(ingredients.count))")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
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
    
    // MARK: - M15.5: Category Filter Pills
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                // "All" pill
                Button {
                    withAnimation { selectedCategory = nil }
                } label: {
                    FilterPill(
                        title: "All",
                        isSelected: selectedCategory == nil && !showStaplesOnly && !showNeedsReviewOnly,
                        size: .regular
                    )
                }

                // Individual category pills
                ForEach(uniqueCategoryNames, id: \.self) { categoryName in
                    Button {
                        withAnimation {
                            selectedCategory = selectedCategory == categoryName ? nil : categoryName
                        }
                    } label: {
                        FilterPill(
                            title: categoryName,
                            isSelected: selectedCategory == categoryName,
                            color: ForagerTheme.categoryColor(for: categoryName),
                            size: .regular
                        )
                    }
                }

                // Staples filter
                Button {
                    showStaplesOnly.toggle()
                } label: {
                    FilterPill(
                        title: "Staples",
                        isSelected: showStaplesOnly,
                        systemImage: "pin.fill"
                    )
                }

                // Review filter
                if needsReviewCount > 0 {
                    Button {
                        showNeedsReviewOnly.toggle()
                    } label: {
                        FilterPill(
                            title: "Review (\(needsReviewCount))",
                            isSelected: showNeedsReviewOnly,
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                }
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .background(ForagerTheme.backgroundCanvas)
    }

    private var uniqueCategoryNames: [String] {
        let names = Set(ingredients.compactMap { $0.category ?? "Uncategorized" })
        let categoryMap = Dictionary(
            categories.map { ($0.displayName, $0.sortOrder) },
            uniquingKeysWith: { first, _ in first }
        )
        return names.sorted { c1, c2 in
            if c1 == "Uncategorized" { return false }
            if c2 == "Uncategorized" { return true }
            let o1 = categoryMap[c1] ?? Int16.max
            let o2 = categoryMap[c2] ?? Int16.max
            return o1 == o2 ? c1 < c2 : o1 < o2
        }
    }
    
    // MARK: - Ingredients List View
    private var ingredientsListView: some View {
        List {
            ForEach(sortedCategoryNames, id: \.self) { categoryName in
                let items = groupedIngredients[categoryName] ?? []

                Section {
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
                                categoryChangePayload = CategoryChangePayload(
                                    ingredientTemplates: [ingredient]
                                )
                            },
                            onError: { message in
                                errorMessage = message
                                showingError = true
                            }
                        )
                    }
                    .onDelete { indexSet in
                        deleteIngredients(from: items, at: indexSet)
                    }
                } header: {
                    ForagerSectionHeader(
                        title: categoryName,
                        count: items.count
                    )
                }
            }
        }
        .listStyle(.plain)
        .background(ForagerTheme.backgroundCanvas)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 70)
        }
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

    // M8.3.1: Count of templates needing review (for badge on filter pill)
    private var needsReviewCount: Int {
        ingredients.filter { $0.needsReview }.count
    }

    private var filteredIngredients: [IngredientTemplate] {
        var filtered = Array(ingredients)

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { ingredient in
                ingredient.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { ingredient in
                (ingredient.category ?? "Uncategorized") == category
            }
        }

        // Apply staples filter
        if showStaplesOnly {
            filtered = filtered.filter { $0.isStaple }
        }

        // M8.3.1: Apply needs-review filter
        if showNeedsReviewOnly {
            filtered = filtered.filter { $0.needsReview }
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

}

// MARK: - Sort Options
enum SortOption: CaseIterable {
    case alphabetical, category, usage, staplesFirst
    
    var displayName: String {
        switch self {
        case .alphabetical: return "A-Z"
        case .category: return "Category"
        case .usage: return "Usage"
        case .staplesFirst: return "Staples"
        }
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
    var onError: ((String) -> Void)?

    @Environment(\.managedObjectContext) private var viewContext
    // M7.3.4: Household service for filtering duplicate checks by householdKey
    @EnvironmentObject private var householdService: HouseholdService
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // 4px category color strip
            Rectangle()
                .fill(ForagerTheme.categoryColor(for: ingredient.category ?? "Uncategorized"))
                .frame(width: 4)

            if isEditMode {
                Button(action: { onSelectionChanged(!isSelected) }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }

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
                VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                    Text(ingredient.name ?? "Unknown ingredient")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)

                    if ingredient.isStaple {
                        Text("Staple")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.accentSecondary)
                    }
                }
                .onTapGesture {
                    if !isEditMode { startNameEdit() }
                }

                if ingredient.needsReview {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(ForagerTheme.statusWarningFG)
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
                    .buttonStyle(.borderless)

                    Button("Save") {
                        saveNameEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.borderless)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                HStack(spacing: ForagerTheme.Spacing.md) {
                    // Usage badge
                    if ingredient.usageCount > 0 {
                        Text("\(ingredient.usageCount)×")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }

                    Button(action: onCategoryAssign) {
                        Image(systemName: "folder")
                            .font(.body)
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: onStapleToggle) {
                        Image(systemName: ingredient.isStaple ? "pin.fill" : "pin")
                            .font(.body)
                            .foregroundStyle(ingredient.isStaple ? ForagerTheme.accentSecondary : ForagerTheme.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
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
            reportError("Ingredient name cannot be empty")
            return
        }

        #if DEBUG
        print("📝 M8.3.1: saveNameEdit called — renaming '\(ingredient.name ?? "nil")' → '\(trimmedName)'")
        #endif

        // M8.3.1: Check for existing template with same name (for merge-on-rename)
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        if let householdKey = householdService.currentHouseholdKey {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@ AND householdKey == %@", trimmedName, ingredient, householdKey)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@ AND householdKey == nil", trimmedName, ingredient)
        }

        do {
            let duplicates = try viewContext.fetch(request)

            if let existingTemplate = duplicates.first {
                #if DEBUG
                print("📝 M8.3.1: Merging into existing '\(existingTemplate.name ?? "nil")' (moving \(ingredient.ingredients?.count ?? 0) ingredients)")
                #endif

                // M8.3.1: Merge — move all ingredient relationships to the existing template
                if let ingredientsToMove = ingredient.ingredients as? Set<Ingredient> {
                    for ing in ingredientsToMove {
                        ing.ingredientTemplate = existingTemplate
                    }
                }

                // Sum usage counts and preserve staple status
                existingTemplate.usageCount += ingredient.usageCount
                if ingredient.isStaple { existingTemplate.isStaple = true }
                existingTemplate.updatedAt = Date()

                // Delete the old (now-empty) template
                viewContext.delete(ingredient)
                try viewContext.save()

                #if DEBUG
                print("✅ M8.3.1: Merge complete — deleted old template")
                #endif

                isEditingName = false
            } else {
                // No duplicate — just rename
                ingredient.name = trimmedName
                ingredient.canonicalName = IngredientTemplate.canonicalName(from: trimmedName)
                ingredient.updatedAt = Date()
                try viewContext.save()

                #if DEBUG
                print("✅ M8.3.1: Renamed to '\(trimmedName)'")
                #endif

                isEditingName = false
            }
        } catch {
            #if DEBUG
            print("❌ M8.3.1: Save failed — \(error)")
            #endif
            reportError("Failed to save: \(error.localizedDescription)")
        }
    }

    private func reportError(_ message: String) {
        if let onError = onError {
            onError(message)
        } else {
            errorMessage = message
            showingError = true
        }
    }
    
}

#Preview {
    NavigationView {
        IngredientsView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
