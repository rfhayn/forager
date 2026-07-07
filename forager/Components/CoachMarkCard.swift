//
//  CoachMarkCard.swift
//  forager
//
//  reskin-provisions-press: shared print-grammar card for the coach mark
//  overlays (ImportGuideOverlay + CoachMarkOverlay), replacing their two
//  duplicated dark-glass cards. Glass is chrome-only under the style
//  contract — overlay cards are content, so this renders as matte paper
//  with an ink band header and price-tag step numerals.
//

import SwiftUI

struct CoachMarkCard<Footer: View>: View {
    let stepIndex: Int          // 0-based
    let stepCount: Int
    let title: String
    let description: String
    var onBack: (() -> Void)?   // shows back chevron in the band when set
    var onSkip: (() -> Void)?   // shows SKIP in the band when set
    @ViewBuilder var footer: Footer

    // Same adaptive ink/paper pair as DashboardView.sectionBand
    private var bandBackground: Color {
        ForagerTheme.adaptiveColor(lightHex: "#201D1A", darkHex: "#E4E1D8")
    }
    private var bandForeground: Color {
        ForagerTheme.adaptiveColor(lightHex: "#E8E6DF", darkHex: "#191714")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Ink band header — centered step counter, back/skip at the edges
            ZStack {
                Text("STEP \(stepIndex + 1) OF \(stepCount)")
                    .font(ForagerTheme.quantityFont)
                    .tracking(0.8)
                    .foregroundStyle(bandForeground)

                HStack {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(bandForeground)
                        }
                    }
                    Spacer()
                    if let onSkip {
                        Button(action: onSkip) {
                            Text("SKIP")
                                .font(ForagerTheme.footnoteFont)
                                .tracking(0.8)
                                .foregroundStyle(bandForeground)
                        }
                    }
                }
            }
            .padding(.horizontal, ForagerTheme.Spacing.md)
            .padding(.vertical, 8)
            .background(bandBackground)

            // Paper body
            VStack(spacing: ForagerTheme.Spacing.lg) {
                Text(title)
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                footer
            }
            .padding(ForagerTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous)
                .strokeBorder(ForagerTheme.borderDefault, lineWidth: 1)
        )
    }
}
