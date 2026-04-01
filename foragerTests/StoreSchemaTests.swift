import XCTest
import CoreData
@testable import forager

/// M18.1.0: Schema v11 validation tests
/// Validates Store entity, new relationships, Recipe attribution attributes,
/// HouseholdScoped conformance, and ManagedObjectFactory support.
final class StoreSchemaTests: XCTestCase {

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

    // MARK: - Helper

    private func createHousehold() -> Household {
        let household = Household(context: context)
        household.id = UUID()
        household.name = "Test Household"
        household.ownerEmail = "test@example.com"
        household.createdDate = Date()
        return household
    }

    private func createStore(name: String = "Costco", color: String = "#1E88E5", household: Household? = nil) -> Store {
        let store = Store(context: context)
        store.id = UUID()
        store.name = name
        store.color = color
        store.sortOrder = 0
        store.dateCreated = Date()
        store.updatedAt = Date()
        if let household = household {
            store.household = household
            store.householdKey = household.id?.uuidString
        }
        return store
    }

    // MARK: - Store Entity Creation

    func testStoreEntityCreation() throws {
        let store = createStore()
        try context.save()

        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Costco")
        XCTAssertEqual(results.first?.color, "#1E88E5")
        XCTAssertEqual(results.first?.sortOrder, 0)
        XCTAssertNotNil(results.first?.id)
        XCTAssertNotNil(results.first?.dateCreated)
        XCTAssertNotNil(results.first?.updatedAt)
    }

    func testStoreAllAttributesPersist() throws {
        let store = createStore(name: "Heinen's", color: "#43A047")
        store.sortOrder = 3
        try context.save()

        context.refresh(store, mergeChanges: false)
        XCTAssertEqual(store.name, "Heinen's")
        XCTAssertEqual(store.color, "#43A047")
        XCTAssertEqual(store.sortOrder, 3)
    }

    // MARK: - Store HouseholdScoped Conformance

    func testStoreConformsToHouseholdScoped() {
        let store = Store(context: context)
        XCTAssertTrue(store is HouseholdScoped, "Store must conform to HouseholdScoped")
    }

    func testStoreHouseholdKeySetCorrectly() throws {
        let household = createHousehold()
        let store = createStore(household: household)
        try context.save()

        XCTAssertEqual(store.householdKey, household.id?.uuidString)
        XCTAssertEqual(store.household, household)
    }

    // MARK: - Store ManagedObjectFactory Compatibility

    /// Validates Store can participate in the factory pattern by verifying it conforms
    /// to HouseholdScoped (which is the factory's type constraint).
    /// NOTE: Full factory integration test requires dual-store PersistenceController
    /// (privateStore/sharedStore resolve by filename), which in-memory /dev/null doesn't provide.
    /// The household + householdKey assignment is tested directly above.
    func testStoreIsFactoryCompatible() {
        let store = Store(context: context)
        // Factory requires HouseholdScoped conformance to set household + householdKey
        let scoped = store as? HouseholdScoped
        XCTAssertNotNil(scoped, "Store must be HouseholdScoped for factory compatibility")
        // Verify the factory-required properties exist and are settable
        scoped?.household = nil
        scoped?.householdKey = "test-key"
        XCTAssertEqual(store.householdKey, "test-key")
    }

    // MARK: - Store → Household Relationship

    func testStoreHouseholdRelationship() throws {
        let household = createHousehold()
        let store1 = createStore(name: "Costco", household: household)
        let store2 = createStore(name: "Target", household: household)
        store2.sortOrder = 1
        try context.save()

        let stores = household.stores as? Set<Store>
        XCTAssertNotNil(stores)
        XCTAssertEqual(stores?.count, 2)

        let storeNames = stores?.map { $0.name ?? "" } ?? []
        XCTAssertTrue(storeNames.contains("Costco"))
        XCTAssertTrue(storeNames.contains("Target"))

        XCTAssertEqual(store1.household, household)
        XCTAssertEqual(store2.household, household)
    }

    func testStoreHouseholdAccessors() throws {
        let household = createHousehold()
        let store = createStore(name: "Aldi", household: household)
        try context.save()

        // Test generated accessors
        let store2 = createStore(name: "Walmart")
        household.addToStores(store2)
        try context.save()

        let stores = household.stores as? Set<Store>
        XCTAssertEqual(stores?.count, 2)

        household.removeFromStores(store)
        try context.save()

        let remaining = household.stores as? Set<Store>
        XCTAssertEqual(remaining?.count, 1)
        XCTAssertEqual(remaining?.first?.name, "Walmart")
    }

    // MARK: - Store → IngredientTemplate Relationship

    func testStoreIngredientTemplateRelationship() throws {
        let store = createStore()
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = "Chicken Breast"
        template.dateCreated = Date()
        template.preferredStore = store
        try context.save()

        XCTAssertEqual(template.preferredStore, store)

        let templates = store.ingredientTemplates as? Set<IngredientTemplate>
        XCTAssertNotNil(templates)
        XCTAssertEqual(templates?.count, 1)
        XCTAssertEqual(templates?.first?.name, "Chicken Breast")
    }

    func testMultipleTemplatesPreferSameStore() throws {
        let store = createStore(name: "Costco")
        for name in ["Chicken Breast", "Ground Beef", "Salmon"] {
            let t = IngredientTemplate(context: context)
            t.id = UUID()
            t.name = name
            t.dateCreated = Date()
            t.preferredStore = store
        }
        try context.save()

        let templates = store.ingredientTemplates as? Set<IngredientTemplate>
        XCTAssertEqual(templates?.count, 3)
    }

    // MARK: - Store → GroceryListItem Relationship

    func testStoreGroceryListItemRelationship() throws {
        let store = createStore()
        let item = GroceryListItem(context: context)
        item.id = UUID()
        item.name = "Milk"
        item.displayText = "Milk"
        item.store = store
        try context.save()

        XCTAssertEqual(item.store, store)

        let items = store.groceryListItems as? Set<GroceryListItem>
        XCTAssertNotNil(items)
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items?.first?.name, "Milk")
    }

    func testStoreDeleteNullifiesGroceryListItems() throws {
        let store = createStore()
        let item = GroceryListItem(context: context)
        item.id = UUID()
        item.name = "Eggs"
        item.displayText = "Eggs"
        item.store = store
        try context.save()

        XCTAssertNotNil(item.store)
        context.delete(store)
        try context.save()

        XCTAssertNil(item.store, "Deleting store should nullify GroceryListItem.store")
        XCTAssertFalse(item.isDeleted, "GroceryListItem should NOT be cascade deleted")
    }

    func testStoreDeleteNullifiesIngredientTemplates() throws {
        let store = createStore()
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = "Butter"
        template.dateCreated = Date()
        template.preferredStore = store
        try context.save()

        context.delete(store)
        try context.save()

        XCTAssertNil(template.preferredStore, "Deleting store should nullify preferredStore")
        XCTAssertFalse(template.isDeleted, "Template should NOT be cascade deleted")
    }

    // MARK: - Recipe Attribution Attributes

    func testRecipeImageURLAttribute() throws {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test Recipe"
        recipe.servings = 4
        recipe.instructions = "Test"
        recipe.imageURL = "https://example.com/image.jpg"
        try context.save()

        context.refresh(recipe, mergeChanges: false)
        XCTAssertEqual(recipe.imageURL, "https://example.com/image.jpg")
    }

    func testRecipeAuthorAttribute() throws {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test Recipe"
        recipe.servings = 4
        recipe.instructions = "Test"
        recipe.author = "Julia Child"
        try context.save()

        context.refresh(recipe, mergeChanges: false)
        XCTAssertEqual(recipe.author, "Julia Child")
    }

    func testRecipeAttributionNilByDefault() throws {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "No Attribution"
        recipe.servings = 2
        recipe.instructions = "Simple"
        try context.save()

        XCTAssertNil(recipe.imageURL, "imageURL should be nil by default")
        XCTAssertNil(recipe.author, "author should be nil by default")
    }

    // MARK: - IngredientTemplate.preferredStore

    func testIngredientTemplatePreferredStoreIsOptional() throws {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = "Flour"
        template.dateCreated = Date()
        try context.save()

        XCTAssertNil(template.preferredStore, "preferredStore should be nil by default")
    }

    // MARK: - GroceryListItem.store

    func testGroceryListItemStoreIsOptional() throws {
        let item = GroceryListItem(context: context)
        item.id = UUID()
        item.name = "Bread"
        item.displayText = "Bread"
        try context.save()

        XCTAssertNil(item.store, "store should be nil by default")
    }

    // MARK: - DataScope Includes Store

    func testDataScopeIncludesStore() {
        // Verify Store conforms to HouseholdScoped at compile time
        // (this test exists purely to catch accidental removal of conformance)
        let store = Store(context: context)
        let scoped: HouseholdScoped = store
        XCTAssertNotNil(scoped)
    }

    // MARK: - Store Extensions

    func testStoreDisplayName() {
        let store = Store(context: context)
        XCTAssertEqual(store.displayName, "Unknown Store")
        store.name = "Trader Joe's"
        XCTAssertEqual(store.displayName, "Trader Joe's")
    }

    func testStoreDisplayColor() {
        let store = Store(context: context)
        XCTAssertEqual(store.displayColor, "#757575")
        store.color = "#FF5722"
        XCTAssertEqual(store.displayColor, "#FF5722")
    }

    // MARK: - Model Entity Count

    func testModelHas13Entities() throws {
        let entities = persistence.container.managedObjectModel.entities
        XCTAssertEqual(entities.count, 13, "Schema v11 should have 13 entities")

        let entityNames = Set(entities.compactMap { $0.name })
        XCTAssertTrue(entityNames.contains("Store"), "Model must contain Store entity")
    }
}
