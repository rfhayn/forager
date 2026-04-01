import XCTest
import CoreData
@testable import forager

/// M18.1.1: StoreService unit tests
/// Validates store CRUD, assignment, reordering, and cross-store resolution
/// using in-memory Core Data.
final class StoreServiceTests: XCTestCase {

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
    private func createTemplate(named name: String) -> IngredientTemplate {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.dateCreated = Date()
        template.updatedAt = Date()
        return template
    }

    @MainActor
    private func createList(named name: String) -> WeeklyList {
        let list = WeeklyList(context: context)
        list.id = UUID()
        list.name = name
        list.dateCreated = Date()
        list.isCompleted = false
        return list
    }

    @MainActor
    private func createGroceryItem(named name: String, in list: WeeklyList) -> GroceryListItem {
        let item = GroceryListItem(context: context)
        item.id = UUID()
        item.name = name
        item.weeklyList = list
        list.addToItems(item)
        return item
    }

    // MARK: - Create

    @MainActor
    func testCreateStore() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")

        XCTAssertNotNil(store)
        XCTAssertEqual(store?.name, "Costco")
        XCTAssertEqual(store?.color, "#E53E3E")
        XCTAssertNotNil(store?.id)
        XCTAssertNotNil(store?.dateCreated)
        XCTAssertNil(service.errorMessage)
    }

    @MainActor
    func testCreateMultipleStoresAutoIncrementsSortOrder() {
        let store1 = service.createStore(name: "Costco", color: "#E53E3E")
        let store2 = service.createStore(name: "Target", color: "#3182CE")
        let store3 = service.createStore(name: "Aldi", color: "#38A169")

        // Verify monotonically increasing (absolute values depend on test ordering
        // since in-memory stores share /dev/null across test instances)
        XCTAssertNotNil(store1)
        XCTAssertNotNil(store2)
        XCTAssertNotNil(store3)
        XCTAssertEqual(store2!.sortOrder, store1!.sortOrder + 1)
        XCTAssertEqual(store3!.sortOrder, store2!.sortOrder + 1)
    }

    // MARK: - Fetch

    @MainActor
    func testFetchStoresReturnsOrderedBySort() {
        let storesBefore = service.fetchStores().count
        let _ = service.createStore(name: "Target", color: "#3182CE")
        let _ = service.createStore(name: "Costco", color: "#E53E3E")
        let _ = service.createStore(name: "Aldi", color: "#38A169")

        let stores = service.fetchStores()

        XCTAssertEqual(stores.count, storesBefore + 3)
        // Verify our 3 new stores are in creation order (ascending sortOrder)
        let newStores = stores.suffix(3)
        XCTAssertEqual(newStores[newStores.startIndex].name, "Target")
        XCTAssertEqual(newStores[newStores.startIndex + 1].name, "Costco")
        XCTAssertEqual(newStores[newStores.startIndex + 2].name, "Aldi")
    }

    @MainActor
    func testFetchStoresScopedByHouseholdKey() {
        service.householdKey = "household-A"
        let _ = service.createStore(name: "Costco", color: "#E53E3E")

        // Create a store with different household key directly
        let otherStore = Store(context: context)
        otherStore.id = UUID()
        otherStore.name = "Target"
        otherStore.color = "#3182CE"
        otherStore.householdKey = "household-B"
        otherStore.sortOrder = 0
        try? context.save()

        let stores = service.fetchStores()
        XCTAssertEqual(stores.count, 1)
        XCTAssertEqual(stores[0].name, "Costco")
    }

    // MARK: - Delete

    @MainActor
    func testDeleteStoreNullsTemplateAssignments() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")!
        let template = createTemplate(named: "chicken breast")
        template.preferredStore = store
        try? context.save()

        service.deleteStore(store)

        XCTAssertNil(template.preferredStore)
    }

    @MainActor
    func testDeleteStoreReassignsTemplates() {
        let costco = service.createStore(name: "Costco", color: "#E53E3E")!
        let target = service.createStore(name: "Target", color: "#3182CE")!
        let template = createTemplate(named: "chicken breast")
        template.preferredStore = costco
        try? context.save()

        service.deleteStore(costco, reassignTo: target)

        XCTAssertEqual(template.preferredStore, target)
    }

    @MainActor
    func testDeleteStoreNullsGroceryItemSnapshots() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")!
        let list = createList(named: "Weekly")
        let item = createGroceryItem(named: "Milk", in: list)
        item.store = store
        try? context.save()

        service.deleteStore(store)

        XCTAssertNil(item.store)
    }

    // MARK: - Reorder

    @MainActor
    func testReorderStores() {
        let store1 = service.createStore(name: "Costco", color: "#E53E3E")!
        let store2 = service.createStore(name: "Target", color: "#3182CE")!
        let store3 = service.createStore(name: "Aldi", color: "#38A169")!

        // Reverse the order
        service.reorderStores([store3, store2, store1])

        XCTAssertEqual(store3.sortOrder, 0)
        XCTAssertEqual(store2.sortOrder, 1)
        XCTAssertEqual(store1.sortOrder, 2)
    }

    // MARK: - Assignment

    @MainActor
    func testAssignStoreToTemplate() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")!
        let template = createTemplate(named: "chicken breast")

        service.assignStore(store, toTemplate: template)

        XCTAssertEqual(template.preferredStore, store)
    }

    @MainActor
    func testAssignNilClearsTemplateStore() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")!
        let template = createTemplate(named: "chicken breast")
        template.preferredStore = store
        try? context.save()

        service.assignStore(nil, toTemplate: template)

        XCTAssertNil(template.preferredStore)
    }

    @MainActor
    func testAssignStoreToGroceryItem() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")!
        let list = createList(named: "Weekly")
        let item = createGroceryItem(named: "Milk", in: list)

        service.assignStore(store, toGroceryItem: item)

        XCTAssertEqual(item.store, store)
    }

    // MARK: - Cross-Store Resolution

    @MainActor
    func testResolveStoreReturnsSameStoreWhenSamePersistentStore() {
        let store = service.createStore(name: "Costco", color: "#E53E3E")!
        let template = createTemplate(named: "chicken breast")
        template.preferredStore = store
        let list = createList(named: "Weekly")
        try? context.save()

        let resolved = service.resolveStore(for: template, targetList: list)

        XCTAssertEqual(resolved, store)
    }

    @MainActor
    func testResolveStoreReturnsNilWhenNoPreferredStore() {
        let template = createTemplate(named: "chicken breast")
        let list = createList(named: "Weekly")
        try? context.save()

        let resolved = service.resolveStore(for: template, targetList: list)

        XCTAssertNil(resolved)
    }

    @MainActor
    func testResolveStoreReturnsNilForNilTemplate() {
        let list = createList(named: "Weekly")
        try? context.save()

        let resolved = service.resolveStore(for: nil, targetList: list)

        XCTAssertNil(resolved)
    }
}
