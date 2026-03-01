//
//  ClaudeAIButton.swift
//  forager
//
//  M10.6.7: Reusable Claude AI button with logo for parse actions.
//  Used across import, recipe, and grocery views.
//

import SwiftUI

// MARK: - Claude Logo Image

/// Renders the Claude asterisk logo at a given size, preserving original color
struct ClaudeLogo: View {
    var size: CGFloat = 18

    var body: some View {
        Image("ClaudeLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

// MARK: - Labeled Button Styles

/// Claude logo + "Parse with AI" label for use in menus and form buttons
struct ClaudeParseLabel: View {
    var text: String = "Parse with AI"

    var body: some View {
        HStack(spacing: 4) {
            ClaudeLogo(size: 16)
            Text(text)
        }
    }
}
