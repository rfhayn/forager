//
//  WeeklyListsView.swift
//  forager
//
//  PHASE 1 UPDATE: Generate from IngredientTemplate.isStaple instead of GroceryItem.isStaple
//  FIX: Added @FetchRequest to WeeklyListRowView for live progress updates
//

import SwiftUI
import CoreData

struct WeeklyListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyList.dateCreated, ascending: false)],
        animation: .default
    ) private var allWeeklyLists: FetchedResults<WeeklyList>

    // M7.3.2: Filter lists based on current household context
    // M7.2.2 FIX: Use currentHouseholdKey which has fallback for nil household.id
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
    @State private var refreshID = UUID()
    
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
            .onAppear {
                // Refresh context when view appears to pick up any changes
                viewContext.refreshAllObjects()
            }
            .onChange(of: popToRoot) { _, _ in
                if showingError { showingError = false }
            }
    }
    
    private var contentView: some View {
        ZStack {
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
    
    private var emptyStateView: some View {
        StandardEmptyStateView(
            iconName: "list.clipboard",
            title: "No Grocery Lists",
            subtitle: "Generate your first list to get started!",
            buttonIcon: "cart.badge.plus",
            buttonText: "Generate from Staples",
            isButtonDisabled: isGeneratingList,
            buttonAction: generateListFromStaples
        )
    }
    
    private var listsView: some View {
        List {
            Section {
                ForEach(weeklyLists, id: \.self) { list in
                    NavigationLink(destination: GroceryListDetailView(weeklyList: list)) {
                        WeeklyListRowView(weeklyList: list)
                    }
                }
                .onDelete(perform: deleteWeeklyLists)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            viewContext.refreshAllObjects()
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                VStack(spacing: 8) {
                    Text("Generating List...")
                        .font(.headline)
                    Text("Organizing by your custom categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            // M7.4: Standardized to simple "+" icon (iOS convention)
            Button(action: generateListFromStaples) {
                Image(systemName: "plus")
            }
            .disabled(isGeneratingList)
        }
    }
    
    // MARK: - Actions
    
    private func generateListFromStaples() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isGeneratingList = true
        }
        
        PersistenceController.shared.performWrite({ context in
            // 1. Create new WeeklyList
            let newList = WeeklyList(context: context)
            newList.id = UUID()
            newList.name = "Weekly Shopping - \(DateFormatter.shortDate.string(from: Date()))"
            newList.dateCreated = Date()
            newList.isCompleted = false
            newList.notes = "Auto-generated from ingredient staples"
            
            // 2. UPDATED: Fetch staples from IngredientTemplate instead of GroceryItem
            let stapleRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            stapleRequest.predicate = NSPredicate(format: "isStaple == YES")
            
            // Sort by category first, then by name within category
            stapleRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \IngredientTemplate.category, ascending: true),
                NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)
            ]
            
            do {
                let stapleTemplates = try context.fetch(stapleRequest)
                
                #if DEBUG
                print("📋 Generating list from \(stapleTemplates.count) staple templates")
                #endif
                
                // 3. Create GroceryListItems from staple templates
                for (index, template) in stapleTemplates.enumerated() {
                    let listItem = GroceryListItem(context: context)
                    listItem.id = UUID()
                    listItem.name = template.name
                    
                    // Use structured quantity fields with default values
                    listItem.displayText = "1"
                    listItem.numericValue = 1.0
                    listItem.standardUnit = nil
                    listItem.isParseable = true
                    listItem.parseConfidence = 1.0
                    
                    listItem.isCompleted = false
                    listItem.source = "staples"
                    listItem.sortOrder = Int16(index)
                    
                    // UPDATED: Copy category from template
                    if let category = template.category, !category.isEmpty {
                        listItem.categoryName = category
                    } else {
                        listItem.categoryName = "Uncategorized"
                    }
                    
                    // Link to the weekly list
                    newList.addToItems(listItem)
                    
                    #if DEBUG
                    print("  ✓ Added '\(template.name ?? "Unknown")' in category '\(listItem.categoryName ?? "None")'")
                    #endif
                }
                
                #if DEBUG
                print("✅ Generated grocery list with \(stapleTemplates.count) items from ingredient templates")
                #endif
                
            } catch {
                #if DEBUG
                print("❌ Error fetching staple templates: \(error)")
                #endif
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch staples: \(error.localizedDescription)"
                    self.showingError = true
                    self.isGeneratingList = false
                }
                return
            }
            
        }, onError: { error in
            DispatchQueue.main.async {
                errorMessage = "Failed to generate list: \(error.localizedDescription)"
                showingError = true
                isGeneratingList = false
            }
        })
        
        // Hide loading after a brief delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGeneratingList = false
            }
        }
    }
    
    private func deleteWeeklyLists(offsets: IndexSet) {
        let listsToDelete = offsets.map { weeklyLists[$0] }
        
        for list in listsToDelete {
            let listID = list.objectID
            PersistenceController.shared.performWrite({ context in
                let listToDelete = context.object(with: listID)
                context.delete(listToDelete) // Cascade delete will handle items
                #if DEBUG
                print("✅ Deleted weekly list: \(list.name ?? "Unnamed")")
                #endif
            }, onError: { error in
                errorMessage = "Failed to delete list: \(error.localizedDescription)"
                showingError = true
            })
        }
    }
}

// MARK: - Enhanced WeeklyListRowView Component

struct WeeklyListRowView: View {
    @ObservedObject var weeklyList: WeeklyList
    
    // FIX: Use @FetchRequest for live updates
    @FetchRequest private var itemsFetch: FetchedResults<GroceryListItem>
    
    init(weeklyList: WeeklyList) {
        self.weeklyList = weeklyList
        
        // Configure FetchRequest for this specific list's items
        let listID = weeklyList.id ?? UUID()
        _itemsFetch = FetchRequest<GroceryListItem>(
            sortDescriptors: [NSSortDescriptor(keyPath: \GroceryListItem.sortOrder, ascending: true)],
            predicate: NSPredicate(format: "weeklyList.id == %@", listID as CVarArg),
            animation: .default
        )
    }
    
    // Computed properties that depend on itemsFetch
    // The key is accessing properties directly from itemsFetch, not a cached array
    private var completedItemsCount: Int {
        var count = 0
        for item in itemsFetch {
            if item.isCompleted {
                count += 1
            }
        }
        return count
    }
    
    private var totalItemsCount: Int {
        itemsFetch.count
    }
    
    private var completionPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }
    
    private var isListCompleted: Bool {
        return totalItemsCount > 0 && completedItemsCount == totalItemsCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weeklyList.name ?? "Unnamed List")
                        .font(.headline)
                        .foregroundColor(isListCompleted ? .secondary : .primary)
                    
                    if let date = weeklyList.dateCreated {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isListCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            // Progress bar
            if totalItemsCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(completedItemsCount) of \(totalItemsCount) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(completionPercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: completionPercentage)
                        .tint(completionPercentage == 1.0 ? .green : .blue)
                        .animation(.easeInOut(duration: 0.3), value: completionPercentage)
                }
            } else {
                Text("Empty list")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WeeklyListsView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
