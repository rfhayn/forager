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

    // M10.6.10: Three-state status icon using IngredientMatchResult.status
    private var statusIcon: some View {
        HStack(spacing: ForagerTheme.Spacing.xs) {
            Group {
                if isAIParsing {
                    ProgressView()
                        .controlSize(.mini)
                } else if let status = matchResult?.status {
                    switch status {
                    case .ready:
                        // M10.6.12: No icon for ready items — only show indicators that need attention
                        Color.clear
                            .frame(width: 14, height: 14)
                    case .needsCategory:
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(ForagerTheme.statusWarningFG)
                    case .needsTemplate:
                        Image(systemName: "plus.circle")
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                } else {
                    Color.clear
                        .frame(width: 14, height: 14)
                }
            }
            .font(.system(size: 14))

            // "NEW" badge for unmatched ingredients
            if !isAIParsing, matchResult?.status == .needsTemplate {
                Text("NEW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(ForagerTheme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
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

    private var isUncategorized: Bool {
        guard let name = categoryName else { return true }
        return name.isEmpty || name.lowercased() == "uncategorized"
    }

    private var categoryLabel: some View {
        Button { onCategoryTap() } label: {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                if let name = categoryName, !name.isEmpty {
                    Circle()
                        .fill(ForagerTheme.categoryColor(for: name))
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(isUncategorized ? ForagerTheme.statusDangerFG : ForagerTheme.textSecondary)
                } else {
                    Text("Choose Category")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.statusDangerFG)
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

/// M10.6.10: Three-state summary bar: "N ready · N need category · N new"
struct IngredientMatchSummaryView: View {
    let ready: Int
    let needsCategory: Int
    let needsTemplate: Int

    // Legacy initializer for callers using the old 2-param API
    init(categorized: Int, uncategorized: Int) {
        self.ready = categorized
        self.needsCategory = uncategorized
        self.needsTemplate = 0
    }

    init(ready: Int, needsCategory: Int, needsTemplate: Int) {
        self.ready = ready
        self.needsCategory = needsCategory
        self.needsTemplate = needsTemplate
    }

    // M10.6.12: Only show items needing attention — hide entirely when all ready
    private var hasItemsNeedingAttention: Bool {
        needsCategory > 0 || needsTemplate > 0
    }

    var body: some View {
        if hasItemsNeedingAttention {
            HStack(spacing: ForagerTheme.Spacing.md) {
                if needsCategory > 0 {
                    Label("\(needsCategory) need category", systemImage: "circle.dashed")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                }
                if needsTemplate > 0 {
                    Label("\(needsTemplate) new", systemImage: "plus.circle")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            }
            .padding(.bottom, ForagerTheme.Spacing.xs)
        }
    }
}
