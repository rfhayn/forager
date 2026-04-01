// ForagerSectionHeader.swift
// M15.3: Centered section header with count badge and collapse chevron
//
// PRD §5.2: 13pt semibold uppercase rounded, centered, count badge, collapse chevron.

import SwiftUI

struct ForagerSectionHeader: View {
    let title: String
    let count: Int
    var totalCount: Int?
    var isExpanded: Binding<Bool>?
    var colorDotHex: String? = nil

    var body: some View {
        HStack {
            if let isExpanded {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.wrappedValue.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(isExpanded.wrappedValue ? .degrees(90) : .zero)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded.wrappedValue)
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            HStack(spacing: ForagerTheme.Spacing.xs) {
                if let hex = colorDotHex {
                    StoreColorDot(hex: hex, size: 10)
                }
                Text(title.uppercased())
                    .font(ForagerTheme.footnoteFont)
                    .tracking(0.5)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }

            Spacer()

            // Count badge
            if let total = totalCount {
                Text("\(count)/\(total)")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .padding(.horizontal, ForagerTheme.Spacing.sm)
                    .padding(.vertical, 2)
                    .background(ForagerTheme.backgroundSecondary)
                    .clipShape(Capsule())
            } else {
                Text("\(count)")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
    }
}
