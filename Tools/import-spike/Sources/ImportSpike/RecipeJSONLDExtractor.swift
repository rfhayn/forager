import Foundation

// MARK: - JSON-LD Extractor

/// Extracts JSON-LD recipe data from HTML content.
/// Searches multiple locations: standard ld+json tags, inline script blocks,
/// and __NEXT_DATA__ server-side rendering payloads.
enum RecipeJSONLDExtractor {

    struct ExtractionContext {
        var jsonLDFound = false
        var recipeFound = false
        var usedGraphWrapper = false
        var usedArrayType = false
        var hadHTMLEntities = false
        var extractionMethod = "none"
        var issues: [String] = []
    }

    /// Extract a Recipe from an HTML string.
    /// Tries multiple extraction strategies in order of reliability.
    static func extract(from html: String) -> (recipe: [String: Any], context: ExtractionContext)? {
        var ctx = ExtractionContext()

        // Strategy 1: Standard <script type="application/ld+json"> blocks
        if let result = extractFromLDJsonTags(html: html, context: &ctx) {
            ctx.extractionMethod = "ld+json"
            return (result.recipe, ctx)
        }

        // Strategy 2: Inline JSON-LD in regular <script> blocks
        if let result = extractFromInlineScripts(html: html, context: &ctx) {
            ctx.extractionMethod = "inline-script"
            return (result.recipe, ctx)
        }

        // Strategy 3: __NEXT_DATA__ (Next.js SSR payload)
        if let result = extractFromNextData(html: html, context: &ctx) {
            ctx.extractionMethod = "__NEXT_DATA__"
            return (result.recipe, ctx)
        }

        if !ctx.jsonLDFound {
            ctx.issues.append("No JSON-LD or recipe structured data found")
        }
        return nil
    }

    // MARK: - Strategy 1: Standard LD+JSON Tags

    private static func extractFromLDJsonTags(html: String, context: inout ExtractionContext) -> (recipe: [String: Any], context: ExtractionContext)? {
        let jsonLDBlocks = extractJSONLDBlocks(from: html)
        guard !jsonLDBlocks.isEmpty else { return nil }
        context.jsonLDFound = true

        for block in jsonLDBlocks {
            var cleaned = block
            if block.contains("&amp;") || block.contains("&#") || block.contains("&lt;") {
                cleaned = decodeHTMLEntities(block)
                context.hadHTMLEntities = true
            }

            guard let data = cleaned.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else {
                context.issues.append("Failed to parse JSON-LD block")
                continue
            }

            if let recipe = findRecipe(in: json, context: &context) {
                context.recipeFound = true
                return (recipe, context)
            }
        }

        context.issues.append("JSON-LD found but no Recipe @type detected in ld+json tags")
        return nil
    }

    // MARK: - Strategy 2: Inline Script Blocks

    /// Some sites (e.g., Marmiton) embed JSON-LD in regular <script> blocks,
    /// not in the standard application/ld+json type.
    private static func extractFromInlineScripts(html: String, context: inout ExtractionContext) -> (recipe: [String: Any], context: ExtractionContext)? {
        // Look for script blocks containing schema.org Recipe data
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
            guard content.count < 50000 else { continue }

            // Look for inline JSON-LD that contains Recipe schema
            guard content.contains("\"@type\"") && content.contains("\"Recipe\"") && content.contains("recipeIngredient") else {
                continue
            }

            // Try to extract the JSON object from the script content
            if let jsonStr = extractJSONFromScript(content),
               let data = jsonStr.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data),
               let recipe = findRecipe(in: json, context: &context) {
                context.jsonLDFound = true
                context.recipeFound = true
                return (recipe, context)
            }
        }

        return nil
    }

    /// Try to extract a JSON object from script content that may have variable assignment.
    private static func extractJSONFromScript(_ content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct JSON object or array
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return trimmed
        }

        // Variable assignment: var x = {...}; or const x = {...};
        // Find the first { and match to its closing }
        if let startIdx = trimmed.firstIndex(of: "{") {
            let substring = String(trimmed[startIdx...])
            if let json = extractBalancedJSON(from: substring) {
                return json
            }
        }

        return nil
    }

    /// Extract a balanced JSON object from a string starting with {.
    private static func extractBalancedJSON(from string: String) -> String? {
        var depth = 0
        var inString = false
        var escaped = false
        var endIndex = string.startIndex

        for (i, char) in string.enumerated() {
            let idx = string.index(string.startIndex, offsetBy: i)

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
                        endIndex = string.index(after: idx)
                        return String(string[string.startIndex..<endIndex])
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Strategy 3: __NEXT_DATA__

    /// Next.js sites embed page data in <script id="__NEXT_DATA__">.
    /// The recipe may be nested deep inside the props structure.
    private static func extractFromNextData(html: String, context: inout ExtractionContext) -> (recipe: [String: Any], context: ExtractionContext)? {
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

        // Recursively search for any dict with recipeIngredient (Recipe-like data)
        if let recipe = findRecipeInNextData(json, context: &context) {
            context.jsonLDFound = true
            context.recipeFound = true
            return (recipe, context)
        }

        return nil
    }

    /// Search __NEXT_DATA__ for recipe-like objects.
    /// These may not have @type but will have recipeIngredient.
    private static func findRecipeInNextData(_ json: Any, context: inout ExtractionContext) -> [String: Any]? {
        // First try standard Recipe @type search
        if let recipe = findRecipe(in: json, context: &context) {
            return recipe
        }

        // Fall back to looking for objects with recipeIngredient key
        return findObjectWithRecipeKeys(in: json)
    }

    /// Find any dict that has recipe-like keys.
    /// Requires `recipeIngredient` (the single most distinctive Recipe key) plus at least
    /// one other recipe key. This prevents false positives from non-recipe objects that
    /// happen to have cookTime or prepTime (e.g., BBC Good Food __NEXT_DATA__).
    private static func findObjectWithRecipeKeys(in json: Any) -> [String: Any]? {
        if let dict = json as? [String: Any] {
            // Check if this dict qualifies as a recipe
            if dict["recipeIngredient"] != nil {
                let secondaryKeys = ["recipeInstructions", "cookTime", "prepTime", "name", "recipeYield"]
                let secondaryCount = secondaryKeys.filter { dict[$0] != nil }.count
                if secondaryCount >= 1 {
                    return dict
                }
            }

            // Recurse into dict values
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

            // Check for @graph wrapper (handle both [[String:Any]] and [Any])
            if let graph = dict["@graph"] as? [Any] {
                context.usedGraphWrapper = true
                for item in graph {
                    if let itemDict = item as? [String: Any],
                       isRecipeType(itemDict, context: &context) {
                        return itemDict
                    }
                }
            }

            // Recurse into dict values
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

    // MARK: - HTML Entity Decoding

    /// Decode common HTML entities found in JSON-LD strings.
    static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&#x27;", "'"),
            ("&#x2F;", "/"),
            ("&nbsp;", " "),
            ("&#8217;", "\u{2019}"),
            ("&#8216;", "\u{2018}"),
            ("&#8220;", "\u{201C}"),
            ("&#8221;", "\u{201D}"),
            ("&#8211;", "\u{2013}"),
            ("&#8212;", "\u{2014}"),
            ("&#176;", "\u{00B0}"),
            ("&#xBC;", "\u{00BC}"),
            ("&#xBD;", "\u{00BD}"),
            ("&#xBE;", "\u{00BE}"),
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Handle numeric entities like &#123;
        let numericPattern = #"&#(\d+);"#
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let nsResult = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsResult.length))
            for match in matches.reversed() {
                let fullRange = match.range
                let numRange = match.range(at: 1)
                if let num = Int(nsResult.substring(with: numRange)),
                   let scalar = Unicode.Scalar(num) {
                    result = (result as NSString).replacingCharacters(in: fullRange, with: String(scalar))
                }
            }
        }

        return result
    }
}
