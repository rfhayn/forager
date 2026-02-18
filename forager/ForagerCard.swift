// ForagerCard.swift
// M15.3: Reusable card view modifier
// M15.6: Added glass variants using iOS 26 Liquid Glass
//
// Three variants:
// - .foragerCard()              Shadow-based fallback (M15.3 original)
// - .foragerGlassCard()         Regular glass for standard cards
// - .foragerProminentGlassCard() Prominent glass for hero/active elements

import SwiftUI

// MARK: - Shadow-Based Card (M15.3 original)

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

// MARK: - Regular Glass Card (M15.6)

struct ForagerGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
    }
}

// MARK: - Prominent Glass Card (M15.6)
// Uses larger radius for visual emphasis; no .prominent Glass variant exists

struct ForagerProminentGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg, style: .continuous))
    }
}

extension View {
    func foragerCard() -> some View {
        modifier(ForagerCardModifier())
    }

    func foragerGlassCard() -> some View {
        modifier(ForagerGlassCardModifier())
    }

    func foragerProminentGlassCard() -> some View {
        modifier(ForagerProminentGlassCardModifier())
    }
}
