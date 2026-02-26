//
//  RecipeCorpusFMComparisonTests.swift
//  foragerTests
//
//  Created for M10.5: Evaluate Foundation Models ingredient parsing accuracy
//  against the existing regex→ML→NLP pipeline using the 50-recipe corpus.
//  Run on a physical device with Apple Intelligence for FM results.
//

import XCTest
@testable import forager

final class RecipeCorpusFMComparisonTests: XCTestCase {

    private var pipelineParser: HybridIngredientParser!

    private var corpusDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()           // Services/
            .deletingLastPathComponent()           // foragerTests/
            .appendingPathComponent("TestData")
            .appendingPathComponent("RecipeCorpus")
    }

    private var outputDir: URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ForagerCorpusResults")
    }

    override func setUp() {
        super.setUp()
        pipelineParser = HybridIngredientParser()
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    // MARK: - FM vs Pipeline Comparison

    func testFMvsPipelineComparison() async throws {
        let categories = ["clean", "no-headers", "unusual-metadata", "messy", "international"]
        var allComparisons: [RecipeComparison] = []

        let fmParser = FoundationModelsIngredientParser()
        let fmAvailable = FoundationModelsIngredientParser.isAvailable

        print("\n" + String(repeating: "=", count: 70))
        print("FOUNDATION MODELS vs PIPELINE — INGREDIENT PARSING COMPARISON")
        print("FM Available: \(fmAvailable)")
        if !fmAvailable {
            print("NOTE: Run on physical device with Apple Intelligence for FM results")
        }
        print(String(repeating: "=", count: 70))

        for category in categories {
            let categoryDir = corpusDir.appendingPathComponent(category)
            let files = try FileManager.default.contentsOfDirectory(at: categoryDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "txt" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            for file in files {
                let text = try String(contentsOf: file, encoding: .utf8)
                let filename = file.deletingPathExtension().lastPathComponent

                // Classify lines (shared — both approaches use the same classified ingredients)
                let rawLines = text.components(separatedBy: .newlines)
                let ocrLines = rawLines.map { OCRLine.fromText($0) }
                let classified = OCRLineClassifier.classifyLines(ocrLines)
                let ingredientLines = classified.filter { $0.type == .ingredient }
                let ingredientTexts = ingredientLines.map(\.text)

                guard !ingredientTexts.isEmpty else {
                    allComparisons.append(RecipeComparison(
                        filename: filename, category: category,
                        totalLines: rawLines.count, ingredients: []
                    ))
                    continue
                }

                // Pipeline parse (per-line, sync)
                let pipelineResults = ingredientTexts.map { line -> ParseSnapshot in
                    let r = pipelineParser.parse(line)
                    return ParseSnapshot(
                        quantity: r.quantity, unit: r.unit, name: r.name,
                        notes: r.notes, confidence: r.confidence, parser: r.parserUsed
                    )
                }

                // FM batch parse (if available)
                var fmResults: [ParseSnapshot]?
                if fmAvailable {
                    if let batch = await fmParser.parseBatch(ingredientTexts) {
                        fmResults = batch.map { r in
                            ParseSnapshot(
                                quantity: r.quantity, unit: r.unit, name: r.name,
                                notes: r.preparation, confidence: 0.95, parser: "fm"
                            )
                        }
                    }
                }

                // Build line-by-line comparisons
                var lineComparisons: [IngredientComparison] = []
                for (i, text) in ingredientTexts.enumerated() {
                    let fm: ParseSnapshot? = fmResults.flatMap { i < $0.count ? $0[i] : nil }
                    lineComparisons.append(IngredientComparison(
                        originalText: text,
                        pipeline: pipelineResults[i],
                        fm: fm
                    ))
                }

                allComparisons.append(RecipeComparison(
                    filename: filename, category: category,
                    totalLines: rawLines.count, ingredients: lineComparisons
                ))

                // Progress indicator
                print("  \(filename): \(ingredientTexts.count) ingredients" +
                      (fmResults != nil ? " (FM ✓)" : ""))
            }
        }

        // Generate comparison report
        let markdown = generateComparisonMarkdown(
            comparisons: allComparisons,
            fmAvailable: fmAvailable
        )
        let mdURL = outputDir.appendingPathComponent("fm-comparison.md")
        try markdown.write(to: mdURL, atomically: true, encoding: .utf8)

        // Console summary
        printSummary(comparisons: allComparisons, fmAvailable: fmAvailable)
        print("\nFull report: \(mdURL.path)")

        XCTAssertFalse(allComparisons.isEmpty, "Should process corpus recipes")
    }

    // MARK: - Result Types

    private struct RecipeComparison {
        let filename: String
        let category: String
        let totalLines: Int
        let ingredients: [IngredientComparison]
    }

    private struct IngredientComparison {
        let originalText: String
        let pipeline: ParseSnapshot
        let fm: ParseSnapshot?

        var hasDisagreement: Bool {
            guard let fm else { return false }
            return !quantityMatches || !unitMatches || !nameMatches
        }

        var fmFixesPipelineGap: Bool {
            guard let fm else { return false }
            return pipeline.quantity == nil && fm.quantity != nil
        }

        /// Pipeline had qty=nil and FM also had qty=nil (both failed or both correct nil)
        var bothMissingQty: Bool {
            return pipeline.quantity == nil && fm?.quantity == nil
        }

        var quantityMatches: Bool {
            guard let fm else { return true }
            if pipeline.quantity == nil && fm.quantity == nil { return true }
            guard let pq = pipeline.quantity, let fq = fm.quantity else { return false }
            return abs(pq - fq) < 0.01
        }

        var unitMatches: Bool {
            guard let fm else { return true }
            return pipeline.unit?.lowercased() == fm.unit?.lowercased()
        }

        var nameMatches: Bool {
            guard let fm else { return true }
            return pipeline.name.lowercased().trimmingCharacters(in: .whitespaces) ==
                   fm.name.lowercased().trimmingCharacters(in: .whitespaces)
        }

        /// Detects known pipeline bug patterns from corpus review
        var pipelineIssuePattern: String? {
            let text = originalText

            // Pattern 1: Metric no-space (400g, 750ml, 2L)
            if text.range(of: #"^\d+(?:\.\d+)?(?:g|kg|ml|cl|dl|L)\b"#, options: .regularExpression) != nil,
               pipeline.quantity == nil {
                return "metric-no-space"
            }

            // Pattern 2: tbs/tablespoon/teaspoon not recognized
            let lower = text.lowercased()
            if lower.contains("tbs ") || lower.contains("tablespoon") || lower.contains("teaspoon") || lower.contains("dessertspoon"),
               pipeline.unit == nil {
                return "unit-abbreviation"
            }

            // Pattern 3: Mixed fraction (2-1/2)
            if text.range(of: #"\d+-\d+/\d+"#, options: .regularExpression) != nil,
               pipeline.quantity == nil {
                return "mixed-fraction"
            }

            return nil
        }
    }

    private struct ParseSnapshot {
        let quantity: Double?
        let unit: String?
        let name: String
        let notes: String?
        let confidence: Float
        let parser: String
    }

    // MARK: - Console Summary

    private func printSummary(comparisons: [RecipeComparison], fmAvailable: Bool) {
        let allIngredients = comparisons.flatMap(\.ingredients)
        let total = allIngredients.count

        let pipelineQtySuccess = allIngredients.filter { $0.pipeline.quantity != nil }.count
        let pipelineFullParse = allIngredients.filter {
            $0.pipeline.quantity != nil && $0.pipeline.unit != nil && !$0.pipeline.name.isEmpty
        }.count

        print("\n" + String(repeating: "-", count: 50))
        print("SUMMARY")
        print(String(repeating: "-", count: 50))
        print("Recipes:           \(comparisons.count)")
        print("Ingredient lines:  \(total)")
        print("")
        print("PIPELINE:")
        print("  Qty extracted:   \(pipelineQtySuccess)/\(total) (\(pct(pipelineQtySuccess, total)))")
        print("  Fully parsed:    \(pipelineFullParse)/\(total) (\(pct(pipelineFullParse, total)))")

        let avgConf = allIngredients.map { Double($0.pipeline.confidence) }
        if !avgConf.isEmpty {
            let avg = avgConf.reduce(0, +) / Double(avgConf.count)
            print("  Avg confidence:  \(String(format: "%.3f", avg))")
        }

        // Known issue patterns
        let patterns = Dictionary(
            grouping: allIngredients.compactMap(\.pipelineIssuePattern),
            by: { $0 }
        ).mapValues(\.count).sorted { $0.value > $1.value }

        if !patterns.isEmpty {
            print("  Known issues:")
            for (pattern, count) in patterns {
                print("    \(pattern.padding(toLength: 20, withPad: " ", startingAt: 0)) \(count) lines")
            }
        }

        if fmAvailable {
            let fmQtySuccess = allIngredients.filter { $0.fm?.quantity != nil }.count
            let fmFullParse = allIngredients.filter {
                $0.fm?.quantity != nil && $0.fm?.unit != nil && !($0.fm?.name.isEmpty ?? true)
            }.count
            let disagreements = allIngredients.filter(\.hasDisagreement).count
            let fmFixes = allIngredients.filter(\.fmFixesPipelineGap).count

            print("")
            print("FOUNDATION MODELS:")
            print("  Qty extracted:   \(fmQtySuccess)/\(total) (\(pct(fmQtySuccess, total)))")
            print("  Fully parsed:    \(fmFullParse)/\(total) (\(pct(fmFullParse, total)))")
            print("")
            print("COMPARISON:")
            print("  Disagreements:   \(disagreements) lines")
            print("  FM fixes gaps:   \(fmFixes) lines (pipeline qty=nil, FM extracted qty)")

            // Per-category breakdown
            print("")
            print("  Per-category disagreements:")
            let byCat = Dictionary(grouping: allIngredients, by: { _ in "" })
            for cat in ["clean", "no-headers", "unusual-metadata", "messy", "international"] {
                let catIngredients = comparisons
                    .filter { $0.category == cat }
                    .flatMap(\.ingredients)
                let catDisagree = catIngredients.filter(\.hasDisagreement).count
                let catFixes = catIngredients.filter(\.fmFixesPipelineGap).count
                let catTotal = catIngredients.count
                print("    \(cat.padding(toLength: 20, withPad: " ", startingAt: 0)) " +
                      "\(catDisagree) disagree, \(catFixes) FM fixes, \(catTotal) total")
            }
            _ = byCat // suppress unused warning
        }

        print(String(repeating: "-", count: 50))
    }

    private func pct(_ n: Int, _ total: Int) -> String {
        total > 0 ? String(format: "%.1f%%", Double(n) / Double(total) * 100) : "0%"
    }

    // MARK: - Markdown Report

    private func generateComparisonMarkdown(
        comparisons: [RecipeComparison],
        fmAvailable: Bool
    ) -> String {
        let allIngredients = comparisons.flatMap(\.ingredients)
        let total = allIngredients.count

        let pipelineQtySuccess = allIngredients.filter { $0.pipeline.quantity != nil }.count

        var md = """
        # FM vs Pipeline — Ingredient Parsing Comparison

        **Generated**: \(ISO8601DateFormatter().string(from: Date()))
        **FM Available**: \(fmAvailable)
        **Recipes**: \(comparisons.count)
        **Ingredient Lines**: \(total)

        ---

        ## Summary

        | Metric | Pipeline | Foundation Models |
        |--------|----------|-------------------|

        """

        if fmAvailable {
            let fmQtySuccess = allIngredients.filter { $0.fm?.quantity != nil }.count
            let disagreements = allIngredients.filter(\.hasDisagreement).count
            let fmFixes = allIngredients.filter(\.fmFixesPipelineGap).count

            md += "| Qty extracted | \(pipelineQtySuccess)/\(total) (\(pct(pipelineQtySuccess, total))) | \(fmQtySuccess)/\(total) (\(pct(fmQtySuccess, total))) |\n"
            md += "| Disagreements | — | \(disagreements) lines |\n"
            md += "| FM fixes pipeline gaps | — | \(fmFixes) lines |\n"
        } else {
            md += "| Qty extracted | \(pipelineQtySuccess)/\(total) (\(pct(pipelineQtySuccess, total))) | *Run on device* |\n"
        }

        // Disagreements table (most interesting section)
        let disagreements = allIngredients.filter(\.hasDisagreement)
        if !disagreements.isEmpty {
            md += "\n## Disagreements — FM ≠ Pipeline\n\n"
            md += "These lines had different results. Review to determine which parser is correct.\n\n"
            md += "| Input | Pipeline | FM |\n"
            md += "|-------|----------|----|\n"
            for d in disagreements {
                let input = escapeMarkdown(String(d.originalText.prefix(55)))
                let pStr = formatSnapshot(d.pipeline)
                let fStr = d.fm.map { formatSnapshot($0) } ?? "—"
                md += "| \(input) | \(pStr) | \(fStr) |\n"
            }
        }

        // FM-fixes-gaps table (FM extracted qty where pipeline returned nil)
        let fixes = allIngredients.filter(\.fmFixesPipelineGap)
        if !fixes.isEmpty {
            md += "\n## FM Fixes Pipeline Gaps\n\n"
            md += "Lines where pipeline returned qty=nil but FM extracted a quantity.\n\n"
            md += "| Input | Pipeline Name | FM Qty | FM Unit | FM Name |\n"
            md += "|-------|---------------|--------|---------|--------|\n"
            for f in fixes {
                let input = escapeMarkdown(String(f.originalText.prefix(50)))
                let pName = escapeMarkdown(String(f.pipeline.name.prefix(30)))
                let fQty = f.fm?.quantity.map { String(format: "%g", $0) } ?? "—"
                let fUnit = f.fm?.unit ?? "—"
                let fName = escapeMarkdown(String(f.fm?.name.prefix(25) ?? "—"))
                md += "| \(input) | \(pName) | \(fQty) | \(fUnit) | \(fName) |\n"
            }
        }

        // Known pipeline issues
        let issues = allIngredients.filter { $0.pipelineIssuePattern != nil }
        if !issues.isEmpty {
            md += "\n## Known Pipeline Issues Detected\n\n"
            md += "| Pattern | Input | Pipeline | FM |\n"
            md += "|---------|-------|----------|----|\n"
            for issue in issues {
                let pat = issue.pipelineIssuePattern ?? ""
                let input = escapeMarkdown(String(issue.originalText.prefix(45)))
                let pStr = formatSnapshot(issue.pipeline)
                let fStr = issue.fm.map { formatSnapshot($0) } ?? "—"
                md += "| \(pat) | \(input) | \(pStr) | \(fStr) |\n"
            }
        }

        // Per-recipe detail tables
        md += "\n---\n\n## Per-Recipe Details\n\n"

        for comp in comparisons {
            md += "### \(comp.filename) (\(comp.category))\n\n"

            if comp.ingredients.isEmpty {
                md += "*No ingredients classified by OCRLineClassifier*\n\n"
                continue
            }

            md += "**\(comp.ingredients.count) ingredients** | "
            let disagreeCount = comp.ingredients.filter(\.hasDisagreement).count
            let fixCount = comp.ingredients.filter(\.fmFixesPipelineGap).count
            if fmAvailable {
                md += "\(disagreeCount) disagreements | \(fixCount) FM fixes\n\n"
            } else {
                let issueCount = comp.ingredients.filter { $0.pipelineIssuePattern != nil }.count
                md += "\(issueCount) known pipeline issues\n\n"
            }

            if fmAvailable {
                md += "| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |\n"
                md += "|-------|-------|--------|--------|--------|---------|---------|---|\n"
            } else {
                md += "| Input | Qty | Unit | Name | Conf | Parser | Issue |\n"
                md += "|-------|-----|------|------|------|--------|-------|\n"
            }

            for ing in comp.ingredients {
                let input = escapeMarkdown(String(ing.originalText.prefix(40)))
                let pQty = ing.pipeline.quantity.map { String(format: "%g", $0) } ?? "—"
                let pUnit = ing.pipeline.unit ?? "—"
                let pName = escapeMarkdown(String(ing.pipeline.name.prefix(20)))

                if fmAvailable, let fm = ing.fm {
                    let fQty = fm.quantity.map { String(format: "%g", $0) } ?? "—"
                    let fUnit = fm.unit ?? "—"
                    let fName = escapeMarkdown(String(fm.name.prefix(20)))
                    let flag = ing.hasDisagreement ? "≠" : "✓"
                    md += "| \(input) | \(pQty) | \(pUnit) | \(pName) | \(fQty) | \(fUnit) | \(fName) | \(flag) |\n"
                } else {
                    let conf = String(format: "%.2f", ing.pipeline.confidence)
                    let issue = ing.pipelineIssuePattern ?? ""
                    md += "| \(input) | \(pQty) | \(pUnit) | \(pName) | \(conf) | \(ing.pipeline.parser) | \(issue) |\n"
                }
            }
            md += "\n"
        }

        return md
    }

    private func formatSnapshot(_ s: ParseSnapshot) -> String {
        let qty = s.quantity.map { String(format: "%g", $0) } ?? "nil"
        let unit = s.unit ?? "nil"
        let name = escapeMarkdown(String(s.name.prefix(20)))
        return "qty=\(qty) unit=\(unit) name=\(name)"
    }

    private func escapeMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "\\|")
    }
}
