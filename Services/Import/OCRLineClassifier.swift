//
//  OCRLineClassifier.swift
//  forager
//
//  Created for M10.2.4: Heuristic line classification for text/photo import
//  Shared by both text paste (M10.2) and photo OCR (M10.3) extraction paths.
//  Ported from spike's classifyLines() with section-aware context boosting.
//

import Foundation
import CoreGraphics

// MARK: - Line Type

/// Classification categories for a line of recipe text
enum LineType: String, CaseIterable {
    case title
    case ingredient
    case instruction
    case metadata       // Servings, prep time, cook time, temperature
    case sectionHeader  // "Ingredients:", "Instructions:", "For the sauce:", etc.
    case unknown
}

// MARK: - OCR Line (Input)

/// Input line with optional OCR metadata. For text-only input, use CGRect.zero for boundingBox.
struct OCRLine {
    let text: String
    let confidence: Float
    let boundingBox: CGRect

    /// Convenience for text-paste path where OCR confidence/bounds don't apply
    static func fromText(_ text: String) -> OCRLine {
        OCRLine(text: text, confidence: 1.0, boundingBox: .zero)
    }
}

// MARK: - Classified Line (Output)

/// A line with its classification result
struct ClassifiedLine {
    let text: String
    let type: LineType
    let confidence: Float
    let score: Float
}

// MARK: - OCR Line Classifier

/// Heuristic scoring classifier for recipe text lines.
/// Uses pattern matching and section-aware context boosting to classify lines.
///
/// Scoring approach:
/// - Each line gets a score for each possible type
/// - Highest score wins, with minimum threshold (0.3)
/// - Section headers boost confidence of subsequent weak lines
/// - Shared by text paste (M10.2) and photo OCR (M10.3)
enum OCRLineClassifier {

    // MARK: - Public API

    /// Classify an array of lines into recipe sections.
    /// Uses section-aware context: once a section header is detected, subsequent
    /// weak lines inherit that section's type until the next header.
    static func classifyLines(_ lines: [OCRLine]) -> [ClassifiedLine] {
        guard !lines.isEmpty else { return [] }

        var results: [ClassifiedLine] = []
        var currentSection: LineType? = nil

        for (index, line) in lines.enumerated() {
            let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            guard !trimmed.isEmpty else { continue }

            // Strip bullet/list prefixes before scoring so ^-anchored patterns see actual content.
            // Preserves original trimmed text in output ClassifiedLine.
            let cleaned = stripBulletPrefix(trimmed)

            // Score for each type using cleaned text
            let scores = scoreLine(cleaned, lineIndex: index, totalLines: lines.count)

            // Check if this is a section header first (use cleaned text for matching)
            if let headerType = detectSectionHeader(cleaned) {
                currentSection = headerType
                results.append(ClassifiedLine(
                    text: trimmed,
                    type: .sectionHeader,
                    confidence: 0.9,
                    score: 0.9
                ))
                continue
            }

            // Find the highest scoring type
            let bestType = scores.max(by: { $0.value < $1.value })

            if let best = bestType, best.value >= 0.3 {
                results.append(ClassifiedLine(
                    text: trimmed,
                    type: best.key,
                    confidence: min(best.value, 1.0),
                    score: best.value
                ))
            } else if let section = currentSection {
                // Weak line — inherit from current section context
                results.append(ClassifiedLine(
                    text: trimmed,
                    type: section,
                    confidence: 0.3,
                    score: 0.3
                ))
            } else {
                results.append(ClassifiedLine(
                    text: trimmed,
                    type: .unknown,
                    confidence: 0.1,
                    score: 0.0
                ))
            }
        }

        return results
    }

    // MARK: - Line Scoring

    /// Score a line against all types, returning a dictionary of type → score
    private static func scoreLine(_ text: String, lineIndex: Int, totalLines: Int) -> [LineType: Float] {
        var scores: [LineType: Float] = [:]

        scores[.title] = scoreTitle(text, lineIndex: lineIndex, totalLines: totalLines)
        scores[.ingredient] = scoreIngredient(text)
        scores[.instruction] = scoreInstruction(text)
        scores[.metadata] = scoreMetadata(text)

        return scores
    }

    // MARK: - Title Scoring

    /// Title signals: first few lines, Title Case, moderate length (5-80 chars)
    private static func scoreTitle(_ text: String, lineIndex: Int, totalLines: Int) -> Float {
        var score: Float = 0.0

        // Position: first 3 lines get a title bonus
        if lineIndex == 0 {
            score += 0.4
        } else if lineIndex <= 2 {
            score += 0.2
        }

        // Title Case detection (most words capitalized)
        let words = text.split(separator: " ")
        if words.count >= 2 {
            let capitalizedCount = words.filter { $0.first?.isUppercase == true }.count
            let ratio = Float(capitalizedCount) / Float(words.count)
            if ratio >= 0.6 {
                score += 0.2
            }
        }

        // Length: typical recipe titles are 5-80 chars
        let length = text.count
        if length >= 5 && length <= 80 {
            score += 0.1
        }

        // Penalty: if it looks like an ingredient or instruction, reduce title score
        if startsWithNumber(text) { score -= 0.3 }
        if startsWithImperativeVerb(text) { score -= 0.2 }

        return max(score, 0.0)
    }

    // MARK: - Ingredient Scoring

    /// Ingredient signals: starts with number/fraction, contains unit words, short line
    private static func scoreIngredient(_ text: String) -> Float {
        var score: Float = 0.0

        // Penalty: numbered steps (1. Mix, Step 2:) are instructions, not ingredients
        if isNumberedStep(text) {
            score -= 0.4
        }

        // Starts with digit or fraction
        if startsWithNumber(text) {
            score += 0.5
        }

        // Contains unit words — strong ingredient signal
        if containsUnitWord(text) {
            score += 0.35
        }

        // Short line (ingredients are typically short — < 80 chars)
        if text.count < 80 {
            score += 0.1
        }

        // Contains fraction characters (½, ¼, ¾, etc.)
        if text.contains(where: { "½¼¾⅓⅔⅛⅜⅝⅞".contains($0) }) {
            score += 0.3
        }

        // Fix 4: Bare ingredient names — common ingredients with no quantity/unit
        if containsBareIngredientName(text) {
            score += 0.3
        }

        // Penalty: very long lines are rarely ingredients
        if text.count > 120 {
            score -= 0.3
        }

        return max(score, 0.0)
    }

    // MARK: - Instruction Scoring

    /// Instruction signals: numbered step, imperative verb, longer lines
    private static func scoreInstruction(_ text: String) -> Float {
        var score: Float = 0.0

        // Numbered step (e.g., "1.", "Step 1:", "1)")
        if isNumberedStep(text) {
            score += 0.5
        }

        // Starts with imperative verb
        if startsWithImperativeVerb(text) {
            score += 0.4
        }

        // Longer line (instructions are typically longer than ingredients)
        if text.count > 60 {
            score += 0.2
        }

        // Contains temperature reference
        if containsTemperature(text) {
            score += 0.15
        }

        // Contains time reference
        if containsTimeReference(text) {
            score += 0.1
        }

        return max(score, 0.0)
    }

    // MARK: - Metadata Scoring

    /// Metadata signals: serving/yield patterns, time patterns, temperature
    private static func scoreMetadata(_ text: String) -> Float {
        let lower = text.lowercased()
        var score: Float = 0.0

        // Serving patterns
        if servingPattern.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
            score += 0.7
        }

        // Time patterns (prep time, cook time, total time)
        if timePattern.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
            score += 0.7
        }

        // Temperature as standalone metadata
        if containsTemperature(text) && text.count < 40 {
            score += 0.3
        }

        // Yield patterns
        if yieldPattern.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
            score += 0.6
        }

        // Fix 5: Unusual metadata labels (Difficulty:, Author:, Cuisine:, etc.)
        if metadataLabelPattern.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
            score += 0.6
        }

        return max(score, 0.0)
    }

    // MARK: - Section Header Detection

    /// Detect section headers like "Ingredients:", "Instructions:", "For the sauce:"
    private static func detectSectionHeader(_ text: String) -> LineType? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespaces)

        // Exact or near-exact matches for common headers
        let ingredientHeaders = ["ingredients", "ingredients:", "what you'll need", "what you'll need:", "you will need", "you will need:", "shopping list"]
        let instructionHeaders = ["instructions", "instructions:", "directions", "directions:", "method", "method:", "steps", "steps:", "how to make it", "how to make it:", "preparation", "preparation:"]
        let metadataHeaders = ["nutrition", "nutrition:", "nutritional information", "nutritional information:", "notes", "notes:", "tips", "tips:"]

        if ingredientHeaders.contains(lower) || lower.hasPrefix("for the ") || lower.hasPrefix("for ") && lower.hasSuffix(":") {
            return .ingredient
        }
        if instructionHeaders.contains(lower) {
            return .instruction
        }
        if metadataHeaders.contains(lower) {
            return .metadata
        }

        return nil
    }

    // MARK: - Bullet Prefix Stripping (Fix 1)

    /// Strip leading bullet/list prefixes so ^-anchored scoring patterns see actual content.
    /// Only strips punctuated numbered lists (1. / 2) / 3:), NOT bare "2 cups flour".
    private static func stripBulletPrefix(_ text: String) -> String {
        // Bullet/dash/star prefixes: "- text", "• text", "* text"
        if let range = text.range(of: #"^\s*[-•*]\s+"#, options: .regularExpression) {
            let stripped = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty { return stripped }
        }
        // Numbered list prefixes: "1. text", "2) text", "3: text" — requires punctuation after digit
        if let range = text.range(of: #"^\s*\d+[.\):]\s+"#, options: .regularExpression) {
            let stripped = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty { return stripped }
        }
        return text
    }

    // MARK: - Pattern Helpers

    private static func startsWithNumber(_ text: String) -> Bool {
        guard let first = text.first else { return false }
        return first.isNumber || "½¼¾⅓⅔⅛⅜⅝⅞".contains(first)
    }

    private static func startsWithImperativeVerb(_ text: String) -> Bool {
        let firstWord = text.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
        return imperativeVerbs.contains(firstWord)
    }

    private static func isNumberedStep(_ text: String) -> Bool {
        numberedStepPattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func containsUnitWord(_ text: String) -> Bool {
        let lower = text.lowercased()
        let words = Set(lower.split(separator: " ").map(String.init))
        return !words.isDisjoint(with: unitWords)
    }

    private static func containsTemperature(_ text: String) -> Bool {
        temperaturePattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func containsTimeReference(_ text: String) -> Bool {
        timeReferencePattern.firstMatch(in: text.lowercased(), range: NSRange(text.startIndex..., in: text)) != nil
    }

    /// Fix 4: Detect bare ingredient names with no quantity or unit
    private static func containsBareIngredientName(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespaces)
        // Check single-word and common multi-word bare ingredients
        return bareIngredients.contains(lower) ||
               bareIngredients.contains(where: { lower.hasPrefix($0 + " ") || lower.hasPrefix($0 + ",") })
    }

    // MARK: - Static Data

    /// 44 imperative cooking verbs from spike research
    private static let imperativeVerbs: Set<String> = [
        "add", "arrange", "bake", "baste", "beat", "blend", "boil", "broil",
        "brown", "brush", "carve", "chop", "coat", "combine", "cook", "cool",
        "cover", "cut", "dice", "drain", "drizzle", "fold", "fry", "garnish",
        "grate", "grill", "heat", "knead", "layer", "let", "marinate", "melt",
        "mix", "peel", "place", "pour", "preheat", "press", "reduce", "remove",
        "rinse", "roast", "roll", "saute", "sauté", "season", "serve", "set",
        "simmer", "slice", "spread", "sprinkle", "stir", "strain", "toss",
        "transfer", "trim", "turn", "using", "warm", "wash", "whisk", "wrap"
    ]

    /// Common cooking measurement units
    private static let unitWords: Set<String> = [
        "cup", "cups", "tablespoon", "tablespoons", "tbsp", "tbs", "teaspoon", "teaspoons", "tsp",
        "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs",
        "gram", "grams", "g", "kilogram", "kilograms", "kg",
        "ml", "milliliter", "milliliters", "liter", "liters", "l",
        "pinch", "dash", "clove", "cloves", "bunch", "bunches",
        "can", "cans", "package", "packages", "pkg", "bag", "bags",
        "slice", "slices", "piece", "pieces", "head", "heads",
        "quart", "quarts", "qt", "gallon", "gallons", "gal", "pint", "pints", "pt",
        "stick", "sticks", "sprig", "sprigs"
    ]

    /// Fix 4: Common bare ingredients (no quantity/unit needed)
    private static let bareIngredients: Set<String> = [
        "salt", "pepper", "oil", "olive oil", "vegetable oil", "sesame oil", "coconut oil",
        "butter", "flour", "sugar", "water", "ice", "ice water",
        "celery", "parsley", "cilantro", "basil", "thyme", "rosemary", "oregano", "dill", "mint",
        "cinnamon", "paprika", "cumin", "turmeric", "nutmeg", "cayenne",
        "garlic", "ginger", "honey", "vinegar", "mustard", "ketchup", "mayo", "mayonnaise",
        "cream", "milk", "cheese", "rice", "pasta", "bread", "noodles",
        "lettuce", "spinach", "arugula", "passata", "stock", "broth",
        "wine", "beer", "sake", "mirin",
        "soy sauce", "fish sauce", "worcestershire sauce", "hot sauce", "sriracha",
        "cornstarch", "baking powder", "baking soda", "yeast",
        "salt and pepper", "cooking spray", "nonstick spray"
    ]

    // MARK: - Regex Patterns (compiled once)

    private static let numberedStepPattern: NSRegularExpression = {
        // Requires punctuation after digit (. ) :), NOT bare digit+space like "2 cups"
        try! NSRegularExpression(pattern: #"^\s*(?:step\s+)?\d+[\.\):]"#, options: .caseInsensitive)
    }()

    private static let temperaturePattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"\d+\s*°\s*[FCfc]|\d+\s*degrees"#, options: .caseInsensitive)
    }()

    private static let servingPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"serves?\s+\d|servings?\s*:?\s*\d|makes?\s+\d"#, options: .caseInsensitive)
    }()

    private static let timePattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"(?:prep|cook|total|bake|rest)\s*(?:time)?\s*:?\s*\d+\s*(?:min|hour|hr|h\b|m\b)"#, options: .caseInsensitive)
    }()

    private static let yieldPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"yields?\s*:?\s*\d|makes?\s+(?:about\s+)?\d"#, options: .caseInsensitive)
    }()

    private static let timeReferencePattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"\d+\s*(?:minutes?|mins?|hours?|hrs?|seconds?|secs?)"#, options: .caseInsensitive)
    }()

    /// Fix 5: Unusual metadata labels not covered by serving/time/yield patterns
    private static let metadataLabelPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"^(?:difficulty|author|cuisine|source|category|course|diet|skill|level|rating|oven|active\s+time|inactive\s+time|hands-on\s+time)\s*:"#, options: .caseInsensitive)
    }()
}
