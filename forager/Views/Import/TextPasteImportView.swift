//
//  TextPasteImportView.swift
//  forager
//
//  Created for M10.2.2: Text input UI for recipe text paste import
//  M10.2.5: Added SectionHighlightView review step between classification and preview.
//  Flow: paste text → classify → review lines → assemble draft → preview.
//

import SwiftUI

// MARK: - Text Paste Phase

/// Local state machine for the text paste flow
private enum TextPastePhase {
    case editing
    case reviewing([EditableClassifiedLine])
}

// MARK: - Text Paste Import View

/// Text input view for pasting recipe text (from websites, messages, emails).
/// After extraction, shows SectionHighlightView for line classification review,
/// then assembles ImportDraftRecipe and hands off to the preview.
struct TextPasteImportView: View {
    @ObservedObject var importService: RecipeImportService
    @FocusState private var textEditorFocused: Bool
    @State private var recipeText = ""
    @State private var phase: TextPastePhase = .editing

    var body: some View {
        switch phase {
        case .editing:
            textInputView

        case .reviewing(let lines):
            let binding = Binding<[EditableClassifiedLine]>(
                get: {
                    if case .reviewing(let current) = phase { return current }
                    return lines
                },
                set: { phase = .reviewing($0) }
            )
            SectionHighlightView(classifiedLines: binding) { correctedLines in
                assembleDraftAndContinue(from: correctedLines)
            }
        }
    }

    // MARK: - Text Input View

    private var textInputView: some View {
        VStack(spacing: 0) {
            // Header hint
            HStack {
                Text("Paste or type a recipe below")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                Spacer()
                if !recipeText.isEmpty {
                    Text("\(recipeText.components(separatedBy: .newlines).count) lines")
                        .font(ForagerTheme.footnoteFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)
            .padding(.top, ForagerTheme.Spacing.md)
            .padding(.bottom, ForagerTheme.Spacing.sm)

            // Text editor
            TextEditor(text: $recipeText)
                .focused($textEditorFocused)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(ForagerTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg)
                        .fill(ForagerTheme.surfaceSecondary)
                )
                .overlay(
                    Group {
                        if recipeText.isEmpty {
                            VStack(spacing: ForagerTheme.Spacing.md) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 32))
                                    .foregroundStyle(ForagerTheme.textTertiary)

                                Text("Paste your recipe here")
                                    .font(ForagerTheme.bodyFont)
                                    .foregroundStyle(ForagerTheme.textTertiary)

                                Text("Include the title, ingredients, and instructions")
                                    .font(ForagerTheme.captionFont)
                                    .foregroundStyle(ForagerTheme.textTertiary)
                            }
                            .allowsHitTesting(false)
                        }
                    }
                )
                .padding(.horizontal, ForagerTheme.Spacing.lg)

            // Action buttons
            HStack(spacing: ForagerTheme.Spacing.md) {
                Button {
                    if let clipboard = UIPasteboard.general.string {
                        recipeText = clipboard
                    }
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        .font(ForagerTheme.secondaryFont)
                }
                .buttonStyle(.bordered)
                .disabled(UIPasteboard.general.string == nil)

                Spacer()

                Button {
                    classifyText()
                } label: {
                    Text("Extract Recipe")
                        .font(ForagerTheme.bodyFont.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
                .disabled(recipeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)
            .padding(.vertical, ForagerTheme.Spacing.md)
        }
        .onAppear { textEditorFocused = true }
    }

    // MARK: - Classification

    /// Run OCRLineClassifier on the pasted text and transition to review phase
    private func classifyText() {
        textEditorFocused = false

        let rawLines = recipeText.components(separatedBy: .newlines)
        let ocrLines = rawLines.map { OCRLine.fromText($0) }
        let classified = OCRLineClassifier.classifyLines(ocrLines)

        let editableLines = classified.map { line in
            EditableClassifiedLine(
                text: line.text,
                type: line.type,
                confidence: line.confidence
            )
        }

        guard !editableLines.isEmpty else {
            importService.state = .failed(.noRecipeFound)
            return
        }

        phase = .reviewing(editableLines)
    }

    // MARK: - Draft Assembly

    /// Assemble an ImportDraftRecipe from user-corrected classified lines
    private func assembleDraftAndContinue(from lines: [EditableClassifiedLine]) {
        let startTime = CFAbsoluteTimeGetCurrent()

        var title = ""
        var ingredients: [String] = []
        var instructions: [String] = []
        var servings: Int?
        var prepMinutes: Int?
        var cookMinutes: Int?

        for line in lines {
            switch line.type {
            case .title:
                if title.isEmpty { title = line.text }
            case .ingredient:
                ingredients.append(line.text)
            case .instruction:
                instructions.append(line.text)
            case .metadata:
                extractMetadata(from: line.text, prepMinutes: &prepMinutes, cookMinutes: &cookMinutes, servings: &servings)
            case .sectionHeader, .unknown:
                break
            }
        }

        // Fallback title: first line
        if title.isEmpty, let first = lines.first {
            title = first.text
        }

        // Assemble instructions
        let instructionText: String
        if instructions.count > 1 {
            let alreadyNumbered = instructions.allSatisfy { $0.first?.isNumber == true || $0.lowercased().hasPrefix("step") }
            instructionText = alreadyNumbered
                ? instructions.joined(separator: "\n")
                : instructions.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        } else {
            instructionText = instructions.first ?? ""
        }

        let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        let draft = ImportDraftRecipe(
            title: ImportField(value: title, confidence: title.isEmpty ? .missing : .medium, source: .heuristic),
            ingredients: ImportField(value: ingredients, confidence: ingredients.isEmpty ? .missing : .medium, source: .heuristic),
            instructions: ImportField(value: instructionText, confidence: instructionText.isEmpty ? .missing : .medium, source: .heuristic),
            prepTimeMinutes: ImportField(value: prepMinutes, confidence: prepMinutes != nil ? .medium : .missing, source: .heuristic),
            cookTimeMinutes: ImportField(value: cookMinutes, confidence: cookMinutes != nil ? .medium : .missing, source: .heuristic),
            servings: ImportField(value: servings ?? 4, confidence: servings != nil ? .medium : .low, source: .heuristic),
            imageURL: ImportField(value: nil, confidence: .missing, source: .heuristic),
            author: ImportField(value: nil, confidence: .missing, source: .heuristic),
            sourceURL: nil,
            description: nil,
            cuisine: nil,
            category: nil,
            tags: nil,
            extractionMethod: "heuristic_text_reviewed",
            extractionTimeMs: elapsed
        )

        importService.state = .needsReview(draft)
    }

    // MARK: - Metadata Extraction

    private func extractMetadata(from text: String, prepMinutes: inout Int?, cookMinutes: inout Int?, servings: inout Int?) {
        let lower = text.lowercased()

        if let match = lower.range(of: #"(?:serves?|servings?|makes?|yields?)\s*:?\s*(\d+)"#, options: .regularExpression) {
            let digits = lower[match].filter(\.isNumber)
            if let num = Int(digits), num > 0, num <= 100 { servings = num }
        }

        if let match = lower.range(of: #"prep\s*(?:time)?\s*:?\s*(\d+)\s*(?:min|m\b|hour|hr|h\b)"#, options: .regularExpression) {
            let digits = lower[match].filter(\.isNumber)
            if let value = Int(digits), value > 0 {
                prepMinutes = lower[match].contains("hour") || lower[match].contains("hr") ? value * 60 : value
            }
        }

        if let match = lower.range(of: #"(?:cook|bake)\s*(?:time)?\s*:?\s*(\d+)\s*(?:min|m\b|hour|hr|h\b)"#, options: .regularExpression) {
            let digits = lower[match].filter(\.isNumber)
            if let value = Int(digits), value > 0 {
                cookMinutes = lower[match].contains("hour") || lower[match].contains("hr") ? value * 60 : value
            }
        }
    }
}
