//
//  HybridParserRoutingTests.swift
//  foragerTests
//
//  Created for M9.5: Parser Dependency Injection
//  Tests routing logic in HybridIngredientParser using mock sub-parsers
//

import XCTest
@testable import forager

/// Tests that HybridIngredientParser routes between sub-parsers correctly.
/// Uses MockIngredientParser to isolate routing logic from real parsing.
final class HybridParserRoutingTests: XCTestCase {

    private var mockRegex: MockIngredientParser!
    private var mockNLP: MockIngredientParser!

    override func setUp() {
        super.setUp()
        mockRegex = MockIngredientParser(name: "regex")
        mockNLP = MockIngredientParser(name: "nlp")
    }

    override func tearDown() {
        mockRegex = nil
        mockNLP = nil
        super.tearDown()
    }

    // MARK: - High-Confidence Regex Short-Circuit

    /// When regex confidence >= threshold, NLP should NOT be consulted
    func testHighConfidenceRegexSkipsNLP() {
        mockRegex.setResult(for: "2 cups flour", name: "flour",
                            quantity: 2.0, unit: "cups", confidence: 0.95)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.8
        )
        let result = hybrid.parse("2 cups flour")

        XCTAssertEqual(result.parserUsed, "regex")
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertEqual(mockRegex.parseCalls.count, 1)
        XCTAssertEqual(mockNLP.parseCalls.count, 0,
                       "NLP should not be called when regex meets threshold")
    }

    /// Regex at exactly the threshold should still short-circuit
    func testRegexAtExactThresholdSkipsNLP() {
        mockRegex.setResult(for: "1 cup sugar", name: "sugar",
                            quantity: 1.0, unit: "cup", confidence: 0.8)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.8
        )
        let result = hybrid.parse("1 cup sugar")

        XCTAssertEqual(result.parserUsed, "regex")
        XCTAssertEqual(mockNLP.parseCalls.count, 0)
    }

    // MARK: - Low-Confidence Regex → NLP Fallback

    /// When regex is below threshold and NLP produces higher confidence, NLP wins
    func testLowConfidenceRegexFallsBackToNLP() {
        mockRegex.setResult(for: "salt to taste", name: "salt to taste",
                            confidence: 0.6)
        mockNLP.setResult(for: "salt to taste", name: "salt",
                          confidence: 0.7)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.8
        )
        let result = hybrid.parse("salt to taste")

        XCTAssertEqual(result.parserUsed, "nlp",
                       "NLP should win when it has higher confidence")
        XCTAssertEqual(result.confidence, 0.7)
        XCTAssertEqual(mockNLP.parseCalls.count, 1)
    }

    /// When regex is below threshold but still better than NLP, result tagged as "hybrid"
    func testRegexBetterThanNLPTaggedAsHybrid() {
        mockRegex.setResult(for: "garlic minced", name: "garlic minced",
                            confidence: 0.7)
        mockNLP.setResult(for: "garlic minced", name: "garlic",
                          confidence: 0.5)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.8
        )
        let result = hybrid.parse("garlic minced")

        XCTAssertEqual(result.parserUsed, "hybrid",
                       "Should be tagged 'hybrid' when regex wins but NLP was consulted")
        XCTAssertEqual(result.confidence, 0.7)
    }

    // MARK: - Custom Threshold

    /// Raising threshold to 0.9 causes more NLP consultations
    func testCustomHighThresholdTriggersMoreNLPFallback() {
        mockRegex.setResult(for: "2 cups flour", name: "flour",
                            quantity: 2.0, unit: "cups", confidence: 0.85)
        mockNLP.setResult(for: "2 cups flour", name: "flour",
                          quantity: 2.0, unit: "cups", confidence: 0.7)

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.9
        )
        let result = hybrid.parse("2 cups flour")

        // 0.85 < 0.9 threshold, so NLP is consulted
        XCTAssertEqual(mockNLP.parseCalls.count, 1,
                       "NLP should be consulted when regex (0.85) < threshold (0.9)")
        // But regex still wins (0.85 > 0.7)
        XCTAssertEqual(result.parserUsed, "hybrid")
        XCTAssertEqual(result.confidence, 0.85)
    }

    // MARK: - Zero Confidence Both

    /// When both parsers produce zero confidence, NLP result returned as best effort
    func testZeroConfidenceBothReturnsNLP() {
        mockRegex.defaultConfidence = 0.0
        mockNLP.defaultConfidence = 0.0

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.8
        )
        let result = hybrid.parse("???")

        XCTAssertEqual(result.parserUsed, "nlp",
                       "When both have zero confidence, NLP result returned as best effort")
    }

    // MARK: - Call Tracking

    /// Verify both parsers receive the exact input string
    func testBothParsersReceiveCorrectInput() {
        mockRegex.defaultConfidence = 0.5
        mockNLP.defaultConfidence = 0.3

        let hybrid = HybridIngredientParser(
            regexParser: mockRegex, nlpParser: mockNLP,
            regexConfidenceThreshold: 0.8
        )
        let _ = hybrid.parse("½ cup butter")

        XCTAssertEqual(mockRegex.parseCalls, ["½ cup butter"])
        XCTAssertEqual(mockNLP.parseCalls, ["½ cup butter"])
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
