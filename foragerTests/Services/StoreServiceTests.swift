import XCTest
import CoreData
@testable import forager

/// Test-only stub for `ScopeProvider` that returns a fixed `DataScope`.
/// Used by `testFetchStoresScopedByHouseholdKey` to exercise the factory's
/// `.household(...)` branch, which actually sets `object.householdKey` —
/// the test's previous assumption (that `service.householdKey` propagates
/// into creation) was pre-ADR-014 and no longer holds.
/// (investigate-import-and-store-test-failures, 2026-04-19)
@MainActor
final class TestStubScopeProvider: ScopeProvider {
    var activeScope: DataScope
    init(_ scope: DataScope) { self.activeScope = scope }
    func scopeSnapshot() -> DataScope { activeScope }
}

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

        // ADR 014: service.createStore explicitly assertionFailures when the
        // factory isn't configured (Services/StoreService.swift:73). Configure
        // it here so tests exercise the real creation path.
        // (fix-test-harness-and-stale-assertions)
        let factory = ManagedObjectFactory(context: context, scopeProvider: nil, persistence: persistence)
        service.configure(factory: factory)
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
    func testFetchStoresScopedByHouseholdKey() throws {
        // Create a persisted Household so the factory's `.household` branch can
        // resolve via ObjectID. Without this, factory falls to `.personal` and
        // explicitly nils out `householdKey` — which is what caused the earlier
        // version of this test to fail before PR #147 exposed it by fixing the
        // setUp crash-loop. (investigate-import-and-store-test-failures)
        let household = Household(context: context)
        household.id = UUID()
        household.name = "A"
        household.createdDate = Date()
        try context.save()

        let householdKeyA = household.id!.uuidString

        // Reconfigure the factory with a stub ScopeProvider returning `.household`
        // so `createStore` routes through the household branch and sets
        // `store.householdKey = household.id?.uuidString`.
        let provider = TestStubScopeProvider(.household(id: household.objectID, storeID: .private))
        let scopedFactory = ManagedObjectFactory(context: context, scopeProvider: provider, persistence: persistence)
        service.configure(factory: scopedFactory)
        service.householdKey = householdKeyA

        let costco = service.createStore(name: "Costco", color: "#E53E3E")
        XCTAssertEqual(costco?.householdKey, householdKeyA, "Factory's .household branch should set householdKey from the resolved Household")

        // Create a store with a different household key directly (bypasses factory)
        let otherStore = Store(context: context)
        otherStore.id = UUID()
        otherStore.name = "Target"
        otherStore.color = "#3182CE"
        otherStore.householdKey = "household-B"
        otherStore.sortOrder = 0
        try context.save()

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
