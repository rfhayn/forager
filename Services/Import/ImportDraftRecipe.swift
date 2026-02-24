//
//  ImportDraftRecipe.swift
//  forager
//
//  Created for M10.1.1: Import models + extraction infrastructure
//  In-memory draft model for recipe import — never persisted directly.
//  Maps into RecipeFormData at save time via toRecipeFormData().
//

import Foundation
import CoreData

// MARK: - Import Field Confidence

/// Confidence level for an extracted field, drives UI indicator dots
enum ImportConfidence: Int, Comparable, Equatable, Codable {
    case missing = 0   // User must provide
    case low = 1       // Red dot — inferred or defaulted
    case medium = 2    // Amber dot — less reliable source
    case high = 3      // Green dot — structured data source

    static func < (lhs: ImportConfidence, rhs: ImportConfidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Import Field Source

/// Tracks which extraction method produced a field value
enum ImportFieldSource: String, Equatable, Codable {
    case jsonLD
    case wkWebView
    case nextData
    case heuristic
    case foundationModels
    case ocr
    case manual
}

// MARK: - Import Field Generic Wrapper

/// Wraps any extracted field with confidence, source attribution, and edit tracking
struct ImportField<T: Equatable>: Equatable {
    var value: T
    var confidence: ImportConfidence
    var source: ImportFieldSource
    var wasEdited: Bool = false
}

// MARK: - Extraction Success Level

enum ExtractionSuccessLevel: Equatable {
    case full      // All core fields present (title + ingredients + instructions)
    case partial   // Some core fields missing — user must fill in
    case failure   // No usable data extracted
}

// MARK: - Import Draft Recipe

/// In-memory staging model for imported recipe data.
/// Never persisted directly — maps into RecipeFormData at save time.
/// Carries per-field confidence for the preview UI.
struct ImportDraftRecipe: Equatable {
    var title: ImportField<String>
    var ingredients: ImportField<[String]>     // Raw text strings from extraction
    var instructions: ImportField<String>
    var prepTimeMinutes: ImportField<Int?>
    var cookTimeMinutes: ImportField<Int?>
    var servings: ImportField<Int>
    var imageURL: ImportField<String?>
    var author: ImportField<String?>
    var sourceURL: String?
    var description: String?
    var cuisine: String?
    var category: String?
    var tags: String?

    var extractionMethod: String               // "ld+json", "wkwebview", etc.
    var extractionTimeMs: Int

    // MARK: - Computed Properties

    var successLevel: ExtractionSuccessLevel {
        let hasTitle = !title.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasIngredients = !ingredients.value.isEmpty
        let hasInstructions = !instructions.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasTitle && hasIngredients && hasInstructions {
            return .full
        } else if hasTitle || hasIngredients || hasInstructions {
            return .partial
        } else {
            return .failure
        }
    }

    var fieldsMissing: [String] {
        var missing: [String] = []
        if title.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("title") }
        if ingredients.value.isEmpty { missing.append("ingredients") }
        if instructions.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("instructions") }
        return missing
    }

    // MARK: - Factory

    /// Pre-populated with safe defaults — extractors start from this
    static func empty() -> ImportDraftRecipe {
        ImportDraftRecipe(
            title: ImportField(value: "", confidence: .missing, source: .manual),
            ingredients: ImportField(value: [], confidence: .missing, source: .manual),
            instructions: ImportField(value: "", confidence: .missing, source: .manual),
            prepTimeMinutes: ImportField(value: nil, confidence: .missing, source: .manual),
            cookTimeMinutes: ImportField(value: nil, confidence: .missing, source: .manual),
            servings: ImportField(value: 4, confidence: .low, source: .manual),
            imageURL: ImportField(value: nil, confidence: .missing, source: .manual),
            author: ImportField(value: nil, confidence: .missing, source: .manual),
            sourceURL: nil,
            description: nil,
            cuisine: nil,
            category: nil,
            tags: nil,
            extractionMethod: "manual",
            extractionTimeMs: 0
        )
    }

    // MARK: - Mapping to RecipeFormData

    /// Converts import draft into the form model used by recipe creation.
    /// Fields not present on RecipeFormData (author, imageURL, cuisine, etc.)
    /// are preview-only and dropped at this point.
    func toRecipeFormData() -> RecipeFormData {
        var formData = RecipeFormData()
        formData.name = title.value.trimmingCharacters(in: .whitespacesAndNewlines)
        formData.prepTime = prepTimeMinutes.value ?? 0
        formData.cookTime = cookTimeMinutes.value ?? 0
        formData.servings = servings.value
        formData.instructions = instructions.value
        formData.tags = tags ?? ""
        formData.isFavorite = false

        // Convert raw ingredient strings into IngredientInput items
        formData.ingredients = ingredients.value.map { text in
            IngredientInput(fullText: text)
        }

        return formData
    }
}

// MARK: - Import Job State Machine

/// State machine for the import flow.
/// idle → received → fetching → extracting → needsReview → saving → saved
/// Any state can transition to failed.
enum ImportJobState: Equatable {
    case idle
    case received(URL)
    case fetching
    case extracting(method: String)
    case needsReview(ImportDraftRecipe)
    case saving
    case saved(NSManagedObjectID)   // Uses ObjectID, not Recipe — NSManagedObject equality is reference-based
    case failed(ImportError)

    var isLoading: Bool {
        switch self {
        case .fetching, .extracting, .saving: return true
        default: return false
        }
    }

    var statusMessage: String {
        switch self {
        case .idle: return ""
        case .received: return "Preparing to import..."
        case .fetching: return "Fetching recipe..."
        case .extracting(let method): return "Extracting recipe via \(method)..."
        case .needsReview: return "Review imported recipe"
        case .saving: return "Saving recipe..."
        case .saved: return "Recipe saved!"
        case .failed(let error): return error.userMessage
        }
    }
}

// MARK: - Import Error

/// Complete error taxonomy for recipe import.
/// Every case maps to a user-facing message — zero silent failures.
enum ImportError: LocalizedError, Equatable {
    // Network (M10.1)
    case networkError(String)
    case timeout

    // Extraction (M10.1-M10.3)
    case noRecipeFound
    case paywallDetected
    case malformedData(String)
    case unsupportedSource(String)

    // Duplicate (M10.1)
    case duplicateFound(existingTitle: String)

    // Save (all phases)
    case saveError(String)

    // OCR (M10.3)
    case ocrFailed(String)
    case cameraPermissionDenied
    case noTextDetected

    // AI (M10.2-M10.3) — silent fallback, not shown to user directly
    case aiExtractionFailed
    case aiUnavailable

    var userMessage: String {
        switch self {
        case .networkError(let detail):
            return "Unable to reach site. \(detail)"
        case .timeout:
            return "Request timed out. Try again."
        case .noRecipeFound:
            return "No recipe found on this page."
        case .paywallDetected:
            return "This recipe may be behind a paywall. Try copying the recipe text instead."
        case .malformedData(let detail):
            return "Recipe data found but couldn't be read. \(detail)"
        case .unsupportedSource(let detail):
            return "\(detail)"
        case .duplicateFound(let title):
            return "A similar recipe already exists: \"\(title)\""
        case .saveError(let detail):
            return "Failed to save recipe. \(detail)"
        case .ocrFailed(let detail):
            return "Text recognition failed. \(detail)"
        case .cameraPermissionDenied:
            return "Camera access required. Enable in Settings."
        case .noTextDetected:
            return "No text detected in image. Try a clearer photo."
        case .aiExtractionFailed:
            return "Could not extract recipe structure."
        case .aiUnavailable:
            return "Recipe extraction unavailable on this device."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .ocrFailed:
            return true
        case .noRecipeFound, .paywallDetected, .malformedData, .unsupportedSource,
             .duplicateFound, .saveError, .cameraPermissionDenied, .noTextDetected,
             .aiExtractionFailed, .aiUnavailable:
            return false
        }
    }

    var errorDescription: String? { userMessage }
}

// MARK: - Duplicate Detection Result

/// Result from duplicate detection — used by import orchestrator
enum DuplicateResult: Equatable {
    case exactURL(NSManagedObjectID)
    case fuzzyTitle(NSManagedObjectID, title: String, distance: Int)
}
