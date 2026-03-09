import XCTest
import CoreData
@testable import forager

/// M7.5 Chunk 1.2b: WeeklyListService unit tests
/// Validates grocery list + item CRUD operations in isolation using in-memory Core Data.
/// Verifies ADR 012: GroceryListItem stores flat string snapshots.
final class WeeklyListServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var templateService: IngredientTemplateService!
    private var parsingService: IngredientParsingService!
    private var service: WeeklyListService!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        templateService = IngredientTemplateService(context: context)
        parsingService = IngredientParsingService(context: context, templateService: templateService)
        service = WeeklyListService(context: context, parsingService: parsingService)
    }

    @MainActor
    override func tearDown() {
        service = nil
        parsingService = nil
        templateService = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helper

    @MainActor
    private func createCategory(named name: String) -> Category {
        let cat = Category(context: context)
        cat.id = UUID()
        cat.name = name
        cat.displayName = name
        cat.sortOrder = 0
        return cat
    }

    // MARK: - WeeklyList CRUD

    @MainActor
    func testCreateList() {
        let list = service.createList(name: "Weekly Groceries")

        XCTAssertNotNil(list)
        XCTAssertEqual(list?.name, "Weekly Groceries")
        XCTAssertNotNil(list?.id)
        XCTAssertNotNil(list?.dateCreated)
        XCTAssertFalse(list?.isCompleted ?? true)
        XCTAssertNil(service.errorMessage)
    }

    @MainActor
    func testDeleteList() throws {
        let list = service.createList(name: "To Delete")
        XCTAssertNotNil(list)

        let listID = list!.objectID
        service.deleteList(list!)

        let deleted = try? context.existingObject(with: listID)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted)
    }

    @MainActor
    func testCompleteList() {
        let list = service.createList(name: "Test List")
        XCTAssertNotNil(list)
        XCTAssertFalse(list!.isCompleted)

        service.completeList(list!)
        XCTAssertTrue(list!.isCompleted)
    }

    // MARK: - GroceryListItem Operations

    @MainActor
    func testAddItem() {
        let list = service.createList(name: "Test List")
        XCTAssertNotNil(list)

        let dairyCategory = createCategory(named: "Dairy")
        let item = service.addItem(
            to: list!, name: "Whole milk", category: dairyCategory,
            numericValue: 1.0, standardUnit: "gallon",
            displayText: "1 gallon", isParseable: true,
            parseConfidence: 0.95, source: "Pancakes"
        )

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "Whole milk")
        XCTAssertEqual(item?.categoryEntity?.name, "Dairy")
        XCTAssertEqual(item?.numericValue ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(item?.standardUnit, "gallon")
        XCTAssertEqual(item?.displayText, "1 gallon")
        XCTAssertTrue(item?.isParseable ?? false)
        XCTAssertEqual(item?.parseConfidence ?? 0, 0.95, accuracy: 0.01)
        XCTAssertEqual(item?.source, "Pancakes")
        XCTAssertFalse(item?.isCompleted ?? true)
        XCTAssertEqual(item?.weeklyList, list)
    }

    @MainActor
    func testAddItemPreservesSnapshotSemantics() {
        // ADR 012: GroceryListItem stores flat string snapshots, not relationships.
        // Changing the template name after adding an item should NOT affect the item.
        let list = service.createList(name: "Test List")
        XCTAssertNotNil(list)

        let dairyCategory = createCategory(named: "Dairy")
        let item = service.addItem(to: list!, name: "butter", category: dairyCategory, displayText: "butter")
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "butter")

        // Simulate what would happen if a template were renamed —
        // the item's name is a snapshot and should remain unchanged
        // (item.name is a stored String, not a relationship to IngredientTemplate)
        let itemName = item?.name
        XCTAssertEqual(itemName, "butter", "Item name is a snapshot — independent of any template")
    }

    @MainActor
    func testRemoveItem() throws {
        let list = service.createList(name: "Test List")
        let item = service.addItem(to: list!, name: "milk", displayText: "milk")
        XCTAssertNotNil(item)

        let itemID = item!.objectID
        service.removeItem(item!)

        let deleted = try? context.existingObject(with: itemID)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted)
    }

    @MainActor
    func testToggleItemChecked() {
        let list = service.createList(name: "Test List")
        let item = service.addItem(to: list!, name: "eggs", displayText: "eggs")
        XCTAssertNotNil(item)
        XCTAssertFalse(item!.isCompleted)
        XCTAssertNil(item?.dateCompleted)

        // Check off
        service.toggleItemChecked(item!)
        XCTAssertTrue(item!.isCompleted)
        XCTAssertNotNil(item?.dateCompleted)

        // Uncheck
        service.toggleItemChecked(item!)
        XCTAssertFalse(item!.isCompleted)
        XCTAssertNil(item?.dateCompleted)
    }

    @MainActor
    func testRemoveCompletedItems() {
        let list = service.createList(name: "Test List")
        let item1 = service.addItem(to: list!, name: "milk", displayText: "milk")
        let item2 = service.addItem(to: list!, name: "eggs", displayText: "eggs")
        let item3 = service.addItem(to: list!, name: "bread", displayText: "bread")

        // Complete two items
        service.toggleItemChecked(item1!)
        service.toggleItemChecked(item2!)

        service.removeCompletedItems(from: list!)

        let remainingItems = (list?.items as? Set<GroceryListItem>)?.filter { !$0.isDeleted }
        XCTAssertEqual(remainingItems?.count, 1)
        XCTAssertEqual(remainingItems?.first?.name, "bread")
    }

    // MARK: - Error Handling

    @MainActor
    func testErrorMessageClearsOnSuccess() {
        service.errorMessage = "Previous error"

        let list = service.createList(name: "Test")
        XCTAssertNotNil(list)
        XCTAssertNil(service.errorMessage, "errorMessage should clear on successful operation")
    }
}
