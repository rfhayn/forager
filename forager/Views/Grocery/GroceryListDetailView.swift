//
//  GroceryListDetailView.swift
//  forager
//
//  M15.3: Sticky bottom progress bar, collapsible sections, check-off
//  haptics/animations, and 100% completion celebration.
//  M18.1.4: Store grouping toggle, color dots, "Buy at..." context menu.
//

import SwiftUI
import CoreData

// M18.1.4: Grocery list grouping mode
// GroceryGroupMode removed — now uses showStoreGrouping toggle with category always present

struct GroceryListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var weeklyListService: WeeklyListService
    @EnvironmentObject private var storeService: StoreService

    @ObservedObject var weeklyList: WeeklyList

    // Services
    @StateObject private var templateService: IngredientTemplateService
    @StateObject private var parsingService: IngredientParsingService
    @StateObject private var autocompleteService: IngredientAutocompleteService

    // M9.26: Editable title
    @State private var isEditingTitle = false
    @State private var editedTitle = ""

    // M9.26: Toggle recipe source display
    @ObservedObject private var preferencesService = UserPreferencesService.shared

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
    @State private var collapsedSections: Set<String> = []

    // M15.3: Celebration
    @State private var showCelebration = false

    // M18.1.4: Store grouping + assignment
    @AppStorage("groceryShowStoreGrouping") private var showStoreGrouping = false
    @State private var storeAssignmentItem: GroceryListItem?

    // Track last-added item so saveToTemplates can update its category
    @State private var lastAddedItem: GroceryListItem?

    // M10.6.6: LLM parsing state
    @State private var isLLMQuickAdding = false
    @State private var llmToastMessage: String?

    // Error feedback
    @State private var showingError = false
    @State private var errorMessage = ""

    // Live data
    @FetchRequest private var listItemsFetch: FetchedResults<GroceryListItem>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
    ) private var allCategories: FetchedResults<Category>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Store.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Store.name, ascending: true)
        ]
    ) private var allStores: FetchedResults<Store>

    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }

    private var stores: [Store] {
        let key = householdService.currentHouseholdKey
        return allStores.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }

    private var hasStores: Bool { !stores.isEmpty }

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
        .sheet(item: $storeAssignmentItem) { item in
            StoreAssignmentModal(
                item: item,
                storeService: storeService,
                householdKey: householdService.currentHouseholdKey
            )
            .presentationDetents(ProcessInfo.processInfo.isiOSAppOnMac ? [.large] : [.medium])
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .llmParsingToast(message: $llmToastMessage)
        .onAppear {
            // M9.12: Scope template lookups to household to prevent cross-store failures
            templateService.householdKey = householdService.currentHouseholdKey
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
        let grouped = Dictionary(grouping: listItems) { $0.categoryEntity?.name ?? "Uncategorized" }
        return grouped.sorted { lhs, rhs in
            if let lhsCategory = categories.first(where: { $0.displayName == lhs.key }),
               let rhsCategory = categories.first(where: { $0.displayName == rhs.key }) {
                return lhsCategory.sortOrder < rhsCategory.sortOrder
            }
            return lhs.key < rhs.key
        }
    }

    // M18.1.5: Nested grouping — Store → Category → Items
    private var groupedByStoreThenCategory: [(storeName: String, storeColor: String?, categoryGroups: [(categoryName: String, items: [GroceryListItem])])] {
        let storeGroups = StoreService.groupByStore(items: listItems, stores: stores)
        return storeGroups.map { storeName, storeColor, storeItems in
            let catGrouped = Dictionary(grouping: storeItems) { $0.categoryEntity?.name ?? "Uncategorized" }
            let sorted = catGrouped.sorted { lhs, rhs in
                if let lhsCat = categories.first(where: { $0.displayName == lhs.key }),
                   let rhsCat = categories.first(where: { $0.displayName == rhs.key }) {
                    return lhsCat.sortOrder < rhsCat.sortOrder
                }
                return lhs.key < rhs.key
            }
            return (storeName, storeColor, sorted.map { ($0.key, $0.value) })
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
        .background(ForagerTheme.surfacePrimary)
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
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .font(ForagerTheme.captionFont)

                TextField("Quick add (e.g., \"2 cups flour\")", text: $quickAddText)
                    .textFieldStyle(.plain)
                    .font(ForagerTheme.bodyFont)
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

                // M10.6.6: LLM sparkle button for AI-enhanced quick add
                if parsingService.isLLMAvailable {
                    if isLLMQuickAdding {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            Task { await quickAddItemWithLLM() }
                        } label: {
                            AIParseLabel(text: "AI Add")
                                .font(ForagerTheme.secondaryFont)
                        }
                        .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Button(action: quickAddItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
                .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(ForagerTheme.Spacing.sm)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
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
                            if let category = template.categoryEntity?.name, !category.isEmpty {
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
            // M18.1.5: Nested grouping — optionally by store, always by category
            if hasStores && showStoreGrouping {
                ForEach(groupedByStoreThenCategory, id: \.storeName) { storeName, storeColor, categoryGroups in
                    let storeExpanded = Binding(
                        get: { !collapsedSections.contains(storeName) },
                        set: { if !$0 { collapsedSections.insert(storeName) } else { collapsedSections.remove(storeName) } }
                    )

                    Section {
                        if !collapsedSections.contains(storeName) {
                            ForEach(categoryGroups, id: \.categoryName) { categoryName, items in
                                let catKey = "\(storeName)/\(categoryName)"
                                let catExpanded = Binding(
                                    get: { !collapsedCategories.contains(catKey) },
                                    set: { if !$0 { collapsedCategories.insert(catKey) } else { collapsedCategories.remove(catKey) } }
                                )

                                Section {
                                    if !collapsedCategories.contains(catKey) {
                                        ForEach(items, id: \.self) { item in
                                            itemRow(item)
                                        }
                                    }
                                } header: {
                                    let completedCount = items.filter { $0.isCompleted }.count
                                    ForagerSectionHeader(
                                        title: categoryName,
                                        count: completedCount,
                                        totalCount: items.count,
                                        isExpanded: catExpanded
                                    )
                                }
                            }
                        }
                    } header: {
                        let allItems = categoryGroups.flatMap { $0.items }
                        let completedCount = allItems.filter { $0.isCompleted }.count
                        ForagerSectionHeader(
                            title: storeName,
                            count: completedCount,
                            totalCount: allItems.count,
                            isExpanded: storeExpanded,
                            colorDotHex: storeColor
                        )
                    }
                }
            } else {
                ForEach(groupedItems, id: \.key) { categoryName, items in
                    let isExpanded = Binding(
                        get: { !collapsedCategories.contains(categoryName) },
                        set: { if !$0 { collapsedCategories.insert(categoryName) } else { collapsedCategories.remove(categoryName) } }
                    )

                    Section {
                        if !collapsedCategories.contains(categoryName) {
                            ForEach(items, id: \.self) { item in
                                itemRow(item)
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ForagerTheme.backgroundCanvas)
    }

    // M18.1.4: Extracted item row with swipe actions and context menu
    private func itemRow(_ item: GroceryListItem) -> some View {
        GroceryListItemRow(
            item: item,
            onToggle: { toggleItemCompletion(item) },
            showRecipeSources: preferencesService.showRecipeSources,
            storeColorHex: hasStores ? item.store?.color : nil
        )
        .listRowBackground(Color.clear)
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
        .contextMenu {
            if hasStores {
                Button {
                    storeAssignmentItem = item
                } label: {
                    Label("Buy at...", systemImage: "storefront")
                }
            }
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
        ToolbarItem(placement: .principal) {
            if isEditingTitle {
                TextField("List name", text: $editedTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .onSubmit { saveTitle() }
            } else {
                Text(weeklyList.name ?? "Grocery List")
                    .font(.headline)
                    .onLongPressGesture {
                        editedTitle = weeklyList.name ?? ""
                        isEditingTitle = true
                    }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                // M18.1.5: Store grouping toggle (category always present)
                if hasStores {
                    Button {
                        withAnimation { showStoreGrouping.toggle() }
                    } label: {
                        Image(systemName: showStoreGrouping ? "building.2.fill" : "building.2")
                            .foregroundStyle(showStoreGrouping ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                    }
                }

                Button {
                    withAnimation { preferencesService.showRecipeSources.toggle() }
                } label: {
                    Image(systemName: preferencesService.showRecipeSources ? "book.fill" : "book")
                        .foregroundStyle(preferencesService.showRecipeSources ? ForagerTheme.accentPrimary : ForagerTheme.textTertiary)
                }
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus.square")
                }
            }
        }
    }

    private func saveTitle() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            weeklyList.name = trimmed
            try? viewContext.save()
        }
        isEditingTitle = false
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

        // M15.3: Auto-collapse fully completed sections after 2s
        if hasStores && showStoreGrouping {
            let storeName = item.store?.name ?? "Unassigned"
            checkAutoCollapseStore(section: storeName)
        }
        if let categoryName = item.categoryEntity?.name {
            let catKey = showStoreGrouping ? "\(item.store?.name ?? "Unassigned")/\(categoryName)" : categoryName
            checkAutoCollapseCategory(category: catKey)
        }
    }

    private func checkAutoCollapseCategory(category: String) {
        let categoryItems = listItems.filter { ($0.categoryEntity?.name ?? "Uncategorized") == category }
        let allCompleted = categoryItems.allSatisfy { $0.isCompleted }
        if allCompleted && !categoryItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let stillAllCompleted = listItems
                    .filter { ($0.categoryEntity?.name ?? "Uncategorized") == category }
                    .allSatisfy { $0.isCompleted }
                guard stillAllCompleted else { return }
                _ = withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.8)) {
                    collapsedCategories.insert(category)
                }
            }
        }
    }

    private func checkAutoCollapseStore(section: String) {
        let sectionItems = listItems.filter { ($0.store?.name ?? "Unassigned") == section }
        let allCompleted = sectionItems.allSatisfy { $0.isCompleted }
        if allCompleted && !sectionItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let stillAllCompleted = listItems
                    .filter { ($0.store?.name ?? "Unassigned") == section }
                    .allSatisfy { $0.isCompleted }
                guard stillAllCompleted else { return }
                _ = withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.8)) {
                    collapsedSections.insert(section)
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

        if let category = template.categoryEntity?.name, !category.isEmpty {
            defaultCategory = category
        }
    }

    // MARK: - M10.6.6: LLM-Enhanced Quick Add

    private func quickAddItemWithLLM() async {
        let trimmedText = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        isLLMQuickAdding = true

        if let (parsed, structured, _) = await parsingService.parseSingleWithLLM(text: trimmedText, source: .groceryListItem) {
            let cleanName = parsed.displayName
            let matchedTemplate = selectedTemplate ?? templateService.searchTemplates(query: cleanName, limit: 1)
                .first(where: { $0.name?.lowercased() == cleanName.lowercased() })

            // M9.12: Resolve category entity from template or default
            let categoryEntity: Category?
            if let template = matchedTemplate, let catEntity = template.categoryEntity {
                categoryEntity = catEntity
            } else {
                categoryEntity = categories.first { $0.displayName == defaultCategory }
            }

            let confidence = matchedTemplate != nil
                ? max(structured.parseConfidence, 0.8)
                : structured.parseConfidence

            let listItem = weeklyListService.addItem(
                to: weeklyList, name: trimmedText, category: categoryEntity,
                store: matchedTemplate?.preferredStore,
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
                    newIngredientCategory = categoryEntity?.displayName ?? defaultCategory
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
        } else {
            // LLM failed — fall through to local parse
            isLLMQuickAdding = false
            quickAddItem()
            return
        }

        isLLMQuickAdding = false
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

        // M9.12: Resolve category entity from template or default
        let categoryEntity: Category?
        if let template = selectedTemplate, let catEntity = template.categoryEntity {
            categoryEntity = catEntity
        } else {
            categoryEntity = categories.first { $0.displayName == defaultCategory }
        }

        let confidence = selectedTemplate != nil
            ? max(structured.parseConfidence, 0.8)
            : structured.parseConfidence

        let listItem = weeklyListService.addItem(
            to: weeklyList, name: trimmedText, category: categoryEntity,
            store: selectedTemplate?.preferredStore,
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
                newIngredientCategory = categoryEntity?.displayName ?? defaultCategory
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
        NavigationStack {
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
    var showRecipeSources: Bool = false
    var storeColorHex: String? = nil

    /// Parsed ingredient name for bold highlighting (matches recipe detail pattern)
    private var parsedIngredientName: String? {
        guard let fullText = item.name else { return nil }
        let cleaned = IngredientParsingService.extractCleanIngredientName(from: fullText)
        return cleaned.isEmpty ? nil : cleaned
    }

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? ForagerTheme.statusSuccessFG : ForagerTheme.textDisabled)
                    .font(.system(size: 18))
                    .scaleEffect(reduceMotion ? 1.0 : (item.isCompleted ? 1.1 : 1.0))
                    .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: item.isCompleted)
            }
            .buttonStyle(.borderless)

            // Store color dot
            if let hex = storeColorHex {
                StoreColorDot(hex: hex)
            }

            // Item text
            if item.isCompleted {
                Text(item.name ?? "Unknown Item")
                    .font(ForagerTheme.bodyFont)
                    .strikethrough()
                    .foregroundStyle(ForagerTheme.textDisabled)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    formattedItemText

                    // Recipe sources inline
                    if showRecipeSources && !item.sourceRecipeNames.isEmpty {
                        Text(item.sourceRecipeNames.joined(separator: ", "))
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, ForagerTheme.Spacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .opacity(item.isCompleted ? 0.6 : 1.0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: item.isCompleted)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name ?? "Unknown Item")
        .accessibilityValue(item.isCompleted ? "Checked" : "Unchecked")
        .accessibilityHint("Double tap to \(item.isCompleted ? "uncheck" : "check off") this item")
    }

    /// Formatted text matching recipe detail: quantity in secondary, name in bold green
    @ViewBuilder
    private var formattedItemText: some View {
        let fullText = item.name ?? "Unknown Item"
        if let ingredientName = parsedIngredientName,
           let range = fullText.range(of: ingredientName, options: .caseInsensitive) {
            let prefix = String(fullText[fullText.startIndex..<range.lowerBound])
            let name = String(fullText[range])
            let suffix = String(fullText[range.upperBound...])
            HStack(spacing: 0) {
                Text(prefix)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                Text(name)
                    .font(ForagerTheme.bodyFont)
                    .bold()
                    .foregroundStyle(ForagerTheme.accentPrimary)
                Text(suffix)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
        } else {
            Text(fullText)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textPrimary)
        }
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
