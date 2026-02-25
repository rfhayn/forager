// ForagerButtonStyles.swift
// M15.3: Reusable button styles
//
// PRD §5.4: Primary/Secondary/Tertiary with pressed scale (0.97) and disabled states.

import SwiftUI

// MARK: - Primary Button Style

struct ForagerPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ForagerTheme.bodyFont.bold())
            .foregroundStyle(isEnabled ? ForagerTheme.buttonPrimaryText : ForagerTheme.buttonPrimaryDisabledText)
            .padding(.horizontal, ForagerTheme.Spacing.xl)
            .padding(.vertical, ForagerTheme.Spacing.md)
            .background(isEnabled ? ForagerTheme.buttonPrimaryDefault : ForagerTheme.buttonPrimaryDisabled)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct ForagerSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ForagerTheme.bodyFont.bold())
            .foregroundStyle(isEnabled ? ForagerTheme.accentPrimary : ForagerTheme.textDisabled)
            .padding(.horizontal, ForagerTheme.Spacing.xl)
            .padding(.vertical, ForagerTheme.Spacing.md)
            .background(isEnabled ? ForagerTheme.accentTint : ForagerTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .stroke(isEnabled ? ForagerTheme.borderAccent : ForagerTheme.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button Style

struct ForagerTertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ForagerTheme.bodyFont.bold())
            .foregroundStyle(isEnabled ? ForagerTheme.accentPrimary : ForagerTheme.textDisabled)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
