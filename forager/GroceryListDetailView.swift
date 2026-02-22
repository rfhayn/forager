//
//  GroceryListDetailView.swift
//  forager
//
//  M15.3: Sticky bottom progress bar, collapsible sections, check-off
//  haptics/animations, and 100% completion celebration.
//

import SwiftUI
import CoreData

struct GroceryListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var weeklyListService: WeeklyListService

    @ObservedObject var weeklyList: WeeklyList

    // Services
    @StateObject private var templateService: IngredientTemplateService
    @StateObject private var parsingService: IngredientParsingService
    @StateObject private var autocompleteService: IngredientAutocompleteService

    // Quick-add state
    @State private var quickAddText = ""
    @State private var showingAutocomplete = false
    @State private var selectedTemplate: IngredientTemplate? = nil
    @State private var defaultCategory = "Uncategorized"

    // Modal state
    @State private var showingAddItem = false
    @State private var showingAddToTemplates = false
    @State private var newIngredientName = ""
    @State private var newIngredientCategory = ""
    @State private var markAsStaple = false

    // M15.3: Collapsible sections
    @State private var collapsedCategories: Set<String> = []

    // M15.3: Celebration
    @State private var showCelebration = false

    // Track last-added item so saveToTemplates can update its category
    @State private var lastAddedItem: GroceryListItem?

    // Error feedback
    @State private var showingError = false
    @State private var errorMessage = ""

    // Live data
    @FetchRequest private var listItemsFetch: FetchedResults<GroceryListItem>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
    ) private var allCategories: FetchedResults<Category>

    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
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

        let listID = weeklyList.id ?? UUID()
        _listItemsFetch = FetchRequest<GroceryListItem>(
            sortDescriptors: [NSSortDescriptor(keyPath: \GroceryListItem.sortOrder, ascending: true)],
            predicate: NSPredicate(format: "weeklyList.id == %@", listID as CVarArg),
            animation: .default
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ForagerTheme.backgroundCanvas.ignoresSafeArea()

            if listItems.isEmpty {
                emptyStateView
            } else {
                shoppingListView
            }

            // M15.3: Celebration banner
            if showCelebration {
                VStack {
                    celebrationBanner
                        .padding(.top, ForagerTheme.Spacing.sm)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(weeklyList.name ?? "Grocery List")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            stickyBottomBar
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingAddItem) {
            AddListItemView(weeklyList: weeklyList)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingAddToTemplates) {
            addToTemplatesSheet
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            autocompleteService.configure(householdKey: householdService.currentHouseholdKey)
            if let firstCategory = categories.first {
                defaultCategory = firstCategory.displayName
            }
        }
        .onChange(of: completedItemsCount) { oldCount, newCount in
            // M15.3: Detect 100% completion
            if newCount == totalItemsCount && totalItemsCount > 0 && oldCount < totalItemsCount {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.7)) {
                    showCelebration = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(reduceMotion ? nil : .default) { showCelebration = false }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var listItems: [GroceryListItem] {
        Array(listItemsFetch)
    }

    private var groupedItems: [(key: String, value: [GroceryListItem])] {
        let grouped = Dictionary(grouping: listItems) { $0.categoryName ?? "Uncategorized" }
        return grouped.sorted { lhs, rhs in
            if let lhsCategory = categories.first(where: { $0.displayName == lhs.key }),
               let rhsCategory = categories.first(where: { $0.displayName == rhs.key }) {
                return lhsCategory.sortOrder < rhsCategory.sortOrder
            }
            return lhs.key < rhs.key
        }
    }

    private var totalItemsCount: Int { listItems.count }
    private var completedItemsCount: Int { listItems.filter { $0.isCompleted }.count }

    private var completionPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }

    // MARK: - Sticky Bottom Bar (Progress + Quick-Add)

    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            // Thin progress bar (6pt)
            if totalItemsCount > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ForagerTheme.backgroundTertiary)
                        Capsule()
                            .fill(progressBarColor)
                            .frame(width: geo.size.width * completionPercentage)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: completionPercentage)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, ForagerTheme.Spacing.lg)
                .padding(.top, ForagerTheme.Spacing.sm)
            }

            // Quick-add bar
            quickAddBar
        }
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shopping progress and quick add")
    }

    private var progressBarColor: Color {
        if completionPercentage >= 1.0 { return ForagerTheme.statusSuccessFG }
        if completionPercentage >= 0.5 { return ForagerTheme.accentSecondary }
        return ForagerTheme.accentPrimary
    }

    // MARK: - Quick Add Bar

    private var quickAddBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Autocomplete (above the text field)
            if showingAutocomplete && !autocompleteService.suggestions.isEmpty {
                autocompleteDropdown
            }

            HStack(spacing: ForagerTheme.Spacing.sm) {
                TextField("Quick add (e.g., \"2 cups flour\")", text: $quickAddText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Quick add item")
                    .accessibilityHint("Type an ingredient to add to the list")
                    .onChange(of: quickAddText) { _, newValue in
                        if newValue.count >= 2 {
                            autocompleteService.debouncedSearch(fullText: newValue)
                            showingAutocomplete = true
                        } else {
                            showingAutocomplete = false
                            selectedTemplate = nil
                        }
                    }
                    .onSubmit { quickAddItem() }

                Button(action: quickAddItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
                .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)
            .padding(.vertical, ForagerTheme.Spacing.md)
        }
    }

    private var autocompleteDropdown: some View {
        VStack(spacing: 0) {
            ForEach(autocompleteService.suggestions.prefix(5), id: \.objectID) { template in
                Button {
                    selectAutocompleteTemplate(template)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name ?? "")
                                .font(ForagerTheme.bodyFont)
                                .foregroundStyle(ForagerTheme.textPrimary)
                            if let category = template.category, !category.isEmpty {
                                Text(category)
                                    .font(ForagerTheme.captionFont)
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
                    .padding(.vertical, ForagerTheme.Spacing.sm)
                    .padding(.horizontal, ForagerTheme.Spacing.lg)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if template != autocompleteService.suggestions.prefix(5).last {
                    Divider().padding(.leading, ForagerTheme.Spacing.lg)
                }
            }
        }
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
        .padding(.horizontal, ForagerTheme.Spacing.lg)
    }

    // MARK: - Shopping List with Collapsible Sections

    private var shoppingListView: some View {
        List {
            ForEach(groupedItems, id: \.key) { categoryName, items in
                let isExpanded = Binding(
                    get: { !collapsedCategories.contains(categoryName) },
                    set: { if !$0 { collapsedCategories.insert(categoryName) } else { collapsedCategories.remove(categoryName) } }
                )

                Section {
                    if !collapsedCategories.contains(categoryName) {
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
                } header: {
                    let completedCount = items.filter { $0.isCompleted }.count
                    ForagerSectionHeader(
                        title: categoryName,
                        count: completedCount,
                        totalCount: items.count,
                        isExpanded: isExpanded
                    )
                }
            }
        }
        .listStyle(.plain)
        .background(ForagerTheme.backgroundCanvas)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Empty List", systemImage: "cart")
        } description: {
            Text("Add some items to get started shopping!")
        } actions: {
            Button(action: { showingAddItem = true }) {
                Text("Add Item")
            }
        }
    }

    // MARK: - Celebration Banner

    private var celebrationBanner: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(ForagerTheme.statusSuccessFG)
            Text("All done!")
                .font(ForagerTheme.bodyFont.bold())
                .foregroundStyle(ForagerTheme.accentPrimary)
        }
        .padding(ForagerTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(ForagerTheme.surfaceSuccess)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .accessibilityLabel("All done! Shopping list complete")
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

    // MARK: - Actions

    private func toggleItemCompletion(_ item: GroceryListItem) {
        let wasCompleted = item.isCompleted

        // M15.3: Haptic feedback
        if wasCompleted {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.7)) {
            weeklyListService.toggleItemChecked(item)
            if let error = weeklyListService.errorMessage {
                errorMessage = error
                showingError = true
            }
        }

        // M15.3: Auto-collapse fully completed categories after 2s
        if let categoryName = item.categoryName {
            checkAutoCollapse(category: categoryName)
        }
    }

    private func checkAutoCollapse(category: String) {
        let categoryItems = listItems.filter { $0.categoryName == category }
        let allCompleted = categoryItems.allSatisfy { $0.isCompleted }
        if allCompleted && !categoryItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Re-check: user may have unchecked during delay
                let stillAllCompleted = listItems
                    .filter { $0.categoryName == category }
                    .allSatisfy { $0.isCompleted }
                guard stillAllCompleted else { return }
                _ = withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.8)) {
                    collapsedCategories.insert(category)
                }
            }
        }
    }

    private func deleteItem(_ item: GroceryListItem) {
        weeklyListService.removeItem(item)
        if let error = weeklyListService.errorMessage {
            errorMessage = error
            showingError = true
        }
    }

    private func markAllItemsComplete() {
        weeklyListService.markAllItemsComplete(in: weeklyList)
        if let error = weeklyListService.errorMessage {
            errorMessage = error
            showingError = true
        }
    }

    // MARK: - Quick Add Logic

    private func selectAutocompleteTemplate(_ template: IngredientTemplate) {
        selectedTemplate = template
        let parsed = parsingService.parseIngredient(text: quickAddText)
        let quantityPart = parsed.quantity ?? ""
        let unitPart = parsed.unit ?? ""

        var rebuiltText = ""
        if !quantityPart.isEmpty { rebuiltText += quantityPart + " " }
        if !unitPart.isEmpty { rebuiltText += unitPart + " " }
        rebuiltText += template.name ?? ""

        quickAddText = rebuiltText
        showingAutocomplete = false

        if let category = template.category, !category.isEmpty {
            defaultCategory = category
        }
    }

    private func quickAddItem() {
        let trimmedText = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // M8.4: Single parse via parseUnified (was double-parse)
        let (parsed, structured) = parsingService.parseUnified(text: trimmedText, source: .groceryListItem)

        if selectedTemplate == nil {
            selectedTemplate = templateService.searchTemplates(query: parsed.name, limit: 1)
                .first(where: { $0.name?.lowercased() == parsed.name.lowercased() })
        }

        let categoryToUse: String
        if let template = selectedTemplate, let category = template.category, !category.isEmpty {
            categoryToUse = category
        } else {
            categoryToUse = defaultCategory
        }

        let confidence = selectedTemplate != nil
            ? max(structured.parseConfidence, 0.8)
            : structured.parseConfidence

        let listItem = weeklyListService.addItem(
            to: weeklyList, name: trimmedText, categoryName: categoryToUse,
            numericValue: structured.numericValue ?? 0.0,
            standardUnit: structured.standardUnit,
            displayText: structured.displayText,
            isParseable: structured.isParseable,
            parseConfidence: confidence, source: "manual"
        )

        if let listItem = listItem {
            if selectedTemplate == nil {
                lastAddedItem = listItem
                newIngredientName = parsed.name
                newIngredientCategory = categoryToUse
                markAsStaple = false
                DispatchQueue.main.async {
                    self.showingAddToTemplates = true
                }
            }
            quickAddText = ""
            selectedTemplate = nil
            showingAutocomplete = false
        } else {
            errorMessage = weeklyListService.errorMessage ?? "Failed to add item"
            showingError = true
        }
    }

    // MARK: - Add to Templates Sheet

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
                        .font(ForagerTheme.captionFont)
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
                    Button("Skip") { showingAddToTemplates = false }
                }
            }
        }
    }


    private func saveToTemplates() {
        let newTemplate = templateService.findOrCreateTemplate(name: newIngredientName, category: newIngredientCategory)
        newTemplate.isStaple = markAsStaple

        // Propagate the user's category choice to the grocery list item
        if let item = lastAddedItem {
            item.categoryName = newIngredientCategory
            lastAddedItem = nil
        }

        weeklyListService.saveContext()
        if let error = weeklyListService.errorMessage {
            errorMessage = error
            showingError = true
        }
        showingAddToTemplates = false
    }
}

// MARK: - List Item Row Component

struct GroceryListItemRow: View {
    @ObservedObject var item: GroceryListItem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? ForagerTheme.statusSuccessFG : ForagerTheme.textDisabled)
                    .scaleEffect(reduceMotion ? 1.0 : (item.isCompleted ? 1.1 : 1.0))
                    .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: item.isCompleted)
            }
            .buttonStyle(.borderless)

            // Item content
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: ForagerTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Text(item.name ?? "Unknown Item")
                            .font(ForagerTheme.bodyFont)
                            .fontWeight(.medium)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? ForagerTheme.textDisabled : ForagerTheme.textPrimary)
                            .lineLimit(2)

                        // Low-confidence indicator — only when parser attempted
                        // a quantity parse but wasn't confident (not for name-only items)
                        if !item.isCompleted && item.parseConfidence > 0 && item.parseConfidence < 0.7 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(ForagerTheme.statusWarningFG)
                        }
                    }

                }

                // Recipe source badges
                if !item.sourceRecipeNames.isEmpty {
                    HStack(spacing: ForagerTheme.Spacing.xs) {
                        ForEach(item.sourceRecipeNames, id: \.self) { recipeName in
                            Text(recipeName)
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.accentPrimary)
                                .padding(.horizontal, ForagerTheme.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(ForagerTheme.accentTint)
                                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs))
                        }
                    }
                }

                // Merged source display
                if let source = item.source, source.hasPrefix("merged") {
                    Text(sourceDisplayText(source))
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }
        }
        .padding(.vertical, ForagerTheme.Spacing.xs)
        .background(item.isCompleted ? ForagerTheme.accentTint.opacity(0.3) : .clear)
        .contentShape(Rectangle())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: item.isCompleted)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name ?? "Unknown Item")
        .accessibilityValue(item.isCompleted ? "Checked" : "Unchecked")
        .accessibilityHint("Double tap to \(item.isCompleted ? "uncheck" : "check off") this item")
    }

    private func sourceDisplayText(_ source: String) -> String {
        if source.hasPrefix("merged") {
            if source.contains("converted") {
                if let count = extractCount(from: source) { return "Merged from \(count) items (converted)" }
                return "Merged (converted)"
            } else {
                if let count = extractCount(from: source) { return "Merged from \(count) items" }
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
        guard let start = source.firstIndex(of: "("),
              let end = source.firstIndex(of: ")") else { return nil }
        return String(source[source.index(after: start)..<end])
    }
}
