import Foundation
import CoreData

/// M7.5: Aggregate service for WeeklyList and GroceryListItem CRUD operations
/// Parent-child lifecycle: GroceryListItems are tightly coupled to their WeeklyList.
/// All grocery list writes go through this service — views never call context.save() directly.
/// Accepts IngredientParsingService via init for M8.4 forward-compatibility.
@MainActor
class WeeklyListService: ObservableObject {

    // MARK: - Properties

    private let viewContext: NSManagedObjectContext
    private let parsingService: IngredientParsingService

    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Initialization

    init(context: NSManagedObjectContext, parsingService: IngredientParsingService) {
        self.viewContext = context
        self.parsingService = parsingService
    }

    // MARK: - WeeklyList Operations

    /// Creates a new grocery list
    func createList(name: String, startDate: Date = Date()) -> WeeklyList? {
        clearError()

        let list = WeeklyList(context: viewContext)
        list.id = UUID()
        list.name = name
        list.dateCreated = startDate
        list.isCompleted = false

        return save("create list") ? list : nil
    }

    /// Deletes a grocery list (cascade deletes its items per Core Data rules)
    func deleteList(_ list: WeeklyList) {
        clearError()
        viewContext.delete(list)
        save("delete list")
    }

    /// Marks a list as completed
    func completeList(_ list: WeeklyList) {
        clearError()
        list.isCompleted = true
        save("complete list")
    }

    /// Updates list name
    func renameList(_ list: WeeklyList, name: String) {
        clearError()
        list.name = name
        save("rename list")
    }

    // MARK: - GroceryListItem Operations

    /// Adds a grocery item using pre-parsed structured data (ADR 012: flat string snapshots)
    func addItem(to list: WeeklyList, name: String, categoryName: String? = nil,
                 numericValue: Double = 0, standardUnit: String? = nil,
                 displayText: String? = nil, isParseable: Bool = false,
                 parseConfidence: Float = 0, source: String? = nil) -> GroceryListItem? {
        clearError()

        let item = GroceryListItem(context: viewContext)
        item.id = UUID()
        item.name = name
        item.categoryName = categoryName
        item.numericValue = numericValue
        item.standardUnit = standardUnit
        item.displayText = displayText
        item.isParseable = isParseable
        item.parseConfidence = parseConfidence
        item.source = source
        item.isCompleted = false
        item.weeklyList = list

        // Set sort order to end of list
        let existingCount = (list.items as? Set<GroceryListItem>)?.count ?? 0
        item.sortOrder = Int16(existingCount)

        return save("add grocery item") ? item : nil
    }

    /// Removes a grocery item from its list
    func removeItem(_ item: GroceryListItem) {
        clearError()
        viewContext.delete(item)
        save("remove grocery item")
    }

    /// Toggles checked state on a grocery item
    func toggleItemChecked(_ item: GroceryListItem) {
        clearError()
        item.isCompleted.toggle()
        item.dateCompleted = item.isCompleted ? Date() : nil
        save("toggle item checked")
    }

    /// Updates a grocery item's properties
    func updateItem(_ item: GroceryListItem, name: String? = nil,
                    categoryName: String? = nil, numericValue: Double? = nil,
                    standardUnit: String? = nil, displayText: String? = nil) {
        clearError()

        if let name = name { item.name = name }
        if let categoryName = categoryName { item.categoryName = categoryName }
        if let numericValue = numericValue { item.numericValue = numericValue }
        if let standardUnit = standardUnit { item.standardUnit = standardUnit }
        if let displayText = displayText { item.displayText = displayText }

        save("update grocery item")
    }

    /// Reorders items within a list
    func reorderItems(_ items: [GroceryListItem]) {
        clearError()
        for (index, item) in items.enumerated() {
            item.sortOrder = Int16(index)
        }
        save("reorder items")
    }

    // MARK: - Batch Operations

    /// Marks all uncompleted items in a list as complete
    func markAllItemsComplete(in list: WeeklyList) {
        clearError()
        guard let items = list.items as? Set<GroceryListItem> else { return }
        for item in items where !item.isCompleted {
            item.isCompleted = true
            item.dateCompleted = Date()
        }
        save("mark all items complete")
    }

    /// Removes all completed items from a list
    func removeCompletedItems(from list: WeeklyList) {
        clearError()
        guard let items = list.items as? Set<GroceryListItem> else { return }
        let completed = items.filter { $0.isCompleted }
        for item in completed {
            viewContext.delete(item)
        }
        save("remove completed items")
    }

    /// Saves the current context for multi-step operations
    func saveContext() {
        clearError()
        save("batch save")
    }

    // MARK: - Error Handling

    private func clearError() {
        errorMessage = nil
    }

    @discardableResult
    private func save(_ operation: String) -> Bool {
        guard viewContext.hasChanges else { return true }

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "Failed to \(operation)"
            #if DEBUG
            print("❌ WeeklyListService: Failed to \(operation): \(error)")
            #endif
            viewContext.rollback()
            return false
        }
    }
}
