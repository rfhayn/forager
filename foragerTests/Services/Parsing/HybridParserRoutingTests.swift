//
//  HybridParserRoutingTests.swift
//  foragerTests
//
//  Created for M9.5: Parser Dependency Injection
//  M8.4: Updated for 3-tier routing (regex → ML → NLP) with winner-only attribution
//  Tests routing logic in HybridIngredientParser using mock sub-parsers
//

import XCTest
@testable import forager

/// Tests that HybridIngredientParser routes between sub-parsers correctly.
/// Uses MockIngredientParser to isolate routing logic from real parsing.
/// M8.4: Tests 3-tier routing (regex → ML → NLP) and winner-only attribution.
final class HybridParserRoutingTests: XCTestCase {

    private var mockRegex: MockIngredientParser!
    private var mockML: MockIngredientParser!
    private var mockNLP: MockIngredientParser!

    override func setUp() {
        super.setUp()
        mockRegex = MockIngredientParser(name: "regex")
        mockML = MockIngredientParser(name: "ml")
        mockNLP = MockIngredientParser(name: "nlp")
    }

    override func tearDown() {
        mockRegex = nil
        mockML = nil
        mockNLP = nil
        super.tearDown()
    }

    // MARK: - High-Confidence Regex Short-Circuit

    /// When regex confidence >= threshold, ML and NLP should NOT be consulted
    func testHighConfidenceRegexSkipsMLAndNLP() {
        mockRegex.setResult(for: "2 cups flour", name: "flour",
                            quantity: 2.0, unit: "cups", confidence: 0.95)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("2 cups flour")

        XCTAssertEqual(result.parserUsed, "regex")
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertEqual(mockRegex.parseCalls.count, 1)
        XCTAssertEqual(mockML.parseCalls.count, 0,
                       "ML should not be called when regex meets threshold")
        XCTAssertEqual(mockNLP.parseCalls.count, 0,
                       "NLP should not be called when regex meets threshold")
    }

    /// Regex at exactly the threshold should still short-circuit
    func testRegexAtExactThresholdSkipsMLAndNLP() {
        mockRegex.setResult(for: "1 cup sugar", name: "sugar",
                            quantity: 1.0, unit: "cup", confidence: 0.9)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("1 cup sugar")

        XCTAssertEqual(result.parserUsed, "regex")
        XCTAssertEqual(mockML.parseCalls.count, 0)
        XCTAssertEqual(mockNLP.parseCalls.count, 0)
    }

    // MARK: - ML Tier

    /// When regex below threshold but ML >= 0.8, ML wins
    func testMLWinsWhenConfident() {
        mockRegex.setResult(for: "garlic minced", name: "garlic minced",
                            confidence: 0.7)
        mockML.setResult(for: "garlic minced", name: "garlic",
                         confidence: 0.85)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("garlic minced")

        XCTAssertEqual(result.parserUsed, "ml",
                       "ML should win when confidence >= 0.8")
        XCTAssertEqual(result.confidence, 0.85)
        XCTAssertEqual(mockNLP.parseCalls.count, 0,
                       "NLP should not be called when ML is confident")
    }

    /// When regex is moderate and ML is moderate, better one wins (no NLP)
    func testRegexBetterThanMLInModerateRange() {
        mockRegex.setResult(for: "garlic minced", name: "garlic minced",
                            confidence: 0.7)
        mockML.setResult(for: "garlic minced", name: "garlic",
                         confidence: 0.6)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("garlic minced")

        XCTAssertEqual(result.parserUsed, "regex",
                       "Regex should win when it has higher confidence than ML")
        XCTAssertEqual(result.confidence, 0.7)
        XCTAssertEqual(mockNLP.parseCalls.count, 0,
                       "NLP should not be consulted in moderate-confidence range")
    }

    // MARK: - NLP Fallback (Both Regex and ML Uncertain)

    /// When both regex and ML < 0.5, NLP is consulted as tiebreaker
    func testNLPConsultedWhenBothLow() {
        mockRegex.setResult(for: "salt to taste", name: "salt to taste",
                            confidence: 0.3)
        mockML.setResult(for: "salt to taste", name: "salt to taste",
                         confidence: 0.4)
        mockNLP.setResult(for: "salt to taste", name: "salt",
                          confidence: 0.7)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("salt to taste")

        XCTAssertEqual(result.parserUsed, "nlp",
                       "NLP should win when it has highest confidence among all three")
        XCTAssertEqual(result.confidence, 0.7)
        XCTAssertEqual(mockNLP.parseCalls.count, 1,
                       "NLP should be consulted when both regex and ML < 0.5")
    }

    // MARK: - No ML Model (Graceful Degradation)

    /// When ML parser is nil, falls back to 2-tier (regex → NLP)
    func testNoMLParserFallsToTwoTier() {
        mockRegex.setResult(for: "salt to taste", name: "salt to taste",
                            confidence: 0.6)
        mockNLP.setResult(for: "salt to taste", name: "salt",
                          confidence: 0.7)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: nil, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("salt to taste")

        XCTAssertEqual(result.parserUsed, "nlp",
                       "Without ML, NLP should win when it has higher confidence")
        XCTAssertEqual(result.confidence, 0.7)
    }

    /// Without ML, regex at original 0.8 threshold still works
    func testNoMLRegexHighConfidence() {
        mockRegex.setResult(for: "2 cups flour", name: "flour",
                            quantity: 2.0, unit: "cups", confidence: 0.85)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: nil, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("2 cups flour")

        // 0.85 < 0.9 threshold, so NLP is consulted in no-ML fallback
        // But NLP default confidence (0.5) < regex (0.85), so regex wins
        XCTAssertEqual(result.parserUsed, "regex")
        XCTAssertEqual(result.confidence, 0.85)
    }

    // MARK: - Zero Confidence All Parsers

    /// When all parsers produce zero confidence, best effort returned
    func testZeroConfidenceAllReturnsNLP() {
        mockRegex.defaultConfidence = 0.0
        mockML.defaultConfidence = 0.0
        mockNLP.defaultConfidence = 0.0

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("???")

        // All at 0.0 — NLP consulted because both regex and ML < 0.5
        XCTAssertEqual(mockNLP.parseCalls.count, 1)
    }

    // MARK: - Call Tracking

    /// Verify parsers receive the exact input string in order
    func testParsersReceiveCorrectInput() {
        mockRegex.defaultConfidence = 0.3
        mockML.defaultConfidence = 0.3
        mockNLP.defaultConfidence = 0.5

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            mlParser: mockML, regexConfidenceThreshold: 0.9
        )
        let _ = hybrid.parse("½ cup butter")

        XCTAssertEqual(mockRegex.parseCalls, ["½ cup butter"])
        XCTAssertEqual(mockML.parseCalls, ["½ cup butter"])
        XCTAssertEqual(mockNLP.parseCalls, ["½ cup butter"],
                       "NLP should be called when both regex and ML < 0.5")
    }

    // MARK: - Default Init Backward Compatibility

    /// Default init (no arguments) should work — ensures backward compatibility
    func testDefaultInitProducesValidResults() {
        let hybrid = HybridIngredientParser()
        let result = hybrid.parse("2 cups flour")

        XCTAssertFalse(result.name.isEmpty, "Default init should produce valid parse results")
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
}
