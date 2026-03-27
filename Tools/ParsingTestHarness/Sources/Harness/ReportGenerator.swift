import Foundation

// MARK: - Report Generator

/// Generates human-readable and JSON reports from run results.
struct ReportGenerator {

    /// Build summary metrics from recipe results and comparisons.
    static func buildSummary(
        recipes: [ParsingEvaluator.RecipeResult],
        comparisons: [ResultComparer.ComparisonResult],
        targetCount: Int,
        aiEnabled: Bool
    ) -> ResultStore.RunSummary {

        let allIngredients = recipes.flatMap(\.ingredients)
        let totalIngredients = allIngredients.count

        // Confidence
        let avgConfidence = allIngredients.isEmpty ? 0.0 :
            Double(allIngredients.map(\.hybrid.confidence).reduce(0, +)) / Double(totalIngredients)

        // Parser distribution
        var distribution: [String: Int] = [:]
        for ing in allIngredients {
            distribution[ing.hybrid.parserUsed, default: 0] += 1
        }

        // Comparison counts — two tiers
        let fullMatchCount = comparisons.filter { $0.agreement == .fullMatch }.count
        let coreMatchCount = comparisons.filter { $0.agreement == .coreMatch }.count
        let matchCount = fullMatchCount + coreMatchCount  // combined for backward compat
        let localWrong = comparisons.filter { $0.agreement == .localLikelyWrong }.count
        let aiWrong = comparisons.filter { $0.agreement == .aiLikelyWrong }.count
        let ambiguous = comparisons.filter { $0.agreement == .ambiguous }.count

        // Pattern detection
        let patterns = ResultComparer.detectPatterns(from: comparisons)

        return ResultStore.RunSummary(
            extractionSuccessRate: targetCount > 0 ? Double(recipes.count) / Double(targetCount) : 0,
            avgLocalConfidence: avgConfidence,
            parserDistribution: distribution,
            totalIngredients: totalIngredients,
            fullMatchCount: fullMatchCount,
            coreMatchCount: coreMatchCount,
            matchCount: matchCount,
            localLikelyWrongCount: localWrong,
            aiLikelyWrongCount: aiWrong,
            ambiguousCount: ambiguous,
            topIssues: Array(patterns.prefix(10)),
            aiEnabled: aiEnabled
        )
    }

    /// Print human-readable report to stderr.
    static func printReport(
        summary: ResultStore.RunSummary,
        recipeCount: Int,
        targetCount: Int,
        failureCount: Int,
        reuseCount: Int,
        newCount: Int,
        baseline: ResultStore.RunData?
    ) {
        printErr("")
        printErr("═══════════════════════════════════════════════════════")
        printErr("PARSING HARNESS REPORT")
        printErr("═══════════════════════════════════════════════════════")
        printErr("Recipes:           \(recipeCount)/\(targetCount) extracted (\(failureCount) failed)")
        printErr("Ingredients:       \(summary.totalIngredients) total")
        printErr("Reuse:             \(reuseCount) recipes reused, \(newCount) new")
        printErr("")
        printErr("LOCAL PARSING:")
        printErr("  Avg confidence:  \(String(format: "%.2f", summary.avgLocalConfidence))")

        let dist = summary.parserDistribution.sorted { $0.value > $1.value }
        let distStr = dist.map { "\($0.key) \($0.value)" }.joined(separator: " | ")
        printErr("  Router:          \(distStr)")
        printErr("")

        if summary.aiEnabled {
            let total = summary.totalIngredients
            let compared = summary.fullMatchCount + summary.coreMatchCount + summary.localLikelyWrongCount + summary.aiLikelyWrongCount + summary.ambiguousCount
            printErr("AI PARSING:")
            printErr("  Compared:        \(compared)/\(total)")
            printErr("")
            printErr("COMPARISON (two-tier):")
            if compared > 0 {
                let corePct = String(format: "%.1f", Double(summary.fullMatchCount + summary.coreMatchCount) / Double(compared) * 100)
                let fullPct = String(format: "%.1f", Double(summary.fullMatchCount) / Double(compared) * 100)
                printErr("  Core agreement:  \(summary.fullMatchCount + summary.coreMatchCount)/\(compared) (\(corePct)%)  ← AI name within local name")
                printErr("  Full agreement:  \(summary.fullMatchCount)/\(compared) (\(fullPct)%)  ← exact match")
                printErr("  Descriptor diffs:  \(summary.coreMatchCount)  (expected — local keeps qualifiers)")
            }
            printErr("  Real issues:       \(summary.localLikelyWrongCount + summary.ambiguousCount)")
            printErr("    Local wrong:     \(summary.localLikelyWrongCount)")
            printErr("    Ambiguous:       \(summary.ambiguousCount)")
            if summary.aiLikelyWrongCount > 0 {
                printErr("    AI wrong:        \(summary.aiLikelyWrongCount)")
            }
        } else {
            printErr("AI PARSING:        Skipped (no ANTHROPIC_API_KEY)")
        }

        printErr("")
        if !summary.topIssues.isEmpty {
            printErr("TOP ISSUES:")
            for (i, issue) in summary.topIssues.prefix(8).enumerated() {
                let examples = issue.examples.prefix(2).joined(separator: "; ")
                printErr("  \(i + 1). \(issue.pattern)  ×\(issue.count)  (e.g., \"\(examples.prefix(60))\")")
            }
        } else {
            printErr("TOP ISSUES:        None detected")
        }

        // Baseline comparison
        if let baseline = baseline {
            printErr("")
            printErr("BASELINE COMPARISON:")
            let baseIssueCount = baseline.summary.topIssues.reduce(0) { $0 + $1.count }
            let currentIssueCount = summary.topIssues.reduce(0) { $0 + $1.count }
            let diff = currentIssueCount - baseIssueCount
            if diff < 0 {
                printErr("  Issues: \(baseIssueCount) → \(currentIssueCount) (↓\(abs(diff)) improved)")
            } else if diff > 0 {
                printErr("  Issues: \(baseIssueCount) → \(currentIssueCount) (↑\(diff) REGRESSION)")
            } else {
                printErr("  Issues: \(currentIssueCount) (no change)")
            }

            let baseMatch = baseline.summary.matchCount
            let currentMatch = summary.matchCount
            if currentMatch != baseMatch {
                printErr("  Agreement: \(baseMatch) → \(currentMatch)")
            }
        }

        printErr("═══════════════════════════════════════════════════════")
    }

    /// Output full JSON report to stdout.
    static func outputJSON(_ runData: ResultStore.RunData) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(runData) {
            print(String(data: data, encoding: .utf8) ?? "{}")
        }
    }
}
