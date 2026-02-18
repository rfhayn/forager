// ForagerCard.swift
// M15.3: Reusable card view modifier
//
// PRD §5.1: surfacePrimary bg, radius.md, bark-tinted shadow (light),
// tonal elevation + rim light (dark), 16pt internal padding.

import SwiftUI

struct ForagerCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
            .shadow(
                color: colorScheme == .dark
                    ? .clear
                    : Color(red: 44/255, green: 36/255, blue: 24/255).opacity(0.12),
                radius: 8, x: 0, y: 2
            )
            .overlay(
                // Dark mode: 1px rim light at 6% white
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.06 : 0), lineWidth: 1)
            )
    }
}

extension View {
    func foragerCard() -> some View {
        modifier(ForagerCardModifier())
    }
}
