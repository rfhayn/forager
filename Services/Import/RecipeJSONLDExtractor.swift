//
//  RecipeJSONLDExtractor.swift
//  forager
//
//  Created for M10.1.2: JSON-LD extractor + schema mapper
//  Ported from Tools/import-spike — extracts JSON-LD recipe data from HTML.
//  3-tier strategy: standard ld+json → inline script blocks → __NEXT_DATA__
//

import Foundation

// MARK: - JSON-LD Extractor

/// Extracts JSON-LD recipe data from HTML content.
/// Implements RecipeExtractor protocol for the strategy pattern.
/// Tries multiple locations: standard ld+json tags, inline script blocks,
/// and __NEXT_DATA__ server-side rendering payloads.
class RecipeJSONLDExtractor: RecipeExtractor {

    let extractorName = "json-ld"

    func extract(from input: RecipeExtractionInput) async throws -> ImportDraftRecipe? {
        guard case .html(let html, let url) = input else { return nil }

        let startTime = CFAbsoluteTimeGetCurrent()
        var context = ExtractionContext()
        context.extractorChain.append(extractorName)

        guard let (recipeDict, updatedContext) = Self.extractRecipeDict(from: html, context: &context) else {
            return nil
        }

        let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        // Map the raw dict to ImportDraftRecipe via SchemaRecipeMapper
        let draft = SchemaRecipeMapper.map(
            recipeDict,
            sourceURL: url.absoluteString,
            extractionMethod: updatedContext.extractorChain.last ?? "ld+json",
            extractionTimeMs: elapsedMs
        )

        return draft
    }

    // MARK: - Core Extraction (static for testability)

    /// Extract a Recipe dict from HTML. Returns nil if no recipe found.
    static func extractRecipeDict(from html: String, context: inout ExtractionContext) -> ([String: Any], ExtractionContext)? {
        // Strategy 1: Standard <script type="application/ld+json"> blocks
        if let result = extractFromLDJsonTags(html: html, context: &context) {
            return result
        }

        // Strategy 2: Inline JSON-LD in regular <script> blocks
        if let result = extractFromInlineScripts(html: html, context: &context) {
            return result
        }

        // Strategy 3: __NEXT_DATA__ (Next.js SSR payload)
        if let result = extractFromNextData(html: html, context: &context) {
            return result
        }

        return nil
    }

    // MARK: - Strategy 1: Standard LD+JSON Tags

    private static func extractFromLDJsonTags(html: String, context: inout ExtractionContext) -> ([String: Any], ExtractionContext)? {
        let jsonLDBlocks = extractJSONLDBlocks(from: html)
        guard !jsonLDBlocks.isEmpty else { return nil }

        for block in jsonLDBlocks {
            var cleaned = block
            if HTMLEntityDecoder.containsEntities(block) {
                cleaned = HTMLEntityDecoder.decode(block)
                context.hadHTMLEntities = true
            }

            guard let data = cleaned.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else {
                continue
            }

            if let recipe = findRecipe(in: json, context: &context) {
                return (recipe, context)
            }
        }

        return nil
    }

    // MARK: - Strategy 2: Inline Script Blocks

    private static func extractFromInlineScripts(html: String, context: inout ExtractionContext) -> ([String: Any], ExtractionContext)? {
        let pattern = #"<script[^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return nil
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let content = nsHTML.substring(with: match.range(at: 1))

            // Skip ld+json blocks (already checked) and very large blocks
            if content.contains("application/ld+json") { continue }
            guard content.count < 50_000 else { continue }

            // Look for inline JSON-LD that contains Recipe schema
            guard content.contains("\"@type\"") && content.contains("\"Recipe\"") && content.contains("recipeIngredient") else {
                continue
            }

            if let jsonStr = extractJSONFromScript(content),
               let data = jsonStr.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data),
               let recipe = findRecipe(in: json, context: &context) {
                context.usedInlineScript = true
                return (recipe, context)
            }
        }

        return nil
    }

    private static func extractJSONFromScript(_ content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return trimmed
        }

        // Variable assignment: var x = {...};
        if let startIdx = trimmed.firstIndex(of: "{") {
            let substring = String(trimmed[startIdx...])
            if let json = extractBalancedJSON(from: substring) {
                return json
            }
        }

        return nil
    }

    /// Extract a balanced JSON object from a string starting with {.
    static func extractBalancedJSON(from string: String) -> String? {
        var depth = 0
        var inString = false
        var escaped = false

        for (i, char) in string.enumerated() {
            if escaped {
                escaped = false
                continue
            }

            if char == "\\" && inString {
                escaped = true
                continue
            }

            if char == "\"" {
                inString = !inString
                continue
            }

            if !inString {
                if char == "{" { depth += 1 }
                if char == "}" {
                    depth -= 1
                    if depth == 0 {
                        let endIndex = string.index(string.startIndex, offsetBy: i + 1)
                        return String(string[string.startIndex..<endIndex])
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Strategy 3: __NEXT_DATA__

    private static func extractFromNextData(html: String, context: inout ExtractionContext) -> ([String: Any], ExtractionContext)? {
        let pattern = #"<script\s+id="__NEXT_DATA__"[^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return nil
        }

        let nsHTML = html as NSString
        guard let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: nsHTML.length)),
              match.numberOfRanges > 1 else {
            return nil
        }

        let content = nsHTML.substring(with: match.range(at: 1))
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }

        // Try standard Recipe @type first, then fall back to recipe key heuristic
        if let recipe = findRecipe(in: json, context: &context) {
            context.usedNextData = true
            return (recipe, context)
        }

        if let recipe = findObjectWithRecipeKeys(in: json) {
            context.usedNextData = true
            return (recipe, context)
        }

        return nil
    }

    /// Find any dict with `recipeIngredient` (mandatory) plus at least one other recipe key.
    /// Prevents false positives from non-recipe objects (e.g., BBC Good Food __NEXT_DATA__).
    private static func findObjectWithRecipeKeys(in json: Any) -> [String: Any]? {
        if let dict = json as? [String: Any] {
            if dict["recipeIngredient"] != nil {
                let secondaryKeys = ["recipeInstructions", "cookTime", "prepTime", "name", "recipeYield"]
                let secondaryCount = secondaryKeys.filter { dict[$0] != nil }.count
                if secondaryCount >= 1 {
                    return dict
                }
            }

            for (_, value) in dict {
                if let found = findObjectWithRecipeKeys(in: value) {
                    return found
                }
            }
        }

        if let array = json as? [Any] {
            for item in array {
                if let found = findObjectWithRecipeKeys(in: item) {
                    return found
                }
            }
        }

        return nil
    }

    // MARK: - HTML Parsing

    /// Extract content from all `<script type="application/ld+json">` tags.
    static func extractJSONLDBlocks(from html: String) -> [String] {
        let pattern = #"<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let contentRange = match.range(at: 1)
            guard contentRange.location != NSNotFound else { return nil }
            return nsHTML.substring(with: contentRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // MARK: - Recipe Search

    /// Recursively search for a schema.org/Recipe object in parsed JSON.
    static func findRecipe(in json: Any, context: inout ExtractionContext) -> [String: Any]? {
        if let dict = json as? [String: Any] {
            if isRecipeType(dict, context: &context) {
                return dict
            }

            // Check for @graph wrapper
            if let graph = dict["@graph"] as? [Any] {
                context.usedGraphWrapper = true
                for item in graph {
                    if let itemDict = item as? [String: Any],
                       isRecipeType(itemDict, context: &context) {
                        return itemDict
                    }
                }
            }

            for (_, value) in dict {
                if let found = findRecipe(in: value, context: &context) {
                    return found
                }
            }
        }

        if let array = json as? [Any] {
            for item in array {
                if let found = findRecipe(in: item, context: &context) {
                    return found
                }
            }
        }

        return nil
    }

    /// Check if a dictionary has @type "Recipe" (handling string and array forms).
    private static func isRecipeType(_ dict: [String: Any], context: inout ExtractionContext) -> Bool {
        guard let typeValue = dict["@type"] else { return false }

        if let typeString = typeValue as? String {
            return typeString == "Recipe" || typeString == "https://schema.org/Recipe"
        }

        if let typeArray = typeValue as? [String] {
            if typeArray.contains("Recipe") || typeArray.contains("https://schema.org/Recipe") {
                context.usedArrayType = true
                return true
            }
        }

        return false
    }
}
