//
//  ClaudeIngredientParser.swift
//  forager
//
//  M10.6.1: Anthropic Messages API adapter for batch ingredient parsing.
//  Uses tool_use for structured output. Retries on 429/529 with exponential backoff.
//  Silent fallback to deterministic pipeline on any error.
//

import Foundation

class ClaudeIngredientParser: LLMIngredientParser {

    let providerName = "claude"

    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5-20251001"
    private let maxRetries = 3
    private let requestTimeout: TimeInterval = 15

    var isConfigured: Bool { !apiKey.isEmpty }

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - LLMIngredientParser

    func parseBatch(_ lines: [String], categories: [String]) async throws -> [LLMParserResult] {
        guard !lines.isEmpty else { return [] }
        guard isConfigured else {
            #if DEBUG
            await MainActor.run {
                DebugLogService.shared.log("parseBatch: API key is empty — throwing invalidAPIKey", category: "LLM")
            }
            #endif
            throw LLMParserError.invalidAPIKey
        }

        #if DEBUG
        await MainActor.run {
            DebugLogService.shared.log("parseBatch: sending \(lines.count) lines to \(model)", category: "LLM")
        }
        #endif

        let requestBody = buildRequestBody(lines: lines, categories: categories)
        let request = try buildURLRequest(body: requestBody)

        let data: Data
        do {
            data = try await executeWithRetry(request: request)
        } catch {
            #if DEBUG
            await MainActor.run {
                DebugLogService.shared.log("parseBatch: request failed — \(error)", category: "LLM")
            }
            #endif
            throw error
        }

        #if DEBUG
        await MainActor.run {
            DebugLogService.shared.log("parseBatch: got \(data.count) bytes response", category: "LLM")
        }
        #endif

        let results = try parseResponse(data: data)
        try validateResults(results)

        #if DEBUG
        await MainActor.run {
            DebugLogService.shared.log("parseBatch: parsed \(results.count) results OK", category: "LLM")
        }
        #endif

        return results
    }

    // MARK: - Request Building

    private func buildRequestBody(lines: [String], categories: [String]) -> [String: Any] {
        let numberedLines = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }
        let userMessage = "Parse these ingredient lines:\n" + numberedLines.joined(separator: "\n")

        var prompt = systemPrompt
        if !categories.isEmpty {
            let categoryList = categories.joined(separator: ", ")
            prompt += "\n\nThe user has these grocery categories: [\(categoryList)]. " +
                "For each ingredient, assign the most appropriate category from this exact list. " +
                "You MUST only use category names that appear in this list — do not invent or modify category names. " +
                "Use null if no category from the list fits well."
        }

        return [
            "model": model,
            "max_tokens": 1024,
            "system": prompt,
            "tools": [categories.isEmpty ? toolDefinition : toolDefinitionWithCategory],
            "tool_choice": ["type": "tool", "name": "parse_ingredients"],
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
    }

    private func buildURLRequest(body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = requestTimeout
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw LLMParserError.malformedResponse("Failed to serialize request: \(error.localizedDescription)")
        }
        return request
    }

    // MARK: - Retry Logic

    private func executeWithRetry(request: URLRequest) async throws -> Data {
        var lastError: LLMParserError?

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMParserError.malformedResponse("Non-HTTP response")
                }

                switch httpResponse.statusCode {
                case 200:
                    return data
                case 401:
                    throw LLMParserError.invalidAPIKey
                case 429:
                    lastError = .rateLimited
                case 529:
                    lastError = .serverOverloaded
                case 500...599:
                    throw LLMParserError.serverError(httpResponse.statusCode)
                default:
                    throw LLMParserError.serverError(httpResponse.statusCode)
                }
            } catch let error as LLMParserError {
                if !error.isRetryable { throw error }
                lastError = error
            } catch let error as URLError where error.code == .timedOut {
                throw LLMParserError.timeout
            } catch {
                throw LLMParserError.networkError(error)
            }

            // Exponential backoff: 1s, 2s, 4s
            if attempt < maxRetries - 1 {
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }
        }

        throw lastError ?? LLMParserError.serverError(0)
    }

    // MARK: - Response Parsing

    private func parseResponse(data: Data) throws -> [LLMParserResult] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw LLMParserError.malformedResponse("Missing content array")
        }

        // Find the tool_use block
        guard let toolUse = content.first(where: { ($0["type"] as? String) == "tool_use" }),
              let input = toolUse["input"] as? [String: Any],
              let ingredients = input["ingredients"] as? [[String: Any]] else {
            throw LLMParserError.malformedResponse("Missing tool_use with parse_ingredients")
        }

        var droppedCount = 0
        let results = ingredients.compactMap { item -> LLMParserResult? in
            guard let name = item["name"] as? String, !name.isEmpty else {
                droppedCount += 1
                return nil
            }

            let quantity = item["quantity"] as? Double
            let unit = item["unit"] as? String
            let notes = item["notes"] as? String
            let category = item["category"] as? String

            return LLMParserResult(
                name: name,
                quantity: quantity,
                unit: unit,
                notes: notes,
                confidence: 0.95,
                category: category
            )
        }

        if droppedCount > 0 {
            throw LLMParserError.validationFailed("Dropped \(droppedCount) items with missing/empty name")
        }

        return results
    }

    // MARK: - Validation

    private func validateResults(_ results: [LLMParserResult]) throws {
        if results.isEmpty {
            throw LLMParserError.validationFailed("Empty results array")
        }

        for result in results {
            if result.name.isEmpty {
                throw LLMParserError.validationFailed("Empty ingredient name")
            }
            if result.name.count > 250 {
                throw LLMParserError.validationFailed("Ingredient name exceeds 250 characters")
            }
            if let qty = result.quantity, qty <= 0 {
                throw LLMParserError.validationFailed("Non-positive quantity: \(qty)")
            }
        }
    }

    // MARK: - Prompts

    private let systemPrompt = """
        You are an ingredient parser for a grocery/recipe app. Parse each ingredient line \
        into structured components. Be precise with quantities and units.

        Rules:
        - Extract quantity as a decimal number (e.g., "1/2" → 0.5, "2 1/2" → 2.5)
        - Standardize common abbreviations: tablespoon/tbsp/tbs → "tbsp", \
        teaspoon/tsp → "tsp", ounce/oz → "oz", pound/lb → "lb"
        - Keep metric units as-is: g, kg, ml, L
        - Separate preparation notes from the ingredient name \
        (e.g., "2 cups flour, sifted" → name: "flour", notes: "sifted")
        - Count items (2 eggs) have quantity but null unit
        - Bare names (salt, pepper) have null quantity and null unit
        - "X to taste/to serve" → quantity null, notes: "to taste"/"to serve"
        - Use SINGULAR form for ingredient names (e.g., "avocado" not "avocados", \
        "pepper" not "peppers", "tomato" not "tomatoes", "egg" not "eggs")
        - The ingredient name must be ONLY the food item — never include count/unit \
        words like "clove", "slice", "piece", "wedge", "head", "stalk", "sprig", \
        "bunch", "ear" in the name. Examples: "2 cloves garlic" → name: "garlic" \
        (not "garlic clove"), "3 stalks celery" → name: "celery" (not "celery stalk"), \
        "1 head cauliflower" → name: "cauliflower" (not "cauliflower head")
        - For "juice of" or "zest of" patterns, the ingredient is the fruit: \
        "juice of 2 limes" → name: "lime", notes: "juice of". \
        "zest of 1 lemon" → name: "lemon", notes: "zest of"
        - Fix obvious spelling errors in ingredient names
        - Do NOT convert between unit systems (keep grams as grams, cups as cups)
        - CRITICAL: Return EXACTLY one result per numbered input line. Never split a line \
        into multiple results. Lines like "2 teaspoons each chili powder and cumin" are ONE \
        ingredient (name: "chili powder and cumin", quantity: 2, unit: "tsp"). \
        Lines like "salt and pepper" are ONE ingredient (name: "salt and pepper").
        """

    private let toolDefinition: [String: Any] = [
        "name": "parse_ingredients",
        "description": "Parse ingredient lines into structured components",
        "input_schema": [
            "type": "object",
            "properties": [
                "ingredients": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string", "description": "Ingredient name"],
                            "quantity": ["type": ["number", "null"], "description": "Numeric quantity or null"],
                            "unit": ["type": ["string", "null"], "description": "Unit of measurement or null"],
                            "notes": ["type": ["string", "null"], "description": "Preparation notes or null"]
                        ],
                        "required": ["name"]
                    ] as [String: Any]
                ] as [String: Any]
            ] as [String: Any],
            "required": ["ingredients"]
        ] as [String: Any]
    ]

    /// Tool definition with category field — used when user's categories are available
    private let toolDefinitionWithCategory: [String: Any] = [
        "name": "parse_ingredients",
        "description": "Parse ingredient lines into structured components with category assignment",
        "input_schema": [
            "type": "object",
            "properties": [
                "ingredients": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string", "description": "Ingredient name"],
                            "quantity": ["type": ["number", "null"], "description": "Numeric quantity or null"],
                            "unit": ["type": ["string", "null"], "description": "Unit of measurement or null"],
                            "notes": ["type": ["string", "null"], "description": "Preparation notes or null"],
                            "category": ["type": ["string", "null"], "description": "Grocery category from the provided list, or null"]
                        ],
                        "required": ["name"]
                    ] as [String: Any]
                ] as [String: Any]
            ] as [String: Any],
            "required": ["ingredients"]
        ] as [String: Any]
    ]
}
