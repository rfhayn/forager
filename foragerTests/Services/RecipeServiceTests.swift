import XCTest
import CoreData
@testable import forager

/// M7.5 Chunk 1.2b: RecipeService unit tests
/// Validates recipe/ingredient CRUD operations in isolation using in-memory Core Data.
final class RecipeServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var templateService: IngredientTemplateService!
    private var parsingService: IngredientParsingService!
    private var service: RecipeService!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        templateService = IngredientTemplateService(context: context)
        parsingService = IngredientParsingService(context: context, templateService: templateService)
        service = RecipeService(context: context, parsingService: parsingService)

        // ADR 014: service.createRecipe etc. go through ManagedObjectFactory.make;
        // without configure(factory:) the implicit-unwrapped `factory!` crashes on
        // first use. (fix-test-harness-and-stale-assertions)
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

    // MARK: - Recipe CRUD

    @MainActor
    func testCreateRecipe() {
        let recipe = service.createRecipe(title: "Pasta Carbonara", servings: 4, prepTime: 15, cookTime: 20, instructions: "Test instructions")

        XCTAssertNotNil(recipe)
        XCTAssertEqual(recipe?.title, "Pasta Carbonara")
        XCTAssertEqual(recipe?.servings, 4)
        XCTAssertEqual(recipe?.prepTime, 15)
        XCTAssertEqual(recipe?.cookTime, 20)
        XCTAssertNotNil(recipe?.id)
        XCTAssertNotNil(recipe?.dateCreated)
        XCTAssertFalse(recipe?.isFavorite ?? true)
        XCTAssertEqual(recipe?.usageCount, 0)
        XCTAssertNil(service.errorMessage)
    }

    @MainActor
    func testUpdateRecipe() {
        let recipe = service.createRecipe(title: "Original", servings: 2, instructions: "Test instructions")
        XCTAssertNotNil(recipe)

        service.updateRecipe(recipe!, title: "Updated Title", servings: 6)

        XCTAssertEqual(recipe?.title, "Updated Title")
        XCTAssertEqual(recipe?.servings, 6)
        XCTAssertNil(service.errorMessage)
    }

    @MainActor
    func testDeleteRecipe() throws {
        let recipe = service.createRecipe(title: "To Delete", servings: 1, instructions: "Test instructions")
        XCTAssertNotNil(recipe)

        let recipeID = recipe!.objectID
        service.deleteRecipe(recipe!)

        // Verify recipe is gone
        let deleted = try? context.existingObject(with: recipeID)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted)
        XCTAssertNil(service.errorMessage)
    }

    @MainActor
    func testToggleFavorite() {
        let recipe = service.createRecipe(title: "Favorite Test", servings: 1, instructions: "Test instructions")
        XCTAssertNotNil(recipe)
        XCTAssertFalse(recipe!.isFavorite)

        service.toggleFavorite(recipe!)
        XCTAssertTrue(recipe!.isFavorite)

        service.toggleFavorite(recipe!)
        XCTAssertFalse(recipe!.isFavorite)
    }

    // MARK: - Duplicate

    @MainActor
    func testDuplicateRecipe() {
        let original = service.createRecipe(title: "Original Recipe", servings: 4, prepTime: 10, cookTime: 30, instructions: "Test instructions")
        XCTAssertNotNil(original)

        // Add an ingredient to the original
        let ingredient = service.addIngredient(
            to: original!, name: "flour",
            numericValue: 2.0, standardUnit: "cups",
            displayText: "2 cups", isParseable: true, parseConfidence: 1.0
        )
        XCTAssertNotNil(ingredient)

        let copy = service.duplicateRecipe(original!)
        XCTAssertNotNil(copy)
        XCTAssertEqual(copy?.title, "Original Recipe (Copy)")
        XCTAssertEqual(copy?.servings, 4)
        XCTAssertEqual(copy?.prepTime, 10)
        XCTAssertEqual(copy?.cookTime, 30)
        XCTAssertNotEqual(copy?.id, original?.id)

        // Verify ingredients were copied with structured data
        let copiedIngredients = copy?.ingredients as? Set<Ingredient>
        XCTAssertEqual(copiedIngredients?.count, 1)

        if let copiedIngredient = copiedIngredients?.first {
            XCTAssertEqual(copiedIngredient.name, "flour")
            XCTAssertEqual(copiedIngredient.numericValue, 2.0, accuracy: 0.01)
            XCTAssertEqual(copiedIngredient.standardUnit, "cups")
            XCTAssertEqual(copiedIngredient.displayText, "2 cups")
            XCTAssertTrue(copiedIngredient.isParseable)
            XCTAssertEqual(copiedIngredient.parseConfidence, 1.0, accuracy: 0.01)
            XCTAssertNotEqual(copiedIngredient.id, ingredient?.id)
        }
    }

    // MARK: - Recipe Attribution (M10.4.0)

    @MainActor
    func testCreateRecipeWithAttribution() {
        let recipe = service.createRecipe(
            title: "Imported Recipe", servings: 4,
            instructions: "Test instructions",
            imageURL: "https://example.com/hero.jpg",
            author: "Julia Child"
        )

        XCTAssertNotNil(recipe)
        XCTAssertEqual(recipe?.imageURL, "https://example.com/hero.jpg")
        XCTAssertEqual(recipe?.author, "Julia Child")
    }

    @MainActor
    func testCreateRecipeWithoutAttributionDefaultsToNil() {
        let recipe = service.createRecipe(title: "Manual Recipe", servings: 2, instructions: "Test instructions")

        XCTAssertNotNil(recipe)
        XCTAssertNil(recipe?.imageURL)
        XCTAssertNil(recipe?.author)
    }

    @MainActor
    func testDuplicateRecipePreservesAttribution() {
        let original = service.createRecipe(
            title: "Attributed Recipe", servings: 4,
            instructions: "Test instructions",
            imageURL: "https://example.com/photo.jpg",
            author: "Kenji López-Alt"
        )
        XCTAssertNotNil(original)

        let copy = service.duplicateRecipe(original!)
        XCTAssertNotNil(copy)
        XCTAssertEqual(copy?.imageURL, "https://example.com/photo.jpg")
        XCTAssertEqual(copy?.author, "Kenji López-Alt")
    }

    @MainActor
    func testToRecipeFormDataMapsAttribution() {
        var draft = ImportDraftRecipe.empty()
        draft.title = ImportField(value: "Test Recipe", confidence: .high, source: .jsonLD)
        draft.imageURL = ImportField(value: "https://example.com/img.jpg", confidence: .high, source: .jsonLD)
        draft.author = ImportField(value: "Test Author", confidence: .high, source: .jsonLD)

        let formData = draft.toRecipeFormData()

        XCTAssertEqual(formData.imageURL, "https://example.com/img.jpg")
        XCTAssertEqual(formData.author, "Test Author")
    }

    @MainActor
    func testToRecipeFormDataNilAttributionDefaults() {
        let draft = ImportDraftRecipe.empty()

        let formData = draft.toRecipeFormData()

        XCTAssertNil(formData.imageURL)
        XCTAssertNil(formData.author)
    }

    // MARK: - Ingredient Operations

    @MainActor
    func testAddIngredientWithStructuredData() {
        let recipe = service.createRecipe(title: "Test Recipe", servings: 4, instructions: "Test instructions")
        XCTAssertNotNil(recipe)

        let ingredient = service.addIngredient(
            to: recipe!, name: "butter",
            numericValue: 3.0, standardUnit: "tbsp",
            displayText: "3 tbsp", isParseable: true, parseConfidence: 0.95
        )

        XCTAssertNotNil(ingredient)
        XCTAssertEqual(ingredient?.name, "butter")
        XCTAssertEqual(ingredient?.numericValue ?? 0, 3.0, accuracy: 0.01)
        XCTAssertEqual(ingredient?.standardUnit, "tbsp")
        XCTAssertEqual(ingredient?.displayText, "3 tbsp")
        XCTAssertTrue(ingredient?.isParseable ?? false)
        XCTAssertEqual(ingredient?.parseConfidence ?? 0, 0.95, accuracy: 0.01)
        XCTAssertEqual(ingredient?.recipe, recipe)
    }

    @MainActor
    func testAddIngredientFromParsedStructuredQuantity() {
        let recipe = service.createRecipe(title: "Test Recipe", servings: 4, instructions: "Test instructions")
        XCTAssertNotNil(recipe)

        let parsed = StructuredQuantity(
            numericValue: 2.0,
            standardUnit: "cups",
            displayText: "2 cups",
            isParseable: true,
            parseConfidence: 1.0,
            parserUsed: "regex"
        )

        let ingredient = service.addIngredient(to: recipe!, parsed: parsed, name: "flour")

        XCTAssertNotNil(ingredient)
        XCTAssertEqual(ingredient?.name, "flour")
        XCTAssertEqual(ingredient?.numericValue ?? 0, 2.0, accuracy: 0.01)
        XCTAssertEqual(ingredient?.standardUnit, "cups")
        XCTAssertEqual(ingredient?.displayText, "2 cups")
        XCTAssertTrue(ingredient?.isParseable ?? false)
    }

    @MainActor
    func testRemoveIngredient() throws {
        let recipe = service.createRecipe(title: "Test Recipe", servings: 4, instructions: "Test instructions")
        XCTAssertNotNil(recipe)

        let ingredient = service.addIngredient(to: recipe!, name: "salt", displayText: "salt")
        XCTAssertNotNil(ingredient)

        let ingredientID = ingredient!.objectID
        service.removeIngredient(ingredient!)

        let deleted = try? context.existingObject(with: ingredientID)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted)
    }

    // MARK: - Error Handling

    @MainActor
    func testErrorMessageClearsOnSuccess() {
        // Force an error by setting one manually
        service.errorMessage = "Previous error"

        // A successful operation should clear it
        let recipe = service.createRecipe(title: "Test", servings: 1, instructions: "Test instructions")
        XCTAssertNotNil(recipe)
        XCTAssertNil(service.errorMessage, "errorMessage should clear on successful operation")
    }

    // MARK: - Zone Assignment Regression (fix-groceryitem-multi-zone-assignment)
    //
    // Verifies Ingredient co-locates with parent Recipe's persistent store. Same
    // class of bug as the GroceryListItem/p20 zone-conflict (error 134040) on
    // 2026-04-21 — Ingredient shares the child-inheritance pattern from ADR 014.
    // See WeeklyListServiceTests for the GroceryListItem side.

    @MainActor
    func testAddIngredient_inSharedStoreRecipe_ingredientLandsInSharedStore() throws {
        // Create recipe directly in the shared store. See companion
        // WeeklyListService test for why direct init + assign + save is needed
        // (service.createRecipe saves internally; Core Data refuses to reassign
        // an already-saved object).
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Carbonara"
        recipe.servings = 4
        recipe.instructions = "Mix"
        recipe.dateCreated = Date()
        context.assign(recipe, to: persistence.sharedStore)
        try context.save()

        let ingredient = service.addIngredient(
            to: recipe, name: "2 cups flour",
            numericValue: 2.0, standardUnit: "cups",
            displayText: "2 cups"
        )

        XCTAssertNotNil(ingredient, "addIngredient returned nil. service.errorMessage: \(service.errorMessage ?? "(none)")")
        XCTAssertEqual(ingredient?.objectID.persistentStore?.url?.lastPathComponent,
                       recipe.objectID.persistentStore?.url?.lastPathComponent,
                       "Ingredient must be co-located with parent recipe's persistent store to prevent CloudKit zone conflict (134040)")
        XCTAssertEqual(ingredient?.objectID.persistentStore?.url?.lastPathComponent,
                       "forager_shared.sqlite",
                       "Recipe was placed in shared store; ingredient should follow")
    }

    @MainActor
    func testAddIngredient_inPrivateStoreRecipe_ingredientLandsInPrivateStore() throws {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Personal Recipe"
        recipe.servings = 2
        recipe.instructions = "Cook"
        recipe.dateCreated = Date()
        context.assign(recipe, to: persistence.privateStore)
        try context.save()

        let ingredient = service.addIngredient(
            to: recipe, name: "1 onion, diced",
            numericValue: 1.0, standardUnit: nil,
            displayText: "1"
        )

        XCTAssertNotNil(ingredient, "addIngredient returned nil. service.errorMessage: \(service.errorMessage ?? "(none)")")
        XCTAssertEqual(ingredient?.objectID.persistentStore?.url?.lastPathComponent,
                       recipe.objectID.persistentStore?.url?.lastPathComponent,
                       "Ingredient must be co-located with parent recipe")
        XCTAssertEqual(ingredient?.objectID.persistentStore?.url?.lastPathComponent,
                       "forager.sqlite",
                       "Recipe was placed in private store; ingredient should follow")
    }
}
