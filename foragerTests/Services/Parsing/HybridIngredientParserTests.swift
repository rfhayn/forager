//
//  HybridIngredientParserTests.swift
//  foragerTests
//
//  M8.3: Hybrid NLP Parser
//  Tests for HybridIngredientParser — router and integration tests
//

import XCTest
@testable import forager

final class HybridIngredientParserTests: XCTestCase {

    private var parser: HybridIngredientParser!

    override func setUp() {
        super.setUp()
        parser = HybridIngredientParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Router Tests

    func testHighConfidenceUsesRegex() {
        // "2 cups flour" should produce high regex confidence → regex path
        let result = parser.parse("2 cups flour")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
        XCTAssertEqual(result.parserUsed, "regex",
            "High-confidence inputs should use regex fast path")
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testMediumConfidenceConsultsMLOrNLP() {
        // Ambiguous input that regex can parse but with lower confidence
        // "garlic, minced" gets parsed by qualifier pattern with confidence 0.70
        let result = parser.parse("garlic, minced")
        XCTAssertTrue(result.name.lowercased().contains("garlic"))
        // M8.4: Winner-only attribution — should be "regex", "ml", or "nlp" (never "hybrid")
        XCTAssertTrue(["regex", "ml", "nlp"].contains(result.parserUsed),
            "Should use winner-only attribution, got: \(result.parserUsed)")
    }

    func testZeroConfidenceFallsBackToNLP() {
        // An unusual phrase that regex can't parse at all
        let result = parser.parse("approximately two medium sized red onions")
        // Should at least get a name out of it
        XCTAssertFalse(result.name.isEmpty)
        XCTAssertGreaterThan(result.confidence, 0.0,
            "NLP should extract something from natural language")
    }

    // MARK: - Regression Tests (full pipeline)

    func testStandardIngredientFullPipeline() {
        let result = parser.parse("2 cups flour")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testFractionFullPipeline() {
        let result = parser.parse("1/2 tsp salt")
        XCTAssertEqual(result.quantity, 0.5)
        XCTAssertEqual(result.unit, "tsp")
        XCTAssertEqual(result.name, "salt")
    }

    func testMixedFractionFullPipeline() {
        let result = parser.parse("1 1/2 tbsp olive oil")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "tbsp")
        XCTAssertEqual(result.name, "olive oil")
    }

    func testQuantityNoUnitFullPipeline() {
        let result = parser.parse("3 large eggs")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.name, "large eggs")
    }

    func testNameOnlyFullPipeline() {
        let result = parser.parse("flour")
        // Either parser might handle this; name should be "flour"
        XCTAssertTrue(result.name.lowercased().contains("flour"))
    }

    // MARK: - New Pattern Tests (full pipeline)

    func testUnicodeFractionFullPipeline() {
        let result = parser.parse("½ cup sugar")
        XCTAssertEqual(result.quantity, 0.5)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "sugar")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.9)
    }

    func testRangeFullPipeline() {
        let result = parser.parse("2-3 cloves garlic")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.name, "garlic")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testParentheticalFullPipeline() {
        let result = parser.parse("1 can (14.5 oz) diced tomatoes")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "can")
        XCTAssertEqual(result.name, "diced tomatoes")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testQualifierFullPipeline() {
        let result = parser.parse("salt to taste")
        XCTAssertTrue(result.name.lowercased().contains("salt"))
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testCompoundPhraseFullPipeline() {
        let result = parser.parse("one and a half cups milk")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "milk")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
    }

    func testDescriptiveAmountFullPipeline() {
        let result = parser.parse("a pinch of cayenne")
        XCTAssertEqual(result.name, "cayenne")
        XCTAssertNotNil(result.quantity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    // MARK: - Performance Tests

    func testHybridPerformance100Items() {
        let inputs = [
            "2 cups flour", "1/2 tsp salt", "3 large eggs", "½ cup sugar",
            "2-3 cloves garlic", "1 can (14.5 oz) tomatoes", "salt to taste",
            "a pinch of cayenne", "one and a half cups milk", "garlic, minced"
        ]
        let testInputs = Array(repeating: inputs, count: 10).flatMap { $0 }

        measure {
            for input in testInputs {
                _ = parser.parse(input)
            }
        }
    }

    func testHighConfidencePathPerformance() {
        // All high-confidence inputs should use regex fast path (no NLP overhead)
        let inputs = Array(repeating: "2 cups flour", count: 100)

        measure {
            for input in inputs {
                _ = parser.parse(input)
            }
        }
    }
}
