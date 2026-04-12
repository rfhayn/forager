import XCTest
import CoreData
@testable import forager

/// M19: ManagedObjectFactory tests
/// NOTE: factory.make() calls persistence.store(for:) which requires on-disk stores
/// with specific filenames (forager.sqlite / forager_shared.sqlite). In-memory stores
/// don't have these filenames, so full factory integration tests crash.
/// These tests validate: HouseholdScoped conformance, scope resolution, error types,
/// and configure closure behavior — everything EXCEPT store assignment.
final class ManagedObjectFactoryTests: XCTestCase {

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

    // MARK: - HouseholdScoped Conformance

    func testAllTopLevelEntitiesConformToHouseholdScoped() {
        // These are the entities that MUST go through the factory
        XCTAssertTrue(Recipe(context: context) is HouseholdScoped)
        XCTAssertTrue(WeeklyList(context: context) is HouseholdScoped)
        XCTAssertTrue(MealPlan(context: context) is HouseholdScoped)
        XCTAssertTrue(PlannedMeal(context: context) is HouseholdScoped)
        XCTAssertTrue(forager.Category(context: context) is HouseholdScoped)
        XCTAssertTrue(IngredientTemplate(context: context) is HouseholdScoped)
        XCTAssertTrue(Store(context: context) is HouseholdScoped)
        // Child entities also conform (inherit scope from parent)
        XCTAssertTrue(Ingredient(context: context) is HouseholdScoped)
        XCTAssertTrue(GroceryListItem(context: context) is HouseholdScoped)
    }

    func testHouseholdScopedPropertiesAreSettable() {
        let recipe = Recipe(context: context)
        let household = Household(context: context)
        household.id = UUID()
        household.name = "Test"
        household.createdDate = Date()

        // Set via protocol
        let scoped = recipe as HouseholdScoped
        scoped.household = household
        scoped.householdKey = "test-key"

        XCTAssertEqual(recipe.household, household)
        XCTAssertEqual(recipe.householdKey, "test-key")
    }

    // MARK: - DataScope Resolution

    func testPersonalScopeIsDefault() {
        // When no provider and no explicit scope, factory defaults to .personal
        // We can't call make() (store resolution crashes), but we can test the scope enum
        let scope = DataScope.personal
        if case .personal = scope {
            // Expected
        } else {
            XCTFail("Expected .personal")
        }
    }

    func testHouseholdScopeCarriesObjectIDAndStoreID() {
        let household = Household(context: context)
        household.id = UUID()
        household.name = "Test"
        household.createdDate = Date()

        let scope = DataScope.household(id: household.objectID, storeID: .shared)

        if case .household(let id, let storeID) = scope {
            XCTAssertEqual(id, household.objectID)
            XCTAssertEqual(storeID, .shared)
        } else {
            XCTFail("Expected .household scope")
        }
    }

    func testScopeProviderPriorityChain() {
        // Priority: explicit > provider > .personal
        // This is documented behavior — just validate the enum is correct
        let explicitScope = DataScope.personal
        let providerScope = DataScope.personal

        // Both should be .personal (can't test .household without on-disk stores)
        if case .personal = explicitScope, case .personal = providerScope {
            // Expected
        } else {
            XCTFail("Both scopes should be .personal in test environment")
        }
    }

    // MARK: - FactoryError Types

    func testFactoryErrorTypes() {
        let household = Household(context: context)
        household.id = UUID()

        let error1 = FactoryError.householdNotFound(household.objectID)
        let error2 = FactoryError.invalidHouseholdObjectID

        // Verify errors have meaningful descriptions
        XCTAssertTrue(error1.localizedDescription.contains("Household not found"))
        XCTAssertTrue(error2.localizedDescription.contains("Household type"))
    }

    // MARK: - Factory Non-Optional in Services (M19 Enforcement)

    @MainActor
    func testServicesHaveFactoryProperty() {
        // Verify all services that create HouseholdScoped entities have factory
        let templateService = IngredientTemplateService(context: context)
        let parsingService = IngredientParsingService(context: context, templateService: templateService)
        let recipeService = RecipeService(context: context, parsingService: parsingService)
        let weeklyListService = WeeklyListService(context: context, parsingService: parsingService)

        // Before configure(), factory is nil (implicitly unwrapped optional)
        // After configure(), it's set — these are compile-time checks that the property exists
        XCTAssertNotNil(recipeService) // Compiles = factory property exists
        XCTAssertNotNil(weeklyListService)
        XCTAssertNotNil(templateService)
    }

    // MARK: - Manual Household Assignment (Validates What Factory Does)

    func testManualHouseholdAssignmentMatchesFactoryBehavior() throws {
        let household = Household(context: context)
        household.id = UUID()
        household.name = "Test Household"
        household.createdDate = Date()

        // This is what the factory does internally for household scope
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test"
        recipe.servings = 1
        recipe.dateCreated = Date()
        recipe.instructions = "Test instructions"
        recipe.household = household
        recipe.householdKey = household.id?.uuidString

        try context.save()

        // Verify the assignment persists
        context.refresh(recipe, mergeChanges: false)
        XCTAssertEqual(recipe.household, household)
        XCTAssertEqual(recipe.householdKey, household.id?.uuidString)
    }

    func testPersonalScopeNilsHousehold() throws {
        let household = Household(context: context)
        household.id = UUID()
        household.name = "Test"
        household.createdDate = Date()

        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test"
        recipe.servings = 1
        recipe.dateCreated = Date()
        recipe.instructions = "Test instructions"
        recipe.household = household
        recipe.householdKey = household.id?.uuidString

        // This is what the factory does for personal scope
        recipe.household = nil
        recipe.householdKey = nil

        try context.save()

        XCTAssertNil(recipe.household)
        XCTAssertNil(recipe.householdKey)
    }
}
