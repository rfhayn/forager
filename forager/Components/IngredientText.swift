//
//  IngredientText.swift
//  forager
//
//  reskin-provisions-press: single shared render for ingredient lines
//  (grocery rows + recipe detail). One concatenated Text run — mono
//  quantity prefix, medium-ink name, secondary qualifier — so long names
//  truncate with an ellipsis instead of wrapping into a column beside the
//  quantity. Names render lowercase (display-only; stored values are
//  untouched) so casing reads the same on every screen.
//

import SwiftUI

struct IngredientText: View {
    /// Full display text (quantity + name + qualifiers), pre-cleaned by the caller.
    let text: String
    /// Parsed ingredient name; splits the mono quantity prefix from the name.
    let parsedName: String?
    /// Completed items render as a single struck-through disabled line.
    var isCompleted: Bool = false

    var body: some View {
        styledText
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var styledText: Text {
        let display = text.lowercased()

        if isCompleted {
            return Text(display)
                .font(ForagerTheme.bodyFont)
                .strikethrough()
                .foregroundStyle(ForagerTheme.textDisabled)
        }

        guard let name = parsedName?.lowercased(), !name.isEmpty,
              let range = display.range(of: name) else {
            return Text(display)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textPrimary)
        }

        let prefix = Text(String(display[display.startIndex..<range.lowerBound]))
            .font(ForagerTheme.quantityFontLarge)
            .foregroundStyle(ForagerTheme.textPrimary)
        let matched = Text(String(display[range]))
            .font(ForagerTheme.bodyFont)
            .fontWeight(.medium)
            .foregroundStyle(ForagerTheme.textPrimary)
        let suffix = Text(String(display[range.upperBound...]))
            .font(ForagerTheme.bodyFont)
            .foregroundStyle(ForagerTheme.textSecondary)

        return Text("\(prefix)\(matched)\(suffix)")
    }
}
