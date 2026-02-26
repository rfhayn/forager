//
//  FoundationModelsIngredientParser.swift
//  forager
//
//  Created for M10.5: Evaluate Foundation Models for ingredient parsing.
//  On-device LLM structured extraction of quantity, unit, name, and preparation
//  from raw ingredient text. Used for accuracy comparison against regex→ML→NLP pipeline.
//

import Foundation
import FoundationModels

// MARK: - Generable Schemas

/// Structured output for a single parsed ingredient line.
/// @Generable constrains the on-device LLM to produce exactly these fields.
@Generable(description: "A parsed ingredient extracted from a recipe line")
struct IngredientGenerable {
    @Guide(description: "Numeric quantity as a decimal (e.g. 2.5 for '2 1/2', 0.25 for '1/4'). Nil if no quantity present (e.g. 'salt and pepper')")
    var quantity: Double?

    @Guide(description: "Unit of measurement, standardized to: cup, tbsp, tsp, oz, lb, g, kg, ml, L, clove, sprig, pinch, handful, bunch, can, head, stalk. Nil for count items like '2 eggs'")
    var unit: String?

    @Guide(description: "The clean ingredient name without quantities, units, or preparation methods")
    var name: String

    @Guide(description: "Preparation notes like 'diced', 'minced', 'at room temperature', 'cut into chunks'. Nil if none")
    var preparation: String?
}

/// Batch output for multiple ingredient lines parsed together.
@Generable(description: "A batch of parsed ingredients from a recipe, maintaining input order")
struct IngredientBatchGenerable {
    @Guide(description: "Parsed ingredients in the same order as the input lines")
    var ingredients: [IngredientGenerable]
}

// MARK: - Foundation Models Ingredient Parser

/// On-device LLM ingredient parser using Apple's Foundation Models framework.
/// Parses ingredient text into structured components (quantity, unit, name, preparation).
///
/// Availability: iPhone 15 Pro+, iPad M1+, with Apple Intelligence enabled and model downloaded.
/// Returns nil when unavailable — callers fall back to the regex→ML→NLP pipeline.
class FoundationModelsIngredientParser {

    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Parse a batch of ingredient lines in a single LLM call.
    /// Returns nil if Foundation Models is unavailable or the call fails.
    func parseBatch(_ lines: [String]) async -> [IngredientGenerable]? {
        guard Self.isAvailable else { return nil }
        guard !lines.isEmpty else { return [] }

        let session = LanguageModelSession(instructions: """
            You are an ingredient parser for a grocery shopping app. For each ingredient line, \
            extract the structured components. Rules:
            - Metric no-space formats: '400g' means quantity=400, unit=g
            - Fractions: '1/2' = 0.5, '2 1/2' = 2.5, '2-1/2' = 2.5
            - Unicode fractions: '½' = 0.5, '¼' = 0.25, '¾' = 0.75
            - Count items: '2 eggs' = quantity=2, unit=nil, name='eggs'
            - Bare names: 'salt and pepper' = quantity=nil, unit=nil, name='salt and pepper'
            - Standardize units: tablespoon/tbs/tbsp → tbsp, teaspoon → tsp, gram/grams → g
            - Strip prep methods from names: '600g beef shin cut into chunks' → \
            name='beef shin', preparation='cut into chunks'
            - Parenthetical notes are preparation: 'butter (softened)' → \
            name='butter', preparation='softened'
            """)

        let numberedLines = lines.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        do {
            let response = try await session.respond(
                to: "Parse these ingredient lines:\n\(numberedLines)",
                generating: IngredientBatchGenerable.self
            )

            let results = response.content.ingredients

            guard results.count == lines.count else {
                print("FM batch: expected \(lines.count) results, got \(results.count)")
                return nil
            }

            return results
        } catch {
            print("FM batch parse failed: \(error)")
            return nil
        }
    }

    /// Parse a single ingredient line.
    func parseSingle(_ line: String) async -> IngredientGenerable? {
        guard let results = await parseBatch([line]) else { return nil }
        return results.first
    }
}
