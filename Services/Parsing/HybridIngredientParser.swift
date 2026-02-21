//
//  HybridIngredientParser.swift
//  forager
//
//  Created for M8.3: Hybrid NLP Parser
//  Routes between RegexIngredientParser (fast path) and NLPIngredientParser (fallback)
//

import Foundation

// MARK: - HybridIngredientParser

/// Router that tries regex first (fast path), falls back to NLP for low-confidence results
/// Returns whichever parser produces the higher confidence result
class HybridIngredientParser: IngredientParser {

    let parserName = "hybrid"

    private let regexConfidenceThreshold: Float
    private let regexParser: IngredientParser
    private let nlpParser: IngredientParser

    // M9.5: Injectable sub-parsers with backward-compatible defaults
    // M8.4 will extend with: mlParser: IngredientParser? = nil
    init(regexParser: IngredientParser = RegexIngredientParser(),
         nlpParser: IngredientParser = NLPIngredientParser(),
         regexConfidenceThreshold: Float = 0.8) {
        self.regexParser = regexParser
        self.nlpParser = nlpParser
        self.regexConfidenceThreshold = regexConfidenceThreshold
    }

    // MARK: - IngredientParser Protocol

    func parse(_ input: String) -> ParserResult {
        // Step 1: Try regex (fast path, microseconds)
        let regexResult = regexParser.parse(input)

        // Step 2: If regex is confident enough, return immediately
        if regexResult.confidence >= regexConfidenceThreshold {
            return regexResult
        }

        // Step 3: Regex not confident — try NLP fallback
        let nlpResult = nlpParser.parse(input)

        // Step 4: Return whichever has higher confidence
        if nlpResult.confidence > regexResult.confidence {
            // NLP won — tag as "nlp"
            return nlpResult
        }

        // Regex won (or tied) — but since we consulted NLP, tag as "hybrid"
        if regexResult.confidence > 0 {
            return ParserResult(
                name: regexResult.name,
                quantity: regexResult.quantity,
                unit: regexResult.unit,
                notes: regexResult.notes,
                confidence: regexResult.confidence,
                originalText: regexResult.originalText,
                parserUsed: "hybrid"
            )
        }

        // Both parsers produced zero confidence — return NLP result as best effort
        return nlpResult
    }
}
