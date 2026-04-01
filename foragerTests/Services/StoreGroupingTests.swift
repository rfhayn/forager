import XCTest
import CoreData
@testable import forager

/// M18.1.4: Tests for store grouping logic, store assignment, and color dot visibility.
final class StoreGroupingTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var service: StoreService!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        service = StoreService(context: context)
    }

    @MainActor
    override func tearDown() {
        service = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @MainActor
    private func makeStore(name: String, color: String, sortOrder: Int16) -> Store {
        let store = Store(context: context)
        store.id = UUID()
        store.name = name
        store.color = color
        store.sortOrder = sortOrder
        store.dateCreated = Date()
        return store
    }

    @MainActor
    private func makeCategory(name: String, sortOrder: Int16) -> forager.Category {
        let cat = forager.Category(context: context)
        cat.id = UUID()
        cat.name = name
        cat.sortOrder = sortOrder
        return cat
    }

    @MainActor
    private func makeItem(name: String, store: Store? = nil, category: forager.Category? = nil, list: WeeklyList) -> GroceryListItem {
        let item = GroceryListItem(context: context)
        item.id = UUID()
        item.name = name
        item.store = store
        item.categoryEntity = category
        item.weeklyList = list
        list.addToItems(item)
        return item
    }

    @MainActor
    private func makeList() -> WeeklyList {
        let list = WeeklyList(context: context)
        list.id = UUID()
        list.name = "Test List"
        list.dateCreated = Date()
        list.isCompleted = false
        return list
    }

    @MainActor
    private func makeTemplate(name: String) -> IngredientTemplate {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.dateCreated = Date()
        template.updatedAt = Date()
        return template
    }

    // MARK: - Group by Store Tests

    @MainActor
    func testGroupByStoreReturnsStoresInSortOrder() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let target = makeStore(name: "Target", color: "#3182CE", sortOrder: 1)
        let list = makeList()

        let _ = makeItem(name: "Milk", store: costco, list: list)
        let _ = makeItem(name: "Bread", store: target, list: list)

        let items = [list.items?.allObjects as? [GroceryListItem] ?? []].flatMap { $0 }
        let result = StoreService.groupByStore(items: items, stores: [costco, target])

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].storeName, "Costco")
        XCTAssertEqual(result[1].storeName, "Target")
    }

    @MainActor
    func testGroupByStoreUnassignedAtBottom() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let list = makeList()

        let _ = makeItem(name: "Milk", store: costco, list: list)
        let _ = makeItem(name: "Bread", list: list)

        let items = list.items?.allObjects as? [GroceryListItem] ?? []
        let result = StoreService.groupByStore(items: items, stores: [costco])

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].storeName, "Costco")
        XCTAssertEqual(result[1].storeName, "Unassigned")
        XCTAssertNil(result[1].storeColor)
    }

    @MainActor
    func testGroupByStorePreservesStoreColor() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let list = makeList()

        let _ = makeItem(name: "Milk", store: costco, list: list)

        let items = list.items?.allObjects as? [GroceryListItem] ?? []
        let result = StoreService.groupByStore(items: items, stores: [costco])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].storeColor, "#E53E3E")
    }

    @MainActor
    func testGroupByStoreSubSortsByCategorySortOrder() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let dairy = makeCategory(name: "Dairy", sortOrder: 1)
        let produce = makeCategory(name: "Produce", sortOrder: 0)
        let list = makeList()

        let milkItem = makeItem(name: "Milk", store: costco, category: dairy, list: list)
        let appleItem = makeItem(name: "Apples", store: costco, category: produce, list: list)

        let items = [milkItem, appleItem]
        let result = StoreService.groupByStore(items: items, stores: [costco])

        XCTAssertEqual(result.count, 1)
        // Produce (sortOrder 0) should come before Dairy (sortOrder 1)
        XCTAssertEqual(result[0].items[0].name, "Apples")
        XCTAssertEqual(result[0].items[1].name, "Milk")
    }

    @MainActor
    func testGroupByStoreEmptyStoresNotIncluded() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let target = makeStore(name: "Target", color: "#3182CE", sortOrder: 1)
        let list = makeList()

        let _ = makeItem(name: "Milk", store: costco, list: list)
        // Target has no items

        let items = list.items?.allObjects as? [GroceryListItem] ?? []
        let result = StoreService.groupByStore(items: items, stores: [costco, target])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].storeName, "Costco")
    }

    @MainActor
    func testGroupByStoreAllUnassigned() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let list = makeList()

        let _ = makeItem(name: "Milk", list: list)
        let _ = makeItem(name: "Bread", list: list)

        let items = list.items?.allObjects as? [GroceryListItem] ?? []
        let result = StoreService.groupByStore(items: items, stores: [costco])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].storeName, "Unassigned")
    }

    // MARK: - Store Assignment Tests

    @MainActor
    func testAssignStoreToItemAndTemplate() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let list = makeList()
        let item = makeItem(name: "Milk", list: list)
        let template = makeTemplate(name: "Milk")

        service.assignStore(costco, toGroceryItem: item)
        service.assignStore(costco, toTemplate: template)

        XCTAssertEqual(item.store, costco)
        XCTAssertEqual(template.preferredStore, costco)
    }

    @MainActor
    func testClearStoreAssignment() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let list = makeList()
        let item = makeItem(name: "Milk", store: costco, list: list)

        service.assignStore(nil, toGroceryItem: item)

        XCTAssertNil(item.store)
    }

    // MARK: - Color Dot Visibility Tests

    @MainActor
    func testColorDotVisibleWhenStoreAssigned() {
        let costco = makeStore(name: "Costco", color: "#E53E3E", sortOrder: 0)
        let list = makeList()
        let item = makeItem(name: "Milk", store: costco, list: list)

        // Color dot hex should be non-nil when store is assigned
        let storeColorHex = item.store?.color
        XCTAssertNotNil(storeColorHex)
        XCTAssertEqual(storeColorHex, "#E53E3E")
    }

    @MainActor
    func testColorDotNotVisibleWhenNoStore() {
        let list = makeList()
        let item = makeItem(name: "Milk", list: list)

        let storeColorHex = item.store?.color
        XCTAssertNil(storeColorHex)
    }
}
