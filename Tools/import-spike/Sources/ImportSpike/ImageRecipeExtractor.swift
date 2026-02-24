import Foundation
import Vision

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Image Recipe Extractor

/// Extracts recipe text from an image using Vision framework OCR,
/// then classifies lines into recipe sections using heuristic scoring.
enum ImageRecipeExtractor {

    /// OCR result with bounding box information.
    struct OCRLine {
        let text: String
        let confidence: Float
        let boundingBox: CGRect  // Normalized coordinates (0-1)
    }

    /// Classification of a text line.
    enum LineType: String, Codable {
        case title
        case ingredient
        case instruction
        case metadata      // servings, time, temperature
        case sectionHeader // "For the sauce:", "Ingredients:"
        case unknown
    }

    /// A classified line from OCR output.
    struct ClassifiedLine: Codable {
        let text: String
        let type: String
        let confidence: Float
        let score: Double
    }

    /// Result of image extraction.
    struct ImageExtractionResult: Codable {
        let ocrLineCount: Int
        let ocrConfidence: Float
        let classifiedLines: [ClassifiedLine]
        let extractedRecipe: ExtractedRecipe?
        let processingTimeMs: Int
        let issues: [String]
    }

    // MARK: - OCR

    /// Perform OCR on an image file and return recognized text lines.
    static func performOCR(imagePath: String) -> (lines: [OCRLine], issues: [String]) {
        var issues: [String] = []

        #if canImport(AppKit)
        guard let image = NSImage(contentsOfFile: imagePath) else {
            return ([], ["Failed to load image from \(imagePath)"])
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ([], ["Failed to create CGImage from NSImage"])
        }
        #else
        return ([], ["Image loading not supported on this platform"])
        #endif

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "fr-FR", "de-DE", "es-ES"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return ([], ["OCR failed: \(error.localizedDescription)"])
        }

        guard let observations = request.results else {
            return ([], ["No OCR results returned"])
        }

        let lines = observations.compactMap { observation -> OCRLine? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return OCRLine(
                text: candidate.string,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            )
        }

        if lines.isEmpty {
            issues.append("OCR found no text in image")
        }

        return (lines, issues)
    }

    // MARK: - Line Classification

    /// Classify OCR lines into recipe sections using section-aware heuristic scoring.
    /// Uses section headers ("Ingredients:", "Instructions:") to set context for
    /// subsequent lines — lines after "Ingredients:" default to ingredient, etc.
    static func classifyLines(_ lines: [OCRLine]) -> [ClassifiedLine] {
        guard !lines.isEmpty else { return [] }

        var classified: [ClassifiedLine] = []
        var currentSection: LineType = .unknown

        for (index, line) in lines.enumerated() {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let (type, score) = classifyLine(text, index: index, totalLines: lines.count)

            // Track section context from headers
            if type == .sectionHeader {
                let lower = text.lowercased()
                if lower.contains("ingredient") {
                    currentSection = .ingredient
                } else if lower.contains("instruction") || lower.contains("direction") ||
                          lower.contains("method") || lower.contains("step") ||
                          lower.contains("preparation") {
                    currentSection = .instruction
                }
                classified.append(ClassifiedLine(
                    text: text, type: type.rawValue,
                    confidence: line.confidence, score: score
                ))
                continue
            }

            // Apply section context: if a line's classification is weak (low score),
            // prefer the current section type
            var finalType = type
            var finalScore = score
            if score < 0.5 && currentSection != .unknown {
                finalType = currentSection
                finalScore = 0.45 // Boosted by context but still flagged as uncertain
            }

            classified.append(ClassifiedLine(
                text: text, type: finalType.rawValue,
                confidence: line.confidence, score: finalScore
            ))
        }

        return classified
    }

    /// Classify a single line based on content heuristics.
    private static func classifyLine(_ text: String, index: Int, totalLines: Int) -> (LineType, Double) {
        let lower = text.lowercased()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Section header detection: "Ingredients:", "Directions:", "For the sauce:", etc.
        let sectionHeaders = ["ingredients", "directions", "instructions", "method",
                              "steps", "preparation", "for the", "recipe", "notes"]
        if trimmed.hasSuffix(":") || trimmed.hasSuffix(":)") {
            let withoutColon = trimmed.dropLast().lowercased()
            if sectionHeaders.contains(where: { withoutColon.hasPrefix($0) || withoutColon == $0 }) {
                return (.sectionHeader, 0.9)
            }
        }
        // Also check without colon
        if sectionHeaders.contains(where: { lower == $0 }) {
            return (.sectionHeader, 0.85)
        }

        // Title detection: first non-empty line, or short Title Case line near top
        if index < 3 && isTitleCase(text) && text.count > 5 && text.count < 80 {
            return (.title, 0.7 - Double(index) * 0.15)
        }

        // Metadata detection: servings, time, temperature patterns
        let metadataScore = metadataScore(for: lower)
        if metadataScore > 0.6 {
            return (.metadata, metadataScore)
        }

        // Ingredient detection
        let ingredientScore = ingredientScore(for: text)
        if ingredientScore > 0.6 {
            return (.ingredient, ingredientScore)
        }

        // Instruction detection
        let instructionScore = instructionScore(for: text)
        if instructionScore > 0.5 {
            return (.instruction, instructionScore)
        }

        // Default: if short, might be ingredient; if long, might be instruction
        if text.count < 50 {
            return (.ingredient, 0.3)
        } else {
            return (.instruction, 0.3)
        }
    }

    /// Check if text is Title Case (most words capitalized).
    private static func isTitleCase(_ text: String) -> Bool {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard words.count > 1 else { return false }
        let skipWords = Set(["a", "an", "the", "and", "or", "of", "in", "for", "with", "to"])
        let capitalizedCount = words.filter { word in
            if skipWords.contains(word.lowercased()) { return true }
            return word.first?.isUppercase == true
        }.count
        return Double(capitalizedCount) / Double(words.count) > 0.6
    }

    /// Score how likely a line is metadata (servings, time, temperature).
    private static func metadataScore(for text: String) -> Double {
        var score = 0.0

        // Serving patterns
        let servingPatterns = ["serves", "servings", "yield", "makes", "portions"]
        if servingPatterns.contains(where: { text.contains($0) }) { score += 0.7 }

        // Time patterns
        let timePatterns = ["minutes", "minute", "mins", "min", "hours", "hour", "hrs", "hr",
                           "prep time", "cook time", "total time", "bake time", "rest time"]
        if timePatterns.contains(where: { text.contains($0) }) { score += 0.7 }

        // Temperature patterns
        if text.contains("°") || text.contains("degrees") ||
           text.range(of: #"\d+\s*[fFcC]\b"#, options: .regularExpression) != nil {
            score += 0.3
        }

        return min(score, 0.95)
    }

    /// Score how likely a line is an ingredient.
    private static func ingredientScore(for text: String) -> Double {
        var score = 0.0
        let lower = text.lowercased()

        // Starts with a number or fraction — strong ingredient signal
        let startsWithNumber = text.range(of: #"^[\d½¼¾⅓⅔⅛⅜⅝⅞]"#, options: .regularExpression) != nil
        if startsWithNumber { score += 0.5 }

        // Contains unit words
        let units = ["cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon",
                     "teaspoons", "tsp", "ounce", "ounces", "oz", "pound", "pounds",
                     "lb", "lbs", "gram", "grams", "g", "kg", "ml", "liter", "liters",
                     "pinch", "dash", "bunch", "clove", "cloves", "can", "cans",
                     "stick", "sticks", "slice", "slices", "piece", "pieces",
                     "package", "packages", "pkg"]
        let words = Set(lower.components(separatedBy: .whitespaces))
        if !units.filter({ words.contains($0) }).isEmpty { score += 0.35 }

        // Short to medium length (ingredients are usually 1 line)
        if text.count < 60 { score += 0.1 }
        if text.count > 120 { score -= 0.3 }

        // Contains comma (ingredient often has modifiers: "flour, sifted")
        if text.contains(",") && text.count < 80 { score += 0.05 }

        return min(max(score, 0.0), 0.95)
    }

    /// Score how likely a line is an instruction step.
    private static func instructionScore(for text: String) -> Double {
        var score = 0.0
        let lower = text.lowercased()

        // Starts with a number followed by a period or parenthesis (numbered step)
        let startsWithStep = text.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) != nil
        if startsWithStep { score += 0.5 }

        // Starts with imperative verb
        let imperativeVerbs = ["preheat", "heat", "mix", "stir", "combine", "add",
                               "pour", "bake", "cook", "place", "set", "bring",
                               "reduce", "remove", "let", "cover", "simmer",
                               "whisk", "beat", "fold", "chop", "dice", "mince",
                               "slice", "drain", "rinse", "season", "serve",
                               "transfer", "spread", "grease", "line", "roll",
                               "knead", "brush", "sprinkle", "garnish", "arrange",
                               "toss", "melt", "sauté", "saute", "roast", "grill",
                               "broil", "fry", "boil", "steam", "blend", "puree"]
        let firstWord = lower.components(separatedBy: .whitespaces).first ?? ""
        if imperativeVerbs.contains(firstWord) { score += 0.4 }

        // Longer lines tend to be instructions
        if text.count > 60 { score += 0.2 }
        if text.count > 120 { score += 0.1 }

        // Contains time references
        if lower.contains("minute") || lower.contains("hour") || lower.contains("second") {
            score += 0.15
        }

        // Contains temperature references
        if lower.contains("°") || lower.contains("degrees") || lower.contains("oven") {
            score += 0.15
        }

        return min(max(score, 0.0), 0.95)
    }

    // MARK: - Recipe Assembly

    /// Assemble classified lines into an ExtractedRecipe.
    static func assembleRecipe(from classified: [ClassifiedLine]) -> ExtractedRecipe {
        var recipe = ExtractedRecipe()

        // Extract title (highest-scoring title line)
        let titles = classified.filter { $0.type == "title" }.sorted { $0.score > $1.score }
        recipe.title = titles.first?.text

        // Extract ingredients
        let ingredients = classified.filter { $0.type == "ingredient" }.map(\.text)
        recipe.ingredients = ingredients.isEmpty ? nil : ingredients

        // Extract instructions
        let instructions = classified.filter { $0.type == "instruction" }.map(\.text)
        if !instructions.isEmpty {
            recipe.instructions = instructions.enumerated().map { (i, step) in
                // Strip existing numbering and re-number
                let cleaned = step.replacingOccurrences(of: #"^\d+[\.\)]\s*"#, with: "", options: .regularExpression)
                return "\(i + 1). \(cleaned)"
            }.joined(separator: "\n")
        }

        // Extract metadata
        for line in classified where line.type == "metadata" {
            let lower = line.text.lowercased()
            if lower.contains("serv") || lower.contains("yield") || lower.contains("makes") {
                recipe.servings = RecipeYieldParser.parse(line.text)
                recipe.servingsRaw = line.text
            }
            if lower.contains("prep") {
                recipe.prepTimeMinutes = extractMinutes(from: line.text)
            }
            if lower.contains("cook") || lower.contains("bake") {
                recipe.cookTimeMinutes = extractMinutes(from: line.text)
            }
            if lower.contains("total") {
                recipe.totalTimeMinutes = extractMinutes(from: line.text)
            }
        }

        return recipe
    }

    /// Extract minutes from a metadata line like "Prep time: 20 minutes" or "Cook: 1 hour 15 min"
    private static func extractMinutes(from text: String) -> Int? {
        var totalMinutes = 0

        // Extract hours
        let hourPattern = #"(\d+)\s*(?:hours?|hrs?|h)\b"#
        if let regex = try? NSRegularExpression(pattern: hourPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let hours = Int(text[range]) {
            totalMinutes += hours * 60
        }

        // Extract minutes
        let minPattern = #"(\d+)\s*(?:minutes?|mins?|m)\b"#
        if let regex = try? NSRegularExpression(pattern: minPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let mins = Int(text[range]) {
            totalMinutes += mins
        }

        // If no time units found, try bare number
        if totalMinutes == 0 {
            let barePattern = #"(\d+)"#
            if let regex = try? NSRegularExpression(pattern: barePattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let num = Int(text[range]) {
                return num
            }
        }

        return totalMinutes > 0 ? totalMinutes : nil
    }

    // MARK: - Full Pipeline

    /// Extract a recipe from an image file: OCR → classify → assemble.
    static func extractFromImage(path: String) -> ImageExtractionResult {
        let start = CFAbsoluteTimeGetCurrent()
        var issues: [String] = []

        // Step 1: OCR
        let (ocrLines, ocrIssues) = performOCR(imagePath: path)
        issues.append(contentsOf: ocrIssues)

        guard !ocrLines.isEmpty else {
            let timeMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            return ImageExtractionResult(
                ocrLineCount: 0,
                ocrConfidence: 0,
                classifiedLines: [],
                extractedRecipe: nil,
                processingTimeMs: timeMs,
                issues: issues
            )
        }

        let avgConfidence = ocrLines.reduce(0.0) { $0 + $1.confidence } / Float(ocrLines.count)

        // Step 2: Classify lines
        let classified = classifyLines(ocrLines)

        // Step 3: Assemble recipe
        let recipe = assembleRecipe(from: classified)

        let timeMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)

        return ImageExtractionResult(
            ocrLineCount: ocrLines.count,
            ocrConfidence: avgConfidence,
            classifiedLines: classified,
            extractedRecipe: recipe,
            processingTimeMs: timeMs,
            issues: issues
        )
    }
}
