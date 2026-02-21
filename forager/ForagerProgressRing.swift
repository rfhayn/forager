// ForagerProgressRing.swift
// M15.3: Circular progress indicator with color shift
//
// PRD §5.6: 56pt ring, accentPrimary → accentSecondary → statusSuccessFG.

import SwiftUI

struct ForagerProgressRing: View {
    let progress: Double // 0.0–1.0
    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(ForagerTheme.backgroundTertiary, lineWidth: 4)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityLabel("List progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }

    private var progressColor: Color {
        if progress >= 1.0 { return ForagerTheme.statusSuccessFG }
        if progress >= 0.5 { return ForagerTheme.accentSecondary }
        return ForagerTheme.accentPrimary
    }
}
