//
//  RecipeCorpusTests.swift
//  foragerTests
//
//  Created for M10.5.2: Test harness for recipe corpus accuracy baseline
//  Runs 50 corpus recipes through OCRLineClassifier + HybridIngredientParser,
//  writes structured results and a markdown review file for human correction.
//

import XCTest
@testable import forager

final class RecipeCorpusTests: XCTestCase {

    // MARK: - Properties

    private var parser: HybridIngredientParser!

    /// Corpus directory derived from this source file's location
    private var corpusDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()           // Services/
            .deletingLastPathComponent()           // foragerTests/
            .appendingPathComponent("TestData")
            .appendingPathComponent("RecipeCorpus")
    }

    /// Output directory for results
    private var outputDir: URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ForagerCorpusResults")
    }

    override func setUp() {
        super.setUp()
        parser = HybridIngredientParser()
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    // MARK: - Corpus Runner

    func testRunFullCorpus() throws {
        let categories = ["clean", "no-headers", "unusual-metadata", "messy", "international"]
        var allResults: [RecipeResult] = []
        var totalClassificationLines = 0
        var totalIngredientLines = 0
        var categoryStats: [String: CategoryStat] = [:]

        for category in categories {
            let categoryDir = corpusDir.appendingPathComponent(category)
            let files = try FileManager.default.contentsOfDirectory(at: categoryDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "txt" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            var stat = CategoryStat()

            for file in files {
                let text = try String(contentsOf: file, encoding: .utf8)
                let filename = file.deletingPathExtension().lastPathComponent
                let result = processRecipe(text: text, filename: filename, category: category)
                allResults.append(result)

                stat.recipeCount += 1
                stat.totalLines += result.classification.count
                stat.ingredientLines += result.parsing.count
                totalClassificationLines += result.classification.count
                totalIngredientLines += result.parsing.count
            }

            categoryStats[category] = stat
        }

        // Write JSON results
        let jsonData = try JSONEncoder.prettyPrinted(allResults)
        let jsonURL = outputDir.appendingPathComponent("corpus-results.json")
        try jsonData.write(to: jsonURL)

        // Write markdown review file
        let markdown = generateReviewMarkdown(results: allResults, categoryStats: categoryStats)
        let mdURL = outputDir.appendingPathComponent("corpus-review.md")
        try markdown.write(to: mdURL, atomically: true, encoding: .utf8)

        // Print summary to console
        print("\n" + String(repeating: "=", count: 60))
        print("RECIPE CORPUS TEST RESULTS")
        print(String(repeating: "=", count: 60))
        print("Total recipes processed: \(allResults.count)")
        print("Total lines classified:  \(totalClassificationLines)")
        print("Total ingredients parsed: \(totalIngredientLines)")
        print("")
        print("Classification distribution:")
        let allClassifications = allResults.flatMap(\.classification)
        let typeCounts = Dictionary(grouping: allClassifications, by: \.classified)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        for (type, count) in typeCounts {
            let pct = totalClassificationLines > 0
                ? String(format: "%.1f%%", Double(count) / Double(totalClassificationLines) * 100)
                : "0%"
            print("  \(type.padding(toLength: 16, withPad: " ", startingAt: 0)) \(count) (\(pct))")
        }
        print("")
        print("Parser usage distribution:")
        let parserCounts = Dictionary(grouping: allResults.flatMap(\.parsing), by: \.parserUsed)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        for (parserName, count) in parserCounts {
            let pct = totalIngredientLines > 0
                ? String(format: "%.1f%%", Double(count) / Double(totalIngredientLines) * 100)
                : "0%"
            print("  \(parserName.padding(toLength: 16, withPad: " ", startingAt: 0)) \(count) (\(pct))")
        }
        print("")
        print("Per-category breakdown:")
        for category in categories {
            if let stat = categoryStats[category] {
                print("  \(category.padding(toLength: 20, withPad: " ", startingAt: 0)) \(stat.recipeCount) recipes, \(stat.totalLines) lines, \(stat.ingredientLines) ingredients")
            }
        }
        print("")
        print("Average confidence:")
        let classConfidences = allClassifications.map(\.confidence)
        let parseConfidences = allResults.flatMap(\.parsing).map(\.confidence)
        if !classConfidences.isEmpty {
            let avgClass = classConfidences.reduce(0, +) / Float(classConfidences.count)
            print("  Classification: \(String(format: "%.3f", avgClass))")
        }
        if !parseConfidences.isEmpty {
            let avgParse = parseConfidences.reduce(0, +) / Float(parseConfidences.count)
            print("  Parsing:        \(String(format: "%.3f", avgParse))")
        }
        print("")
        print("Output files:")
        print("  JSON:     \(jsonURL.path)")
        print("  Markdown: \(mdURL.path)")
        print(String(repeating: "=", count: 60))

        // Basic assertions — the test should not crash
        XCTAssertEqual(allResults.count, 50, "Should process all 50 corpus recipes")
        XCTAssertGreaterThan(totalClassificationLines, 0, "Should classify at least some lines")
        XCTAssertGreaterThan(totalIngredientLines, 0, "Should parse at least some ingredients")
    }

    // MARK: - Performance

    func testCorpusPerformance() throws {
        let categories = ["clean", "no-headers", "unusual-metadata", "messy", "international"]
        var texts: [(String, String, String)] = [] // (text, filename, category)

        for category in categories {
            let categoryDir = corpusDir.appendingPathComponent(category)
            let files = try FileManager.default.contentsOfDirectory(at: categoryDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "txt" }
            for file in files {
                let text = try String(contentsOf: file, encoding: .utf8)
                texts.append((text, file.deletingPathExtension().lastPathComponent, category))
            }
        }

        measure {
            for (text, filename, category) in texts {
                _ = processRecipe(text: text, filename: filename, category: category)
            }
        }
    }

    // MARK: - Processing

    private func processRecipe(text: String, filename: String, category: String) -> RecipeResult {
        // Stage 1: Classification
        let rawLines = text.components(separatedBy: .newlines)
        let ocrLines = rawLines.map { OCRLine.fromText($0) }
        let classified = OCRLineClassifier.classifyLines(ocrLines)

        let classificationResults = classified.enumerated().map { (index, line) in
            ClassificationResult(
                lineNumber: index + 1,
                text: line.text,
                classified: line.type.rawValue,
                confidence: line.confidence
            )
        }

        // Stage 2: Parse ingredient lines
        let ingredientLines = classified.filter { $0.type == .ingredient }
        let parsingResults = ingredientLines.enumerated().map { (index, line) in
            let result = parser.parse(line.text)
            return ParsingResult(
                lineNumber: classificationResults.first(where: { $0.text == line.text })?.lineNumber ?? (index + 1),
                text: line.text,
                quantity: result.quantity.map { formatQuantity($0) },
                unit: result.unit,
                name: result.name,
                confidence: result.confidence,
                parserUsed: result.parserUsed
            )
        }

        return RecipeResult(
            filename: filename,
            category: category,
            totalLines: rawLines.count,
            classification: classificationResults,
            parsing: parsingResults
        )
    }

    private func formatQuantity(_ value: Double) -> String {
        if value == value.rounded() && value < 1000 {
            return String(Int(value))
        }
        return String(format: "%.2g", value)
    }

    // MARK: - Markdown Review File Generation

    private func generateReviewMarkdown(results: [RecipeResult], categoryStats: [String: CategoryStat]) -> String {
        var md = """
        # Recipe Corpus Review File

        **Generated**: \(ISO8601DateFormatter().string(from: Date()))
        **Total Recipes**: \(results.count)
        **Purpose**: Review classifier and parser predictions. Change `Y` to `N` in the Correct? column and fill Correction for any errors.

        ## How to Review

        1. Scan each recipe's Classification table — is every line classified correctly?
        2. Scan the Parsing table — for ingredient lines, are qty/unit/name correct?
        3. For incorrect predictions: change `Y` to `N` and describe the fix in the Correction column
        4. Examples of corrections:
           - Classification: `N` | `should be: ingredient` (line was misclassified)
           - Parsing: `N` | `qty=14.5 unit=oz name=diced tomatoes` (wrong parse)

        ---

        ## Summary Statistics

        | Category | Recipes | Lines | Ingredients |
        |----------|---------|-------|-------------|

        """

        let categories = ["clean", "no-headers", "unusual-metadata", "messy", "international"]
        for cat in categories {
            if let stat = categoryStats[cat] {
                md += "| \(cat) | \(stat.recipeCount) | \(stat.totalLines) | \(stat.ingredientLines) |\n"
            }
        }

        let allClassifications = results.flatMap(\.classification)
        let typeCounts = Dictionary(grouping: allClassifications, by: \.classified).mapValues(\.count)
        md += "\n### Classification Distribution\n\n"
        md += "| Type | Count | % |\n|------|-------|---|\n"
        let totalLines = allClassifications.count
        for type in ["title", "ingredient", "instruction", "metadata", "sectionHeader", "unknown"] {
            let count = typeCounts[type] ?? 0
            let pct = totalLines > 0 ? String(format: "%.1f", Double(count) / Double(totalLines) * 100) : "0"
            md += "| \(type) | \(count) | \(pct)% |\n"
        }

        let allParsing = results.flatMap(\.parsing)
        let parserCounts = Dictionary(grouping: allParsing, by: \.parserUsed).mapValues(\.count)
        md += "\n### Parser Usage\n\n"
        md += "| Parser | Count | % |\n|--------|-------|---|\n"
        let totalParsed = allParsing.count
        for parserName in ["regex", "ml", "nlp"] {
            let count = parserCounts[parserName] ?? 0
            let pct = totalParsed > 0 ? String(format: "%.1f", Double(count) / Double(totalParsed) * 100) : "0"
            md += "| \(parserName) | \(count) | \(pct)% |\n"
        }

        md += "\n---\n\n"

        // Per-recipe tables
        for result in results {
            md += "## \(result.filename)\n\n"
            md += "**Category**: \(result.category) | **Lines**: \(result.totalLines) | **Ingredients found**: \(result.parsing.count)\n\n"

            // Classification table
            md += "### Classification\n\n"
            md += "| # | Text | Classified | Conf | Correct? | Correction |\n"
            md += "|---|------|-----------|------|----------|------------|\n"
            for cl in result.classification {
                let escapedText = cl.text.replacingOccurrences(of: "|", with: "\\|")
                    .prefix(80)
                let conf = String(format: "%.2f", cl.confidence)
                md += "| \(cl.lineNumber) | \(escapedText) | \(cl.classified) | \(conf) | Y | |\n"
            }

            // Parsing table (only if there are ingredient lines)
            if !result.parsing.isEmpty {
                md += "\n### Parsing (ingredient lines)\n\n"
                md += "| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |\n"
                md += "|---|------|-----|------|------|------|--------|----------|------------|\n"
                for pr in result.parsing {
                    let escapedText = pr.text.replacingOccurrences(of: "|", with: "\\|")
                        .prefix(60)
                    let qty = pr.quantity ?? "—"
                    let unit = pr.unit ?? "—"
                    let escapedName = pr.name.replacingOccurrences(of: "|", with: "\\|")
                        .prefix(30)
                    let conf = String(format: "%.2f", pr.confidence)
                    md += "| \(pr.lineNumber) | \(escapedText) | \(qty) | \(unit) | \(escapedName) | \(conf) | \(pr.parserUsed) | Y | |\n"
                }
            }

            md += "\n---\n\n"
        }

        return md
    }

    // MARK: - Result Models

    private struct RecipeResult: Encodable {
        let filename: String
        let category: String
        let totalLines: Int
        let classification: [ClassificationResult]
        let parsing: [ParsingResult]
    }

    private struct ClassificationResult: Encodable {
        let lineNumber: Int
        let text: String
        let classified: String
        let confidence: Float
    }

    private struct ParsingResult: Encodable {
        let lineNumber: Int
        let text: String
        let quantity: String?
        let unit: String?
        let name: String
        let confidence: Float
        let parserUsed: String
    }

    private struct CategoryStat {
        var recipeCount = 0
        var totalLines = 0
        var ingredientLines = 0
    }
}

// MARK: - JSONEncoder Extension

private extension JSONEncoder {
    static func prettyPrinted<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(value)
    }
}
