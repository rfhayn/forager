//
//  RecipeExtractor.swift
//  forager
//
//  Created for M10.1.1: Import models + extraction infrastructure
//  Strategy pattern protocol for recipe extraction — mirrors HybridIngredientParser architecture.
//  Extractors return nil when input isn't their format (same pattern as MLIngredientParser.init?()).
//

import Foundation

// MARK: - Extraction Input

/// Describes the input type for recipe extraction
enum RecipeExtractionInput {
    case html(String, url: URL)   // HTML content with source URL (M10.1: URL import)
    case text(String)              // Plain text paste (M10.2)
    case image(Data)               // Image data from camera/library (M10.3)
}

// MARK: - Recipe Extractor Protocol

/// Strategy pattern protocol for recipe extraction.
/// Each implementation handles one extraction method (JSON-LD, WKWebView, OCR, etc.).
///
/// Return contract:
/// - Return `nil` = "this input isn't my format, try the next extractor"
/// - Throw `ImportError` = "I recognized this input as mine but extraction failed"
protocol RecipeExtractor {
    var extractorName: String { get }
    func extract(from input: RecipeExtractionInput) async throws -> ImportDraftRecipe?
}

// MARK: - Extraction Context

/// Tracks which edge case paths were exercised during extraction.
/// Logged to telemetry for debugging and extraction rate analysis.
struct ExtractionContext: Equatable {
    var usedGraphWrapper: Bool = false
    var usedArrayType: Bool = false
    var hadHTMLEntities: Bool = false
    var usedNextData: Bool = false
    var usedInlineScript: Bool = false
    var extractorChain: [String] = []    // Names of extractors attempted, in order

    /// Summary string for telemetry logging
    var edgeCaseFlags: [String] {
        var flags: [String] = []
        if usedGraphWrapper { flags.append("@graph") }
        if usedArrayType { flags.append("array_type") }
        if hadHTMLEntities { flags.append("html_entities") }
        if usedNextData { flags.append("__NEXT_DATA__") }
        if usedInlineScript { flags.append("inline_script") }
        return flags
    }
}
