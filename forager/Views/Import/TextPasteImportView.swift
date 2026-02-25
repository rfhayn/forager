//
//  TextPasteImportView.swift
//  forager
//
//  Created for M10.2.2: Text input UI for recipe text paste import
//  Large TextEditor with paste-from-clipboard, "Extract Recipe" button.
//  Feeds into existing RecipeImportPreviewView on successful extraction.
//

import SwiftUI

// MARK: - Text Paste Import View

/// Text input view for pasting recipe text (from websites, messages, emails).
/// Presented as the initial view when user chooses "Paste Recipe Text" import mode.
struct TextPasteImportView: View {
    @ObservedObject var importService: RecipeImportService
    @FocusState private var textEditorFocused: Bool
    @State private var recipeText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header hint
            HStack {
                Text("Paste or type a recipe below")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                Spacer()
                if !recipeText.isEmpty {
                    Text("\(recipeText.components(separatedBy: .newlines).count) lines")
                        .font(ForagerTheme.captionFont)
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ForagerTheme.surfaceSecondary)
                )
                .overlay(
                    // Placeholder when empty
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
                // Paste from clipboard
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

                // Extract recipe
                Button {
                    textEditorFocused = false
                    Task {
                        await importService.importFromText(recipeText)
                    }
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
}
