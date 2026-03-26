//
//  HybridIngredientParser.swift
//  forager
//
//  Created for M8.3: Hybrid NLP Parser
//  M8.4: 3-tier routing — regex (fast) → ML (BiLSTM-CRF) → NLP (fallback)
//  Winner-only attribution: parserUsed reports the winning parser, never "hybrid"
//

import Foundation

// MARK: - HybridIngredientParser

/// 3-tier confidence router: regex → ML → NLP.
/// Returns the winning parser's result directly (winner-only attribution).
/// parserName "hybrid" satisfies protocol but is never used for telemetry attribution.
class HybridIngredientParser: IngredientParser {

    let parserName = "hybrid"

    private let regexParser: IngredientParser
    private let mlParser: IngredientParser?
    private let nlpParser: IngredientParser
    private let regexConfidenceThreshold: Float

    // M8.4: 3-tier routing with injectable sub-parsers
    // mlParser is optional — nil if CoreML model/resources unavailable
    init(regexParser: IngredientParser = RegexIngredientParser(),
         nlpParser: IngredientParser = NLPIngredientParser(),
         mlParser: IngredientParser? = nil,
         regexConfidenceThreshold: Float = 0.9) {
        self.regexParser = regexParser
        self.mlParser = mlParser
        self.nlpParser = nlpParser
        self.regexConfidenceThreshold = regexConfidenceThreshold

        #if DEBUG
        if mlParser == nil {
            print("⚠️ MLIngredientParser failed to load. ML parsing disabled.")
        }
        #endif
    }

    // MARK: - IngredientParser Protocol

    func parse(_ input: String) -> ParserResult {
        // M9.35: Sanitize input before any parser sees it
        let input = IngredientPreprocessor.sanitize(input)

        // Step 1: Regex fast path (microseconds)
        let regexResult = regexParser.parse(input)
        if regexResult.confidence >= regexConfidenceThreshold {
            return regexResult
        }

        // Step 2: ML model (milliseconds)
        if let mlParser = mlParser {
            let mlResult = mlParser.parse(input)
            if mlResult.confidence >= 0.8 {
                return mlResult
            }

            // Step 3: NLP fallback only if both regex and ML are highly uncertain
            if regexResult.confidence < 0.5 && mlResult.confidence < 0.5 {
                let nlpResult = nlpParser.parse(input)
                return [regexResult, mlResult, nlpResult]
                    .max(by: { $0.confidence < $1.confidence })!
            }

            // Return better of regex vs ML
            return mlResult.confidence > regexResult.confidence ? mlResult : regexResult
        }

        // Fallback: no ML model available — original 2-tier behavior
        if regexResult.confidence >= 0.8 {
            return regexResult
        }
        let nlpResult = nlpParser.parse(input)
        return nlpResult.confidence > regexResult.confidence ? nlpResult : regexResult
    }
}
