//
//  ImportGuideOverlay.swift
//  forager
//
//  M9.34: Coach mark overlay for first-time recipe import guide.
//  Reuses CoachMarkAnchorKey from OnboardingView.swift.
//

import SwiftUI

struct ImportGuideOverlay: View {
    @Binding var isActive: Bool
    @AppStorage("hasSeenImportGuide") private var hasSeenImportGuide = false

    @State private var currentStep = 0
    @State private var anchors: [String: CGRect] = [:]
    @State private var cardVisible = false
    @State private var screenHeight: CGFloat = 0

    private let steps: [(target: String?, title: String, description: String)] = [
        (
            target: "importTitle",
            title: "Review the Recipe",
            description: "Check the title, servings, and timing. Tap anything to edit."
        ),
        (
            target: "ingredientRow",
            title: "Ingredient Status",
            description: "Each ingredient is parsed and matched to your library.\n\n✅ Green = matched\n🟡 Amber = needs a category\n➕ New = not in your library yet"
        ),
        (
            target: "smartIndicator",
            title: "Smart Indicators",
            description: "Green rows detect multiple ingredients on one line — tap to split.\n\nAmber rows flag alternatives (X or Y) where you should pick one."
        ),
        (
            target: "aiParseButton",
            title: "AI-Powered Parsing",
            description: "Tap 'Parse with AI' to auto-categorize all ingredients. Long-press any ingredient for more options."
        ),
        (
            target: "saveButton",
            title: "Save Your Recipe",
            description: "Save to add this recipe and all ingredients to your library. They'll be available for meal planning and grocery lists."
        )
    ]

    private var step: (target: String?, title: String, description: String) {
        steps[currentStep]
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop with optional spotlight
            spotlightLayer

            // Tap target for advancing (non-final steps)
            if currentStep < steps.count - 1 {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { advanceStep() }
            }

            // Floating card
            cardLayer
        }
        .ignoresSafeArea()
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { screenHeight = geo.size.height }
            }
        )
        .onPreferenceChange(CoachMarkAnchorKey.self) { newAnchors in
            anchors = newAnchors
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                cardVisible = true
            }
        }
    }

    // MARK: - Spotlight

    @ViewBuilder
    private var spotlightLayer: some View {
        if let targetName = step.target, let frame = anchors[targetName] {
            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black.opacity(0.7))
                )
                let insetFrame = frame.insetBy(dx: -12, dy: -8)
                context.blendMode = .destinationOut
                context.fill(
                    Path(roundedRect: insetFrame, cornerRadius: 16),
                    with: .color(.white)
                )
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        } else {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    // MARK: - Card

    @ViewBuilder
    private var cardLayer: some View {
        VStack {
            if let targetName = step.target, let frame = anchors[targetName] {
                if frame.midY > screenHeight / 2 {
                    Spacer()
                    cardContent
                        .padding(.horizontal, 24)
                        .padding(.bottom, screenHeight - frame.minY + 24)
                } else {
                    Spacer()
                        .frame(height: frame.maxY + 24)
                    cardContent
                        .padding(.horizontal, 24)
                    Spacer()
                }
            } else {
                Spacer()
                cardContent
                    .padding(.horizontal, 32)
                Spacer()
            }
        }
        .opacity(cardVisible ? 1 : 0)
        .scaleEffect(cardVisible ? 1 : 0.9)
    }

    private var cardContent: some View {
        VStack(spacing: 16) {
            // Step counter + skip
            HStack {
                if currentStep > 0 {
                    Button { goBack() } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                Spacer()
                Text("\(currentStep + 1) of \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Button { complete() } label: {
                    Text("Skip")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Text(step.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(step.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if currentStep == steps.count - 1 {
                Button { complete() } label: {
                    Text("Got It")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ForagerTheme.accentPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous))
                }
                .padding(.top, 8)
            } else {
                Text("Tap anywhere to continue")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
        )
        .onTapGesture {
            if currentStep < steps.count - 1 {
                advanceStep()
            }
        }
    }

    // MARK: - Actions

    private func advanceStep() {
        withAnimation(.easeInOut(duration: 0.25)) { cardVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentStep += 1
            withAnimation(.easeOut(duration: 0.3)) { cardVisible = true }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.25)) { cardVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentStep -= 1
            withAnimation(.easeOut(duration: 0.3)) { cardVisible = true }
        }
    }

    private func complete() {
        hasSeenImportGuide = true
        withAnimation(.easeOut(duration: 0.3)) { isActive = false }
    }
}
