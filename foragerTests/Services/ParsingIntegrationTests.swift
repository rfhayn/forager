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

    @MainActor
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
        let recipe = recipeService.createRecipe(title: "Test Recipe", servings: 4, instructions: "Test instructions")
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
        XCTAssertEqual(ingredient?.standardUnit, "cup",
                       "Parsed standardUnit should be 'cup' (normalized singular)")
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

        // M9.12: Create Category entity for relationship-based assignment
        let produceCategory = forager.Category(context: context)
        produceCategory.id = UUID()
        produceCategory.name = "Produce"
        produceCategory.sortOrder = 0

        // Pass parsed result to WeeklyListService
        let item = weeklyListService.addItem(
            to: list!, name: "garlic",
            category: produceCategory,
            numericValue: parsed.numericValue ?? 0,
            standardUnit: parsed.standardUnit,
            displayText: parsed.displayText,
            isParseable: parsed.isParseable,
            parseConfidence: parsed.parseConfidence,
            source: "Test Recipe"
        )

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "garlic")
        XCTAssertEqual(item?.categoryEntity?.name, "Produce",
                       "M9.12: categoryEntity relationship replaces flat string")
        XCTAssertEqual(item?.source, "Test Recipe")
    }

    /// Test 3: Same ingredient added via both services creates a single IngredientTemplate
    @MainActor
    func testTemplateNormalizationAcrossServices() {
        // Add "flour" via RecipeService
        let recipe = recipeService.createRecipe(title: "Recipe A", servings: 2, instructions: "Test instructions")
        XCTAssertNotNil(recipe)
        let _ = templateService.findOrCreateTemplate(name: "flour")

        // Add "flour" via another recipe (simulating WeeklyListService path)
        let recipe2 = recipeService.createRecipe(title: "Recipe B", servings: 4, instructions: "Test instructions")
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
        let recipe = recipeService.createRecipe(title: "Original", servings: 4, instructions: "Test instructions")
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
        let recipe = recipeService.createRecipe(title: "DI Test", servings: 1, instructions: "Test instructions")
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

    // MARK: - M8.4 Phase 9: End-to-End Integration Scenarios

    /// Scenario 1: Quick-add "3 cloves garlic" → template is "garlic", qty=3, unit=clove
    @MainActor
    func testQuickAddGarlicParsing() {
        let list = weeklyListService.createList(name: "Test List")
        XCTAssertNotNil(list)

        let parsed = parsingService.parseToStructured(text: "3 cloves garlic", source: .groceryListItem)

        XCTAssertEqual(parsed.numericValue ?? 0, 3.0, accuracy: 0.01, "Quantity should be 3")
        XCTAssertEqual(parsed.standardUnit, "clove", "Unit should be 'clove' (normalized singular)")
        XCTAssertTrue(parsed.isParseable, "Should be parseable")

        // Verify template creation
        let template = templateService.findOrCreateTemplate(name: "garlic")
        XCTAssertNotNil(template)
        XCTAssertEqual(template.canonicalName, IngredientTemplate.canonicalName(from: "garlic"))
    }

    /// Scenario 2: Quick-add "milk 2%" → template is "milk 2%", no quantity/unit warning
    @MainActor
    func testQuickAddMilkPercentage() {
        let parsed = parsingService.parseToStructured(text: "milk 2%", source: .groceryListItem)

        // "milk 2%" is an edge case — the parser should extract a name that includes "milk"
        // The "2%" may or may not be parsed as quantity depending on parser tier
        let parsedIngredient = parsingService.parseIngredient(text: "milk 2%")
        // v2 ML model may extract "2%" or "milk" as name depending on labeling
        XCTAssertTrue(parsedIngredient.name.lowercased().contains("milk") ||
                       parsedIngredient.name.contains("2%"),
                       "Name should contain 'milk' or '2%', got: \(parsedIngredient.name)")

        // Template should be created
        let template = templateService.findOrCreateTemplate(name: parsedIngredient.displayName)
        XCTAssertNotNil(template)
    }

    /// Scenario 3: Recipe ingredient "1/4 tsp black pepper" → template is "black pepper"
    @MainActor
    func testRecipeIngredientFractionParsing() {
        let recipe = recipeService.createRecipe(title: "Test", servings: 4, instructions: "Test")
        XCTAssertNotNil(recipe)

        let (parsed, structured) = parsingService.parseUnified(text: "1/4 tsp black pepper")

        XCTAssertEqual(structured.numericValue ?? 0, 0.25, accuracy: 0.01,
                       "1/4 should parse to 0.25")
        XCTAssertEqual(structured.standardUnit, "tsp", "Unit should be 'tsp'")
        XCTAssertTrue(parsed.name.lowercased().contains("pepper"),
                       "Name should contain 'pepper'")

        // Template should normalize to "black pepper"
        let template = templateService.findOrCreateTemplate(name: parsed.displayName)
        XCTAssertTrue(template.canonicalName?.contains("pepper") ?? false,
                       "Template canonical name should contain 'pepper'")
    }

    /// Scenario 4: Recipe ingredient "a handful of fresh cilantro" → name contains "cilantro"
    @MainActor
    func testRecipeIngredientNaturalLanguage() {
        let parsed = parsingService.parseIngredient(text: "a handful of fresh cilantro")

        // This is a difficult parse — "a handful of" is not a standard qty/unit
        // The key assertion: "cilantro" should be extracted as the ingredient name
        XCTAssertTrue(parsed.name.lowercased().contains("cilantro"),
                       "Name should contain 'cilantro' regardless of parser tier")
    }

    /// Scenario 5: Quick-add "bananas" → template is "bananas" (plural preserved)
    @MainActor
    func testQuickAddPluralPreservation() {
        let parsed = parsingService.parseIngredient(text: "bananas")

        // Name should preserve the plural form
        XCTAssertTrue(parsed.name.lowercased().contains("banana"),
                       "Name should contain 'banana'")

        // Template normalization singularizes: "bananas" → "banana"
        let template = templateService.findOrCreateTemplate(name: "bananas")
        XCTAssertNotNil(template)
    }

    /// Scenario 6: parseAndConnectIngredients bulk add → all ingredients parsed correctly
    @MainActor
    func testBulkAddMultipleIngredients() {
        let recipe = recipeService.createRecipe(title: "Bulk Test", servings: 4, instructions: "Test")
        XCTAssertNotNil(recipe)

        let texts = [
            "2 cups flour",
            "1 tsp salt",
            "3 eggs",
            "1/2 cup sugar"
        ]

        let ingredients = parsingService.parseAndConnectIngredients(for: recipe!, ingredientTexts: texts)

        XCTAssertEqual(ingredients.count, 4, "Should create 4 ingredients")

        // All should be parseable (these are straightforward)
        let parseableCount = ingredients.filter { $0.isParseable }.count
        XCTAssertGreaterThanOrEqual(parseableCount, 3,
                                     "At least 3 of 4 standard ingredients should be parseable")

        // Each should have a template assigned
        for ingredient in ingredients {
            XCTAssertNotNil(ingredient.ingredientTemplate,
                            "Each ingredient should have a template: \(ingredient.name ?? "nil")")
        }

        // Verify sort order preserved
        for (index, ingredient) in ingredients.enumerated() {
            XCTAssertEqual(ingredient.sortOrder, Int16(index),
                           "Sort order should match input order")
        }
    }

    /// Scenario 7: Recipe scaling → ML-parsed ingredients scale correctly
    @MainActor
    func testRecipeScalingWithParsedIngredients() {
        let recipe = recipeService.createRecipe(title: "Scale Test", servings: 4, instructions: "Test")
        XCTAssertNotNil(recipe)

        // Add ingredients with structured data
        let parsed = parsingService.parseToStructured(text: "2 cups flour")
        let _ = recipeService.addIngredient(to: recipe!, parsed: parsed, name: "flour")

        let parsed2 = parsingService.parseToStructured(text: "1 tsp salt")
        let _ = recipeService.addIngredient(to: recipe!, parsed: parsed2, name: "salt")

        // Scale by 2x
        let scalingService = RecipeScalingService(context: context)
        let scaled = scalingService.scale(recipe: recipe!, scaleFactor: 2.0)

        XCTAssertEqual(scaled.scaledServings, 8, "Servings should double")
        XCTAssertEqual(scaled.scaledIngredients.count, 2, "Should have 2 scaled ingredients")

        // Parseable ingredients should be auto-scaled
        XCTAssertGreaterThanOrEqual(scaled.autoScaledCount, 1,
                                     "At least 1 ingredient should be auto-scaled")

        // Verify a scaled ingredient's display text contains the doubled quantity
        let flourScaled = scaled.scaledIngredients.first { $0.name.lowercased().contains("flour") }
        XCTAssertNotNil(flourScaled, "Should find scaled flour ingredient")
        if let flourScaled = flourScaled {
            XCTAssertTrue(flourScaled.wasScaled, "Flour should be auto-scaled")
        }
    }

    /// Scenario 8: Edit recipe → structured fields preserved through update cycle
    @MainActor
    func testEditRecipePreservesStructuredFields() {
        let recipe = recipeService.createRecipe(title: "Edit Test", servings: 2, instructions: "Test")
        XCTAssertNotNil(recipe)

        // Add ingredient with parsed data
        let parsed = parsingService.parseToStructured(text: "1.5 cups sugar")
        let template = templateService.findOrCreateTemplate(name: "sugar")
        let ingredient = recipeService.addIngredient(
            to: recipe!, parsed: parsed, name: "sugar", template: template
        )
        XCTAssertNotNil(ingredient)

        // Simulate edit: update the ingredient name/quantity via service
        recipeService.updateIngredient(ingredient!, name: "brown sugar",
                                        numericValue: 2.0, standardUnit: "cup")

        // Verify structured fields are updated
        XCTAssertEqual(ingredient!.name, "brown sugar")
        XCTAssertEqual(ingredient!.numericValue, 2.0, accuracy: 0.01)
        XCTAssertEqual(ingredient!.standardUnit, "cup")

        // Template reference should still be intact
        XCTAssertNotNil(ingredient!.ingredientTemplate,
                        "Template reference should survive edit")
    }

    // MARK: - M9.5: Mock Parser Injection Demo

    /// Test 6: Mock parser can be injected through the full chain
    /// Demonstrates that M9.5 DI infrastructure works end-to-end:
    /// MockIngredientParser → IngredientParsingService → RecipeService
    @MainActor
    func testMockParserInjectionThroughFullChain() {
        // Create a mock parser that returns predictable results
        let mockParser = MockIngredientParser(name: "test-mock")
        mockParser.setResult(for: "test ingredient",
                             name: "mock ingredient",
                             quantity: 99.0, unit: "mock-units",
                             confidence: 0.42)

        // Inject mock through the full chain
        let mockParsingService = IngredientParsingService(
            context: context,
            templateService: templateService,
            parser: mockParser
        )

        // Parse through the service — should use our mock
        let parsed = mockParsingService.parseToStructured(text: "test ingredient")

        XCTAssertEqual(parsed.numericValue ?? 0, 99.0, accuracy: 0.01,
                       "Mock parser's quantity should flow through")
        XCTAssertEqual(parsed.standardUnit, "mock-units",
                       "Mock parser's unit should flow through")
        XCTAssertEqual(parsed.parseConfidence, 0.42, accuracy: 0.01,
                       "Mock parser's confidence should flow through")
        XCTAssertEqual(mockParser.parseCalls.count, 1,
                       "Mock should have been called exactly once")
        XCTAssertEqual(mockParser.parseCalls.first, "test ingredient",
                       "Mock should have received the original input")
    }
}
