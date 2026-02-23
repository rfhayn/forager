//
//  IngredientParser.swift
//  forager
//
//  Created for M8.3: Hybrid NLP Parser
//  M8.4: Added MLIngredientParser (BiLSTM-CRF) as third implementation
//  Protocol abstraction for ingredient parsing strategies
//

import Foundation

// MARK: - Parser Protocol

/// Protocol for ingredient parsing strategies.
/// Implementations: RegexIngredientParser (fast path), MLIngredientParser (BiLSTM-CRF), NLPIngredientParser (fallback).
/// HybridIngredientParser routes between them via confidence thresholds.
protocol IngredientParser {
    func parse(_ input: String) -> ParserResult
    var parserName: String { get }
}

// MARK: - Parser Result

/// Unified result type returned by all parser implementations
struct ParserResult {
    let name: String
    let quantity: Double?
    let unit: String?
    let notes: String?
    let confidence: Float       // 0.0-1.0
    let originalText: String
    let parserUsed: String      // "regex", "ml", "nlp"

    /// Convenience: whether a numeric quantity was successfully extracted
    var isParseable: Bool {
        return quantity != nil
    }

    /// Convenience: whether all three components (qty, unit, name) were extracted
    var isFullyParsed: Bool {
        return quantity != nil && unit != nil && !name.isEmpty
    }
}
