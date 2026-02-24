import Foundation

// MARK: - HTTP Fetching

/// Fetch HTML content from a URL synchronously using URLSession + semaphore.
func fetchHTML(from urlString: String, timeout: TimeInterval = 15) -> (html: String?, statusCode: Int?, error: String?) {
    guard let url = URL(string: urlString) else {
        return (nil, nil, "Invalid URL: \(urlString)")
    }

    var request = URLRequest(url: url, timeoutInterval: timeout)
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
    request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

    let semaphore = DispatchSemaphore(value: 0)
    var resultHTML: String?
    var resultStatus: Int?
    var resultError: String?

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }

        if let error = error {
            resultError = error.localizedDescription
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            resultStatus = httpResponse.statusCode
        }

        if let data = data {
            resultHTML = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
        }
    }

    task.resume()
    semaphore.wait()

    return (resultHTML, resultStatus, resultError)
}

// MARK: - Single URL Extraction

/// Extract a recipe from a single URL and print the result.
func extractSingle(url: String) {
    fputs("Fetching: \(url)\n", stderr)

    let start = CFAbsoluteTimeGetCurrent()
    let (html, statusCode, fetchError) = fetchHTML(from: url)
    let fetchTimeMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)

    guard let html = html else {
        let error = fetchError ?? "No HTML content"
        fputs("Error: \(error) (HTTP \(statusCode ?? 0), \(fetchTimeMs)ms)\n", stderr)
        return
    }

    fputs("Fetched \(html.count) chars in \(fetchTimeMs)ms (HTTP \(statusCode ?? 0))\n", stderr)

    guard let (recipeDict, extractCtx) = RecipeJSONLDExtractor.extract(from: html) else {
        fputs("No recipe found in JSON-LD\n", stderr)
        if !RecipeJSONLDExtractor.extractJSONLDBlocks(from: html).isEmpty {
            fputs("  JSON-LD blocks found, but none contain a Recipe\n", stderr)
        } else {
            fputs("  No JSON-LD blocks found in HTML\n", stderr)
        }
        return
    }

    let (recipe, mapCtx) = SchemaRecipeMapper.map(recipeDict, sourceURL: url)

    // Print results
    fputs("\n=== Extraction Results ===\n", stderr)
    fputs("Title: \(recipe.title ?? "(none)")\n", stderr)
    fputs("Author: \(recipe.author ?? "(none)")\n", stderr)
    fputs("Servings: \(recipe.servings.map { String($0) } ?? "(none)") (raw: \(recipe.servingsRaw ?? "n/a"))\n", stderr)
    fputs("Prep time: \(recipe.prepTimeMinutes.map { "\($0) min" } ?? "(none)")\n", stderr)
    fputs("Cook time: \(recipe.cookTimeMinutes.map { "\($0) min" } ?? "(none)")\n", stderr)
    fputs("Total time: \(recipe.totalTimeMinutes.map { "\($0) min" } ?? "(none)")\n", stderr)
    fputs("Image: \(recipe.imageURL != nil ? "yes" : "no")\n", stderr)
    fputs("Ingredients: \(recipe.ingredients?.count ?? 0)\n", stderr)
    fputs("Instructions: \(recipe.instructions != nil ? "yes (\(recipe.instructions!.count) chars)" : "no")\n", stderr)
    fputs("Fields extracted: \(recipe.fieldsExtracted)/8\n", stderr)
    fputs("Fields missing: \(recipe.fieldsMissing.joined(separator: ", "))\n", stderr)

    if extractCtx.usedGraphWrapper { fputs("  [edge case] Used @graph wrapper\n", stderr) }
    if extractCtx.usedArrayType { fputs("  [edge case] Used array @type\n", stderr) }
    if extractCtx.hadHTMLEntities { fputs("  [edge case] Had HTML entities in JSON-LD\n", stderr) }
    if mapCtx.hadHowToSteps { fputs("  [edge case] Had HowToStep instructions\n", stderr) }
    if mapCtx.hadHowToSections { fputs("  [edge case] Had HowToSection nesting\n", stderr) }
    if mapCtx.hadUnusualYield { fputs("  [edge case] Had unusual yield format\n", stderr) }

    for issue in extractCtx.issues + mapCtx.issues {
        fputs("  [issue] \(issue)\n", stderr)
    }

    // Output JSON to stdout
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let jsonData = try? encoder.encode(recipe),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
}

// MARK: - Matrix Extraction

/// A site entry parsed from the test matrix markdown.
struct MatrixEntry {
    let number: Int
    let siteName: String
    let url: String
    let tier: Int
}

/// Parse the test site matrix markdown to extract site entries.
func parseTestMatrix(at path: String) -> [MatrixEntry] {
    guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
        fputs("Error: Cannot read matrix file at \(path)\n", stderr)
        return []
    }

    var entries: [MatrixEntry] = []
    var currentTier = 0

    for line in content.components(separatedBy: "\n") {
        // Detect tier headers
        if line.contains("Tier 1") { currentTier = 1 }
        else if line.contains("Tier 2") { currentTier = 2 }
        else if line.contains("Tier 3") { currentTier = 3 }
        else if line.contains("Tier 4") { currentTier = 4 }

        // Parse table rows: | # | Site | URL | ...
        let columns = line.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard columns.count >= 3,
              let number = Int(columns[0]),
              columns[2].hasPrefix("http") else {
            continue
        }

        entries.append(MatrixEntry(
            number: number,
            siteName: columns[1],
            url: columns[2],
            tier: currentTier
        ))
    }

    return entries
}

/// Run extraction against all sites in the matrix and produce a report.
func extractMatrix(matrixPath: String, reportPath: String?) {
    let entries = parseTestMatrix(at: matrixPath)
    guard !entries.isEmpty else {
        fputs("Error: No site entries found in matrix\n", stderr)
        return
    }

    fputs("Found \(entries.count) sites in test matrix\n", stderr)
    fputs("Starting extraction (2-second delay between requests)...\n\n", stderr)

    var results: [SiteExtractionResult] = []

    for (index, entry) in entries.enumerated() {
        fputs("[\(index + 1)/\(entries.count)] \(entry.siteName): \(entry.url)\n", stderr)

        let start = CFAbsoluteTimeGetCurrent()
        let (html, statusCode, fetchError) = fetchHTML(from: entry.url)
        let fetchTimeMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)

        if let html = html {
            if let (recipeDict, extractCtx) = RecipeJSONLDExtractor.extract(from: html) {
                let (recipe, mapCtx) = SchemaRecipeMapper.map(recipeDict, sourceURL: entry.url)

                let result = SiteExtractionResult(
                    siteNumber: entry.number,
                    siteName: entry.siteName,
                    url: entry.url,
                    tier: entry.tier,
                    jsonLDFound: true,
                    recipeFound: true,
                    recipe: recipe,
                    extractionTimeMs: fetchTimeMs,
                    issues: extractCtx.issues + mapCtx.issues,
                    httpStatusCode: statusCode,
                    error: nil,
                    usedGraphWrapper: extractCtx.usedGraphWrapper,
                    usedArrayType: extractCtx.usedArrayType,
                    hadHowToSteps: mapCtx.hadHowToSteps,
                    hadHowToSections: mapCtx.hadHowToSections,
                    hadHTMLEntities: extractCtx.hadHTMLEntities,
                    hadUnusualYield: mapCtx.hadUnusualYield,
                    extractionMethod: extractCtx.extractionMethod
                )
                results.append(result)

                let status = recipe.fieldsMissing.isEmpty ? "FULL" : "PARTIAL (\(recipe.fieldsMissing.joined(separator: ", ")))"
                fputs("  ✓ Recipe found via \(extractCtx.extractionMethod) — \(status) — \(fetchTimeMs)ms\n", stderr)
            } else {
                let hasJSONLD = !RecipeJSONLDExtractor.extractJSONLDBlocks(from: html).isEmpty
                let result = SiteExtractionResult(
                    siteNumber: entry.number,
                    siteName: entry.siteName,
                    url: entry.url,
                    tier: entry.tier,
                    jsonLDFound: hasJSONLD,
                    recipeFound: false,
                    recipe: nil,
                    extractionTimeMs: fetchTimeMs,
                    issues: hasJSONLD ? ["JSON-LD found but no Recipe type"] : ["No JSON-LD found"],
                    httpStatusCode: statusCode,
                    error: nil,
                    usedGraphWrapper: false,
                    usedArrayType: false,
                    hadHowToSteps: false,
                    hadHowToSections: false,
                    hadHTMLEntities: false,
                    hadUnusualYield: false,
                    extractionMethod: "none"
                )
                results.append(result)
                fputs("  ✗ No recipe — \(hasJSONLD ? "JSON-LD found, no Recipe type" : "No JSON-LD") — \(fetchTimeMs)ms\n", stderr)
            }
        } else {
            let result = SiteExtractionResult(
                siteNumber: entry.number,
                siteName: entry.siteName,
                url: entry.url,
                tier: entry.tier,
                jsonLDFound: false,
                recipeFound: false,
                recipe: nil,
                extractionTimeMs: fetchTimeMs,
                issues: [],
                httpStatusCode: statusCode,
                error: fetchError ?? "No HTML content",
                usedGraphWrapper: false,
                usedArrayType: false,
                hadHowToSteps: false,
                hadHowToSections: false,
                hadHTMLEntities: false,
                hadUnusualYield: false,
                extractionMethod: "none"
            )
            results.append(result)
            fputs("  ✗ Fetch error: \(fetchError ?? "unknown") (HTTP \(statusCode ?? 0)) — \(fetchTimeMs)ms\n", stderr)
        }

        // Rate limiting: 2-second delay between requests
        if index < entries.count - 1 {
            Thread.sleep(forTimeInterval: 2.0)
        }
    }

    // Build report
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    let report = ExtractionReport(
        generatedAt: formatter.string(from: Date()),
        totalSites: entries.count,
        results: results
    )

    // Print summary
    fputs("\n" + String(repeating: "=", count: 60) + "\n", stderr)
    fputs("EXTRACTION REPORT SUMMARY\n", stderr)
    fputs(String(repeating: "=", count: 60) + "\n", stderr)
    fputs("Total sites:           \(report.totalSites)\n", stderr)
    fputs("JSON-LD found:         \(report.jsonLDFoundCount)/\(report.totalSites)\n", stderr)
    fputs("Recipe found:          \(report.recipeFoundCount)/\(report.totalSites)\n", stderr)
    fputs("Full extraction:       \(report.fullExtractionCount)/\(report.totalSites)\n", stderr)
    fputs("Partial extraction:    \(report.partialExtractionCount)/\(report.totalSites)\n", stderr)
    fputs("No extraction:         \(report.noExtractionCount)/\(report.totalSites)\n", stderr)
    fputs("Blocked (403/429):     \(report.blockedCount)/\(report.totalSites)\n", stderr)
    fputs("Median time:           \(report.medianExtractionTimeMs)ms\n", stderr)
    fputs("\nEdge cases:\n", stderr)
    fputs("  @graph wrappers:     \(report.graphWrapperCount)/\(report.totalSites)\n", stderr)
    fputs("  Array @type:         \(report.arrayTypeCount)/\(report.totalSites)\n", stderr)
    fputs("  HowToStep:           \(report.howToStepsCount)/\(report.totalSites)\n", stderr)
    fputs("  HowToSection:        \(report.howToSectionsCount)/\(report.totalSites)\n", stderr)
    fputs("  HTML entities:       \(report.htmlEntitiesCount)/\(report.totalSites)\n", stderr)
    fputs("  Unusual yield:       \(report.unusualYieldCount)/\(report.totalSites)\n", stderr)
    fputs(String(repeating: "=", count: 60) + "\n", stderr)

    // Write JSON report
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let jsonData = try? encoder.encode(report) {
        let outputPath = reportPath ?? "extraction-report.json"
        let outputURL = URL(fileURLWithPath: outputPath)
        try? jsonData.write(to: outputURL)
        fputs("\nReport written to: \(outputPath)\n", stderr)

        // Also print to stdout
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}

// MARK: - Local HTML Extraction

/// Extract a recipe from a local HTML file.
func extractFromFile(path: String) {
    guard let html = try? String(contentsOfFile: path, encoding: .utf8) else {
        fputs("Error: Cannot read file at \(path)\n", stderr)
        return
    }

    fputs("Reading local HTML: \(path) (\(html.count) chars)\n", stderr)

    guard let (recipeDict, extractCtx) = RecipeJSONLDExtractor.extract(from: html) else {
        fputs("No recipe found in JSON-LD\n", stderr)
        return
    }

    let (recipe, _) = SchemaRecipeMapper.map(recipeDict, sourceURL: nil)

    fputs("Title: \(recipe.title ?? "(none)")\n", stderr)
    fputs("Ingredients: \(recipe.ingredients?.count ?? 0)\n", stderr)
    fputs("Fields extracted: \(recipe.fieldsExtracted)/8\n", stderr)

    for issue in extractCtx.issues {
        fputs("  [issue] \(issue)\n", stderr)
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let jsonData = try? encoder.encode(recipe),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
}

// MARK: - Entry Point

let args = CommandLine.arguments

if args.count < 2 {
    printUsage()
} else {
    switch args[1] {
    case "--url":
        if args.count >= 3 {
            extractSingle(url: args[2])
        } else {
            fputs("Error: --url requires a URL argument\n", stderr)
        }

    case "--matrix":
        if args.count >= 3 {
            let reportPath = args.count >= 5 && args[3] == "--report" ? args[4] : nil
            extractMatrix(matrixPath: args[2], reportPath: reportPath)
        } else {
            fputs("Error: --matrix requires a path argument\n", stderr)
        }

    case "--html":
        if args.count >= 3 {
            extractFromFile(path: args[2])
        } else {
            fputs("Error: --html requires a file path argument\n", stderr)
        }

    case "--image":
        if args.count >= 3 {
            extractFromImage(path: args[2])
        } else {
            fputs("Error: --image requires a file path argument\n", stderr)
        }

    case "--help", "-h":
        printUsage()

    default:
        fputs("Unknown option: \(args[1])\n", stderr)
        printUsage()
    }
}

// MARK: - Image Extraction

/// Extract a recipe from an image file using OCR + heuristic classification.
func extractFromImage(path: String) {
    fputs("Processing image: \(path)\n", stderr)

    let result = ImageRecipeExtractor.extractFromImage(path: path)

    fputs("\n=== OCR Results ===\n", stderr)
    fputs("Lines recognized: \(result.ocrLineCount)\n", stderr)
    fputs("Average confidence: \(String(format: "%.1f%%", result.ocrConfidence * 100))\n", stderr)
    fputs("Processing time: \(result.processingTimeMs)ms\n", stderr)

    if !result.issues.isEmpty {
        for issue in result.issues {
            fputs("  [issue] \(issue)\n", stderr)
        }
    }

    fputs("\n=== Line Classification ===\n", stderr)
    for line in result.classifiedLines {
        let typeTag = line.type.padding(toLength: 14, withPad: " ", startingAt: 0)
        let conf = String(format: "%.0f%%", line.confidence * 100)
        let score = String(format: "%.2f", line.score)
        fputs("  [\(typeTag)] (\(conf), s=\(score)) \(line.text)\n", stderr)
    }

    if let recipe = result.extractedRecipe {
        fputs("\n=== Extracted Recipe ===\n", stderr)
        fputs("Title: \(recipe.title ?? "(none)")\n", stderr)
        fputs("Ingredients: \(recipe.ingredients?.count ?? 0)\n", stderr)
        fputs("Instructions: \(recipe.instructions != nil ? "yes" : "no")\n", stderr)
        fputs("Servings: \(recipe.servings.map { String($0) } ?? "(none)")\n", stderr)
        fputs("Prep time: \(recipe.prepTimeMinutes.map { "\($0) min" } ?? "(none)")\n", stderr)
        fputs("Cook time: \(recipe.cookTimeMinutes.map { "\($0) min" } ?? "(none)")\n", stderr)
        fputs("Fields extracted: \(recipe.fieldsExtracted)/8\n", stderr)

        // Output JSON to stdout
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(result),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    } else {
        fputs("\nNo recipe could be assembled from OCR output\n", stderr)
    }
}

func printUsage() {
    fputs("""
    ImportSpike — Recipe Extraction Tool (URL + Image)

    Usage:
      ImportSpike --url <url>                          Extract recipe from a URL
      ImportSpike --matrix <path> [--report <path>]    Extract from test matrix
      ImportSpike --html <path>                        Extract from local HTML file
      ImportSpike --image <path>                       Extract recipe from image (OCR)
      ImportSpike --help                               Show this help

    Examples:
      swift run ImportSpike --url "https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/"
      swift run ImportSpike --matrix "../../docs/import-research/test-site-matrix.md"
      swift run ImportSpike --html "./saved-recipe.html"
      swift run ImportSpike --image "./cookbook-page.jpg"

    """, stderr)
}
