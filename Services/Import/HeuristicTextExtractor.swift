//
//  HeuristicTextExtractor.swift
//  forager
//
//  Created for M10.2.4: Heuristic text fallback extractor
//  Thin adapter over OCRLineClassifier — wraps plain text lines as OCRLine,
//  classifies them, and assembles an ImportDraftRecipe.
//  Works on all devices (no Foundation Models dependency).
//

import Foundation

// MARK: - Heuristic Text Extractor

/// Extracts recipes from plain text using heuristic line classification.
/// Fallback for devices without Foundation Models, or when AI extraction fails.
/// All fields get `.medium` confidence (heuristic source).
class HeuristicTextExtractor: RecipeExtractor {
    let extractorName = "heuristic_text"

    func extract(from input: RecipeExtractionInput) async throws -> ImportDraftRecipe? {
        guard case .text(let text) = input else { return nil }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Split into lines and wrap as OCRLine
        let rawLines = text.components(separatedBy: .newlines)
        let ocrLines = rawLines.map { OCRLine.fromText($0) }

        // Classify all lines
        let classified = OCRLineClassifier.classifyLines(ocrLines)

        guard !classified.isEmpty else {
            throw ImportError.noRecipeFound
        }

        // Assemble draft from classified lines
        let draft = assembleDraft(from: classified, extractionTimeMs: elapsed(since: startTime))

        // Validate: need at least some ingredients
        guard !draft.ingredients.value.isEmpty else {
            throw ImportError.noRecipeFound
        }

        return draft
    }

    // MARK: - Assembly

    /// Assemble an ImportDraftRecipe from classified lines
    private func assembleDraft(from lines: [ClassifiedLine], extractionTimeMs: Int) -> ImportDraftRecipe {
        var title = ""
        var ingredients: [String] = []
        var instructions: [String] = []
        var prepMinutes: Int?
        var cookMinutes: Int?
        var servings: Int?

        for line in lines {
            switch line.type {
            case .title:
                // Take the first title-classified line
                if title.isEmpty {
                    title = line.text
                }

            case .ingredient:
                ingredients.append(line.text)

            case .instruction:
                instructions.append(line.text)

            case .metadata:
                // Extract structured values from metadata lines
                extractMetadata(from: line.text, prepMinutes: &prepMinutes, cookMinutes: &cookMinutes, servings: &servings)

            case .sectionHeader:
                // Section headers are structural — skip from output
                break

            case .unknown:
                // Skip unclassified lines
                break
            }
        }

        // If no title was detected, use the first non-empty line
        if title.isEmpty, let firstLine = lines.first(where: { $0.type != .sectionHeader }) {
            title = firstLine.text
        }

        // Combine instruction lines into a single string with numbering
        let instructionText: String
        if instructions.count > 1 {
            // If instructions aren't already numbered, add numbers
            let alreadyNumbered = instructions.allSatisfy { line in
                line.first?.isNumber == true || line.lowercased().hasPrefix("step")
            }
            if alreadyNumbered {
                instructionText = instructions.joined(separator: "\n")
            } else {
                instructionText = instructions.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            }
        } else {
            instructionText = instructions.first ?? ""
        }

        return ImportDraftRecipe(
            title: ImportField(value: title, confidence: title.isEmpty ? .missing : .medium, source: .heuristic),
            ingredients: ImportField(value: ingredients, confidence: ingredients.isEmpty ? .missing : .medium, source: .heuristic),
            instructions: ImportField(
                value: instructionText,
                confidence: instructionText.isEmpty ? .missing : .medium,
                source: .heuristic
            ),
            prepTimeMinutes: ImportField(
                value: prepMinutes,
                confidence: prepMinutes != nil ? .medium : .missing,
                source: .heuristic
            ),
            cookTimeMinutes: ImportField(
                value: cookMinutes,
                confidence: cookMinutes != nil ? .medium : .missing,
                source: .heuristic
            ),
            servings: ImportField(
                value: servings ?? 4,
                confidence: servings != nil ? .medium : .low,
                source: .heuristic
            ),
            imageURL: ImportField(value: nil, confidence: .missing, source: .heuristic),
            author: ImportField(value: nil, confidence: .missing, source: .heuristic),
            sourceURL: nil,
            description: nil,
            cuisine: nil,
            category: nil,
            tags: nil,
            extractionMethod: "heuristic_text",
            extractionTimeMs: extractionTimeMs
        )
    }

    // MARK: - Metadata Extraction

    /// Parse structured values (prep time, cook time, servings) from metadata lines
    private func extractMetadata(from text: String, prepMinutes: inout Int?, cookMinutes: inout Int?, servings: inout Int?) {
        let lower = text.lowercased()

        // Servings: "Serves 4", "Servings: 6", "Makes 12"
        if let match = lower.range(of: #"(?:serves?|servings?|makes?|yields?)\s*:?\s*(\d+)"#, options: .regularExpression) {
            let numRange = lower[match].filter(\.isNumber)
            if let num = Int(numRange), num > 0, num <= 100 {
                servings = num
            }
        }

        // Prep time: "Prep time: 15 min", "Prep: 20 minutes"
        if let match = lower.range(of: #"prep\s*(?:time)?\s*:?\s*(\d+)\s*(?:min|m\b|hour|hr|h\b)"#, options: .regularExpression) {
            let substring = lower[match]
            if let minutes = extractMinutes(from: String(substring)) {
                prepMinutes = minutes
            }
        }

        // Cook time: "Cook time: 30 min", "Bake: 45 minutes"
        if let match = lower.range(of: #"(?:cook|bake)\s*(?:time)?\s*:?\s*(\d+)\s*(?:min|m\b|hour|hr|h\b)"#, options: .regularExpression) {
            let substring = lower[match]
            if let minutes = extractMinutes(from: String(substring)) {
                cookMinutes = minutes
            }
        }
    }

    /// Extract minutes from a time string like "30 min" or "1 hour"
    private func extractMinutes(from text: String) -> Int? {
        let lower = text.lowercased()
        guard lower.contains(where: \.isNumber) else { return nil }

        // Find all digits
        let digits = lower.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return nil }

        // Convert hours to minutes if needed
        if lower.contains("hour") || lower.contains("hr") || (lower.contains("h") && !lower.contains("min")) {
            return value * 60
        }
        return value
    }

    // MARK: - Helpers

    private func elapsed(since start: CFAbsoluteTime) -> Int {
        Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
    }
}
