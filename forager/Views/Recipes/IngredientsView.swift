// IngredientsView.swift
// M7.5 Phase 2: Enum-based sheet routing replaces boolean flags

import SwiftUI
import CoreData

struct IngredientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService
    @EnvironmentObject private var parsingService: IngredientParsingService
    @EnvironmentObject private var storeService: StoreService

    @Binding var popToRoot: Bool

    // MARK: - Core Data Fetch
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \IngredientTemplate.isStaple, ascending: false),
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

    // MARK: - Enum-Based Sheet Routing (M7.5 Phase 2)
    private enum ActiveSheet: Identifiable {
        case addForm
        case review
        case duplicateReview
        case categoryChange([IngredientTemplate])
        case storeChange([IngredientTemplate])

        var id: String {
            switch self {
            case .addForm: return "addForm"
            case .review: return "review"
            case .duplicateReview: return "duplicateReview"
            case .categoryChange: return "categoryChange"
            case .storeChange: return "storeChange"
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
    @State private var showDuplicatesOnly = false
    @State private var activeSheet: ActiveSheet?
    @State private var errorMessage: String?

    // M10.6.7: LLM re-parse state
    @State private var isLLMBatchParsing = false
    @State private var llmToastMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // M7.4: Removed search bar, now using .searchable() for Apple Music pattern
            // Filter Section
            filterSection

            // M15.5: Review banner (when items need review and not already filtering to review)
            if needsReviewCount > 0 && !showNeedsReviewOnly {
                reviewBanner
            }

            // M18.1.5: Store assignment banner (dismissible)
            if needsStoreCount > 0 && hasStoresInHousehold && !storeAssignmentBannerDismissed {
                storeAssignmentBanner
            }

            // M15: Duplicate banner (when duplicates exist and not already filtering)
            if duplicateGroupCount > 0 && !showDuplicatesOnly {
                duplicateBanner
            }

            // M15.5: Staples summary header (when filtering to staples)
            if showStaplesOnly {
                staplesSummaryHeader
            }

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
                            activeSheet = .categoryChange(Array(selectedIngredients))
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
                    Button(action: { activeSheet = .addForm }) {
                        Image(systemName: "plus")
                    }
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    if isEditMode {
                        Button("Done") {
                            withAnimation(reduceMotion ? nil : .default) {
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addForm:
                AddIngredientView()
            case .review:
                IngredientReviewSheet(
                    ingredients: ingredients.filter { $0.needsReview }
                )
            case .duplicateReview:
                DuplicateReviewSheet(duplicateGroups: duplicateGroups)
            case .categoryChange(let templates):
                CategoryChangeModal(
                    ingredientTemplates: templates,
                    onAssignmentsComplete: {
                        selectedIngredients.removeAll()
                        isEditMode = false
                        activeSheet = nil
                    }
                )
            case .storeChange(let templates):
                StoreChangeModal(
                    ingredientTemplates: templates,
                    storeService: storeService,
                    householdKey: householdService.currentHouseholdKey,
                    onAssignmentsComplete: {
                        selectedIngredients.removeAll()
                        isEditMode = false
                        activeSheet = nil
                    }
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .llmParsingToast(message: $llmToastMessage)
        .onChange(of: popToRoot) { _, _ in
            activeSheet = nil
            errorMessage = nil
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
                    withAnimation(reduceMotion ? nil : .default) { selectedCategory = nil }
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
                        withAnimation(reduceMotion ? nil : .default) {
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
                    .accessibilityLabel("\(categoryName) filter")
                    .accessibilityValue(selectedCategory == categoryName ? "Selected" : "Not selected")
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

                // Duplicate filter
                if duplicateGroupCount > 0 {
                    Button {
                        showDuplicatesOnly.toggle()
                    } label: {
                        FilterPill(
                            title: "Dupes (\(duplicateGroupCount))",
                            isSelected: showDuplicatesOnly,
                            systemImage: "doc.on.doc"
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
        let names = Set(ingredients.compactMap { $0.categoryEntity?.name ?? "Uncategorized" })
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
    
    // MARK: - M15.5: Review Banner

    private var reviewBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ForagerTheme.statusWarningFG)
            Text("\(needsReviewCount) ingredient\(needsReviewCount == 1 ? "" : "s") need\(needsReviewCount == 1 ? "s" : "") review")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textPrimary)
            Spacer()
            // M10.6.7: AI re-parse for needsReview templates
            if parsingService.isLLMAvailable {
                if isLLMBatchParsing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task { await batchLLMReparseTemplates() }
                    } label: {
                        AIParseLabel()
                            .font(ForagerTheme.footnoteFont)
                    }
                }
            }
            Button("Review Now") {
                activeSheet = .review
            }
            .font(ForagerTheme.footnoteFont.bold())
            .foregroundStyle(ForagerTheme.accentPrimary)
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfaceWarning)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(needsReviewCount) ingredients need review")
        .accessibilityHint("Double tap Review Now to start guided review")
    }

    // MARK: - M18.1.5: Store Assignment Banner

    @AppStorage("storeAssignmentBannerDismissed") private var storeAssignmentBannerDismissed = false

    private var storeAssignmentBanner: some View {
        HStack {
            Image(systemName: "storefront")
                .foregroundStyle(ForagerTheme.accentPrimary)
            Text("\(needsStoreCount) ingredient\(needsStoreCount == 1 ? "" : "s") without a store")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textPrimary)
            Spacer()
            Button("Assign") {
                let unassigned = ingredients.filter { $0.preferredStore == nil }
                activeSheet = .storeChange(unassigned)
            }
            .font(ForagerTheme.footnoteFont.bold())
            .foregroundStyle(ForagerTheme.accentPrimary)
            Button {
                storeAssignmentBannerDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.xs)
    }

    // MARK: - M15: Duplicate Banner

    private var duplicateBanner: some View {
        HStack {
            Image(systemName: "doc.on.doc.fill")
                .foregroundStyle(ForagerTheme.statusWarningFG)
            Text("\(duplicateGroupCount) duplicate\(duplicateGroupCount == 1 ? "" : "s") found")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textPrimary)
            Spacer()
            Button("Review Now") {
                activeSheet = .duplicateReview
            }
            .font(ForagerTheme.footnoteFont.bold())
            .foregroundStyle(ForagerTheme.accentPrimary)
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfaceWarning)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(duplicateGroupCount) duplicate ingredients found")
        .accessibilityHint("Double tap Review Now to merge duplicates")
    }

    // MARK: - M15.5: Staples Summary Header

    private var staplesSummaryHeader: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(ForagerTheme.accentSecondary)
            Text("\(stapleCount) staple\(stapleCount == 1 ? "" : "s")")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textPrimary)
            Spacer()
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.xs)
    }

    private var stapleCount: Int {
        ingredients.filter { $0.isStaple }.count
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
                                activeSheet = .categoryChange([ingredient])
                            },
                            onStoreAssign: {
                                activeSheet = .storeChange([ingredient])
                            },
                            onError: { message in
                                errorMessage = message
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
        ContentUnavailableView {
            Label("No Ingredients", systemImage: "leaf")
        } description: {
            Text("Ingredients appear here as you add recipes and grocery items")
        }
    }
    
    // MARK: - Computed Properties

    // M8.3.1: Count of templates needing review (for badge on filter pill)
    private var needsReviewCount: Int {
        ingredients.filter { $0.needsReview }.count
    }

    // M18.1.5: Ingredients without a preferred store
    private var needsStoreCount: Int {
        ingredients.filter { $0.preferredStore == nil }.count
    }

    private var hasStoresInHousehold: Bool {
        let key = householdService.currentHouseholdKey
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        if let key {
            request.predicate = NSPredicate(format: "householdKey == %@", key)
        } else {
            request.predicate = NSPredicate(format: "householdKey == nil")
        }
        return (try? viewContext.count(for: request)) ?? 0 > 0
    }

    // M15: Duplicate detection — group by canonical name, find collisions
    private var duplicateGroups: [(name: String, templates: [IngredientTemplate])] {
        let grouped = Dictionary(grouping: ingredients) {
            ($0.canonicalName ?? $0.name?.lowercased() ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return grouped
            .filter { $0.value.count > 1 }
            .map { (name: $0.key, templates: $0.value) }
            .sorted { $0.name < $1.name }
    }

    private var duplicateGroupCount: Int {
        duplicateGroups.count
    }

    private var duplicateTemplateIDs: Set<NSManagedObjectID> {
        Set(duplicateGroups.flatMap { $0.templates.map { $0.objectID } })
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
                (ingredient.categoryEntity?.name ?? "Uncategorized") == category
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

        // M15: Apply duplicates filter
        if showDuplicatesOnly {
            let dupeIDs = duplicateTemplateIDs
            filtered = filtered.filter { dupeIDs.contains($0.objectID) }
        }

        // Apply sorting
        return applySorting(to: filtered)
    }
    
    private var groupedIngredients: [String: [IngredientTemplate]] {
        Dictionary(grouping: filteredIngredients) { ingredient in
            ingredient.categoryEntity?.name ?? "Uncategorized"
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
        ingredientTemplateService.updateStaple(ingredient, isStaple: !ingredient.isStaple)
        if let error = ingredientTemplateService.errorMessage {
            errorMessage = error
        }
    }

    private func markSelectedAsStaples(_ isStaple: Bool) {
        for ingredient in selectedIngredients {
            ingredient.isStaple = isStaple
        }
        ingredientTemplateService.saveContext()
        if let error = ingredientTemplateService.errorMessage {
            for ingredient in selectedIngredients {
                ingredient.isStaple = !isStaple
            }
            errorMessage = error
        } else {
            selectedIngredients.removeAll()
            isEditMode = false
        }
    }

    private func bulkDeleteSelected() {
        for ingredient in selectedIngredients {
            ingredientTemplateService.deleteTemplate(ingredient)
        }
        if let error = ingredientTemplateService.errorMessage {
            errorMessage = error
        } else {
            selectedIngredients.removeAll()
            isEditMode = false
        }
    }

    private func deleteIngredients(from items: [IngredientTemplate], at indexSet: IndexSet) {
        for index in indexSet {
            ingredientTemplateService.deleteTemplate(items[index])
        }
        if let error = ingredientTemplateService.errorMessage {
            errorMessage = error
        }
    }

    // MARK: - M10.6.7: LLM Re-Parse for Needs Review Templates

    /// Re-parse needsReview templates via LLM to extract clean ingredient names.
    /// Updates template names in place, preserving categories and staple status.
    private func batchLLMReparseTemplates() async {
        let reviewTemplates = ingredients.filter { $0.needsReview }
        guard !reviewTemplates.isEmpty else { return }

        isLLMBatchParsing = true

        let texts = reviewTemplates.map { $0.name ?? "" }
        if let results = await parsingService.parseBatchWithLLM(texts: texts, source: .recipeIngredient) {
            for (index, (parsed, _, _)) in results.enumerated() {
                guard index < reviewTemplates.count else { break }
                let template = reviewTemplates[index]
                let cleanName = parsed.displayName

                // Only update if the parsed name is different and non-empty
                if !cleanName.isEmpty && cleanName != template.name {
                    ingredientTemplateService.updateTemplate(
                        template, name: cleanName,
                        category: template.categoryEntity, isStaple: template.isStaple
                    )
                }
            }
            llmToastMessage = "AI cleaned \(results.count) ingredient names"
        } else {
            llmToastMessage = parsingService.lastLLMError ?? "AI parsing failed"
        }

        isLLMBatchParsing = false
    }
    
    private func applySorting(to ingredients: [IngredientTemplate]) -> [IngredientTemplate] {
        switch sortOption {
        case .alphabetical:
            return ingredients.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .category:
            return ingredients.sorted {
                let cat1 = $0.categoryEntity?.name ?? "Uncategorized"
                let cat2 = $1.categoryEntity?.name ?? "Uncategorized"
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
    let onStoreAssign: () -> Void
    var onError: ((String) -> Void)?

    @Environment(\.managedObjectContext) private var viewContext
    // M7.3.4: Household service for filtering duplicate checks by householdKey
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // 4px category color strip
            Rectangle()
                .fill(ForagerTheme.categoryColor(for: ingredient.categoryEntity?.name ?? "Uncategorized"))
                .frame(width: 4)

            if isEditMode {
                // reskin-provisions-press: square print check (see GroceryListItemRow)
                Button(action: { onSelectionChanged(!isSelected) }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                            .strokeBorder(isSelected ? Color.clear : ForagerTheme.textPrimary, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                    .fill(isSelected ? ForagerTheme.accentPrimary : Color.clear)
                            )
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ForagerTheme.buttonPrimaryText)
                        }
                    }
                    .frame(width: 20, height: 20)
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
                    // Matches IngredientText's name treatment: lowercase
                    // display, medium ink, one line
                    Text((ingredient.name ?? "Unknown ingredient").lowercased())
                        .font(ForagerTheme.bodyFont)
                        .fontWeight(.medium)
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

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
                    .foregroundColor(ForagerTheme.accentPrimary)
                    .buttonStyle(.borderless)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Button(action: onCategoryAssign) {
                        Image(systemName: "folder")
                            .font(.body)
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // M18.1.5: Store assignment
                    Button(action: onStoreAssign) {
                        HStack(spacing: 4) {
                            if let store = ingredient.preferredStore {
                                StoreColorDot(hex: store.color, size: 8)
                            }
                            Image(systemName: ingredient.preferredStore != nil ? "storefront.fill" : "storefront")
                                .font(.body)
                                .foregroundStyle(ingredient.preferredStore != nil
                                    ? ForagerTheme.storeColor(hex: ingredient.preferredStore?.color)
                                    : ForagerTheme.textTertiary)
                        }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ingredient.name ?? "Unknown"), \(ingredient.categoryEntity?.name ?? "Uncategorized")\(ingredient.isStaple ? ", staple" : "")")
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

                // M8.4 Phase 7: Log correction before merge (original = old template, corrected = merge target)
                let originalName = ingredient.name ?? ""
                let correctedName = existingTemplate.name ?? trimmedName
                if originalName.lowercased() != correctedName.lowercased() {
                    ParsingTelemetryService.shared.logCorrection(
                        originalName: originalName,
                        originalQuantity: nil,
                        originalUnit: nil,
                        originalConfidence: 0,
                        correctedName: correctedName,
                        correctedQuantity: nil,
                        correctedUnit: nil,
                        source: .templateRename
                    )
                }

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
                ingredientTemplateService.deleteTemplate(ingredient)

                #if DEBUG
                print("✅ M8.3.1: Merge complete — deleted old template")
                #endif

                if let error = ingredientTemplateService.errorMessage {
                    reportError(error)
                } else {
                    isEditingName = false
                }
            } else {
                // M8.4 Phase 7: Log correction if name actually changed (case-insensitive)
                let originalName = ingredient.name ?? ""
                if originalName.lowercased() != trimmedName.lowercased() {
                    ParsingTelemetryService.shared.logCorrection(
                        originalName: originalName,
                        originalQuantity: nil,
                        originalUnit: nil,
                        originalConfidence: 0,
                        correctedName: trimmedName,
                        correctedQuantity: nil,
                        correctedUnit: nil,
                        source: .templateRename
                    )
                }

                // No duplicate — just rename
                ingredientTemplateService.updateTemplate(ingredient, name: trimmedName,
                    category: ingredient.categoryEntity, isStaple: ingredient.isStaple)

                #if DEBUG
                print("✅ M8.3.1: Renamed to '\(trimmedName)'")
                #endif

                if let error = ingredientTemplateService.errorMessage {
                    reportError(error)
                } else {
                    isEditingName = false
                }
            }
        } catch {
            #if DEBUG
            print("❌ M8.3.1: Fetch failed — \(error)")
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

// MARK: - M15.5: Ingredient Review Sheet

struct IngredientReviewSheet: View {
    let ingredients: [IngredientTemplate]
    @State private var currentIndex = 0
    @State private var editedName = ""
    @State private var selectedCategory: String = ""
    @State private var isStaple = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default
    ) private var allCategories: FetchedResults<Category>

    var body: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.lg) {
                // Progress bar
                ProgressView(value: Double(currentIndex), total: Double(ingredients.count))
                    .tint(ForagerTheme.accentPrimary)

                // Progress text
                HStack {
                    Spacer()
                    Text("\(currentIndex + 1) of \(ingredients.count)")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }

                // Current ingredient card
                if currentIndex < ingredients.count {
                    ingredientCard(ingredients[currentIndex])
                }

                Spacer()

                // Action buttons
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Button {
                        advance()
                    } label: {
                        Text("Skip")
                            .font(ForagerTheme.bodyFont)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                                    .strokeBorder(ForagerTheme.borderDefault)
                            )
                    }

                    Button {
                        saveAndAdvance()
                    } label: {
                        Text("Save & Next")
                            .font(ForagerTheme.bodyFont.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                            .foregroundStyle(.white)
                            .background(ForagerTheme.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                    }
                }
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("Review Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { loadCurrentIngredient() }
        }
    }

    // MARK: - Ingredient Card

    private func ingredientCard(_ template: IngredientTemplate) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
            // Why it needs review
            reviewReasonBadge(template)

            // Editable name
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                Text("Name")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                TextField("Ingredient name", text: $editedName)
                    .font(ForagerTheme.bodyFont)
                    .textFieldStyle(.roundedBorder)
            }

            // Category picker
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                Text("Category")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)

                Menu {
                    Button("Uncategorized") {
                        selectedCategory = ""
                    }
                    ForEach(allCategories, id: \.objectID) { category in
                        Button(category.displayName) {
                            selectedCategory = category.displayName
                        }
                    }
                } label: {
                    HStack {
                        if selectedCategory.isEmpty {
                            Text("Choose Category")
                                .foregroundStyle(ForagerTheme.textTertiary)
                        } else {
                            HStack(spacing: ForagerTheme.Spacing.sm) {
                                Circle()
                                    .fill(ForagerTheme.categoryColor(for: selectedCategory))
                                    .frame(width: 12, height: 12)
                                Text(selectedCategory)
                                    .foregroundStyle(ForagerTheme.textPrimary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                    .font(ForagerTheme.bodyFont)
                    .padding(ForagerTheme.Spacing.md)
                    .background(ForagerTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                            .strokeBorder(ForagerTheme.borderDefault)
                    )
                }
            }

            // Staple toggle
            Toggle(isOn: $isStaple) {
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(isStaple ? ForagerTheme.accentSecondary : ForagerTheme.textTertiary)
                    Text("Staple ingredient")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                }
            }
            .tint(ForagerTheme.accentSecondary)

            // Usage info
            if template.usageCount > 0 {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    Image(systemName: "chart.bar")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text(template.usageDescription)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
    }

    // MARK: - Review Reason Badge

    private func reviewReasonBadge(_ template: IngredientTemplate) -> some View {
        let reason = reviewReason(for: template)
        return HStack(spacing: ForagerTheme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(ForagerTheme.statusWarningFG)
            Text(reason)
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
        .padding(.horizontal, ForagerTheme.Spacing.sm)
        .padding(.vertical, ForagerTheme.Spacing.xs)
        .background(ForagerTheme.surfaceWarning)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
    }

    private func reviewReason(for template: IngredientTemplate) -> String {
        guard let name = template.name else { return "Missing name" }
        let lower = name.lowercased()

        if name.contains("(") { return "Contains parenthetical text" }

        let fractions = CharacterSet(charactersIn: "½⅓¼⅔¾⅛⅜⅝⅞")
        if name.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) || fractions.contains($0) }) {
            return "Contains numbers or quantities"
        }

        let qualifiers = ["to taste", "to garnish", "as needed", "for serving", "for garnish", "as desired", "to serve", "for topping"]
        for suffix in qualifiers {
            if lower.hasSuffix(suffix) { return "Contains qualifier phrase" }
        }

        let words = lower.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let unitPrefixes: Set<String> = ["loaf", "loaves", "bunch", "bunches", "head", "heads", "sprig", "sprigs", "slice", "slices", "piece", "pieces", "can", "cans", "jar", "jars", "bag", "bags", "package", "packages", "box", "boxes", "bottle", "bottles", "cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp", "pinch", "dash", "handful"]
        if words.count > 1, let first = words.first, unitPrefixes.contains(first) {
            return "Starts with a unit/measure"
        }

        return "Needs review"
    }

    // MARK: - Actions

    private func loadCurrentIngredient() {
        guard currentIndex < ingredients.count else { return }
        let template = ingredients[currentIndex]
        editedName = template.name ?? ""
        selectedCategory = template.categoryEntity?.name ?? ""
        isStaple = template.isStaple
    }

    private func advance() {
        if currentIndex < ingredients.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                currentIndex += 1
            }
            loadCurrentIngredient()
        } else {
            dismiss()
        }
    }

    private func saveAndAdvance() {
        guard currentIndex < ingredients.count else { return }
        let template = ingredients[currentIndex]

        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameToUse = (!trimmedName.isEmpty && trimmedName != template.name) ? trimmedName : (template.name ?? "")
        // M9.12: Look up Category entity from selected name
        let categoryToUse: Category? = selectedCategory.isEmpty ? nil : allCategories.first { $0.displayName == selectedCategory }

        ingredientTemplateService.updateTemplate(template, name: nameToUse,
            category: categoryToUse, isStaple: isStaple)

        advance()
    }
}

// MARK: - M15: Duplicate Review Sheet

struct DuplicateReviewSheet: View {
    let duplicateGroups: [(name: String, templates: [IngredientTemplate])]
    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService

    var body: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.lg) {
                // Progress bar
                ProgressView(value: Double(currentIndex), total: Double(duplicateGroups.count))
                    .tint(ForagerTheme.accentPrimary)

                HStack {
                    Spacer()
                    Text("\(currentIndex + 1) of \(duplicateGroups.count)")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }

                if currentIndex < duplicateGroups.count {
                    duplicateGroupCard(duplicateGroups[currentIndex])
                }

                Spacer()

                // Action buttons
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Button {
                        advance()
                    } label: {
                        Text("Skip")
                            .font(ForagerTheme.bodyFont)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                                    .strokeBorder(ForagerTheme.borderDefault)
                            )
                    }

                    Button {
                        mergeAndAdvance()
                    } label: {
                        Text("Merge")
                            .font(ForagerTheme.bodyFont.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                            .foregroundStyle(.white)
                            .background(ForagerTheme.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                    }
                }
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("Merge Duplicates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Duplicate Group Card

    private func duplicateGroupCard(_ group: (name: String, templates: [IngredientTemplate])) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
            // Header badge
            HStack(spacing: ForagerTheme.Spacing.xs) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.statusWarningFG)
                Text("\(group.templates.count) templates with the same name")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            .padding(.horizontal, ForagerTheme.Spacing.sm)
            .padding(.vertical, ForagerTheme.Spacing.xs)
            .background(ForagerTheme.surfaceWarning)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))

            // Canonical name
            Text("\"\(group.name)\"")
                .font(ForagerTheme.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(ForagerTheme.textPrimary)

            // Each template in the group
            ForEach(group.templates, id: \.objectID) { template in
                templateRow(template, isKeeper: template == bestTemplate(in: group.templates))
            }

            // Merge explanation
            if let keeper = bestTemplate(in: group.templates) {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text("Merge will keep \"\(keeper.name ?? group.name)\" (\(keeper.usageCount)×) and transfer all relationships from the others.")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
    }

    private func templateRow(_ template: IngredientTemplate, isKeeper: Bool) -> some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // Keeper indicator
            Image(systemName: isKeeper ? "checkmark.circle.fill" : "minus.circle")
                .foregroundStyle(isKeeper ? ForagerTheme.statusSuccessFG : ForagerTheme.textTertiary)
                .font(.title3)

            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    Text(template.name ?? "Unknown")
                        .font(ForagerTheme.bodyFont)
                        .fontWeight(isKeeper ? .semibold : .regular)
                        .foregroundStyle(ForagerTheme.textPrimary)

                    if isKeeper {
                        Text("Keep")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(ForagerTheme.statusSuccessFG)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ForagerTheme.statusSuccessFG.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
                    }
                }

                HStack(spacing: ForagerTheme.Spacing.md) {
                    if let category = template.categoryEntity?.name, !category.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ForagerTheme.categoryColor(for: category))
                                .frame(width: 8, height: 8)
                            Text(category)
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textTertiary)
                        }
                    } else {
                        Text("Uncategorized")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }

                    Text("\(template.usageCount)× used")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)

                    if template.isStaple {
                        HStack(spacing: 2) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                            Text("Staple")
                                .font(ForagerTheme.captionFont)
                        }
                        .foregroundStyle(ForagerTheme.accentSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(ForagerTheme.Spacing.sm)
        .background(isKeeper ? ForagerTheme.statusSuccessFG.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
    }

    // MARK: - Helpers

    private func bestTemplate(in templates: [IngredientTemplate]) -> IngredientTemplate? {
        templates.sorted {
            if $0.usageCount != $1.usageCount { return $0.usageCount > $1.usageCount }
            return ($0.dateCreated ?? .distantPast) < ($1.dateCreated ?? .distantPast)
        }.first
    }

    private func advance() {
        if currentIndex < duplicateGroups.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                currentIndex += 1
            }
        } else {
            dismiss()
        }
    }

    private func mergeAndAdvance() {
        guard currentIndex < duplicateGroups.count else { return }
        let group = duplicateGroups[currentIndex]
        guard let keeper = bestTemplate(in: group.templates) else {
            advance()
            return
        }

        let duplicates = group.templates.filter { $0 != keeper }

        for duplicate in duplicates {
            // Transfer ingredient relationships
            if let ingredients = duplicate.ingredients as? Set<Ingredient> {
                for ingredient in ingredients {
                    ingredient.ingredientTemplate = keeper
                }
            }

            // Consolidate usage count
            keeper.usageCount += duplicate.usageCount

            // Preserve category if keeper lacks one
            if keeper.categoryEntity == nil,
               let dupCategoryEntity = duplicate.categoryEntity {
                keeper.categoryEntity = dupCategoryEntity
            }

            // Preserve staple status
            if duplicate.isStaple && !keeper.isStaple {
                keeper.isStaple = true
            }

            keeper.updatedAt = Date()
            ingredientTemplateService.deleteTemplate(duplicate)
        }
        ingredientTemplateService.saveContext()

        #if DEBUG
        print("M15: Merged \(duplicates.count) duplicate(s) for '\(group.name)' into keeper (usage: \(keeper.usageCount))")
        #endif

        advance()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        IngredientsView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
