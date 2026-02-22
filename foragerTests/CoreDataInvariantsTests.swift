import XCTest
import CoreData
@testable import forager

/// M7.5 Phase 3.2: Core Data Invariant Tests
/// Validates critical data integrity rules that must never be violated
/// Pattern: In-memory testing following existing MigrationValidationTests approach
final class CoreDataInvariantsTests: XCTestCase {

    var persistence: PersistenceController!
    var context: NSManagedObjectContext!

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

    // MARK: - Seeding Invariants

    /// Test 1: Default seeding is idempotent
    func testDefaultSeedingIdempotency() throws {
        try DefaultSeeder.seedDefaultsIfNeeded(in: context)
        let firstCount = try context.count(for: Category.fetchRequest())

        try DefaultSeeder.seedDefaultsIfNeeded(in: context)
        let secondCount = try context.count(for: Category.fetchRequest())

        XCTAssertEqual(firstCount, secondCount, "Seeding should be idempotent")
        XCTAssertGreaterThan(firstCount, 0, "Should have default categories")
    }

    // MARK: - Template Invariants

    /// Test 2: IngredientTemplate uses `name` (not `displayName`)
    func testIngredientTemplateUsesNameProperty() throws {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = "Basil"
        template.dateCreated = Date()
        try context.save()

        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Basil")
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1, "Should find template by name property")
        XCTAssertEqual(results.first?.name, "Basil")
    }

    // MARK: - Cascade Delete Invariants

    /// Test 3: Deleting recipe cascades to Ingredient entities
    func testRecipeDeleteCascadesToIngredients() throws {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test Recipe"
        recipe.servings = 4
        recipe.instructions = "Test instructions"

        let ingredient = Ingredient(context: context)
        ingredient.id = UUID()
        ingredient.name = "Test Ingredient"
        ingredient.numericValue = 2.0
        ingredient.standardUnit = "cups"
        ingredient.displayText = "2 cups"
        ingredient.isParseable = true
        ingredient.parseConfidence = 1.0
        ingredient.recipe = recipe
        try context.save()

        let ingredientID = ingredient.objectID

        context.delete(recipe)
        try context.save()

        // Ingredient should be cascade deleted with recipe
        let deleted = try? context.existingObject(with: ingredientID)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted,
                      "Ingredient should be cascade deleted with recipe")
    }

    /// Test 4: Category delete behavior
    func testCategoryDeleteBehavior() throws {
        let category = Category(context: context)
        category.id = UUID()
        category.name = "Test Category"
        try context.save()

        context.delete(category)
        XCTAssertNoThrow(try context.save(), "Category deletion should succeed")
    }

    /// Test 5: Ingredient structured fields store correctly
    func testIngredientStructuredFieldsPersist() throws {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test"
        recipe.servings = 4
        recipe.instructions = "Test instructions"

        let ingredient = Ingredient(context: context)
        ingredient.id = UUID()
        ingredient.name = "flour"
        ingredient.numericValue = 2.5
        ingredient.standardUnit = "cups"
        ingredient.displayText = "2 1/2 cups"
        ingredient.isParseable = true
        ingredient.parseConfidence = 0.95
        ingredient.sortOrder = 0
        ingredient.recipe = recipe
        try context.save()

        // Re-fetch to verify persistence
        context.refresh(ingredient, mergeChanges: false)
        XCTAssertEqual(ingredient.numericValue, 2.5, accuracy: 0.01)
        XCTAssertEqual(ingredient.standardUnit, "cups")
        XCTAssertEqual(ingredient.displayText, "2 1/2 cups")
        XCTAssertTrue(ingredient.isParseable)
        XCTAssertEqual(ingredient.parseConfidence, 0.95, accuracy: 0.01)
    }
}
