//
//  MockLLMIngredientParser.swift
//  foragerTests
//
//  M10.6.1: Test mock for LLMIngredientParser protocol.
//  Returns predetermined results or throws errors on demand.
//

import Foundation
@testable import forager

class MockLLMIngredientParser: LLMIngredientParser {

    let providerName = "mock"
    var isConfigured: Bool = true

    /// Set this to control what parseBatch returns
    var stubbedResults: [LLMParserResult] = []

    /// Set this to make parseBatch throw
    var stubbedError: Error?

    /// Tracks how many times parseBatch was called
    var parseBatchCallCount = 0

    /// Tracks the last input passed to parseBatch
    var lastInput: [String]?

    func parseBatch(_ lines: [String]) async throws -> [LLMParserResult] {
        parseBatchCallCount += 1
        lastInput = lines

        if let error = stubbedError {
            throw error
        }

        return stubbedResults
    }
}
