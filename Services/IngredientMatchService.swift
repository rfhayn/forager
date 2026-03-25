//
//  IngredientMatchService.swift
//  forager
//
//  Created for M10.6.8: Shared ingredient matching logic
//  Centralizes parse → template lookup → status determination
//  used by Import, Create, Edit, and RecipeDetail views.
//

import Foundation
import CoreData

// MARK: - Match Result Model

/// Result of matching an ingredient text against existing templates.
/// Value type — views store these in @State keyed by Int (import) or UUID (recipe forms).
struct IngredientMatchResult {
    let rawText: String
    let parsedName: String
    let parsedQuantity: String?
    let parsedUnit: String?
    let parsedNotes: String?
    let status: IngredientStatus
    let categoryName: String?
    let templateName: String?
    let wasAIParsed: Bool
    let aiParsedName: String?
}

extension IngredientMatchResult {
    /// Return a copy with the category updated and status set to .ready.
    func withCategory(_ newCategory: String) -> IngredientMatchResult {
        IngredientMatchResult(
            rawText: rawText,
            parsedName: parsedName,
            parsedQuantity: parsedQuantity,
            parsedUnit: parsedUnit,
            parsedNotes: parsedNotes,
            status: .ready,
            categoryName: newCategory,
            templateName: templateName,
            wasAIParsed: wasAIParsed,
            aiParsedName: aiParsedName
        )
    }
}

// MARK: - Service

/// Centralizes ingredient matching: parse text → search templates → determine status.
/// Stateless — computes and returns results; views own the state.
@MainActor
class IngredientMatchService: ObservableObject {
    private let parsingService: IngredientParsingService
    private let templateService: IngredientTemplateService

    init(parsingService: IngredientParsingService, templateService: IngredientTemplateService) {
        self.parsingService = parsingService
        self.templateService = templateService
    }

    // MARK: - Single Match

    /// Parse text, look up template, and determine match status.
    /// Returns nil for empty or too-short text.
    func matchIngredient(text: String) -> IngredientMatchResult? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }

        let parsed = parsingService.parseIngredient(text: trimmed)
        return buildResult(rawText: trimmed, parsed: parsed, wasAIParsed: false, aiParsedName: nil)
    }

    // MARK: - Batch Match

    /// Match multiple ingredient texts at once.
    func matchBatch(texts: [String]) -> [IngredientMatchResult?] {
        texts.map { matchIngredient(text: $0) }
    }

    // MARK: - AI Parse Single

    /// Parse a single ingredient via LLM and return enriched match result.
    /// Returns nil on failure — caller should keep existing local result.
    /// Pass user's category names to enable AI category assignment.
    func aiParseSingle(text: String, source: ParsingTelemetryEvent.ParsingSource, categories: [String] = []) async -> IngredientMatchResult? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }

        // Get deterministic parse for comparison
        let localParsed = parsingService.parseIngredient(text: trimmed)

        guard let (parsed, _, aiCategory) = await parsingService.parseSingleWithLLM(text: trimmed, source: source, categories: categories) else {
            return nil
        }

        let aiName = parsed.displayName
        let localName = localParsed.displayName
        let nameChanged = aiName.lowercased() != localName.lowercased()

        // Validate AI category against user's actual category list
        let validatedCategory = Self.validateCategory(aiCategory, against: categories)

        return buildResult(
            rawText: trimmed,
            parsed: parsed,
            wasAIParsed: true,
            aiParsedName: nameChanged ? aiName : nil,
            aiCategory: validatedCategory
        )
    }

    // MARK: - AI Parse Batch

    /// Parse a batch of ingredients via LLM and return enriched match results.
    /// Returns nil on failure — caller should keep existing local results.
    /// Pass user's category names to enable AI category assignment.
    func aiParseBatch(texts: [String], source: ParsingTelemetryEvent.ParsingSource, categories: [String] = []) async -> [IngredientMatchResult]? {
        let trimmedTexts = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !trimmedTexts.isEmpty else { return nil }

        // Get deterministic parses for comparison
        let localParses = trimmedTexts.map { parsingService.parseIngredient(text: $0) }

        guard let results = await parsingService.parseBatchWithLLM(texts: trimmedTexts, source: source, categories: categories) else {
            return nil
        }

        var matchResults: [IngredientMatchResult] = []
        for (index, (parsed, _, aiCategory)) in results.enumerated() {
            guard index < trimmedTexts.count else { break }

            let aiName = parsed.displayName
            let localName = localParses[index].displayName
            let nameChanged = aiName.lowercased() != localName.lowercased()

            // Validate AI category against user's actual category list
            let validatedCategory = Self.validateCategory(aiCategory, against: categories)

            let result = buildResult(
                rawText: trimmedTexts[index],
                parsed: parsed,
                wasAIParsed: true,
                aiParsedName: nameChanged ? aiName : nil,
                aiCategory: validatedCategory
            )
            matchResults.append(result)
        }

        return matchResults
    }

    // MARK: - Summary

    /// Count categorized vs uncategorized from a collection of match results.
    func matchSummary(from results: [IngredientMatchResult?]) -> (categorized: Int, uncategorized: Int) {
        let nonNil = results.compactMap { $0 }
        let categorized = nonNil.filter { $0.categoryName != nil }.count
        return (categorized: categorized, uncategorized: nonNil.count - categorized)
    }

    // MARK: - Normalization

    /// Expose template normalization for callers that need consistent name keys.
    func normalizedName(_ name: String) -> String {
        templateService.normalize(name: name)
    }

    // MARK: - Private

    /// Validate that an AI-returned category actually exists in the user's category list.
    /// Returns the matched category name (preserving user's casing) or nil if no match.
    private static func validateCategory(_ aiCategory: String?, against validCategories: [String]) -> String? {
        guard let ai = aiCategory, !ai.isEmpty else { return nil }
        // If no valid categories provided, accept as-is (non-import contexts)
        guard !validCategories.isEmpty else { return ai }
        // Case-insensitive match against user's actual category list
        return validCategories.first(where: { $0.lowercased() == ai.lowercased() })
    }

    /// Shared logic: look up template by parsed name and determine status.
    /// AI-suggested category is used when the template has no category.
    private func buildResult(
        rawText: String,
        parsed: ParsedIngredient,
        wasAIParsed: Bool,
        aiParsedName: String?,
        aiCategory: String? = nil
    ) -> IngredientMatchResult {
        // Sanitize rawText for display — strips "(, melted)" → "(melted)" and other scraping artifacts
        let displayRawText = IngredientPreprocessor.sanitize(rawText)
        let cleanName = parsed.displayName
        let candidates = templateService.searchTemplates(query: cleanName, limit: 5)
        let exactMatch = candidates.first(where: {
            $0.name?.lowercased() == cleanName.lowercased()
        })

        let status: IngredientStatus
        let categoryName: String?
        let templateName: String?

        if let template = exactMatch {
            templateName = template.name
            if let category = template.categoryEntity?.name, !category.isEmpty {
                // Template has a category — use it (including user-assigned "Uncategorized")
                status = .ready
                categoryName = category
            } else if let ai = aiCategory, !ai.isEmpty {
                // No template category, but AI suggested one
                status = .ready
                categoryName = ai
            } else {
                status = .needsCategory
                categoryName = nil
            }
        } else if let ai = aiCategory, !ai.isEmpty {
            // No template found, but AI suggested a category
            status = .needsTemplate
            categoryName = ai
            templateName = nil
        } else {
            status = .needsTemplate
            categoryName = nil
            templateName = nil
        }

        return IngredientMatchResult(
            rawText: displayRawText,
            parsedName: cleanName,
            parsedQuantity: parsed.quantity,
            parsedUnit: parsed.unit,
            parsedNotes: parsed.notes,
            status: status,
            categoryName: categoryName,
            templateName: templateName,
            wasAIParsed: wasAIParsed,
            aiParsedName: aiParsedName
        )
    }
}
