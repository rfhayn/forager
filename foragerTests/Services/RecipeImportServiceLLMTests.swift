//
//  RecipeImportServiceLLMTests.swift
//  foragerTests
//
//  M10.6.4: Tests for LLM integration in RecipeImportService.
//  Verifies LLM-first path, fallback behavior, and telemetry logging.
//

import XCTest
import CoreData
@testable import forager

@MainActor
final class RecipeImportServiceLLMTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var importService: RecipeImportService!
    private var mockParser: MockLLMIngredientParser!

    private var persistence: PersistenceController!
    private var previousShared: PersistenceController!

    override func setUp() {
        super.setUp()

        // Dual-store in-memory controller (matches production dual-store shape so
        // RecipeImportService.persistAndFinish's `.shared.privateStore` lookup works).
        // (fix-test-harness-and-stale-assertions, 2026-04-19)
        persistence = PersistenceController(inMemory: true)
        previousShared = PersistenceController.shared
        PersistenceController.shared = persistence

        context = persistence.container.viewContext
        let templateService = IngredientTemplateService(context: context)
        let parsingService = IngredientParsingService(context: context, templateService: templateService)
        importService = RecipeImportService(context: context, parsingService: parsingService)

        mockParser = MockLLMIngredientParser()

        // Ensure LLM is disabled by default for isolation
        UserDefaults.standard.removeObject(forKey: "llmParsingEnabled")
        KeychainHelper.deleteLLMAPIKey()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "llmParsingEnabled")
        KeychainHelper.deleteLLMAPIKey()
        // Restore the shared controller so later tests aren't coupled to ours.
        if let previous = previousShared {
            PersistenceController.shared = previous
        }
        previousShared = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeDraft(
        title: String = "Test Recipe",
        ingredients: [String] = ["2 cups flour", "3 eggs"]
    ) -> ImportDraftRecipe {
        ImportDraftRecipe(
            title: ImportField(value: title, confidence: .high, source: .manual),
            ingredients: ImportField(value: ingredients, confidence: .high, source: .manual),
            instructions: ImportField(value: "Mix and bake.", confidence: .high, source: .manual),
            prepTimeMinutes: ImportField(value: 10, confidence: .medium, source: .manual),
            cookTimeMinutes: ImportField(value: 30, confidence: .medium, source: .manual),
            servings: ImportField(value: 4, confidence: .high, source: .manual),
            imageURL: ImportField(value: nil, confidence: .missing, source: .manual),
            author: ImportField(value: nil, confidence: .missing, source: .manual),
            sourceURL: nil,
            extractionMethod: "test",
            extractionTimeMs: 0
        )
    }

    // MARK: - 1. LLM Disabled → Pipeline Used

    func testSaveImportUsesPipelineWhenLLMDisabled() async {
        let draft = makeDraft()

        let result = await importService.saveImport(from: draft)

        XCTAssertNotNil(result, "Save should succeed via pipeline fallback")
        // Verify recipe was created
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = try? context.fetch(fetchRequest)
        XCTAssertEqual(recipes?.count, 1)
        XCTAssertEqual(recipes?.first?.title, "Test Recipe")

        // Verify ingredients were created
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        let ingredients = try? context.fetch(ingredientRequest)
        XCTAssertEqual(ingredients?.count, 2)
    }

    // MARK: - 2. Pipeline Fallback Creates Valid Ingredients

    func testPipelineFallbackCreatesIngredientsWithTemplates() async {
        let draft = makeDraft(ingredients: ["1 cup sugar"])

        let result = await importService.saveImport(from: draft)

        XCTAssertNotNil(result)
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        let ingredients = try? context.fetch(ingredientRequest)
        XCTAssertEqual(ingredients?.count, 1)
        // Template should be connected
        XCTAssertNotNil(ingredients?.first?.ingredientTemplate)
    }

    // MARK: - 3. Save Result Contains Uncategorized Templates

    func testSaveResultIncludesUncategorizedTemplates() async {
        let draft = makeDraft(ingredients: ["1 cup mystery ingredient"])

        let result = await importService.saveImport(from: draft)

        XCTAssertNotNil(result)
        // New template should be uncategorized
        XCTAssertFalse(result!.uncategorizedTemplateIDs.isEmpty)
    }

    // MARK: - 4. Replace Existing Recipe Works

    func testReplaceExistingRecipeUpdatesFields() async {
        // Create initial recipe
        let initialDraft = makeDraft(ingredients: ["1 cup flour"])
        let initialResult = await importService.saveImport(from: initialDraft)
        XCTAssertNotNil(initialResult)
        guard let initialResult = initialResult else { return }

        // Obtain permanent objectID after save
        try? context.obtainPermanentIDs(for: [context.object(with: initialResult.recipeObjectID)])
        let permanentID = context.object(with: initialResult.recipeObjectID).objectID

        // Replace with updated draft
        let updatedDraft = makeDraft(title: "Updated Recipe", ingredients: ["2 cups sugar", "3 eggs", "1 tsp vanilla"])

        let replaceResult = await importService.replaceExistingRecipe(
            objectID: permanentID,
            with: updatedDraft
        )

        XCTAssertNotNil(replaceResult)

        // Verify recipe was updated
        let recipe = try? context.existingObject(with: permanentID) as? Recipe
        XCTAssertEqual(recipe?.title, "Updated Recipe")

        // Verify ingredients were replaced (1 old → 3 new)
        let ingredients = recipe?.ingredients as? Set<Ingredient>
        XCTAssertEqual(ingredients?.count, 3)
    }

    // MARK: - 5. Empty Ingredients Still Saves Recipe

    func testEmptyIngredientsStillSavesRecipe() async {
        let draft = makeDraft(ingredients: [])

        let result = await importService.saveImport(from: draft)

        XCTAssertNotNil(result)
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let recipes = try? context.fetch(fetchRequest)
        XCTAssertEqual(recipes?.count, 1)
    }
}
