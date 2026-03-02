//
//  IngredientMatchRow.swift
//  forager
//
//  Created for M10.6.8: Shared ingredient display component
//  Replaces duplicated ingredientRow() + formattedIngredientText() across
//  Import, Create, Edit, and RecipeDetail views.
//

import SwiftUI

/// Reusable ingredient row with status icon, formatted text, and category label.
/// Supports compact mode (recipe views) and detailed mode (import preview with raw text).
struct IngredientMatchRow: View {
    let matchResult: IngredientMatchResult?
    let rawText: String
    let isEditing: Bool
    let isAIParsing: Bool
    let showRawText: Bool
    let categoryName: String?
    let onTapEdit: () -> Void
    let onCategoryTap: () -> Void
    @Binding var editText: String
    var onSubmitEdit: (() -> Void)?

    // M10.6.8: Internal focus management — auto-focuses on appear, commits on blur
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
            // Detailed mode: show raw text above parsed breakdown
            if showRawText, let result = matchResult {
                rawTextLine(result: result)
            }

            // Main line: status icon + ingredient text
            HStack(spacing: ForagerTheme.Spacing.sm) {
                statusIcon

                if isEditing {
                    editField
                } else {
                    displayText
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { onTapEdit() }
                }
            }

            // Category label
            categoryLabel
                .padding(.leading, 22)
        }
    }

    // MARK: - Status Icon

    private var statusIcon: some View {
        Group {
            if isAIParsing {
                ProgressView()
                    .controlSize(.mini)
            } else if categoryName != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(ForagerTheme.statusSuccessFG)
            } else if matchResult != nil {
                Image(systemName: "circle")
                    .foregroundStyle(ForagerTheme.textTertiary)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .font(.system(size: 14))
    }

    // MARK: - Edit Field

    private var editField: some View {
        TextField("Ingredient", text: $editText)
            .font(ForagerTheme.bodyFont)
            .foregroundStyle(ForagerTheme.textPrimary)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit { onSubmitEdit?() }
            .focused($isFocused)
            .onAppear { isFocused = true }
            .onChange(of: isFocused) { _, focused in
                if !focused && isEditing {
                    onSubmitEdit?()
                }
            }
    }

    // MARK: - Display Text

    /// Format ingredient text with parsed name in bold accent.
    /// Quantity/unit prefix in secondary, name bold accent, suffix in secondary.
    @ViewBuilder
    private var displayText: some View {
        if let info = matchResult {
            let text = rawText

            if let range = text.range(of: info.parsedName, options: .caseInsensitive) {
                // Parsed name found in raw text — highlight it
                let prefix = String(text[text.startIndex..<range.lowerBound])
                let name = String(text[range])
                let suffix = String(text[range.upperBound...])
                HStack(spacing: 0) {
                    Text(prefix)
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Text(name)
                        .font(ForagerTheme.bodyFont)
                        .bold()
                        .foregroundStyle(ForagerTheme.accentPrimary)
                    Text(suffix)
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            } else if showRawText {
                // Detailed mode: raw text shown separately, just show parsed name
                Text(info.parsedName)
                    .font(ForagerTheme.bodyFont)
                    .bold()
                    .foregroundStyle(ForagerTheme.accentPrimary)
            } else {
                // Compact fallback: show full text with parsed name appended
                HStack(spacing: 0) {
                    Text(text)
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                    Text(" → ")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textDisabled)
                    Text(info.parsedName)
                        .font(ForagerTheme.captionFont)
                        .bold()
                        .foregroundStyle(ForagerTheme.accentPrimary)
                }
            }
        } else {
            Text(rawText)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textPrimary)
        }
    }

    // MARK: - Raw Text Line (Import Detailed Mode)

    @ViewBuilder
    private func rawTextLine(result: IngredientMatchResult) -> some View {
        HStack(spacing: ForagerTheme.Spacing.xs) {
            Text(result.rawText)
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textTertiary)
                .lineLimit(1)

            if result.wasAIParsed {
                ClaudeLogo(size: 12)
            }
        }
    }

    // MARK: - Category Label

    private var categoryLabel: some View {
        Button { onCategoryTap() } label: {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                if let name = categoryName, !name.isEmpty {
                    Circle()
                        .fill(ForagerTheme.categoryColor(for: name))
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                } else {
                    Text("Choose Category")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Match Summary View

/// Shared summary bar: "N categorized · N need category"
struct IngredientMatchSummaryView: View {
    let categorized: Int
    let uncategorized: Int

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            if categorized > 0 {
                Label("\(categorized) categorized", systemImage: "checkmark.circle.fill")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.statusSuccessFG)
            }
            if uncategorized > 0 {
                Label("\(uncategorized) need category", systemImage: "circle")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .padding(.bottom, ForagerTheme.Spacing.xs)
    }
}
