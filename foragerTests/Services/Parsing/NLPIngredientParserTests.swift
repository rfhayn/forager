//
//  NLPIngredientParserTests.swift
//  foragerTests
//
//  M8.3: Hybrid NLP Parser
//  Tests for NLPIngredientParser — NaturalLanguage framework fallback
//

import XCTest
@testable import forager

final class NLPIngredientParserTests: XCTestCase {

    private var parser: NLPIngredientParser!

    override func setUp() {
        super.setUp()
        parser = NLPIngredientParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Basic Parsing

    func testStandardIngredient() {
        let result = parser.parse("2 cups flour")
        XCTAssertNotNil(result.quantity)
        XCTAssertEqual(result.parserUsed, "nlp")
        XCTAssertGreaterThan(result.confidence, 0.0)
    }

    func testNameOnlyIngredient() {
        let result = parser.parse("flour")
        XCTAssertTrue(result.name.lowercased().contains("flour"))
        XCTAssertEqual(result.parserUsed, "nlp")
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

    // MARK: - Quantity Extraction

    func testNumericQuantityExtraction() {
        let result = parser.parse("3 cups water")
        XCTAssertEqual(result.quantity, 3.0)
    }

    func testNoQuantity() {
        let result = parser.parse("salt")
        XCTAssertNil(result.quantity)
    }

    // MARK: - Unit Extraction

    func testUnitExtraction() {
        let result = parser.parse("2 tablespoons oil")
        XCTAssertNotNil(result.unit)
    }

    // MARK: - Qualifier Detection

    func testQualifierPhrase() {
        let result = parser.parse("salt to taste")
        XCTAssertNotNil(result.notes)
        XCTAssertTrue(result.name.lowercased().contains("salt"))
    }

    // MARK: - Confidence Ceiling

    func testConfidenceNeverExceedsCap() {
        let result = parser.parse("2 cups flour")
        XCTAssertLessThanOrEqual(result.confidence, 0.75,
            "NLP confidence should be capped at 0.75")
    }

    // MARK: - Parser Identification

    func testParserName() {
        let result = parser.parse("2 cups flour")
        XCTAssertEqual(result.parserUsed, "nlp")
    }

    // MARK: - Performance

    func testNLPParsingPerformanceSingleItem() {
        measure {
            _ = parser.parse("2 cups all-purpose flour")
        }
    }

    func testNLPParsingPerformance50Items() {
        let inputs = [
            "2 cups flour", "salt to taste", "3 cloves garlic", "1 lb chicken breast",
            "olive oil as needed", "2 tablespoons soy sauce", "fresh basil leaves",
            "a pinch of cayenne pepper", "1 medium onion diced", "3 large eggs"
        ]
        let testInputs = Array(repeating: inputs, count: 5).flatMap { $0 }

        measure {
            for input in testInputs {
                _ = parser.parse(input)
            }
        }
    }
}
