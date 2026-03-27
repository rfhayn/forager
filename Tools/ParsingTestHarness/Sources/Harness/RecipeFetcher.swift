import Foundation

// MARK: - Recipe Fetcher

/// Fetches recipe URLs and extracts ingredients via JSON-LD.
struct RecipeFetcher {

    struct FetchResult {
        let url: String
        let title: String?
        let ingredients: [String]
        let extractionMethod: String
        let extractionTimeMs: Int
        let issues: [String]
    }

    struct FetchError: Error {
        let url: String
        let reason: String
        let httpStatus: Int?
    }

    private let session: URLSession
    private let delayBetweenRequests: TimeInterval

    init(delayBetweenRequests: TimeInterval = 2.0) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
        ]
        self.session = URLSession(configuration: config)
        self.delayBetweenRequests = delayBetweenRequests
    }

    /// Fetch a single recipe URL and extract ingredients.
    func fetch(url urlString: String) async throws -> FetchResult {
        guard let url = URL(string: urlString) else {
            throw FetchError(url: urlString, reason: "Invalid URL", httpStatus: nil)
        }

        let start = Date()
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchError(url: urlString, reason: "Non-HTTP response", httpStatus: nil)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FetchError(url: urlString, reason: "HTTP \(httpResponse.statusCode)", httpStatus: httpResponse.statusCode)
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw FetchError(url: urlString, reason: "Could not decode HTML", httpStatus: httpResponse.statusCode)
        }

        // Extract recipe via JSON-LD
        guard let extraction = RecipeJSONLDExtractor.extract(from: html) else {
            throw FetchError(url: urlString, reason: "No JSON-LD recipe found", httpStatus: httpResponse.statusCode)
        }

        // Map to structured recipe
        let (mapped, _) = SchemaRecipeMapper.map(extraction.recipe, sourceURL: urlString)
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)

        guard let ingredients = mapped.ingredients, !ingredients.isEmpty else {
            throw FetchError(url: urlString, reason: "No ingredients in recipe", httpStatus: httpResponse.statusCode)
        }

        return FetchResult(
            url: urlString,
            title: mapped.title,
            ingredients: ingredients,
            extractionMethod: extraction.context.extractionMethod,
            extractionTimeMs: elapsedMs,
            issues: extraction.context.issues
        )
    }

    /// Fetch multiple URLs with rate limiting and broken link recovery.
    func fetchAll(
        urls: [RecipeDiscovery.SelectedURL],
        discovery: RecipeDiscovery,
        targetCount: Int,
        logger: RunLogger? = nil
    ) async -> (results: [FetchResult], failures: [(url: String, reason: String)]) {
        var results: [FetchResult] = []
        var failures: [(url: String, reason: String)] = []
        var usedURLs = Set(urls.map(\.url))
        var queue = urls

        var index = 0
        while results.count < targetCount && index < queue.count {
            let selected = queue[index]
            index += 1

            if index > 1 {
                try? await Task.sleep(nanoseconds: UInt64(delayBetweenRequests * 1_000_000_000))
            }

            printErr("  [\(results.count + 1)/\(targetCount)] \(selected.site): \(selected.url.prefix(80))...")
            logger?.logFetchStart(url: selected.url, index: results.count + 1, total: targetCount)

            do {
                let result = try await fetch(url: selected.url)
                results.append(result)
                printErr("    ✓ \(result.ingredients.count) ingredients — \(result.title ?? "untitled")")
                logger?.logFetchSuccess(url: selected.url, title: result.title, ingredientCount: result.ingredients.count, method: result.extractionMethod, timeMs: result.extractionTimeMs)
            } catch let error as FetchError {
                failures.append((url: selected.url, reason: error.reason))
                discovery.markBroken(url: selected.url, reason: error.reason)
                printErr("    ✗ \(error.reason) — pulling replacement")

                let replaced: Bool
                if let replacement = discovery.getReplacement(excluding: usedURLs) {
                    queue.append(replacement)
                    usedURLs.insert(replacement.url)
                    replaced = true
                } else {
                    replaced = false
                }
                logger?.logFetchFailure(url: selected.url, reason: error.reason, replaced: replaced)
            } catch {
                failures.append((url: selected.url, reason: error.localizedDescription))
                printErr("    ✗ \(error.localizedDescription)")
                logger?.logFetchFailure(url: selected.url, reason: error.localizedDescription, replaced: false)
            }
        }

        return (results, failures)
    }
}
