// ForagerSectionHeader.swift
// M15.3: Section header with count badge and collapse chevron
// reskin-provisions-press: restyled as the ink "store band" from the
// Provisions Press mockup — full-width ink bar, left-aligned condensed
// uppercase title, mono count in mustard. Inverts to paper-on-ink in dark.

import SwiftUI

/// Title-only ink band — the print grammar's section divider for screens
/// that don't need a count (Settings, Dashboard). Same band colors as
/// ForagerSectionHeader.
struct ForagerBand: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(ForagerTheme.footnoteFont)
                .tracking(0.8)
                .foregroundStyle(ForagerTheme.adaptiveColor(lightHex: "#E8E6DF", darkHex: "#191714"))
            Spacer()
        }
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .padding(.vertical, 6)
        .background(ForagerTheme.adaptiveColor(lightHex: "#201D1A", darkHex: "#E4E1D8"))
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
    }
}

struct ForagerSectionHeader: View {
    let title: String
    let count: Int
    var totalCount: Int?
    var isExpanded: Binding<Bool>?
    var colorDotHex: String? = nil

    // Band colors deliberately invert against the canvas: ink bar on paper
    // in light mode, paper bar on ink in dark mode (mockup dark store band).
    private var bandBackground: Color {
        ForagerTheme.adaptiveColor(lightHex: "#201D1A", darkHex: "#E4E1D8")
    }
    private var bandForeground: Color {
        ForagerTheme.adaptiveColor(lightHex: "#E8E6DF", darkHex: "#191714")
    }
    /// Mustard tuned per band background (dark band gets bright mustard,
    /// paper band gets mustard ink) — both ≥ 3:1 on their band.
    private var bandCount: Color {
        ForagerTheme.adaptiveColor(lightHex: "#D89A2B", darkHex: "#8B6318")
    }

    var body: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            if let isExpanded {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.wrappedValue.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(isExpanded.wrappedValue ? .degrees(90) : .zero)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(bandForeground)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded.wrappedValue)
                }
                .buttonStyle(.borderless)
            }

            if let hex = colorDotHex {
                StoreColorDot(hex: hex, size: 10)
            }

            Text(title.uppercased())
                .font(ForagerTheme.footnoteFont)
                .tracking(0.8)
                .foregroundStyle(bandForeground)
                .lineLimit(1)

            Spacer(minLength: ForagerTheme.Spacing.sm)

            // Count — mono numerals, mustard (the price-tag corner of the band)
            if let total = totalCount {
                Text("\(count)/\(total)")
                    .font(ForagerTheme.quantityFont)
                    .foregroundStyle(bandCount)
            } else {
                Text("\(count)")
                    .font(ForagerTheme.quantityFont)
                    .foregroundStyle(bandCount)
            }
        }
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .padding(.vertical, 6)
        .background(bandBackground)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
    }
}
