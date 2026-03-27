import Foundation

// MARK: - Parsing Evaluator

/// Runs all parsers on each ingredient and stores results independently.
struct ParsingEvaluator {

    // MARK: - Result Types

    struct LocalParseResult: Codable {
        let name: String
        let quantity: Double?
        let unit: String?
        let notes: String?
        let confidence: Float
        let parserUsed: String
    }

    struct AIParseResult: Codable {
        let name: String
        let quantity: Double?
        let unit: String?
        let notes: String?
        let provider: String
    }

    struct IngredientResult: Codable {
        let raw: String
        let sanitized: String
        let regex: LocalParseResult
        let nlp: LocalParseResult
        let hybrid: LocalParseResult
        var ai: AIParseResult?
    }

    struct RecipeResult: Codable {
        let url: String
        let title: String?
        let extractionMethod: String
        // ingredients is var so AI results can be added later
        let ingredientCount: Int
        var ingredients: [IngredientResult]
        let source: String  // "reuse" or "new"
    }

    // MARK: - Local Parsing

    private let regexParser = RegexIngredientParser()
    private let nlpParser = NLPIngredientParser()
    private let hybridParser = HybridIngredientParser(mlParser: nil)

    /// Parse all ingredients from a fetched recipe using local parsers.
    func parseLocal(fetchResult: RecipeFetcher.FetchResult, source: String, logger: RunLogger? = nil) -> RecipeResult {
        var ingredientResults: [IngredientResult] = []

        logger?.logRecipeParseSummary(title: fetchResult.title, url: fetchResult.url, ingredientCount: fetchResult.ingredients.count)

        for raw in fetchResult.ingredients {
            let sanitized = IngredientPreprocessor.sanitize(raw)

            let regexResult = regexParser.parse(sanitized)
            let nlpResult = nlpParser.parse(sanitized)
            let hybridResult = hybridParser.parse(sanitized)

            logger?.logIngredientParse(raw: raw, sanitized: sanitized, regex: regexResult, nlp: nlpResult, hybrid: hybridResult)

            ingredientResults.append(IngredientResult(
                raw: raw,
                sanitized: sanitized,
                regex: LocalParseResult(
                    name: regexResult.name,
                    quantity: regexResult.quantity,
                    unit: regexResult.unit,
                    notes: regexResult.notes,
                    confidence: regexResult.confidence,
                    parserUsed: regexResult.parserUsed
                ),
                nlp: LocalParseResult(
                    name: nlpResult.name,
                    quantity: nlpResult.quantity,
                    unit: nlpResult.unit,
                    notes: nlpResult.notes,
                    confidence: nlpResult.confidence,
                    parserUsed: nlpResult.parserUsed
                ),
                hybrid: LocalParseResult(
                    name: hybridResult.name,
                    quantity: hybridResult.quantity,
                    unit: hybridResult.unit,
                    notes: hybridResult.notes,
                    confidence: hybridResult.confidence,
                    parserUsed: hybridResult.parserUsed
                )
            ))
        }

        return RecipeResult(
            url: fetchResult.url,
            title: fetchResult.title,
            extractionMethod: fetchResult.extractionMethod,
            ingredientCount: ingredientResults.count,
            ingredients: ingredientResults,
            source: source
        )
    }

    // MARK: - AI Parsing

    /// Add AI parse results to existing recipe results. Modifies in place.
    func addAIParsing(to results: inout [RecipeResult], apiKey: String, logger: RunLogger? = nil) async {
        let parser = ClaudeIngredientParser(apiKey: apiKey)

        for i in results.indices {
            let ingredients = results[i].ingredients.map(\.raw)
            guard !ingredients.isEmpty else { continue }

            printErr("  AI parsing: \(results[i].title ?? results[i].url.prefix(60).description) (\(ingredients.count) ingredients)...")
            logger?.logRecipeParseSummary(title: results[i].title, url: results[i].url, ingredientCount: ingredients.count)

            do {
                let aiResults = try await parser.parseBatch(ingredients, categories: [])

                // Match AI results to ingredients by index
                for j in 0..<min(results[i].ingredients.count, aiResults.count) {
                    let ai = aiResults[j]
                    results[i].ingredients[j].ai = AIParseResult(
                        name: ai.name,
                        quantity: ai.quantity,
                        unit: ai.unit,
                        notes: ai.notes,
                        provider: "claude"
                    )
                    logger?.logAIParseResult(index: j + 1, raw: ingredients[j], aiName: ai.name, aiQty: ai.quantity, aiUnit: ai.unit, aiNotes: ai.notes)
                }

                if aiResults.count != ingredients.count {
                    printErr("    ⚠️  AI returned \(aiResults.count) results for \(ingredients.count) ingredients")
                    logger?.write("    ⚠️  AI count mismatch: returned \(aiResults.count) for \(ingredients.count) inputs")
                }
            } catch {
                printErr("    ✗ AI parsing failed: \(error)")
                logger?.write("    ✗ AI parsing failed: \(error)")
            }

            // Brief pause between API calls
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}
