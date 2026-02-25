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

    // MARK: - Save Import

    /// Atomically save a reviewed draft as a Recipe + Ingredients.
    /// Uses a child context so template service saves stay in-memory until final persist.
    /// Returns the saved Recipe's objectID, or nil on failure.
    func saveImport(from draft: ImportDraftRecipe) -> NSManagedObjectID? {
        state = .saving

        // Child context for atomic save — template service saves push to parent in memory
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = viewContext

        // Create services scoped to child context
        let childTemplateService = IngredientTemplateService(context: childContext)
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

        // Parse and connect ingredients — template saves go to childContext only
        let _ = childParsingService.parseAndConnectIngredients(
            for: recipe,
            ingredientTexts: draft.ingredients.value
        )

        // Atomic persist: child → parent → disk
        do {
            try childContext.save()    // Push all changes to viewContext (in memory)
            try viewContext.save()     // Persist everything to disk in one write
            let objectID = recipe.objectID
            state = .saved(objectID)
            return objectID
        } catch {
            viewContext.rollback()
            state = .failed(.saveError(error.localizedDescription))
            return nil
        }
    }

    // MARK: - Replace Existing Recipe

    /// In-place update of an existing Recipe with data from the import draft.
    /// Preserves PlannedMeal references and CloudKit object identity (ADR 012).
    /// Deletes old Ingredients and creates new ones via parseAndConnectIngredients.
    func replaceExistingRecipe(objectID: NSManagedObjectID, with draft: ImportDraftRecipe) -> NSManagedObjectID? {
        state = .saving

        // Child context for atomic replace
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = viewContext

        // Services scoped to child context
        let childTemplateService = IngredientTemplateService(context: childContext)
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

        // Parse and connect new ingredients
        let _ = childParsingService.parseAndConnectIngredients(
            for: recipe,
            ingredientTexts: draft.ingredients.value
        )

        // Atomic persist: child → parent → disk
        do {
            try childContext.save()
            try viewContext.save()
            state = .saved(objectID)
            return objectID
        } catch {
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
