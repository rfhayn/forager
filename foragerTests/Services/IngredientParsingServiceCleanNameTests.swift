//
//  IngredientParsingServiceCleanNameTests.swift
//  foragerTests
//
//  M9.1.2: Tests for centralized extractCleanIngredientName
//  Pure logic — no Core Data required.
//

import XCTest
@testable import forager

final class IngredientParsingServiceCleanNameTests: XCTestCase {

    // MARK: - Standard Measurements

    func testStandardMeasurement() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "2 cups flour")
        XCTAssertEqual(result, "Flour")
    }

    func testFractionMeasurement() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "1/4 tsp black pepper")
        XCTAssertEqual(result, "Black Pepper")
    }

    func testUnicodeFraction() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "½ cup sugar")
        XCTAssertEqual(result, "Sugar")
    }

    func testCountUnit() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "3 cloves garlic")
        XCTAssertEqual(result, "Garlic")
    }

    // MARK: - Complex Patterns

    func testParenthetical() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "1 can (14.5 oz) diced tomatoes")
        XCTAssertTrue(result.contains("Tomatoes"), "Expected result to contain 'Tomatoes', got '\(result)'")
    }

    func testQualifierToTaste() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "salt to taste")
        XCTAssertEqual(result, "Salt")
    }

    func testDescriptiveAmount() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "a pinch of salt")
        XCTAssertEqual(result, "Salt")
    }

    // MARK: - Edge Cases

    func testNameOnly() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "butter")
        XCTAssertEqual(result, "Butter")
    }

    func testEmptyString() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "")
        XCTAssertEqual(result, "")
    }

    func testWhitespaceOnly() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "   ")
        XCTAssertEqual(result, "")
    }

    func testLeadingTrailingSpace() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "  2 cups flour  ")
        XCTAssertEqual(result, "Flour")
    }

    func testCapitalization() {
        let result = IngredientParsingService.extractCleanIngredientName(from: "2 tbsp olive oil")
        XCTAssertEqual(result, "Olive Oil")
    }
}
