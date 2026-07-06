// ForagerProgressRing.swift
// M15.3: Circular progress indicator with color shift
// reskin-provisions-press: restyled from a ring to the print grammar —
// mono percentage over a flat linear bar (same language as the list
// detail's bottom progress bar). Name kept so call sites don't churn.

import SwiftUI

struct ForagerProgressRing: View {
    let progress: Double // 0.0–1.0
    @ScaledMetric(relativeTo: .subheadline) private var barWidth: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Percentage — mono price-tag numeral
            Text("\(Int(progress * 100))%")
                .font(ForagerTheme.quantityFontLarge)
                .foregroundStyle(progress >= 1.0 ? ForagerTheme.statusSuccessFG : ForagerTheme.textPrimary)

            // Flat progress bar — tomato fill on print track
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                    .fill(ForagerTheme.borderDefault)
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                    .fill(progressColor)
                    .frame(width: max(4, barWidth * progress))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: progress)
            }
            .frame(width: barWidth, height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("List progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }

    private var progressColor: Color {
        progress >= 1.0 ? ForagerTheme.statusSuccessFG : ForagerTheme.accentPrimary
    }
}
