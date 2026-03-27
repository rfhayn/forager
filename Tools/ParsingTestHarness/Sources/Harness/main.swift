import Foundation

// MARK: - Parsing Test Harness Entry Point

let args = CommandLine.arguments

// Parse CLI arguments
let count = intArg("--count", from: args) ?? 50
let reusePercent = intArg("--reuse", from: args) ?? 40
let rerunLast = args.contains("--rerun-last")
let localOnly = args.contains("--local-only")
let updateBaseline = args.contains("--update-baseline")
let jsonOnly = args.contains("--json")
let exportTrainingData = args.contains("--export-training-data")
let specificURLs = stringArg("--urls", from: args)?.components(separatedBy: ",")

// Resolve paths relative to package root
let packageDir = resolvePackageDir()
let dataDir = packageDir.appendingPathComponent("Data")
let resultsDir = packageDir.appendingPathComponent("Results")

// Ensure Results directory exists
try? FileManager.default.createDirectory(at: resultsDir, withIntermediateDirectories: true)

// Handle --export-training-data: export and exit immediately
if exportTrainingData {
    let trainingDataURL = resultsDir.appendingPathComponent("training-data.json")
    let exportURL = resultsDir.appendingPathComponent("training-export-bio.json")
    let collector = TrainingDataCollector()
    let count = collector.exportForMLTraining(from: trainingDataURL, to: exportURL)
    if count > 0 {
        printErr("Exported \(count) BIO-tagged samples to \(exportURL.path)")
    } else {
        printErr("No training data to export. Run the harness with AI enabled first.")
    }
    // Exit — no harness run needed
    _exit(0)
}

let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
let aiEnabled = !localOnly && apiKey != nil && !(apiKey?.isEmpty ?? true)

if !jsonOnly {
    printErr("═══════════════════════════════════════════════════════")
    printErr("FORAGER PARSING TEST HARNESS")
    printErr("═══════════════════════════════════════════════════════")
    printErr("Target: \(count) recipes | Reuse: \(reusePercent)% | AI: \(aiEnabled ? "ON" : "OFF")")
    printErr("")
}

// Wrap async work
await runHarness()

// MARK: - Main Pipeline

func runHarness() async {
    // Create run logger
    let log = RunLogger(resultsDir: resultsDir)

    // Step 1: Select URLs
    if !jsonOnly { printErr("📋 Step 1: Selecting recipe URLs...") }
    let discovery = RecipeDiscovery(
        dataDir: dataDir,
        resultsDir: resultsDir,
        targetCount: count,
        reusePercentage: reusePercent
    )
    let selectedURLs = discovery.selectURLs(rerunLast: rerunLast, specificURLs: specificURLs)

    if selectedURLs.isEmpty {
        printErr("❌ No URLs available. Add URLs to Data/recipe-urls.json or Data/sitemap-sources.json")
        return
    }

    let reuseCount = selectedURLs.filter { $0.source == .reuse }.count
    let newCount = selectedURLs.count - reuseCount
    if !jsonOnly { printErr("  Selected \(selectedURLs.count) URLs (\(reuseCount) reuse, \(newCount) new)") }

    log.logURLSelection(selected: selectedURLs, reuseCount: reuseCount, newCount: newCount)

    // Step 2: Fetch & Extract
    if !jsonOnly { printErr("\n🌐 Step 2: Fetching recipes...") }
    log.step(2, "FETCH & EXTRACT")
    let fetcher = RecipeFetcher()
    let (fetchResults, failures) = await fetcher.fetchAll(
        urls: selectedURLs,
        discovery: discovery,
        targetCount: count,
        logger: log
    )

    if !jsonOnly { printErr("  Fetched \(fetchResults.count) recipes (\(failures.count) failed)") }
    log.logFetchSummary(success: fetchResults.count, failed: failures.count, total: count)

    guard !fetchResults.isEmpty else {
        printErr("❌ No recipes extracted. Check your seed URLs.")
        return
    }

    // Step 3: Parse locally
    if !jsonOnly { printErr("\n🔬 Step 3: Parsing ingredients (local)...") }
    log.step(3, "LOCAL PARSING")
    let evaluator = ParsingEvaluator()
    var recipeResults = fetchResults.map { fetch in
        let source = selectedURLs.first(where: { $0.url == fetch.url })?.source.rawValue ?? "new"
        return evaluator.parseLocal(fetchResult: fetch, source: source, logger: log)
    }

    let totalIngredients = recipeResults.reduce(0) { $0 + $1.ingredientCount }
    if !jsonOnly { printErr("  Parsed \(totalIngredients) ingredients across \(recipeResults.count) recipes") }

    // Step 4: AI parsing (optional)
    if aiEnabled, let key = apiKey {
        if !jsonOnly { printErr("\n🤖 Step 4: Parsing ingredients (Claude API)...") }
        log.step(4, "AI PARSING (Claude API)")
        await evaluator.addAIParsing(to: &recipeResults, apiKey: key, logger: log)
    } else {
        log.logAISkipped()
    }

    // Step 4b: Collect training data from AI results
    if aiEnabled {
        let collector = TrainingDataCollector()
        let newEntries = collector.collect(from: recipeResults)
        if !newEntries.isEmpty {
            let trainingDataURL = resultsDir.appendingPathComponent("training-data.json")
            let totalCount = collector.save(newEntries: newEntries, to: trainingDataURL)
            log.logTrainingDataCollection(newEntries: newEntries.count, totalEntries: totalCount)
            if !jsonOnly {
                printErr("\n🧠 Training data: \(newEntries.count) new entries collected (\(totalCount) total accumulated)")
            }
        }
    }

    // Step 5: Compare & Evaluate
    if !jsonOnly { printErr("\n📊 Step 5: Comparing results...") }
    log.step(5, "COMPARISON & EVALUATION")
    let comparisons = recipeResults.flatMap(\.ingredients).map { ResultComparer.compare(ingredient: $0) }

    // Log all comparisons with issues
    for comp in comparisons where !comp.issues.isEmpty {
        log.logComparison(raw: comp.raw, agreement: comp.agreement, issues: comp.issues)
    }

    // Build summary
    let summary = ReportGenerator.buildSummary(
        recipes: recipeResults,
        comparisons: comparisons,
        targetCount: count,
        aiEnabled: aiEnabled
    )

    // Load baseline for comparison
    let store = ResultStore(resultsDir: resultsDir)
    let baseline = store.loadBaseline()

    // Step 6: Report
    let runId = ISO8601DateFormatter().string(from: Date())
        .replacingOccurrences(of: ":", with: "-")
    let runData = ResultStore.RunData(
        runId: runId,
        timestamp: ISO8601DateFormatter().string(from: Date()),
        recipeCount: recipeResults.count,
        ingredientCount: totalIngredients,
        reusePercentage: reusePercent,
        recipes: recipeResults,
        comparisons: comparisons,
        summary: summary
    )

    // Print human report
    if !jsonOnly {
        ReportGenerator.printReport(
            summary: summary,
            recipeCount: recipeResults.count,
            targetCount: count,
            failureCount: failures.count,
            reuseCount: reuseCount,
            newCount: newCount,
            baseline: baseline
        )
    }

    // Log summary
    log.logSummary(summary: summary, recipeCount: recipeResults.count, failureCount: failures.count)

    // Save results
    store.saveRun(runData)
    discovery.savePreviousURLs(selectedURLs)

    if updateBaseline {
        store.saveBaseline(runData)
    }

    // JSON output to stdout
    if jsonOnly {
        ReportGenerator.outputJSON(runData)
    }
}

// MARK: - CLI Helpers

func intArg(_ name: String, from args: [String]) -> Int? {
    guard let idx = args.firstIndex(of: name), idx + 1 < args.count else { return nil }
    return Int(args[idx + 1])
}

func stringArg(_ name: String, from args: [String]) -> String? {
    guard let idx = args.firstIndex(of: name), idx + 1 < args.count else { return nil }
    return args[idx + 1]
}

func resolvePackageDir() -> URL {
    // Walk up from the executable to find Package.swift
    var dir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Harness/
        .deletingLastPathComponent()  // Sources/
        .deletingLastPathComponent()  // ParsingTestHarness/

    // Fallback: check if we're running from the project root
    if !FileManager.default.fileExists(atPath: dir.appendingPathComponent("Package.swift").path) {
        // Try current working directory
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if FileManager.default.fileExists(atPath: cwd.appendingPathComponent("Package.swift").path) {
            dir = cwd
        } else if FileManager.default.fileExists(atPath: cwd.appendingPathComponent("Tools/ParsingTestHarness/Package.swift").path) {
            dir = cwd.appendingPathComponent("Tools/ParsingTestHarness")
        }
    }
    return dir
}
