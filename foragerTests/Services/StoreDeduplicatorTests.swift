import XCTest
import CoreData
@testable import forager

/// fix-no-store-default-duplicates: StoreDeduplicator tests.
///
/// Mirror of CategoryDeduplicatorTests with two divergences that reflect
/// StoreDeduplicator's own behavioral differences:
///   1. Grouping key covers (name, scope, isDefault) — `testDefaultAndUserSameNameNotDeduped`
///      exercises the isDefault dimension.
///   2. Relationships are explicitly re-parented (vs Category's nullify+safety-net
///      pattern) — `testReParentsTemplates` and `testReParentsGroceryListItems`
///      verify this.
///
/// `PersistenceController(inMemory: true)` can leak state across tests under
/// some run configurations (same pattern as CategoryDeduplicatorTests flakes).
/// To remain isolated: each test method uses its own unique name prefix, and
/// assertions are scoped to that prefix via predicate. Collisions are
/// structurally impossible.
final class StoreDeduplicatorTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        #if DEBUG
        DefaultSeeder.resetSeedingStatus()
        #endif
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
    }

    override func tearDown() {
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Fetch Stores with an exact name match. Used to assert dedup results
    /// scoped to a single test's fixtures.
    private func countStores(named name: String) throws -> Int {
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        return try context.count(for: request)
    }

    private func fetchStores(named name: String) throws -> [Store] {
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        return try context.fetch(request)
    }

    private func createStore(
        name: String,
        isDefault: Bool = false,
        householdKey: String? = nil,
        date: Date = Date()
    ) -> Store {
        let store = Store(context: context)
        store.id = UUID()
        store.name = name
        store.isDefault = isDefault
        store.householdKey = householdKey
        store.dateCreated = date
        store.updatedAt = Date()
        store.color = "#4CAF50"
        store.sortOrder = 0
        return store
    }

    private func createTemplate(name: String, preferredStore: Store) -> IngredientTemplate {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.canonicalName = name.lowercased()
        template.preferredStore = preferredStore
        template.dateCreated = Date()
        return template
    }

    private func createWeeklyListWithItem(itemName: String, store: Store) -> GroceryListItem {
        let list = WeeklyList(context: context)
        list.id = UUID()
        list.name = "Test List"
        list.dateCreated = Date()
        list.isCompleted = false

        let item = GroceryListItem(context: context)
        context.assign(item, to: persistence.privateStore)
        item.id = UUID()
        item.name = itemName
        item.displayText = itemName
        item.numericValue = 1
        item.parseConfidence = 1.0
        item.isParseable = true
        item.isCompleted = false
        item.sortOrder = 0
        item.weeklyList = list
        item.store = store
        return item
    }

    // MARK: - Basic Dedup

    func testNoDuplicatesIsNoop() throws {
        let name = "SDT_NoDup_\(UUID().uuidString)"
        _ = createStore(name: name)
        try context.save()

        XCTAssertEqual(try countStores(named: name), 1)
        try StoreDeduplicator(context: context).removeDuplicates()
        XCTAssertEqual(try countStores(named: name), 1, "Row is untouched when it's the only one in its group")
    }

    func testFiveDefaultDuplicatesCollapseToOneOldest() throws {
        let name = "SDT_FiveDef_\(UUID().uuidString)"
        let oldest = createStore(
            name: name, isDefault: true,
            date: Date().addingTimeInterval(-500)
        )
        for offset in [-400, -300, -200, -100] {
            _ = createStore(
                name: name, isDefault: true,
                date: Date().addingTimeInterval(TimeInterval(offset))
            )
        }
        try context.save()

        XCTAssertEqual(try countStores(named: name), 5)

        try StoreDeduplicator(context: context).removeDuplicates()

        let remaining = try fetchStores(named: name)
        XCTAssertEqual(remaining.count, 1, "Four duplicates removed, one keeper")
        XCTAssertEqual(remaining.first?.dateCreated, oldest.dateCreated, "Oldest is kept")
    }

    // MARK: - Relationship Re-Parenting

    func testReParentsTemplates() throws {
        let name = "SDT_ReparentTpl_\(UUID().uuidString)"
        let oldest = createStore(name: name, date: Date().addingTimeInterval(-200))
        let duplicate = createStore(name: name, date: Date().addingTimeInterval(-100))
        let flour = createTemplate(name: "SDT_flour_\(UUID().uuidString)", preferredStore: duplicate)
        let sugar = createTemplate(name: "SDT_sugar_\(UUID().uuidString)", preferredStore: duplicate)
        let butter = createTemplate(name: "SDT_butter_\(UUID().uuidString)", preferredStore: duplicate)
        try context.save()

        try StoreDeduplicator(context: context).removeDuplicates()

        XCTAssertEqual(flour.preferredStore, oldest, "Template re-parented to keeper")
        XCTAssertEqual(sugar.preferredStore, oldest)
        XCTAssertEqual(butter.preferredStore, oldest)
        XCTAssertEqual(try countStores(named: name), 1, "Duplicate removed, keeper survives")
    }

    func testReParentsGroceryListItems() throws {
        let name = "SDT_ReparentItem_\(UUID().uuidString)"
        let oldest = createStore(name: name, date: Date().addingTimeInterval(-200))
        let duplicate = createStore(name: name, date: Date().addingTimeInterval(-100))
        let item1 = createWeeklyListWithItem(itemName: "SDT_rice_\(UUID().uuidString)", store: duplicate)
        let item2 = createWeeklyListWithItem(itemName: "SDT_beans_\(UUID().uuidString)", store: duplicate)
        try context.save()

        try StoreDeduplicator(context: context).removeDuplicates()

        XCTAssertEqual(item1.store, oldest, "GroceryListItem re-parented to keeper")
        XCTAssertEqual(item2.store, oldest)
        XCTAssertEqual(try countStores(named: name), 1)
    }

    // MARK: - Scope Safety

    func testCrossScopeNotDeduped() throws {
        let name = "SDT_CrossScope_\(UUID().uuidString)"
        _ = createStore(name: name, isDefault: true, householdKey: nil)
        _ = createStore(name: name, isDefault: true, householdKey: "household-ABC")
        try context.save()

        try StoreDeduplicator(context: context).removeDuplicates()

        XCTAssertEqual(try countStores(named: name), 2, "Same name in different scopes is not a duplicate")
    }

    func testDefaultAndUserSameNameNotDeduped() throws {
        let name = "SDT_DefVsUser_\(UUID().uuidString)"
        _ = createStore(name: name, isDefault: true)
        _ = createStore(name: name, isDefault: false)
        try context.save()

        try StoreDeduplicator(context: context).removeDuplicates()

        XCTAssertEqual(try countStores(named: name), 2, "isDefault dimension separates semantic groups")
    }

    // MARK: - Idempotency

    func testIdempotentSecondRun() throws {
        let name = "SDT_Idem_\(UUID().uuidString)"
        _ = createStore(name: name, isDefault: true, date: Date().addingTimeInterval(-200))
        _ = createStore(name: name, isDefault: true, date: Date().addingTimeInterval(-100))
        try context.save()

        try StoreDeduplicator(context: context).removeDuplicates()
        XCTAssertEqual(try countStores(named: name), 1, "First run removes the duplicate")

        let secondPass = try StoreDeduplicator(context: context).removeDuplicates()
        XCTAssertEqual(secondPass, 0, "Second run is a no-op")
        XCTAssertEqual(try countStores(named: name), 1, "Keeper still present")
    }
}
