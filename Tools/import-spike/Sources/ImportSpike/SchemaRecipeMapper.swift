import Foundation

// MARK: - Schema.org Recipe Mapper

/// Maps a schema.org/Recipe JSON dictionary to an ExtractedRecipe model.
/// Handles the many format variations found across real recipe sites.
enum SchemaRecipeMapper {

    struct MappingContext {
        var hadHowToSteps = false
        var hadHowToSections = false
        var hadUnusualYield = false
        var issues: [String] = []
    }

    /// Map a schema.org Recipe dict to an ExtractedRecipe.
    static func map(_ dict: [String: Any], sourceURL: String?) -> (recipe: ExtractedRecipe, context: MappingContext) {
        var recipe = ExtractedRecipe()
        var ctx = MappingContext()

        recipe.sourceURL = sourceURL

        // Title
        recipe.title = stringValue(dict["name"])

        // Author
        recipe.author = extractAuthor(dict["author"])

        // Description
        recipe.description = stringValue(dict["description"])

        // Cuisine
        recipe.cuisine = stringValue(dict["recipeCuisine"])

        // Category
        recipe.category = stringValue(dict["recipeCategory"])

        // Ingredients
        recipe.ingredients = extractIngredients(dict["recipeIngredient"], context: &ctx)

        // Instructions
        recipe.instructions = extractInstructions(dict["recipeInstructions"], context: &ctx)

        // Times
        recipe.prepTimeMinutes = extractTime(dict["prepTime"])
        recipe.cookTimeMinutes = extractTime(dict["cookTime"])
        recipe.totalTimeMinutes = extractTime(dict["totalTime"])

        // Servings / Yield
        let (servings, raw) = extractYield(dict["recipeYield"], context: &ctx)
        recipe.servings = servings
        recipe.servingsRaw = raw

        // Image
        recipe.imageURL = extractImageURL(dict["image"])

        return (recipe, ctx)
    }

    // MARK: - Field Extractors

    /// Extract a string from various JSON value types.
    private static func stringValue(_ value: Any?) -> String? {
        guard let value = value else { return nil }

        if let str = value as? String {
            let cleaned = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }

        if let array = value as? [String], let first = array.first {
            return first.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    /// Extract author name from various author formats.
    private static func extractAuthor(_ value: Any?) -> String? {
        guard let value = value else { return nil }

        // Direct string
        if let str = value as? String { return str }

        // Person/Organization object
        if let dict = value as? [String: Any] {
            return stringValue(dict["name"])
        }

        // Array of authors
        if let array = value as? [[String: Any]], let first = array.first {
            return stringValue(first["name"])
        }

        if let array = value as? [String], let first = array.first {
            return first
        }

        return nil
    }

    /// Extract ingredients array, handling various formats.
    private static func extractIngredients(_ value: Any?, context: inout MappingContext) -> [String]? {
        guard let value = value else { return nil }

        // Standard: array of strings
        if let array = value as? [String] {
            return filterIngredientHeaders(array, context: &context)
        }

        // Single string (some sites join all ingredients)
        if let str = value as? String {
            let lines = str.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return filterIngredientHeaders(lines, context: &context)
        }

        // Array of PropertyValue objects (rare)
        if let array = value as? [[String: Any]] {
            let strings = array.compactMap { item -> String? in
                if let text = item["text"] as? String { return text }
                if let name = item["name"] as? String { return name }
                return nil
            }
            return strings.isEmpty ? nil : filterIngredientHeaders(strings, context: &context)
        }

        return nil
    }

    /// Filter out ingredient group headers like "For the sauce:", "Dressing:"
    private static func filterIngredientHeaders(_ ingredients: [String], context: inout MappingContext) -> [String] {
        return ingredients.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip empty lines
            guard !trimmed.isEmpty else { return false }

            // Detect group headers — these end with ":" and have no quantity indicators
            if trimmed.hasSuffix(":") {
                let withoutColon = String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces)
                // Check if it looks like a header (short, starts with "For" or is title-like)
                let headerPatterns = ["for the", "for ", "sauce", "filling", "topping",
                                      "dressing", "marinade", "garnish", "crust", "frosting",
                                      "glaze", "batter", "dough"]
                let lower = withoutColon.lowercased()
                if headerPatterns.contains(where: { lower.hasPrefix($0) || lower == $0 }) {
                    context.issues.append("Filtered ingredient group header: \"\(trimmed)\"")
                    return false
                }
            }
            return true
        }
    }

    /// Extract instructions from various formats.
    private static func extractInstructions(_ value: Any?, context: inout MappingContext) -> String? {
        guard let value = value else { return nil }

        // Direct string
        if let str = value as? String {
            return cleanInstructionText(str)
        }

        // Array of strings
        if let array = value as? [String] {
            let cleaned = array.map { cleanInstructionText($0) }
                .filter { !$0.isEmpty }
            return cleaned.isEmpty ? nil : formatInstructionSteps(cleaned)
        }

        // Array of HowToStep or HowToSection objects
        if let array = value as? [[String: Any]] {
            return extractFromHowToArray(array, context: &context)
        }

        // Mixed array (strings and objects)
        if let array = value as? [Any] {
            var steps: [String] = []
            for item in array {
                if let str = item as? String {
                    steps.append(cleanInstructionText(str))
                } else if let dict = item as? [String: Any] {
                    if let extracted = extractFromHowToDict(dict, context: &context) {
                        steps.append(contentsOf: extracted)
                    }
                }
            }
            return steps.isEmpty ? nil : formatInstructionSteps(steps)
        }

        return nil
    }

    /// Extract steps from an array of HowTo objects.
    private static func extractFromHowToArray(_ array: [[String: Any]], context: inout MappingContext) -> String? {
        var steps: [String] = []

        for item in array {
            if let extracted = extractFromHowToDict(item, context: &context) {
                steps.append(contentsOf: extracted)
            }
        }

        return steps.isEmpty ? nil : formatInstructionSteps(steps)
    }

    /// Extract step text from a single HowTo dict (HowToStep or HowToSection).
    private static func extractFromHowToDict(_ dict: [String: Any], context: inout MappingContext) -> [String]? {
        let type = dict["@type"] as? String ?? ""

        if type == "HowToStep" {
            context.hadHowToSteps = true
            if let text = dict["text"] as? String {
                return [cleanInstructionText(text)]
            }
            if let name = dict["name"] as? String {
                return [cleanInstructionText(name)]
            }
            return nil
        }

        if type == "HowToSection" {
            context.hadHowToSections = true
            var steps: [String] = []
            // Section may have a name
            if let name = dict["name"] as? String {
                steps.append("**\(name)**")
            }
            // Section contains itemListElement with HowToSteps
            if let items = dict["itemListElement"] as? [[String: Any]] {
                for item in items {
                    if let extracted = extractFromHowToDict(item, context: &context) {
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
        cleaned = RecipeJSONLDExtractor.decodeHTMLEntities(cleaned)
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
    private static func extractYield(_ value: Any?, context: inout MappingContext) -> (Int?, String?) {
        guard let value = value else { return (nil, nil) }

        // Direct integer
        if let num = value as? Int { return (num, String(num)) }

        // String
        if let str = value as? String {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            let parsed = RecipeYieldParser.parse(trimmed)
            // Flag unusual formats
            if parsed != nil && Int(trimmed) == nil {
                context.hadUnusualYield = true
            }
            return (parsed, trimmed)
        }

        // Array — take first element
        if let array = value as? [Any], let first = array.first {
            if let str = first as? String {
                let parsed = RecipeYieldParser.parse(str)
                if parsed != nil && Int(str.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
                    context.hadUnusualYield = true
                }
                return (parsed, str)
            }
            if let num = first as? Int { return (num, String(num)) }
        }

        return (nil, nil)
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
