import Foundation

// MARK: - Run Logger

/// Writes a detailed step-by-step log file for each harness run.
/// Logs go to Results/log-{runId}.txt alongside the JSON results.
class RunLogger {
    private let fileHandle: FileHandle?
    private let filePath: URL
    private let startTime: Date

    init(resultsDir: URL) {
        self.startTime = Date()
        let timestamp = ISO8601DateFormatter().string(from: startTime)
            .replacingOccurrences(of: ":", with: "-")
        self.filePath = resultsDir.appendingPathComponent("log-\(timestamp).txt")

        FileManager.default.createFile(atPath: filePath.path, contents: nil)
        self.fileHandle = FileHandle(forWritingAtPath: filePath.path)

        write("════════════════════════════════════════════════════════════")
        write("FORAGER PARSING TEST HARNESS — RUN LOG")
        write("Started: \(timestamp)")
        write("════════════════════════════════════════════════════════════")
        write("")
    }

    deinit {
        let elapsed = Date().timeIntervalSince(startTime)
        write("")
        write("════════════════════════════════════════════════════════════")
        write("Run completed in \(String(format: "%.1f", elapsed))s")
        write("Log: \(filePath.lastPathComponent)")
        write("════════════════════════════════════════════════════════════")
        fileHandle?.closeFile()
    }

    // MARK: - Step Headers

    func step(_ number: Int, _ title: String) {
        write("")
        write("──────────────────────────────────────────────────────────")
        write("STEP \(number): \(title)")
        write("──────────────────────────────────────────────────────────")
    }

    // MARK: - Logging Methods

    func write(_ message: String) {
        let line = message + "\n"
        fileHandle?.write(Data(line.utf8))
    }

    func logURLSelection(selected: [RecipeDiscovery.SelectedURL], reuseCount: Int, newCount: Int) {
        step(1, "RECIPE URL SELECTION")
        write("Target: \(selected.count) recipes")
        write("Reuse: \(reuseCount) | New: \(newCount)")
        write("")
        for (i, url) in selected.enumerated() {
            write("  [\(i + 1)] [\(url.source.rawValue)] \(url.site): \(url.url)")
        }
    }

    func logFetchStart(url: String, index: Int, total: Int) {
        write("  [\(index)/\(total)] Fetching: \(url)")
    }

    func logFetchSuccess(url: String, title: String?, ingredientCount: Int, method: String, timeMs: Int) {
        write("    ✓ \(title ?? "untitled") — \(ingredientCount) ingredients via \(method) (\(timeMs)ms)")
    }

    func logFetchFailure(url: String, reason: String, replaced: Bool) {
        write("    ✗ FAILED: \(reason)\(replaced ? " — pulling replacement" : "")")
    }

    func logFetchSummary(success: Int, failed: Int, total: Int) {
        step(2, "FETCH & EXTRACT COMPLETE")
        write("Success: \(success)/\(total) | Failed: \(failed)")
    }

    func logIngredientParse(raw: String, sanitized: String, regex: ParserResult, nlp: ParserResult, hybrid: ParserResult) {
        write("  Input: \"\(raw)\"")
        if raw != sanitized {
            write("  Sanitized: \"\(sanitized)\"")
        }
        write("    Regex:  name=\"\(regex.name)\" qty=\(regex.quantity.map { String($0) } ?? "nil") unit=\(regex.unit ?? "nil") conf=\(String(format: "%.2f", regex.confidence))")
        write("    NLP:    name=\"\(nlp.name)\" qty=\(nlp.quantity.map { String($0) } ?? "nil") unit=\(nlp.unit ?? "nil") conf=\(String(format: "%.2f", nlp.confidence))")
        write("    Hybrid: name=\"\(hybrid.name)\" qty=\(hybrid.quantity.map { String($0) } ?? "nil") unit=\(hybrid.unit ?? "nil") conf=\(String(format: "%.2f", hybrid.confidence)) [via \(hybrid.parserUsed)]")
    }

    func logRecipeParseSummary(title: String?, url: String, ingredientCount: Int) {
        write("")
        write("Recipe: \(title ?? "untitled")")
        write("URL: \(url)")
        write("Ingredients: \(ingredientCount)")
    }

    func logAIParseResult(index: Int, raw: String, aiName: String, aiQty: Double?, aiUnit: String?, aiNotes: String?) {
        write("  [\(index)] \"\(raw)\"")
        write("    AI: name=\"\(aiName)\" qty=\(aiQty.map { String($0) } ?? "nil") unit=\(aiUnit ?? "nil") notes=\(aiNotes ?? "nil")")
    }

    func logAISkipped() {
        step(4, "AI PARSING — SKIPPED (no ANTHROPIC_API_KEY)")
    }

    func logComparison(raw: String, agreement: ResultComparer.Agreement, issues: [String]) {
        if !issues.isEmpty {
            write("  [\(agreement.rawValue)] \"\(raw.prefix(60))\"")
            for issue in issues {
                write("    → \(issue)")
            }
        }
    }

    func logSummary(summary: ResultStore.RunSummary, recipeCount: Int, failureCount: Int) {
        step(6, "SUMMARY")
        write("Recipes: \(recipeCount) extracted (\(failureCount) failed)")
        write("Ingredients: \(summary.totalIngredients)")
        write("Avg confidence: \(String(format: "%.2f", summary.avgLocalConfidence))")

        let dist = summary.parserDistribution.sorted { $0.value > $1.value }
        write("Parser distribution: \(dist.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))")

        if summary.aiEnabled {
            let total = summary.matchCount + summary.localLikelyWrongCount + summary.aiLikelyWrongCount + summary.ambiguousCount
            write("Agreement: \(summary.matchCount)/\(total)")
            write("Local likely wrong: \(summary.localLikelyWrongCount)")
            write("AI likely wrong: \(summary.aiLikelyWrongCount)")
        }

        if !summary.topIssues.isEmpty {
            write("")
            write("Top issues:")
            for issue in summary.topIssues.prefix(10) {
                write("  \(issue.pattern) ×\(issue.count)")
                for ex in issue.examples.prefix(2) {
                    write("    e.g. \"\(ex.prefix(80))\"")
                }
            }
        }
    }
}
