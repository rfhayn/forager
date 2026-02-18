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
    @EnvironmentObject private var householdService: HouseholdService

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
        .onAppear {
            autocompleteService.configure(householdKey: householdService.currentHouseholdKey)
            if let firstCategory = categories.first {
                defaultCategory = firstCategory.displayName
            }
        }
        .onChange(of: completedItemsCount) { oldCount, newCount in
            // M15.3: Detect 100% completion
            if newCount == totalItemsCount && totalItemsCount > 0 && oldCount < totalItemsCount {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showCelebration = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation { showCelebration = false }
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
                            .animation(.easeInOut(duration: 0.3), value: completionPercentage)
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
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: ForagerTheme.Spacing.xl) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundStyle(ForagerTheme.accentPrimary)

            VStack(spacing: ForagerTheme.Spacing.md) {
                Text("Empty List")
                    .font(ForagerTheme.cardTitle)
                Text("Add some items to get started shopping!")
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { showingAddItem = true }) {
                Label("Add Item", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ForagerPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            item.isCompleted.toggle()
            item.dateCompleted = item.isCompleted ? Date() : nil

            do {
                try viewContext.save()
            } catch {
                #if DEBUG
                print("Failed to toggle completion: \(error)")
                #endif
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    collapsedCategories.insert(category)
                }
            }
        }
    }

    private func deleteItem(_ item: GroceryListItem) {
        viewContext.delete(item)
        do {
            try viewContext.save()
        } catch {
            #if DEBUG
            print("Failed to delete item: \(error)")
            #endif
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
            #if DEBUG
            print("Failed to mark all complete: \(error)")
            #endif
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

        let parsed = parsingService.parseIngredient(text: trimmedText)
        let structured = parsingService.parseToStructured(text: trimmedText)

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

            if selectedTemplate == nil {
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
        } catch {
            #if DEBUG
            print("Failed to quick add item: \(error)")
            #endif
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
                            Text("\(categoryEmoji(for: category.displayName)) \(category.displayName)")
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

    private func saveToTemplates() {
        let newTemplate = templateService.findOrCreateTemplate(name: newIngredientName, category: newIngredientCategory)
        newTemplate.isStaple = markAsStaple

        do {
            if viewContext.hasChanges { try viewContext.save() }
            showingAddToTemplates = false
        } catch {
            #if DEBUG
            print("Failed to save ingredient: \(error)")
            #endif
            showingAddToTemplates = false
        }
    }
}

// MARK: - List Item Row Component

struct GroceryListItemRow: View {
    @ObservedObject var item: GroceryListItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? ForagerTheme.statusSuccessFG : ForagerTheme.textDisabled)
                    .scaleEffect(item.isCompleted ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: item.isCompleted)
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

                        // Low-confidence indicator
                        if !item.isCompleted && item.parseConfidence < 0.7 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(ForagerTheme.statusWarningFG)
                        }
                    }

                    Spacer()

                    // Quantity — right-aligned, no parentheses
                    if let displayText = item.displayText, !displayText.isEmpty, displayText != "1" {
                        Text(displayText)
                            .font(ForagerTheme.secondaryFont.monospacedDigit())
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .strikethrough(item.isCompleted)
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
        .animation(.easeInOut(duration: 0.3), value: item.isCompleted)
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
