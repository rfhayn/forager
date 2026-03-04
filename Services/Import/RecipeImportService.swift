//
//  RecipeImportService.swift
//  forager
//
//  Created for M10.1.3: Import orchestrator + service
//  Orchestrates URL fetch → extraction → preview → atomic save.
//  Child context pattern ensures Recipe + all Ingredients persist in single save.
//

import Foundation
import CoreData

// MARK: - Import Save Result

/// Return type for save operations — includes recipe object ID and any
/// uncategorized templates that need CategoryAssignmentModal presentation.
struct ImportSaveResult {
    let recipeObjectID: NSManagedObjectID
    let uncategorizedTemplateIDs: [NSManagedObjectID]
}

// MARK: - Recipe Import Service

/// Orchestrates the recipe import flow: URL fetch → extraction → preview → save.
/// Uses ImportJobState state machine for UI binding.
/// Atomic save via child context — template service saves push to parent in memory,
/// final viewContext.save() persists everything to disk at once.
@MainActor
class RecipeImportService: ObservableObject {

    // MARK: - Published State

    @Published var state: ImportJobState = .idle

    // MARK: - Dependencies

    private let viewContext: NSManagedObjectContext
    private let parsingService: IngredientParsingService

    // M10.6.11: Household key for scoping templates created during import
    var householdKeyProvider: (() -> String?)?

    // Extractors (strategy pattern — tried in priority order)
    private let extractors: [RecipeExtractor] = [
        RecipeJSONLDExtractor(),
        WKWebViewExtractor()
    ]

    // MARK: - Initialization

    init(context: NSManagedObjectContext, parsingService: IngredientParsingService) {
        self.viewContext = context
        self.parsingService = parsingService
    }

    // MARK: - Import from URL

    /// Fetch HTML from URL and try extractors in priority order.
    /// Transitions: idle → received → fetching → extracting → needsReview or failed
    func importFromURL(_ url: URL) async {
        state = .received(url)

        // Check for known unsupported sources before fetching
        if let sourceError = checkUnsupportedSource(url) {
            state = .failed(sourceError)
            return
        }

        state = .fetching

        // Fetch HTML
        let html: String
        do {
            html = try await fetchHTML(from: url)
        } catch let error as ImportError {
            state = .failed(error)
            return
        } catch {
            state = .failed(.networkError(error.localizedDescription))
            return
        }

        // Try extractors in priority order
        let input = RecipeExtractionInput.html(html, url: url)
        var lastError: ImportError?

        for extractor in extractors {
            state = .extracting(method: extractor.extractorName)

            do {
                if let draft = try await extractor.extract(from: input) {
                    state = .needsReview(draft)
                    return
                }
            } catch let error as ImportError {
                // Extractor recognized input but extraction failed — keep the error
                lastError = error
            } catch {
                // Unexpected error — wrap it
                lastError = .malformedData(error.localizedDescription)
            }
        }

        // All extractors returned nil (none claimed the input)
        // If any extractor threw, show that error; otherwise generic "no recipe"
        state = .failed(lastError ?? .noRecipeFound)
    }

    // MARK: - Import from Text

    /// Extract recipe from pasted text. Tries Foundation Models first, falls back to heuristic.
    /// Transitions: idle → extracting → needsReview or failed
    func importFromText(_ text: String) async {
        let input = RecipeExtractionInput.text(text)

        // Try Foundation Models first (returns nil if unavailable)
        let textExtractors: [RecipeExtractor] = [
            FoundationModelsExtractor(),
            HeuristicTextExtractor()
        ]

        var lastError: ImportError?

        for extractor in textExtractors {
            state = .extracting(method: extractor.extractorName)

            do {
                if let draft = try await extractor.extract(from: input) {
                    state = .needsReview(draft)
                    return
                }
            } catch let error as ImportError {
                lastError = error
            } catch {
                lastError = .malformedData(error.localizedDescription)
            }
        }

        state = .failed(lastError ?? .noRecipeFound)
    }

    // MARK: - Save Import

    /// Atomically save a reviewed draft as a Recipe + Ingredients.
    /// Uses a child context so template service saves stay in-memory until final persist.
    /// M10.6.4: Now async — attempts LLM parsing first, falls back to local pipeline.
    /// M10.6.9: Accepts index-based category assignments from preview to set on templates.
    /// Returns ImportSaveResult with recipe ID and uncategorized template IDs, or nil on failure.
    func saveImport(from draft: ImportDraftRecipe, categoryAssignments: [Int: String] = [:]) async -> ImportSaveResult? {
        state = .saving

        let resolvedHouseholdKey = householdKeyProvider?()
        DebugLogService.shared.log("saveImport: householdKey=\(resolvedHouseholdKey ?? "nil"), ingredients=\(draft.ingredients.value.count)", category: "Import")

        // Child context for atomic save — template service saves push to parent in memory
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = viewContext

        // Create services scoped to child context
        let childTemplateService = IngredientTemplateService(context: childContext)
        // M10.6.11: Propagate household key so templates are visible in IngredientsView
        childTemplateService.householdKey = resolvedHouseholdKey
        let childParsingService = IngredientParsingService(
            context: childContext,
            templateService: childTemplateService
        )

        // Create Recipe entity
        let recipe = Recipe(context: childContext)
        recipe.id = UUID()
        recipe.title = draft.title.value
        recipe.servings = Int16(draft.servings.value)
        recipe.prepTime = Int16(draft.prepTimeMinutes.value ?? 0)
        recipe.cookTime = Int16(draft.cookTimeMinutes.value ?? 0)
        recipe.instructions = draft.instructions.value
        recipe.sourceURL = draft.sourceURL
        recipe.tags = draft.tags
        recipe.dateCreated = Date()
        recipe.usageCount = 0
        recipe.isFavorite = false
        // M10.6.11: Scope recipe to current household
        recipe.householdKey = householdKeyProvider?()

        // M10.6.4: LLM-first path — try batch parsing before local pipeline
        let createdIngredients: [Ingredient]
        if let llmResult = await tryLLMParsing(
            texts: draft.ingredients.value,
            recipe: recipe,
            context: childContext,
            templateService: childTemplateService,
            categoryAssignments: categoryAssignments
        ) {
            DebugLogService.shared.log("tryLLMParsing: \(llmResult.count) results, falling back=no", category: "Import")
            createdIngredients = llmResult
        } else {
            DebugLogService.shared.log("tryLLMParsing: falling back=yes, using local pipeline", category: "Import")
            // Fallback: existing local pipeline (unchanged)
            createdIngredients = childParsingService.parseAndConnectIngredients(
                for: recipe,
                ingredientTexts: draft.ingredients.value,
                categoryAssignments: categoryAssignments
            )
        }

        // Atomic persist: child → parent → disk
        return persistAndFinish(
            recipe: recipe,
            createdIngredients: createdIngredients,
            childContext: childContext
        )
    }

    // MARK: - Replace Existing Recipe

    /// In-place update of an existing Recipe with data from the import draft.
    /// Preserves PlannedMeal references and CloudKit object identity (ADR 012).
    /// M10.6.4: Now async — attempts LLM parsing first, falls back to local pipeline.
    /// M10.6.9: Accepts index-based category assignments from preview to set on templates.
    func replaceExistingRecipe(objectID: NSManagedObjectID, with draft: ImportDraftRecipe, categoryAssignments: [Int: String] = [:]) async -> ImportSaveResult? {
        state = .saving

        // Child context for atomic replace
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = viewContext

        // Services scoped to child context
        let childTemplateService = IngredientTemplateService(context: childContext)
        // M10.6.11: Propagate household key so templates are visible in IngredientsView
        childTemplateService.householdKey = householdKeyProvider?()
        let childParsingService = IngredientParsingService(
            context: childContext,
            templateService: childTemplateService
        )

        guard let recipe = try? childContext.existingObject(with: objectID) as? Recipe else {
            state = .failed(.saveError("Could not find existing recipe"))
            return nil
        }

        // Delete existing ingredients
        if let ingredients = recipe.ingredients as? Set<Ingredient> {
            for ingredient in ingredients {
                childContext.delete(ingredient)
            }
        }

        // Update recipe fields from draft
        recipe.title = draft.title.value
        recipe.instructions = draft.instructions.value
        recipe.prepTime = Int16(draft.prepTimeMinutes.value ?? 0)
        recipe.cookTime = Int16(draft.cookTimeMinutes.value ?? 0)
        recipe.servings = Int16(draft.servings.value)
        recipe.sourceURL = draft.sourceURL
        recipe.tags = draft.tags

        // M10.6.4: LLM-first path
        let createdIngredients: [Ingredient]
        if let llmResult = await tryLLMParsing(
            texts: draft.ingredients.value,
            recipe: recipe,
            context: childContext,
            templateService: childTemplateService,
            categoryAssignments: categoryAssignments
        ) {
            createdIngredients = llmResult
        } else {
            createdIngredients = childParsingService.parseAndConnectIngredients(
                for: recipe,
                ingredientTexts: draft.ingredients.value,
                categoryAssignments: categoryAssignments
            )
        }

        // Atomic persist: child → parent → disk
        return persistAndFinish(
            recipe: recipe,
            createdIngredients: createdIngredients,
            childContext: childContext
        )
    }

    // MARK: - M10.6.4: LLM Parsing Integration

    /// Attempt LLM batch parsing for ingredient texts.
    /// Returns created Ingredient entities on success, nil on any failure (silent fallback).
    /// M10.6.9: Accepts category assignments to set on templates during creation.
    private func tryLLMParsing(
        texts: [String],
        recipe: Recipe,
        context: NSManagedObjectContext,
        templateService: IngredientTemplateService,
        categoryAssignments: [Int: String] = [:]
    ) async -> [Ingredient]? {
        guard let parser = LLMSettingsService.shared.activeParser() else { return nil }

        do {
            let llmResults = try await parser.parseBatch(texts)

            // M10.6.9: Validate count — if LLM returned fewer results than inputs,
            // fall back to local pipeline so no ingredients are silently dropped.
            // Truncate extras (LLM sometimes splits compound lines).
            let validResults: [LLMParserResult]
            if llmResults.count < texts.count {
                #if DEBUG
                print("⚠️ M10.6.9: LLM returned \(llmResults.count) results for \(texts.count) inputs — falling back to local pipeline")
                #endif
                return nil
            } else if llmResults.count > texts.count {
                validResults = Array(llmResults.prefix(texts.count))
            } else {
                validResults = llmResults
            }

            var createdIngredients: [Ingredient] = []

            for (index, llmResult) in validResults.enumerated() {
                let originalText = texts[index]
                let parserResult = llmResult.toParserResult(originalText: originalText, provider: parser.providerName)

                let ingredient = Ingredient(context: context)
                ingredient.id = UUID()
                ingredient.name = originalText
                ingredient.numericValue = llmResult.quantity ?? 0.0
                ingredient.standardUnit = llmResult.unit
                ingredient.displayText = formatDisplayText(quantity: llmResult.quantity, unit: llmResult.unit)
                ingredient.isParseable = llmResult.quantity != nil
                ingredient.parseConfidence = llmResult.confidence
                ingredient.notes = llmResult.notes
                ingredient.sortOrder = Int16(index)
                ingredient.recipe = recipe

                // M10.6.9: Use category from preview assignments if available
                let template = templateService.findOrCreateTemplate(
                    name: llmResult.name,
                    category: categoryAssignments[index]
                )
                ingredient.ingredientTemplate = template
                // M10.6.12: Removed redundant incrementUsage — findOrCreateTemplate already increments

                createdIngredients.append(ingredient)

                // Telemetry — log with "claude" (or provider name) as parserUsed
                _ = ParsingTelemetryService.shared.logParsingEvent(
                    rawInput: originalText,
                    parsedName: parserResult.name,
                    parsedQuantity: parserResult.quantity,
                    parsedUnit: parserResult.unit,
                    parseConfidence: parserResult.confidence,
                    parserUsed: parser.providerName,
                    source: .import_
                )
            }

            return createdIngredients
        } catch {
            // Silent fallback — any LLM error triggers pipeline path
            #if DEBUG
            print("⚠️ M10.6.4: LLM parsing failed, falling back to pipeline: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Format display text from quantity and unit (e.g., "2 cups", "1.5", "")
    private func formatDisplayText(quantity: Double?, unit: String?) -> String {
        var parts: [String] = []
        if let qty = quantity { parts.append(String(qty)) }
        if let unit = unit { parts.append(unit) }
        return parts.joined(separator: " ")
    }

    // MARK: - Persist Helper

    /// Shared persist logic for saveImport and replaceExistingRecipe
    private func persistAndFinish(
        recipe: Recipe,
        createdIngredients: [Ingredient],
        childContext: NSManagedObjectContext
    ) -> ImportSaveResult? {
        do {
            try childContext.save()
            DebugLogService.shared.log("persistAndFinish: child save=ok", category: "Import")
            try viewContext.save()
            DebugLogService.shared.log("persistAndFinish: parent save=ok", category: "Import")

            let uncategorizedIDs = createdIngredients.compactMap { ingredient -> NSManagedObjectID? in
                guard let template = ingredient.ingredientTemplate else { return nil }
                if template.category == nil || template.category?.isEmpty == true {
                    return template.objectID
                }
                return nil
            }
            let uniqueIDs = Array(Set(uncategorizedIDs))

            let objectID = recipe.objectID
            state = .saved(objectID)
            return ImportSaveResult(recipeObjectID: objectID, uncategorizedTemplateIDs: uniqueIDs)
        } catch {
            DebugLogService.shared.log("persistAndFinish: FAILED — \(error.localizedDescription)", category: "Import")
            viewContext.rollback()
            state = .failed(.saveError(error.localizedDescription))
            return nil
        }
    }

    // MARK: - Duplicate Detection

    /// Check if a draft recipe already exists in the database.
    /// Called by the preview UI before save — returns nil if no duplicate found.
    func checkDuplicate(for draft: ImportDraftRecipe) -> DuplicateResult? {
        DuplicateDetectionService.checkForDuplicate(
            title: draft.title.value,
            sourceURL: draft.sourceURL,
            context: viewContext
        )
    }

    // MARK: - Cancel

    /// Reset to idle state. No cleanup needed — draft is in-memory only.
    func cancelImport() {
        state = .idle
    }

    // MARK: - Unsupported Source Detection

    /// Pre-flight check for URLs that will never yield recipe data.
    /// Fails fast with a helpful message instead of wasting a network round-trip.
    private func checkUnsupportedSource(_ url: URL) -> ImportError? {
        guard let host = url.host?.lowercased() else { return nil }

        if host.contains("pinterest") {
            return .unsupportedSource("Pinterest pins don't contain recipe data. Try the original recipe link.")
        }
        if host.contains("tiktok") || host.contains("instagram") || host.contains("facebook.com/reel") {
            return .unsupportedSource("Social media video import is not yet supported.")
        }
        return nil
    }

    // MARK: - HTML Fetching

    /// Fetch HTML from a URL with a mobile User-Agent.
    /// Throws ImportError for network/HTTP failures.
    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw ImportError.timeout
            }
            throw ImportError.networkError(urlError.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImportError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 403 || httpResponse.statusCode == 451 {
                throw ImportError.paywallDetected
            }
            throw ImportError.networkError("HTTP \(httpResponse.statusCode)")
        }

        guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .ascii) else {
            throw ImportError.malformedData("Could not decode response")
        }

        return html
    }
}
