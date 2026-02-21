//
//  MockIngredientParser.swift
//  foragerTests
//
//  Created for M9.5: Parser Dependency Injection
//  Configurable mock for testing parser routing and injection
//

import Foundation
@testable import forager

/// Mock parser that returns preset results and tracks calls.
/// Use in tests to verify routing logic without real parsing.
class MockIngredientParser: IngredientParser {
    let parserName: String
    var parseResults: [String: ParserResult] = [:]
    private(set) var parseCalls: [String] = []

    /// Default result returned when no preset match exists
    var defaultConfidence: Float = 0.5

    init(name: String = "mock") {
        self.parserName = name
    }

    func parse(_ input: String) -> ParserResult {
        parseCalls.append(input)
        return parseResults[input] ?? ParserResult(
            name: input,
            quantity: nil,
            unit: nil,
            notes: nil,
            confidence: defaultConfidence,
            originalText: input,
            parserUsed: parserName
        )
    }

    /// Configure a preset result for a specific input
    func setResult(for input: String, name: String, quantity: Double? = nil,
                   unit: String? = nil, confidence: Float) {
        parseResults[input] = ParserResult(
            name: name,
            quantity: quantity,
            unit: unit,
            notes: nil,
            confidence: confidence,
            originalText: input,
            parserUsed: parserName
        )
    }

    /// Reset call tracking
    func reset() {
        parseCalls.removeAll()
    }
}
