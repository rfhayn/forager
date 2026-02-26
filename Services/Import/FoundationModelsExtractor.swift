//
//  FoundationModelsExtractor.swift
//  forager
//
//  Created for M10.2.1/M10.2.3: Foundation Models @Generable recipe extraction
//  On-device LLM for structured recipe extraction from pasted text.
//  Falls back gracefully when Foundation Models unavailable (non-Pro devices, model not ready).
//

import Foundation
import FoundationModels

// MARK: - Generable Recipe Schema

/// Structured output schema for Foundation Models extraction.
/// @Generable constrains the LLM to produce exactly these fields — no post-processing parsing needed.
@Generable(description: "A recipe extracted from unstructured text")
struct ImportedRecipeGenerable {
    @Guide(description: "The recipe title or name")
    var title: String

    @Guide(description: "Array of ingredient lines, each as originally written (e.g. '2 cups flour')")
    var ingredients: [String]

    @Guide(description: "Step-by-step cooking instructions, preserving numbered steps if present")
    var instructions: String

    @Guide(description: "Prep time in minutes, nil if not mentioned")
    var prepTimeMinutes: Int?

    @Guide(description: "Cook time in minutes, nil if not mentioned")
    var cookTimeMinutes: Int?

    @Guide(description: "Number of servings, nil if not mentioned")
    var servings: Int?
}

// MARK: - Foundation Models Extractor

/// Extracts recipes from pasted text using the on-device Foundation Models LLM.
/// Returns nil when Foundation Models is unavailable (graceful degradation to heuristic fallback).
///
/// Availability: iPhone 15 Pro+, iPad M1+, with Apple Intelligence enabled and model downloaded.
class FoundationModelsExtractor: RecipeExtractor {
    let extractorName = "foundation_models"

    /// Check if Foundation Models is available on this device.
    /// Three possible unavailable reasons: deviceNotEligible, appleIntelligenceNotEnabled, modelNotReady.
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Detailed availability for UI messaging (e.g. "Enable Apple Intelligence in Settings")
    static var availability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    func extract(from input: RecipeExtractionInput) async throws -> ImportDraftRecipe? {
        // Only handle text input
        guard case .text(let text) = input else { return nil }

        // Check availability — return nil to let heuristic fallback handle it
        guard Self.isAvailable else { return nil }

        let startTime = CFAbsoluteTimeGetCurrent()

        let session = LanguageModelSession(instructions: """
            You are a recipe extraction assistant. Extract the recipe from the provided text.
            Preserve ingredient lines exactly as written. Combine instruction steps into a
            single string with numbered steps. Extract times in minutes and servings as integers.
            If a field is not present in the text, leave it as nil.
            """)

        do {
            let response = try await session.respond(
                to: text,
                generating: ImportedRecipeGenerable.self
            )

            let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            let result = response.content

            // Validate: at minimum we need a title and ingredients
            guard !result.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !result.ingredients.isEmpty else {
                throw ImportError.noRecipeFound
            }

            return ImportDraftRecipe(
                title: ImportField(value: result.title, confidence: .high, source: .foundationModels),
                ingredients: ImportField(value: result.ingredients, confidence: .high, source: .foundationModels),
                instructions: ImportField(
                    value: result.instructions,
                    confidence: result.instructions.isEmpty ? .missing : .high,
                    source: .foundationModels
                ),
                prepTimeMinutes: ImportField(
                    value: result.prepTimeMinutes,
                    confidence: result.prepTimeMinutes != nil ? .high : .missing,
                    source: .foundationModels
                ),
                cookTimeMinutes: ImportField(
                    value: result.cookTimeMinutes,
                    confidence: result.cookTimeMinutes != nil ? .high : .missing,
                    source: .foundationModels
                ),
                servings: ImportField(
                    value: result.servings ?? 4,
                    confidence: result.servings != nil ? .high : .low,
                    source: .foundationModels
                ),
                imageURL: ImportField(value: nil, confidence: .missing, source: .foundationModels),
                author: ImportField(value: nil, confidence: .missing, source: .foundationModels),
                sourceURL: nil,
                description: nil,
                cuisine: nil,
                category: nil,
                tags: nil,
                extractionMethod: "foundation_models",
                extractionTimeMs: elapsed
            )
        } catch let error as LanguageModelSession.GenerationError {
            // Map Foundation Models errors to import errors
            switch error {
            case .assetsUnavailable:
                // Model not downloaded yet — fall back to heuristic
                return nil
            case .guardrailViolation:
                throw ImportError.aiExtractionFailed
            case .decodingFailure:
                throw ImportError.aiExtractionFailed
            default:
                throw ImportError.aiExtractionFailed
            }
        }
    }
}
