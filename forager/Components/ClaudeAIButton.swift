//
//  AIParseButton.swift
//  forager
//
//  M10.6.7: Reusable AI button with sparkle icon for parse actions.
//  M9.29: Replaced Claude logo with generic AI sparkle icon.
//  Used across import, recipe, and grocery views.
//

import SwiftUI

// MARK: - AI Parse Label

/// Sparkle icon + text label for AI parse actions
struct AIParseLabel: View {
    var text: String = "Parse with AI"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundStyle(ForagerTheme.accentPrimary)
            Text(text)
        }
    }
}

// MARK: - AI Sparkle Icon

/// Generic AI icon using SF Symbols sparkle
struct AISparkleIcon: View {
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: size))
            .foregroundStyle(ForagerTheme.accentPrimary)
    }
}
