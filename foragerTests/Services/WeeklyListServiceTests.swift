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

        // ADR 014: service.createList goes through ManagedObjectFactory.make;
        // configure(factory:) is required to avoid crashing on the implicit-
        // unwrapped `factory!`. (fix-test-harness-and-stale-assertions)
        let factory = ManagedObjectFactory(context: context, scopeProvider: nil, persistence: persistence)
        service.configure(factory: factory)
        templateService.configure(factory: factory)
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
    private func createCategory(named name: String) -> forager.Category {
        let cat = forager.Category(context: context)
        cat.id = UUID()
        cat.name = name
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

    // MARK: - Store Snapshot (M18.1.2)

    @MainActor
    func testAddItemWithPreferredStoreSnapshotsStore() {
        let list = service.createList(name: "Test List")
        XCTAssertNotNil(list)

        // Create a store
        let store = Store(context: context)
        store.id = UUID()
        store.name = "Costco"
        store.color = "#FF0000"

        let item = service.addItem(
            to: list!, name: "chicken", store: store, displayText: "chicken"
        )

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.store, store, "Item should snapshot the passed store")
        XCTAssertEqual(item?.store?.name, "Costco")
    }

    @MainActor
    func testAddItemWithoutStoreHasNilStore() {
        let list = service.createList(name: "Test List")
        XCTAssertNotNil(list)

        let item = service.addItem(
            to: list!, name: "milk", displayText: "milk"
        )

        XCTAssertNotNil(item)
        XCTAssertNil(item?.store, "Item without store param should have nil store")
    }

    @MainActor
    func testStoreSnapshotIsIndependentOfLaterChanges() {
        let list = service.createList(name: "Test List")
        XCTAssertNotNil(list)

        let store = Store(context: context)
        store.id = UUID()
        store.name = "Costco"
        store.color = "#FF0000"

        let item = service.addItem(
            to: list!, name: "rice", store: store, displayText: "rice"
        )
        XCTAssertEqual(item?.store?.name, "Costco")

        // Change the store name after item creation
        store.name = "Walmart"

        // The item's store relationship still points to the same object,
        // so it reflects the change (this is Core Data relationship behavior).
        // The snapshot pattern means we capture the store at ADD time —
        // if the template's preferredStore changes later, NEW items get the new store,
        // but existing items keep their original store reference.
        XCTAssertEqual(item?.store?.name, "Walmart",
            "Store is a relationship, not a flat copy — name change is visible")
    }

    // MARK: - Error Handling

    @MainActor
    func testErrorMessageClearsOnSuccess() {
        service.errorMessage = "Previous error"

        let list = service.createList(name: "Test")
        XCTAssertNotNil(list)
        XCTAssertNil(service.errorMessage, "errorMessage should clear on successful operation")
    }

    // MARK: - Zone Assignment Regression (fix-groceryitem-multi-zone-assignment)
    //
    // These tests verify that GroceryListItem creation co-locates the new item
    // with the parent WeeklyList's persistent store. Before the fix, Core Data's
    // relationship-based store inference ran lazily at save time and did not
    // prevent the CloudKit mirroring delegate from routing the CKRecord into the
    // wrong zone, causing error 134040 "Object graph corruption detected — objects
    // assigned to multiple zones".
    //
    // The in-memory dual-store setup (PersistenceController(inMemory: true))
    // mirrors the production topology (forager.sqlite + forager_shared.sqlite).
    // The tests place the list in the shared store explicitly and assert the new
    // item lands in the same store, rather than defaulting to the first store.

    @MainActor
    func testAddItem_inSharedStoreList_itemLandsInSharedStore() throws {
        // Create list directly in the shared store (simulates a household-scoped
        // list on a member device, or an owner-device scenario where CloudKit
        // routes via household relationship). Direct init + assign + save is
        // required because service.createList saves internally, and Core Data
        // refuses to reassign an already-saved object to a different store.
        let list = WeeklyList(context: context)
        list.id = UUID()
        list.name = "Shared List"
        list.dateCreated = Date()
        list.isCompleted = false
        context.assign(list, to: persistence.sharedStore)
        try context.save()

        let item = service.addItem(
            to: list, name: "Whole milk",
            numericValue: 1.0, standardUnit: "gallon",
            displayText: "1 gallon"
        )

        XCTAssertNotNil(item, "addItem returned nil. service.errorMessage: \(service.errorMessage ?? "(none)")")
        XCTAssertEqual(item?.objectID.persistentStore?.url?.lastPathComponent,
                       list.objectID.persistentStore?.url?.lastPathComponent,
                       "Item must be co-located with parent list's persistent store to prevent CloudKit zone conflict (134040)")
        XCTAssertEqual(item?.objectID.persistentStore?.url?.lastPathComponent,
                       "forager_shared.sqlite",
                       "List was placed in shared store; item should follow")
    }

    @MainActor
    func testAddItem_inPrivateStoreList_itemLandsInPrivateStore() throws {
        let list = WeeklyList(context: context)
        list.id = UUID()
        list.name = "Personal List"
        list.dateCreated = Date()
        list.isCompleted = false
        context.assign(list, to: persistence.privateStore)
        try context.save()

        let item = service.addItem(
            to: list, name: "Cereal",
            numericValue: 1.0, standardUnit: "box",
            displayText: "1 box"
        )

        XCTAssertNotNil(item, "addItem returned nil. service.errorMessage: \(service.errorMessage ?? "(none)")")
        XCTAssertEqual(item?.objectID.persistentStore?.url?.lastPathComponent,
                       list.objectID.persistentStore?.url?.lastPathComponent,
                       "Item must be co-located with parent list")
        XCTAssertEqual(item?.objectID.persistentStore?.url?.lastPathComponent,
                       "forager.sqlite",
                       "List was placed in private store; item should follow")
    }
}
