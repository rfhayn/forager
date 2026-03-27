import Foundation

// MARK: - Result Store

/// Persists run results and manages baselines.
struct ResultStore {

    let resultsDir: URL

    // MARK: - Run Data

    struct RunData: Codable {
        let runId: String
        let timestamp: String
        let recipeCount: Int
        let ingredientCount: Int
        let reusePercentage: Int
        let recipes: [ParsingEvaluator.RecipeResult]
        let comparisons: [ResultComparer.ComparisonResult]
        let summary: RunSummary
    }

    struct RunSummary: Codable {
        let extractionSuccessRate: Double
        let avgLocalConfidence: Double
        let parserDistribution: [String: Int]
        let totalIngredients: Int
        let fullMatchCount: Int      // Exact name + qty + unit match
        let coreMatchCount: Int      // AI canonical name within local name (descriptor diff)
        let matchCount: Int          // fullMatch + coreMatch combined
        let localLikelyWrongCount: Int
        let aiLikelyWrongCount: Int
        let ambiguousCount: Int
        let topIssues: [ResultComparer.IssuePattern]
        let aiEnabled: Bool
    }

    // MARK: - Save / Load

    func saveRun(_ data: RunData) {
        let filename = "run-\(data.runId).json"
        let path = resultsDir.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(data) {
            try? jsonData.write(to: path)
            printErr("💾 Results saved to \(filename)")
        }
        cleanOldRuns()
    }

    func loadBaseline() -> RunData? {
        let path = resultsDir.appendingPathComponent("baseline.json")
        guard let data = try? Data(contentsOf: path) else { return nil }
        return try? JSONDecoder().decode(RunData.self, from: data)
    }

    func saveBaseline(_ data: RunData) {
        let path = resultsDir.appendingPathComponent("baseline.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(data) {
            try? jsonData.write(to: path)
            printErr("📏 Baseline updated")
        }
    }

    /// Keep only the last 10 run files.
    private func cleanOldRuns() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: resultsDir, includingPropertiesForKeys: [.creationDateKey]) else { return }
        let runFiles = files
            .filter { $0.lastPathComponent.hasPrefix("run-") && $0.pathExtension == "json" }
            .sorted { a, b in
                let aDate = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let bDate = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return aDate > bDate
            }
        for file in runFiles.dropFirst(10) {
            try? fm.removeItem(at: file)
        }
    }
}
