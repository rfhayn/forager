//
//  OCRLineClassifierTests.swift
//  foragerTests
//
//  Tests for M10.2.4: Heuristic line classification
//  Covers all scoring paths, section headers, context boosting, and edge cases.
//

import XCTest
@testable import forager

final class OCRLineClassifierTests: XCTestCase {

    // MARK: - Title Detection

    func testFirstLineWithTitleCase_classifiedAsTitle() {
        let lines = [OCRLine.fromText("Classic Chicken Parmesan")]
        let result = OCRLineClassifier.classifyLines(lines)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].type, .title)
    }

    func testFirstLineStartingWithNumber_notTitle() {
        let lines = [
            OCRLine.fromText("2 cups flour"),
            OCRLine.fromText("1 tsp salt")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        XCTAssertEqual(result[0].type, .ingredient)
    }

    // MARK: - Ingredient Detection

    func testLineStartingWithNumber_classifiedAsIngredient() {
        let lines = [
            OCRLine.fromText("Garlic Bread"),
            OCRLine.fromText("2 cups all-purpose flour")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let ingredientLine = result.first(where: { $0.text == "2 cups all-purpose flour" })
        XCTAssertEqual(ingredientLine?.type, .ingredient)
    }

    func testLineWithFractionCharacter_classifiedAsIngredient() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("½ cup sugar")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let ingredientLine = result.first(where: { $0.text == "½ cup sugar" })
        XCTAssertEqual(ingredientLine?.type, .ingredient)
    }

    func testLineWithUnitWords_classifiedAsIngredient() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("3 tablespoons olive oil")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let ingredientLine = result.first(where: { $0.text == "3 tablespoons olive oil" })
        XCTAssertEqual(ingredientLine?.type, .ingredient)
    }

    func testMultipleIngredientLines_allDetected() {
        let lines = [
            OCRLine.fromText("Simple Pasta"),
            OCRLine.fromText("Ingredients:"),
            OCRLine.fromText("1 lb pasta"),
            OCRLine.fromText("2 cups marinara sauce"),
            OCRLine.fromText("1/4 cup parmesan cheese")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let ingredients = result.filter { $0.type == .ingredient }
        XCTAssertGreaterThanOrEqual(ingredients.count, 3)
    }

    // MARK: - Instruction Detection

    func testNumberedStep_classifiedAsInstruction() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("1. Preheat the oven to 350°F and prepare a baking sheet with parchment paper.")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let instruction = result.first(where: { $0.text.hasPrefix("1.") })
        XCTAssertEqual(instruction?.type, .instruction)
    }

    func testImperativeVerb_classifiedAsInstruction() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("Instructions:"),
            OCRLine.fromText("Mix the flour and sugar together in a large bowl until well combined.")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let instruction = result.first(where: { $0.text.hasPrefix("Mix") })
        XCTAssertEqual(instruction?.type, .instruction)
    }

    func testStepPrefix_classifiedAsInstruction() {
        let lines = [
            OCRLine.fromText("My Recipe"),
            OCRLine.fromText("Step 1: Combine all dry ingredients in a bowl and whisk until evenly distributed.")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let instruction = result.first(where: { $0.text.hasPrefix("Step") })
        XCTAssertEqual(instruction?.type, .instruction)
    }

    // MARK: - Metadata Detection

    func testServingsLine_classifiedAsMetadata() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("Serves 4")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let metadata = result.first(where: { $0.text == "Serves 4" })
        XCTAssertEqual(metadata?.type, .metadata)
    }

    func testPrepTimeLine_classifiedAsMetadata() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("Prep time: 15 minutes")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let metadata = result.first(where: { $0.text.contains("Prep time") })
        XCTAssertEqual(metadata?.type, .metadata)
    }

    func testCookTimeLine_classifiedAsMetadata() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("Cook time: 30 min")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let metadata = result.first(where: { $0.text.contains("Cook time") })
        XCTAssertEqual(metadata?.type, .metadata)
    }

    // MARK: - Section Headers

    func testIngredientsHeader_classifiedAsSectionHeader() {
        let lines = [
            OCRLine.fromText("My Recipe"),
            OCRLine.fromText("Ingredients:")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let header = result.first(where: { $0.text == "Ingredients:" })
        XCTAssertEqual(header?.type, .sectionHeader)
    }

    func testDirectionsHeader_classifiedAsSectionHeader() {
        let lines = [
            OCRLine.fromText("My Recipe"),
            OCRLine.fromText("Directions:")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let header = result.first(where: { $0.text == "Directions:" })
        XCTAssertEqual(header?.type, .sectionHeader)
    }

    func testMethodHeader_classifiedAsSectionHeader() {
        let lines = [
            OCRLine.fromText("My Recipe"),
            OCRLine.fromText("Method:")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let header = result.first(where: { $0.text == "Method:" })
        XCTAssertEqual(header?.type, .sectionHeader)
    }

    // MARK: - Section Context Boosting

    func testWeakLineAfterIngredientHeader_inheritsIngredientType() {
        let lines = [
            OCRLine.fromText("My Recipe"),
            OCRLine.fromText("Ingredients:"),
            OCRLine.fromText("salt"),           // Short, ambiguous line
            OCRLine.fromText("pepper")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let saltLine = result.first(where: { $0.text == "salt" })
        let pepperLine = result.first(where: { $0.text == "pepper" })
        XCTAssertEqual(saltLine?.type, .ingredient)
        XCTAssertEqual(pepperLine?.type, .ingredient)
    }

    // MARK: - Empty Input

    func testEmptyInput_returnsEmptyResults() {
        let result = OCRLineClassifier.classifyLines([])
        XCTAssertTrue(result.isEmpty)
    }

    func testBlankLines_skipped() {
        let lines = [
            OCRLine.fromText(""),
            OCRLine.fromText("  "),
            OCRLine.fromText("My Recipe"),
            OCRLine.fromText("")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "My Recipe")
    }

    // MARK: - Full Recipe Classification

    func testFullRecipe_allSectionsDetected() {
        let lines = [
            OCRLine.fromText("Classic Pancakes"),
            OCRLine.fromText("Serves 4"),
            OCRLine.fromText("Prep time: 10 min"),
            OCRLine.fromText("Cook time: 15 min"),
            OCRLine.fromText("Ingredients:"),
            OCRLine.fromText("2 cups flour"),
            OCRLine.fromText("2 eggs"),
            OCRLine.fromText("1 cup milk"),
            OCRLine.fromText("Instructions:"),
            OCRLine.fromText("1. Mix dry ingredients together"),
            OCRLine.fromText("2. Add wet ingredients and stir until just combined"),
            OCRLine.fromText("3. Cook on griddle until bubbles form, then flip")
        ]
        let result = OCRLineClassifier.classifyLines(lines)

        let types = result.map(\.type)
        XCTAssertTrue(types.contains(.title))
        XCTAssertTrue(types.contains(.ingredient))
        XCTAssertTrue(types.contains(.instruction))
        XCTAssertTrue(types.contains(.metadata))
        XCTAssertTrue(types.contains(.sectionHeader))
    }

    // MARK: - Unicode and Special Characters

    func testUnicodeFractions_detected() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("¼ tsp cinnamon")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let line = result.first(where: { $0.text.contains("cinnamon") })
        XCTAssertEqual(line?.type, .ingredient)
    }

    func testTemperatureWithDegreeSymbol_boostedInstruction() {
        let lines = [
            OCRLine.fromText("Test Recipe"),
            OCRLine.fromText("Instructions:"),
            OCRLine.fromText("Bake at 375°F for 25 minutes until golden brown and a toothpick comes out clean.")
        ]
        let result = OCRLineClassifier.classifyLines(lines)
        let instruction = result.first(where: { $0.text.contains("375°F") })
        XCTAssertEqual(instruction?.type, .instruction)
    }
}
