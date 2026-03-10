//
//  SchemaRecipeMapper.swift
//  forager
//
//  Created for M10.1.2: JSON-LD extractor + schema mapper
//  Ported from Tools/import-spike — maps schema.org/Recipe dict to ImportDraftRecipe.
//  Handles 5 instruction formats, 4 ingredient formats, 4 image formats, 4 author formats.
//

import Foundation

// MARK: - Schema.org Recipe Mapper

/// Maps a schema.org/Recipe JSON dictionary to an ImportDraftRecipe model.
/// Handles the many format variations found across real recipe sites.
/// Produces ImportField<T> wrappers with confidence levels driven by extraction quality.
enum SchemaRecipeMapper {

    /// Map a schema.org Recipe dict to an ImportDraftRecipe.
    /// Confidence is `.high` for cleanly extracted structured data,
    /// `.medium` when unusual formats required extra parsing.
    static func map(
        _ dict: [String: Any],
        sourceURL: String?,
        extractionMethod: String,
        extractionTimeMs: Int
    ) -> ImportDraftRecipe {
        var draft = ImportDraftRecipe.empty()
        draft.sourceURL = sourceURL
        draft.extractionMethod = extractionMethod
        draft.extractionTimeMs = extractionTimeMs

        let source: ImportFieldSource = .jsonLD

        // Title
        if let title = stringValue(dict["name"]), !title.isEmpty {
            draft.title = ImportField(value: title, confidence: .high, source: source)
        }

        // Author (4 formats: string, Person object, array of objects, array of strings)
        if let author = extractAuthor(dict["author"]) {
            draft.author = ImportField(value: author, confidence: .high, source: source)
        }

        // Description, cuisine, category — simple string fields
        draft.description = stringValue(dict["description"])
        draft.cuisine = stringValue(dict["recipeCuisine"])
        draft.category = stringValue(dict["recipeCategory"])

        // Ingredients (4 formats: string array, single string, PropertyValue objects, mixed)
        if let ingredients = extractIngredients(dict["recipeIngredient"]), !ingredients.isEmpty {
            draft.ingredients = ImportField(value: ingredients, confidence: .high, source: source)
        }

        // Instructions (5 formats: string, string array, HowToStep, HowToSection, mixed)
        var hadSections = false
        if let instructions = extractInstructions(dict["recipeInstructions"], hadSections: &hadSections) {
            // HowToSection nesting reduces confidence — more structure to misinterpret
            let confidence: ImportConfidence = hadSections ? .medium : .high
            draft.instructions = ImportField(value: instructions, confidence: confidence, source: source)
        }

        // Times (ISO 8601 duration or bare numbers)
        if let prep = extractTime(dict["prepTime"]) {
            draft.prepTimeMinutes = ImportField(value: prep, confidence: .high, source: source)
        }
        if let cook = extractTime(dict["cookTime"]) {
            draft.cookTimeMinutes = ImportField(value: cook, confidence: .high, source: source)
        }

        // Servings/yield (integer, string, array — unusual formats get medium confidence)
        let (servings, hadUnusualYield) = extractYield(dict["recipeYield"])
        if let servings = servings {
            let confidence: ImportConfidence = hadUnusualYield ? .medium : .high
            draft.servings = ImportField(value: servings, confidence: confidence, source: source)
        }

        // Image (4 formats: URL string, ImageObject, array of strings, array of ImageObjects)
        if let imageURL = extractImageURL(dict["image"]) {
            draft.imageURL = ImportField(value: imageURL, confidence: .high, source: source)
        }

        return draft
    }

    // MARK: - Field Extractors

    /// Extract a string from various JSON value types, decoding HTML entities.
    private static func stringValue(_ value: Any?) -> String? {
        guard let value = value else { return nil }

        var result: String?
        if let str = value as? String {
            let cleaned = str.trimmingCharacters(in: .whitespacesAndNewlines)
            result = cleaned.isEmpty ? nil : cleaned
        } else if let array = value as? [String], let first = array.first {
            result = first.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Decode HTML entities (e.g., &amp; → &) — same pattern as cleanInstructionText
        if let text = result, HTMLEntityDecoder.containsEntities(text) {
            result = HTMLEntityDecoder.decode(text)
        }

        return result
    }

    /// Extract author name from various author formats.
    private static func extractAuthor(_ value: Any?) -> String? {
        guard let value = value else { return nil }

        if let str = value as? String { return str }

        // Person/Organization object
        if let dict = value as? [String: Any] {
            return stringValue(dict["name"])
        }

        // Array of Person/Organization objects
        if let array = value as? [[String: Any]], let first = array.first {
            return stringValue(first["name"])
        }

        // Array of strings
        if let array = value as? [String], let first = array.first {
            return first
        }

        return nil
    }

    /// Extract ingredients array, handling various formats.
    private static func extractIngredients(_ value: Any?) -> [String]? {
        guard let value = value else { return nil }

        // Standard: array of strings
        if let array = value as? [String] {
            return filterIngredientHeaders(array)
        }

        // Single string (some sites join all ingredients)
        if let str = value as? String {
            let lines = str.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return filterIngredientHeaders(lines)
        }

        // Array of PropertyValue objects
        if let array = value as? [[String: Any]] {
            let strings = array.compactMap { item -> String? in
                if let text = item["text"] as? String { return text }
                if let name = item["name"] as? String { return name }
                return nil
            }
            return strings.isEmpty ? nil : filterIngredientHeaders(strings)
        }

        return nil
    }

    /// Filter out ingredient group headers like "For the sauce:", "Dressing:"
    private static func filterIngredientHeaders(_ ingredients: [String]) -> [String] {
        ingredients.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }

            // Detect group headers — end with ":" and match known header patterns
            if trimmed.hasSuffix(":") {
                let withoutColon = String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces)
                let headerPatterns = ["for the", "for ", "sauce", "filling", "topping",
                                      "dressing", "marinade", "garnish", "crust", "frosting",
                                      "glaze", "batter", "dough"]
                let lower = withoutColon.lowercased()
                if headerPatterns.contains(where: { lower.hasPrefix($0) || lower == $0 }) {
                    return false
                }
            }
            return true
        }
    }

    /// Extract instructions from various formats.
    private static func extractInstructions(_ value: Any?, hadSections: inout Bool) -> String? {
        guard let value = value else { return nil }

        // Direct string
        if let str = value as? String {
            let cleaned = cleanInstructionText(str)
            return cleaned.isEmpty ? nil : cleaned
        }

        // Array of strings
        if let array = value as? [String] {
            let cleaned = array.map { cleanInstructionText($0) }
                .filter { !$0.isEmpty }
            return cleaned.isEmpty ? nil : formatInstructionSteps(cleaned)
        }

        // Array of HowToStep or HowToSection objects
        if let array = value as? [[String: Any]] {
            return extractFromHowToArray(array, hadSections: &hadSections)
        }

        // Mixed array (strings and objects)
        if let array = value as? [Any] {
            var steps: [String] = []
            for item in array {
                if let str = item as? String {
                    steps.append(cleanInstructionText(str))
                } else if let dict = item as? [String: Any] {
                    if let extracted = extractFromHowToDict(dict, hadSections: &hadSections) {
                        steps.append(contentsOf: extracted)
                    }
                }
            }
            return steps.isEmpty ? nil : formatInstructionSteps(steps)
        }

        return nil
    }

    /// Extract steps from an array of HowTo objects.
    private static func extractFromHowToArray(_ array: [[String: Any]], hadSections: inout Bool) -> String? {
        var steps: [String] = []

        for item in array {
            if let extracted = extractFromHowToDict(item, hadSections: &hadSections) {
                steps.append(contentsOf: extracted)
            }
        }

        return steps.isEmpty ? nil : formatInstructionSteps(steps)
    }

    /// Extract step text from a single HowTo dict (HowToStep or HowToSection).
    private static func extractFromHowToDict(_ dict: [String: Any], hadSections: inout Bool) -> [String]? {
        let type = dict["@type"] as? String ?? ""

        if type == "HowToStep" {
            if let text = dict["text"] as? String {
                return [cleanInstructionText(text)]
            }
            if let name = dict["name"] as? String {
                return [cleanInstructionText(name)]
            }
            return nil
        }

        if type == "HowToSection" {
            hadSections = true
            var steps: [String] = []
            if let name = dict["name"] as? String {
                steps.append("**\(name)**")
            }
            if let items = dict["itemListElement"] as? [[String: Any]] {
                for item in items {
                    if let extracted = extractFromHowToDict(item, hadSections: &hadSections) {
                        steps.append(contentsOf: extracted)
                    }
                }
            }
            return steps.isEmpty ? nil : steps
        }

        // Generic object with text
        if let text = dict["text"] as? String {
            return [cleanInstructionText(text)]
        }

        return nil
    }

    /// Clean up instruction text — remove HTML tags and excess whitespace.
    private static func cleanInstructionText(_ text: String) -> String {
        var cleaned = text
        // Strip HTML tags
        cleaned = cleaned.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        // Collapse whitespace
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        // Decode HTML entities
        if HTMLEntityDecoder.containsEntities(cleaned) {
            cleaned = HTMLEntityDecoder.decode(cleaned)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Format instruction steps with numbered lines.
    private static func formatInstructionSteps(_ steps: [String]) -> String {
        var result: [String] = []
        var stepNum = 1
        for step in steps {
            if step.hasPrefix("**") {
                // Section header — don't number it
                result.append(step)
            } else {
                result.append("\(stepNum). \(step)")
                stepNum += 1
            }
        }
        return result.joined(separator: "\n")
    }

    /// Extract time value from ISO 8601 duration or other formats.
    private static func extractTime(_ value: Any?) -> Int? {
        guard let value = value else { return nil }

        if let str = value as? String {
            return ISO8601DurationParser.parseToMinutes(str)
        }

        if let num = value as? Int { return num }
        if let num = value as? Double { return Int(num) }

        return nil
    }

    /// Extract yield/servings value from various formats.
    /// Returns (parsed servings, whether unusual format was encountered).
    private static func extractYield(_ value: Any?) -> (Int?, Bool) {
        guard let value = value else { return (nil, false) }

        // Direct integer
        if let num = value as? Int { return (num, false) }

        // String
        if let str = value as? String {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            let parsed = RecipeYieldParser.parse(trimmed)
            let unusual = parsed != nil && Int(trimmed) == nil
            return (parsed, unusual)
        }

        // Array — take first element
        if let array = value as? [Any], let first = array.first {
            if let str = first as? String {
                let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsed = RecipeYieldParser.parse(trimmed)
                let unusual = parsed != nil && Int(trimmed) == nil
                return (parsed, unusual)
            }
            if let num = first as? Int { return (num, false) }
        }

        return (nil, false)
    }

    /// Extract image URL from various formats.
    private static func extractImageURL(_ value: Any?) -> String? {
        guard let value = value else { return nil }

        // Direct URL string
        if let str = value as? String { return str }

        // ImageObject
        if let dict = value as? [String: Any] {
            return dict["url"] as? String ?? dict["contentUrl"] as? String
        }

        // Array of strings — take first
        if let array = value as? [String], let first = array.first { return first }

        // Array of ImageObjects — take first
        if let array = value as? [[String: Any]], let first = array.first {
            return first["url"] as? String ?? first["contentUrl"] as? String
        }

        return nil
    }
}
