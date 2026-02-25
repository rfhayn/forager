// FilterPill.swift
// M15.3: Shared filter pill component
//
// PRD §5.7: Capsule shape, 3 sizes, ForagerTheme colors.
// Used in IngredientsView (M15.5), RecipeListView (M15.4), and elsewhere.
// Designed as a pure view — wrap in Button or Menu for interactivity.

import SwiftUI

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var systemImage: String? = nil
    var color: Color? = nil
    var size: PillSize = .regular

    enum PillSize {
        case compact, regular, large

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return 8
            case .regular: return 10
            case .large: return 14
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return 5
            case .regular: return 6
            case .large: return 7
            }
        }

        var font: Font {
            switch self {
            case .compact: return ForagerTheme.captionFont
            case .regular: return ForagerTheme.captionFont
            case .large: return ForagerTheme.footnoteFont
            }
        }
    }

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.xs) {
            if let color {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            if let systemImage {
                Image(systemName: systemImage)
                    .font(size == .compact ? .caption2 : .caption)
                    .fontWeight(.medium)
            }
            Text(title)
                .font(size.font)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .foregroundStyle(isSelected ? .white : ForagerTheme.textSecondary)
        .background(
            Capsule()
                .fill(isSelected ? (color ?? ForagerTheme.accentPrimary) : ForagerTheme.backgroundSecondary)
        )
        .overlay(
            Capsule()
                .stroke(ForagerTheme.borderSubtle, lineWidth: isSelected ? 0 : 0.5)
        )
    }
}
