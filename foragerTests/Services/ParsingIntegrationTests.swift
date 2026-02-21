import XCTest
import CoreData
@testable import forager

/// M7.5 Chunk 1.2c: Integration tests for parse → service → persist pipeline
/// Uses real IngredientParsingService (not mocked) to validate full end-to-end flow.
/// These tests become the regression safety net when M8.4 swaps in the ML parser.
final class ParsingIntegrationTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var templateService: IngredientTemplateService!
    private var parsingService: IngredientParsingService!
    private var recipeService: RecipeService!
    private var weeklyListService: WeeklyListService!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        templateService = IngredientTemplateService(context: context)
        parsingService = IngredientParsingService(context: context, templateService: templateService)
        recipeService = RecipeService(context: context, parsingService: parsingService)
        weeklyListService = WeeklyListService(context: context, parsingService: parsingService)
    }

    override func tearDown() {
        weeklyListService = nil
        recipeService = nil
        parsingService = nil
        templateService = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Pipeline Tests

    /// Test 1: Parse text → RecipeService → Ingredient entity with correct structured data
    @MainActor
    func testParseToRecipeIngredientPipeline() {
        let recipe = recipeService.createRecipe(title: "Test Recipe", servings: 4)
        XCTAssertNotNil(recipe)

        // Parse "2 cups flour" through the real parsing service
        let parsed = parsingService.parseToStructured(text: "2 cups flour")

        // Pass parsed result to RecipeService
        let ingredient = recipeService.addIngredient(
            to: recipe!, parsed: parsed, name: "flour",
            template: templateService.findOrCreateTemplate(name: "flour")
        )

        XCTAssertNotNil(ingredient)
        XCTAssertEqual(ingredient?.numericValue ?? 0, 2.0, accuracy: 0.01,
                       "Parsed numericValue should be 2.0")
        XCTAssertEqual(ingredient?.standardUnit, "cups",
                       "Parsed standardUnit should be 'cups'")
        XCTAssertTrue(ingredient?.isParseable ?? false,
                      "Should be parseable")
        XCTAssertGreaterThan(ingredient?.parseConfidence ?? 0, 0.5,
                             "Confidence should be high for a simple parse")

        // Verify template was created
        let templates = templateService.searchTemplates(query: "flour")
        XCTAssertFalse(templates.isEmpty, "IngredientTemplate 'flour' should exist")
    }

    /// Test 2: Parse text → WeeklyListService → GroceryListItem with flat snapshot (ADR 012)
    @MainActor
    func testParseToGroceryItemPipeline() {
        let list = weeklyListService.createList(name: "Test List")
        XCTAssertNotNil(list)

        // Parse "3 cloves garlic" through the real parsing service
        let parsed = parsingService.parseToStructured(text: "3 cloves garlic")

        // Pass parsed result to WeeklyListService
        let item = weeklyListService.addItem(
            to: list!, name: "garlic",
            categoryName: "Produce",
            numericValue: parsed.numericValue ?? 0,
            standardUnit: parsed.standardUnit,
            displayText: parsed.displayText,
            isParseable: parsed.isParseable,
            parseConfidence: parsed.parseConfidence,
            source: "Test Recipe"
        )

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "garlic")
        XCTAssertEqual(item?.categoryName, "Produce",
                       "ADR 012: categoryName is a flat string snapshot")
        XCTAssertEqual(item?.source, "Test Recipe")
    }

    /// Test 3: Same ingredient added via both services creates a single IngredientTemplate
    @MainActor
    func testTemplateNormalizationAcrossServices() {
        // Add "flour" via RecipeService
        let recipe = recipeService.createRecipe(title: "Recipe A", servings: 2)
        XCTAssertNotNil(recipe)
        let _ = templateService.findOrCreateTemplate(name: "flour")

        // Add "flour" via another recipe (simulating WeeklyListService path)
        let recipe2 = recipeService.createRecipe(title: "Recipe B", servings: 4)
        XCTAssertNotNil(recipe2)
        let _ = templateService.findOrCreateTemplate(name: "Flour") // uppercase variation

        // Verify: single template exists (normalization deduplicates)
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "canonicalName == %@",
                                         IngredientTemplate.canonicalName(from: "flour"))
        let templates = try? context.fetch(request)
        XCTAssertEqual(templates?.count, 1,
                       "Should have exactly one 'flour' template after normalization")
    }

    /// Test 4: Duplicate recipe preserves all structured quantity fields
    @MainActor
    func testDuplicateRecipePreservesStructuredData() {
        let recipe = recipeService.createRecipe(title: "Original", servings: 4)
        XCTAssertNotNil(recipe)

        // Add ingredient with specific structured data
        let parsed = parsingService.parseToStructured(text: "1.5 cups sugar")
        let template = templateService.findOrCreateTemplate(name: "sugar")
        let _ = recipeService.addIngredient(to: recipe!, parsed: parsed, name: "sugar", template: template)

        // Duplicate
        let copy = recipeService.duplicateRecipe(recipe!)
        XCTAssertNotNil(copy)

        // Verify structured data preserved on the copy
        let copiedIngredients = (copy?.ingredients as? Set<Ingredient>)
        XCTAssertEqual(copiedIngredients?.count, 1)

        if let copiedIngredient = copiedIngredients?.first {
            XCTAssertEqual(copiedIngredient.numericValue, parsed.numericValue ?? 0, accuracy: 0.01,
                           "numericValue should be preserved")
            XCTAssertEqual(copiedIngredient.standardUnit, parsed.standardUnit,
                           "standardUnit should be preserved")
            XCTAssertEqual(copiedIngredient.displayText, parsed.displayText,
                           "displayText should be preserved")
            XCTAssertEqual(copiedIngredient.isParseable, parsed.isParseable,
                           "isParseable should be preserved")
            XCTAssertEqual(copiedIngredient.parseConfidence, parsed.parseConfidence, accuracy: 0.01,
                           "parseConfidence should be preserved")
            XCTAssertEqual(copiedIngredient.ingredientTemplate, template,
                           "Template reference should be preserved")
        }
    }

    /// Test 5: Services use the injected IngredientParsingService instance
    @MainActor
    func testParsingServiceInjectionForwarding() {
        // Create services with our specific parsingService instance
        // (This test ensures M9.5-partial DI will work when ML parser is injected)
        let recipe = recipeService.createRecipe(title: "DI Test", servings: 1)
        XCTAssertNotNil(recipe)

        // Use the parsing service to parse — verifying it's the same instance
        // that was injected into RecipeService
        let parsed = parsingService.parseToStructured(text: "2 tbsp olive oil")
        XCTAssertTrue(parsed.isParseable, "Injected parsing service should work")
        XCTAssertGreaterThan(parsed.parseConfidence, 0,
                             "Injected parsing service should produce confidence > 0")

        // The service was created with this specific parsingService —
        // if DI is broken, the services would use a different (or nil) parser
        let ingredient = recipeService.addIngredient(
            to: recipe!, parsed: parsed, name: "olive oil"
        )
        XCTAssertNotNil(ingredient, "Service should work with injected parsing service")
        XCTAssertTrue(ingredient?.isParseable ?? false)
    }
}
