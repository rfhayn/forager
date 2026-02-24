//
//  RegexIngredientParserTests.swift
//  foragerTests
//
//  M8.3: Hybrid NLP Parser
//  Tests for RegexIngredientParser — regression + new pattern coverage
//

import XCTest
@testable import forager

final class RegexIngredientParserTests: XCTestCase {

    private var parser: RegexIngredientParser!

    override func setUp() {
        super.setUp()
        parser = RegexIngredientParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Regression Tests (existing behavior preserved)

    func testStandardQuantityUnitName() {
        let result = parser.parse("2 cups flour")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
        XCTAssertEqual(result.confidence, 1.0)
        XCTAssertEqual(result.parserUsed, "regex")
    }

    func testFractionQuantity() {
        let result = parser.parse("1/2 tsp salt")
        XCTAssertEqual(result.quantity, 0.5)
        XCTAssertEqual(result.unit, "tsp")
        XCTAssertEqual(result.name, "salt")
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testMixedFraction() {
        let result = parser.parse("1 1/2 tbsp olive oil")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "tbsp")
        XCTAssertEqual(result.name, "olive oil")
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testQuantityWithNoUnit() {
        let result = parser.parse("3 large eggs")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "large eggs")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testNameOnly() {
        let result = parser.parse("flour")
        XCTAssertNil(result.quantity)
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "flour")
        XCTAssertEqual(result.confidence, 0.0)
    }

    func testEmptyInput() {
        let result = parser.parse("")
        XCTAssertEqual(result.name, "Unknown ingredient")
        XCTAssertEqual(result.confidence, 0.0)
    }

    func testShortInput() {
        let result = parser.parse("ab")
        XCTAssertEqual(result.name, "ab")
        XCTAssertEqual(result.confidence, 0.0)
    }

    // MARK: - Unicode Fraction Tests

    func testUnicodeFractionWithUnit() {
        let result = parser.parse("½ cup sugar")
        XCTAssertEqual(result.quantity, 0.5)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "sugar")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.9)
    }

    func testUnicodeFractionQuarter() {
        let result = parser.parse("¼ tsp salt")
        XCTAssertEqual(result.quantity, 0.25)
        XCTAssertEqual(result.unit, "tsp")
        XCTAssertEqual(result.name, "salt")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.9)
    }

    func testUnicodeCombinedFraction() {
        let result = parser.parse("1½ cups flour")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.9)
    }

    func testUnicodeThird() {
        let result = parser.parse("⅓ cup brown sugar")
        XCTAssertNotNil(result.quantity)
        if let qty = result.quantity {
            XCTAssertEqual(qty, 1.0/3.0, accuracy: 0.01)
        }
        XCTAssertEqual(result.unit, "cup")
    }

    // MARK: - Range Pattern Tests

    func testRangeWithUnit() {
        let result = parser.parse("1-2 cups flour")
        XCTAssertEqual(result.quantity, 2.0) // Takes higher value
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
        XCTAssertNotNil(result.notes)
    }

    func testRangeWithCountUnit() {
        let result = parser.parse("2-3 cloves garlic")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.unit, "clove")
        XCTAssertEqual(result.name, "garlic")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testRangeWithoutUnit() {
        let result = parser.parse("2-3 eggs")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.name, "eggs")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testWordRangePattern() {
        let result = parser.parse("3 to 4 tbsp butter")
        XCTAssertEqual(result.quantity, 4.0)
        XCTAssertEqual(result.unit, "tbsp")
        XCTAssertEqual(result.name, "butter")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
    }

    func testEnDashRange() {
        let result = parser.parse("2–3 cups stock")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "stock")
    }

    // MARK: - Parenthetical Pattern Tests

    func testParentheticalWithUnit() {
        let result = parser.parse("1 can (14.5 oz) diced tomatoes")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "can")
        XCTAssertEqual(result.name, "diced tomatoes")
        XCTAssertEqual(result.notes, "14.5 oz")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testParentheticalSizeDescriptor() {
        let result = parser.parse("2 (6-inch) tortillas")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.name, "tortillas")
        XCTAssertEqual(result.notes, "6-inch")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    // MARK: - Compound Phrase Tests

    func testOneAndAHalf() {
        let result = parser.parse("one and a half cups milk")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "milk")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testWordNumber() {
        let result = parser.parse("two cups sugar")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "sugar")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testWordNumberNoUnit() {
        let result = parser.parse("three large eggs")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "large eggs")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.6)
    }

    // MARK: - Qualifier Pattern Tests

    func testSaltToTaste() {
        let result = parser.parse("salt to taste")
        XCTAssertEqual(result.name, "salt")
        XCTAssertEqual(result.notes, "to taste")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testPepperAsNeeded() {
        let result = parser.parse("pepper as needed")
        XCTAssertEqual(result.name, "pepper")
        XCTAssertEqual(result.notes, "as needed")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testCommaQualifier() {
        let result = parser.parse("garlic, minced")
        XCTAssertEqual(result.name, "garlic")
        XCTAssertEqual(result.notes, "minced")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testForGarnish() {
        let result = parser.parse("fresh parsley for garnish")
        XCTAssertEqual(result.notes, "for garnish")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    // MARK: - Descriptive Amount Tests

    func testPinchOfSalt() {
        let result = parser.parse("a pinch of salt")
        XCTAssertEqual(result.name, "salt")
        XCTAssertNotNil(result.quantity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testHandfulOfHerbs() {
        let result = parser.parse("a handful of herbs")
        XCTAssertEqual(result.name, "herbs")
        XCTAssertNotNil(result.quantity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testPinchOfCayenne() {
        let result = parser.parse("a pinch of cayenne")
        XCTAssertEqual(result.name, "cayenne")
        XCTAssertNotNil(result.quantity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testSplashOfVinegar() {
        let result = parser.parse("a splash of vinegar")
        XCTAssertEqual(result.name, "vinegar")
        XCTAssertNotNil(result.quantity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testBarePinch() {
        let result = parser.parse("pinch of cayenne")
        XCTAssertEqual(result.name, "cayenne")
        XCTAssertNotNil(result.quantity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    // MARK: - Unit Standardization Tests

    func testCupsStandardized() {
        let result = parser.parse("3 cups water")
        XCTAssertEqual(result.unit, "cup")
    }

    func testTbspStandardized() {
        let result = parser.parse("2 tablespoons oil")
        XCTAssertEqual(result.unit, "tbsp")
    }

    func testLbsStandardized() {
        let result = parser.parse("1 lbs chicken")
        XCTAssertEqual(result.unit, "lb")
    }

    // MARK: - Concatenated Qty+Unit (no space)

    func testConcatenatedOzUnit() {
        // "16oz baby carrots" → qty 16, unit oz, name "baby carrots"
        let result = parser.parse("16oz baby carrots")
        XCTAssertEqual(result.quantity, 16.0, "Should extract 16 from '16oz'")
        XCTAssertEqual(result.unit, "oz", "Should extract 'oz' from '16oz'")
        XCTAssertEqual(result.name, "baby carrots", "Should preserve 'baby carrots' as name")
        XCTAssertGreaterThan(result.confidence, 0.5, "Should have reasonable confidence")
    }

    func testConcatenatedTbspUnit() {
        let result = parser.parse("2tbsp olive oil")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "tbsp")
        XCTAssertEqual(result.name, "olive oil")
    }

    func testConcatenatedCupUnit() {
        let result = parser.parse("1cup sugar")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "sugar")
    }

    func testConcatenatedDecimalQty() {
        let result = parser.parse("1.5cups flour")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
    }

    // MARK: - Performance Tests

    func testParsingPerformance100Items() {
        let inputs = [
            "2 cups flour", "1/2 tsp salt", "3 large eggs", "½ cup sugar",
            "2-3 cloves garlic", "1 can (14.5 oz) tomatoes", "salt to taste",
            "a pinch of cayenne", "one and a half cups milk", "garlic, minced"
        ]

        // Repeat to get 100 items
        let testInputs = Array(repeating: inputs, count: 10).flatMap { $0 }

        measure {
            for input in testInputs {
                _ = parser.parse(input)
            }
        }
    }
}
