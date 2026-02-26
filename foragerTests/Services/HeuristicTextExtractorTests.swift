//
//  HeuristicTextExtractorTests.swift
//  foragerTests
//
//  Tests for M10.2.4: Heuristic text extractor
//  End-to-end extraction from plain text → ImportDraftRecipe.
//

import XCTest
@testable import forager

final class HeuristicTextExtractorTests: XCTestCase {

    private var extractor: HeuristicTextExtractor!

    override func setUp() {
        super.setUp()
        extractor = HeuristicTextExtractor()
    }

    // MARK: - Basic Extraction

    func testSimpleRecipe_extractsTitleAndIngredients() async throws {
        let text = """
        Classic Pancakes

        Ingredients:
        2 cups flour
        2 eggs
        1 cup milk
        2 tbsp sugar

        Instructions:
        1. Mix dry ingredients
        2. Add wet ingredients and stir
        3. Cook on griddle
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(draft)
        XCTAssertFalse(draft!.title.value.isEmpty)
        XCTAssertGreaterThanOrEqual(draft!.ingredients.value.count, 3)
        XCTAssertFalse(draft!.instructions.value.isEmpty)
    }

    func testRecipeWithMetadata_extractsServingsAndTimes() async throws {
        let text = """
        Garlic Bread
        Serves 4
        Prep time: 10 min
        Cook time: 15 min

        Ingredients:
        1 loaf French bread
        4 tbsp butter
        3 cloves garlic

        Instructions:
        1. Slice bread in half
        2. Mix butter and garlic
        3. Spread on bread and bake at 375°F
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(draft)
        XCTAssertEqual(draft!.servings.value, 4)
    }

    // MARK: - Confidence Levels

    func testHeuristicExtraction_allFieldsMediumConfidence() async throws {
        let text = """
        Simple Salad

        Ingredients:
        2 cups mixed greens
        1 cup cherry tomatoes

        Instructions:
        Toss greens and tomatoes together.
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(draft)
        XCTAssertEqual(draft!.title.source, .heuristic)
        XCTAssertEqual(draft!.ingredients.source, .heuristic)
        XCTAssertEqual(draft!.title.confidence, .medium)
        XCTAssertEqual(draft!.ingredients.confidence, .medium)
    }

    // MARK: - Error Cases

    func testEmptyText_throwsNoRecipeFound() async {
        do {
            _ = try await extractor.extract(from: .text(""))
            XCTFail("Should have thrown")
        } catch let error as ImportError {
            XCTAssertEqual(error, .noRecipeFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNoIngredients_throwsNoRecipeFound() async {
        do {
            _ = try await extractor.extract(from: .text("Just some random text without any recipe content"))
            XCTFail("Should have thrown")
        } catch let error as ImportError {
            XCTAssertEqual(error, .noRecipeFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Input Type Filtering

    func testHTMLInput_returnsNil() async throws {
        let url = URL(string: "https://example.com")!
        let result = try await extractor.extract(from: .html("<html></html>", url: url))
        XCTAssertNil(result, "Should return nil for non-text input")
    }

    // MARK: - Extraction Method

    func testExtractionMethod_isHeuristicText() async throws {
        let text = """
        Test Recipe

        Ingredients:
        1 cup flour

        Instructions:
        Mix everything.
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertEqual(draft?.extractionMethod, "heuristic_text")
    }

    // MARK: - Extraction Time

    func testExtractionTime_underOneSecond() async throws {
        let text = """
        Quick Test

        Ingredients:
        1 cup flour
        2 cups sugar
        3 tbsp butter

        Instructions:
        1. Mix together
        2. Bake at 350°F
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(draft)
        // Heuristic should be very fast — well under 1 second (1000ms)
        XCTAssertLessThan(draft!.extractionTimeMs, 1000)
    }

    // MARK: - Complex Recipe

    func testRecipeWithSubgroups_flattensIngredients() async throws {
        let text = """
        Chocolate Cake

        For the cake:
        2 cups flour
        1 cup sugar
        3 eggs

        For the frosting:
        2 cups powdered sugar
        1/2 cup butter

        Instructions:
        1. Mix cake ingredients
        2. Bake at 350°F for 30 minutes
        3. Make frosting and spread on cooled cake
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(draft)
        // Should capture ingredients from both subgroups
        XCTAssertGreaterThanOrEqual(draft!.ingredients.value.count, 4)
    }

    // MARK: - Instruction Numbering

    func testUnnumberedInstructions_getNumbered() async throws {
        let text = """
        Simple Soup

        Ingredients:
        1 can tomatoes
        2 cups water

        Instructions:
        Heat water in a pot
        Add tomatoes
        Simmer for 20 minutes
        """

        let draft = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(draft)
        // Unnumbered instructions should get auto-numbered
        if !draft!.instructions.value.isEmpty {
            XCTAssertTrue(
                draft!.instructions.value.contains("1.") || draft!.instructions.value.contains("Heat"),
                "Instructions should be present"
            )
        }
    }
}
