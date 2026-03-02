//
//  LLMIngredientParser.swift
//  forager
//
//  M10.6.1: Protocol for LLM-based batch ingredient parsing.
//  Separate from IngredientParser because: (1) async vs sync,
//  (2) batch vs per-line, (3) network dependency vs local-only.
//

import Foundation

// MARK: - LLM Parser Protocol

/// Protocol for LLM-based ingredient parsing with provider abstraction.
/// Unlike IngredientParser (sync, per-line), this is async and batch-oriented.
protocol LLMIngredientParser {
    /// Parse a batch of ingredient lines in a single API call.
    /// Categories are the user's existing grocery categories for AI assignment.
    func parseBatch(_ lines: [String], categories: [String]) async throws -> [LLMParserResult]

    /// Provider identifier for telemetry ("claude", "gpt", "gemini")
    var providerName: String { get }

    /// Check if this provider is configured and available
    var isConfigured: Bool { get }
}

extension LLMIngredientParser {
    /// Convenience overload without categories for backward compatibility
    func parseBatch(_ lines: [String]) async throws -> [LLMParserResult] {
        try await parseBatch(lines, categories: [])
    }
}

// MARK: - LLM Parser Result

/// Result type from LLM parsing, bridges to existing ParserResult
struct LLMParserResult {
    let name: String
    let quantity: Double?
    let unit: String?
    let notes: String?
    let confidence: Float
    let category: String?

    /// Bridge to existing ParserResult used by Ingredient entity creation
    func toParserResult(originalText: String, provider: String) -> ParserResult {
        ParserResult(
            name: name,
            quantity: quantity,
            unit: unit,
            notes: notes,
            confidence: confidence,
            originalText: originalText,
            parserUsed: provider
        )
    }
}

// MARK: - LLM Parser Errors

enum LLMParserError: Error, LocalizedError {
    case invalidAPIKey
    case rateLimited
    case serverOverloaded
    case serverError(Int)
    case networkError(Error)
    case timeout
    case malformedResponse(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimited:
            return "Rate limited — try again shortly"
        case .serverOverloaded:
            return "Server overloaded — try again shortly"
        case .serverError(let code):
            return "Server error (\(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .malformedResponse(let detail):
            return "Malformed response: \(detail)"
        case .validationFailed(let detail):
            return "Validation failed: \(detail)"
        }
    }

    /// Whether this error should trigger a retry
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .serverOverloaded:
            return true
        default:
            return false
        }
    }
}
