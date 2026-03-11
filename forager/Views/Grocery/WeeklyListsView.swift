//
//  WeeklyListsView.swift
//  forager
//
//  M15.3: Card-based grocery list overview with progress rings,
//  category chip pills, and 3-option creation dialog.
//

import SwiftUI
import CoreData

struct WeeklyListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyList.dateCreated, ascending: false)],
        animation: .default
    ) private var allWeeklyLists: FetchedResults<WeeklyList>

    // M7.3.2: Filter lists based on current household context
    private var weeklyLists: [WeeklyList] {
        let currentHouseholdKey = householdService.currentHouseholdKey
        return allWeeklyLists.filter { list in
            if let householdKey = currentHouseholdKey {
                return list.householdKey == householdKey
            } else {
                return list.householdKey == nil
            }
        }
    }

    // State management
    @State private var isGeneratingList = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingCreateOptions = false
    @State private var showingMealPlanPicker = false

    var body: some View {
        contentView
            .navigationTitle("Grocery Lists")
            .toolbar {
                toolbarContent
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("New Grocery List", isPresented: $showingCreateOptions) {
                Button("From Staples") { generateListFromStaples() }
                Button("From Meal Plan") { showingMealPlanPicker = true }
                Button("Empty List") { createEmptyList() }
            }
            .sheet(isPresented: $showingMealPlanPicker) {
                MealPlanGrocerySheet { plan in
                    generateListFromMealPlan(plan)
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                viewContext.refreshAllObjects()
            }
            .onChange(of: popToRoot) { _, _ in
                if showingError { showingError = false }
            }
    }

    private var contentView: some View {
        ZStack {
            ForagerTheme.backgroundCanvas
                .ignoresSafeArea()

            if weeklyLists.isEmpty && !isGeneratingList {
                emptyStateView
            } else {
                listsView
            }

            if isGeneratingList {
                loadingOverlay
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Grocery Lists", systemImage: "cart")
        } description: {
            Text("Create your first list to start shopping")
        } actions: {
            Button("New List", systemImage: "plus.circle.fill") {
                showingCreateOptions = true
            }
            .buttonStyle(.borderedProminent)
            .tint(ForagerTheme.accentPrimary)
            .disabled(isGeneratingList)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - List View

    private var listsView: some View {
        List {
            ForEach(weeklyLists, id: \.self) { list in
                NavigationLink(destination: GroceryListDetailView(weeklyList: list)) {
                    WeeklyListRowView(weeklyList: list)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: ForagerTheme.Spacing.xs,
                    leading: ForagerTheme.Spacing.lg,
                    bottom: ForagerTheme.Spacing.xs,
                    trailing: ForagerTheme.Spacing.lg
                ))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteList(list)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(ForagerTheme.backgroundCanvas)
        .scrollContentBackground(.hidden)
        .refreshable {
            viewContext.refreshAllObjects()
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: ForagerTheme.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)

                VStack(spacing: ForagerTheme.Spacing.sm) {
                    Text("Generating List...")
                        .font(ForagerTheme.cardTitle)
                    Text("Organizing by your custom categories")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
            .padding(ForagerTheme.Spacing.xl)
            .background(ForagerTheme.surfacePrimary)
            .cornerRadius(ForagerTheme.Radius.lg)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg, style: .continuous))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingCreateOptions = true }) {
                Image(systemName: "plus")
            }
            .disabled(isGeneratingList)
        }
    }

    // MARK: - Actions

    private func generateListFromStaples() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            isGeneratingList = true
        }

        // M9.13: Capture scope for background factory (ADR 014)
        let currentKey = householdService.currentHouseholdKey
        PersistenceController.shared.performWrite({ context in
            // M9.13: Background context — householdKey set manually, store assignment
            // handled by performWrite's merge policy. Factory not available in bg context.
            let newList = WeeklyList(context: context)
            newList.id = UUID()
            newList.name = "Weekly Shopping - \(DateFormatter.shortDate.string(from: Date()))"
            newList.dateCreated = Date()
            newList.isCompleted = false
            newList.notes = "Auto-generated from ingredient staples"
            newList.householdKey = currentKey

            // M10.6.18: Scope staple fetch to household (ADR 013)
            let stapleRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            if let key = currentKey {
                stapleRequest.predicate = NSPredicate(format: "isStaple == YES AND householdKey == %@", key)
            } else {
                stapleRequest.predicate = NSPredicate(format: "isStaple == YES AND householdKey == nil")
            }
            stapleRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)
            ]

            do {
                let stapleTemplates = try context.fetch(stapleRequest)

                for (index, template) in stapleTemplates.enumerated() {
                    let listItem = GroceryListItem(context: context)
                    listItem.id = UUID()
                    listItem.name = template.name
                    listItem.displayText = "1"
                    listItem.numericValue = 1.0
                    listItem.standardUnit = nil
                    listItem.isParseable = true
                    listItem.parseConfidence = 1.0
                    listItem.isCompleted = false
                    listItem.source = "staples"
                    listItem.sortOrder = Int16(index)
                    // M9.12: Set categoryEntity directly from template
                    listItem.categoryEntity = template.categoryEntity
                    newList.addToItems(listItem)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch staples: \(error.localizedDescription)"
                    self.showingError = true
                    self.isGeneratingList = false
                }
                return
            }
        }, onSuccess: {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                isGeneratingList = false
            }
        }, onError: { error in
            errorMessage = "Failed to generate list: \(error.localizedDescription)"
            showingError = true
            isGeneratingList = false
        })
    }

    private func generateListFromMealPlan(_ plan: MealPlan) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            isGeneratingList = true
        }

        MealPlanService.shared.generateGroceryList(from: plan)

        // MealPlanService.generateGroceryList uses viewContext (synchronous)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            isGeneratingList = false
        }
    }

    private func createEmptyList() {
        let currentKey = householdService.currentHouseholdKey
        PersistenceController.shared.performWrite({ context in
            // M9.13: Background context — householdKey set manually (ADR 014)
            let newList = WeeklyList(context: context)
            newList.id = UUID()
            newList.name = "Shopping - \(DateFormatter.shortDate.string(from: Date()))"
            newList.dateCreated = Date()
            newList.isCompleted = false
            newList.householdKey = currentKey
        }, onError: { error in
            errorMessage = "Failed to create list: \(error.localizedDescription)"
            showingError = true
        })
    }

    private func deleteList(_ list: WeeklyList) {
        let listID = list.objectID
        PersistenceController.shared.performWrite({ context in
            let listToDelete = context.object(with: listID)
            context.delete(listToDelete)
        }, onError: { error in
            errorMessage = "Failed to delete list: \(error.localizedDescription)"
            showingError = true
        })
    }
}

// MARK: - Card-Based Row Component

struct WeeklyListRowView: View {
    @ObservedObject var weeklyList: WeeklyList
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var itemsFetch: FetchedResults<GroceryListItem>

    init(weeklyList: WeeklyList) {
        self.weeklyList = weeklyList
        let listID = weeklyList.id ?? UUID()
        _itemsFetch = FetchRequest<GroceryListItem>(
            sortDescriptors: [NSSortDescriptor(keyPath: \GroceryListItem.sortOrder, ascending: true)],
            predicate: NSPredicate(format: "weeklyList.id == %@", listID as CVarArg),
            animation: .default
        )
    }

    private var completedItemsCount: Int {
        itemsFetch.filter { $0.isCompleted }.count
    }

    private var totalItemsCount: Int {
        itemsFetch.count
    }

    private var completionPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }

    private var isListCompleted: Bool {
        totalItemsCount > 0 && completedItemsCount == totalItemsCount
    }

    private var categoryComposition: [(name: String, count: Int)] {
        Dictionary(grouping: Array(itemsFetch)) { $0.categoryEntity?.name ?? "Uncategorized" }
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card body: text info + progress ring
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                    Text(weeklyList.name ?? "Unnamed List")
                        .font(ForagerTheme.cardTitle)
                        .foregroundStyle(isListCompleted ? ForagerTheme.textTertiary : ForagerTheme.textPrimary)

                    if let date = weeklyList.dateCreated {
                        Text(date, style: .date)
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }

                    Text("\(completedItemsCount) of \(totalItemsCount) items")
                        .font(ForagerTheme.secondaryFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }

                Spacer()

                if totalItemsCount > 0 {
                    ForagerProgressRing(progress: completionPercentage)
                }
            }

            // Category chip pills
            if !categoryComposition.isEmpty {
                Divider()
                    .padding(.vertical, ForagerTheme.Spacing.sm)

                CategoryChipPills(categories: categoryComposition)
            }
        }
        .foragerGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weeklyList.name ?? "Unnamed List"), \(completedItemsCount) of \(totalItemsCount) items checked")
        .onAppear {
            // Force Core Data to re-fault objects so relationship-derived
            // properties (like categoryName via ingredientTemplate) refresh
            viewContext.refreshAllObjects()
        }
    }
}

// MARK: - Meal Plan Picker for Grocery Generation

private struct MealPlanGrocerySheet: View {
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MealPlan.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default
    ) private var availablePlans: FetchedResults<MealPlan>

    let onSelect: (MealPlan) -> Void

    var body: some View {
        NavigationView {
            Group {
                if availablePlans.isEmpty {
                    VStack(spacing: ForagerTheme.Spacing.lg) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(ForagerTheme.textTertiary)
                        Text("No Meal Plans")
                            .font(ForagerTheme.cardTitle)
                        Text("Create a meal plan first, then generate a grocery list from it.")
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ForagerTheme.Spacing.xl)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(availablePlans, id: \.id) { plan in
                        Button {
                            onSelect(plan)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                                    Text(plan.name ?? "Unnamed Plan")
                                        .font(ForagerTheme.bodyFont)
                                        .foregroundStyle(ForagerTheme.textPrimary)
                                    if let start = plan.startDate {
                                        Text(start, style: .date)
                                            .font(ForagerTheme.captionFont)
                                            .foregroundStyle(ForagerTheme.textTertiary)
                                    }
                                }
                                Spacer()
                                if plan.isActive {
                                    Text("Active")
                                        .font(ForagerTheme.captionFont)
                                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WeeklyListsView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
