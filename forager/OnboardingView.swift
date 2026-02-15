//
//  OnboardingView.swift
//  forager
//
//  M7.6.3: Coach mark onboarding overlay system
//  Spotlight overlays on the real app with sample data visible underneath.
//  Replaces the original 8-page ScrollView (Iteration 1) with 7 coach mark steps.
//

import SwiftUI

// MARK: - Coach Mark Anchor PreferenceKey

// Collects named CGRect frames from target views so the overlay
// can position spotlight cutouts over the actual UI elements.
struct CoachMarkAnchorKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - View Extension for Tagging Anchors

extension View {
    // Tags a view as a coach mark target by reporting its global frame
    func coachMarkAnchor(_ name: String) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: CoachMarkAnchorKey.self,
                        value: [name: geo.frame(in: .global)]
                    )
            }
        )
    }
}

// MARK: - Notification for Onboarding Replay

extension Notification.Name {
    static let replayOnboarding = Notification.Name("replayOnboarding")
}

// MARK: - Coach Mark Step Definition

private struct CoachMarkStep {
    let targetAnchor: String?      // nil = full dim (no spotlight)
    let switchToTab: NavigationTab? // nil = don't switch
    let title: String
    let description: String
    let isFinalStep: Bool

    init(
        target: String? = nil,
        tab: NavigationTab? = nil,
        title: String,
        description: String,
        isFinal: Bool = false
    ) {
        self.targetAnchor = target
        self.switchToTab = tab
        self.title = title
        self.description = description
        self.isFinalStep = isFinal
    }
}

// MARK: - Coach Mark Overlay

struct CoachMarkOverlay: View {
    @Binding var isActive: Bool
    @Binding var selectedTab: NavigationTab
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.managedObjectContext) private var viewContext

    @State private var currentStep = 0
    @State private var anchors: [String: CGRect] = [:]
    @State private var cardVisible = false
    @State private var screenHeight: CGFloat = 0

    private var steps: [CoachMarkStep] {
        let hasSampleData = SampleDataSeeder.hasSampleData
        return [
            CoachMarkStep(
                title: "Welcome to forager",
                description: hasSampleData
                    ? "We've loaded sample data so you can explore each feature.\nTap anywhere to continue."
                    : "Let's take a quick tour of each feature.\nTap anywhere to continue."
            ),
            CoachMarkStep(
                target: "tabBar",
                tab: .lists,
                title: "Grocery Lists",
                description: "Your shopping lists, organized by store section. Check off items as you shop."
            ),
            CoachMarkStep(
                target: "tabBar",
                tab: .ingredients,
                title: "Ingredients & Staples",
                description: "Your ingredient library. Mark frequent items as staples — always one tap away."
            ),
            CoachMarkStep(
                target: "tabBar",
                tab: .recipes,
                title: "Recipes",
                description: "Add recipes — forager parses ingredients automatically. Add to your grocery list with one tap."
            ),
            CoachMarkStep(
                target: "tabBar",
                tab: .mealPlans,
                title: "Meal Plans",
                description: "Plan your week with recipes, then generate your grocery list from the plan."
            ),
            CoachMarkStep(
                target: "hamburger",
                tab: .lists,
                title: "Menu & Settings",
                description: "Tap the menu for Categories and Settings. Set up a household here to share with family."
            ),
            CoachMarkStep(
                title: "You're Ready",
                description: hasSampleData
                    ? "Explore the sample data, or clear it and start fresh."
                    : "You're all set — happy cooking!",
                isFinal: true
            ),
        ]
    }

    private var step: CoachMarkStep {
        steps[currentStep]
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop with optional spotlight cutout
            spotlightLayer

            // Tap target for dimmed area outside the card (non-final steps)
            if !step.isFinalStep {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { advanceStep() }
            }

            // Floating explanation card
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
            applyTabSwitch()
            withAnimation(.easeOut(duration: 0.3)) {
                cardVisible = true
            }
        }
    }

    // MARK: - Spotlight Layer

    // Semi-transparent backdrop with a cutout revealing the target view
    @ViewBuilder
    private var spotlightLayer: some View {
        if let targetName = step.targetAnchor, let frame = anchors[targetName] {
            Canvas { context, size in
                // Fill entire screen with dim overlay
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black.opacity(0.7))
                )
                // Punch out the spotlight
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
            // Full dim — no spotlight
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    // MARK: - Card Layer

    @ViewBuilder
    private var cardLayer: some View {
        VStack {
            if step.targetAnchor != nil, let frame = anchors[step.targetAnchor!] {
                // Position card above or below the spotlight target
                if frame.midY > screenHeight / 2 {
                    // Target is in bottom half — card goes above
                    Spacer()
                    cardContent
                        .padding(.horizontal, 24)
                        .padding(.bottom, screenHeight - frame.minY + 24)
                } else {
                    // Target is in top half — card goes below
                    Spacer()
                        .frame(height: frame.maxY + 24)
                    cardContent
                        .padding(.horizontal, 24)
                    Spacer()
                }
            } else {
                // Centered card (welcome / final step)
                Spacer()
                cardContent
                    .padding(.horizontal, 32)
                Spacer()
            }
        }
        .opacity(cardVisible ? 1 : 0)
        .scaleEffect(cardVisible ? 1 : 0.9)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: 16) {
            // Arrow pointing toward target (for spotlight steps)
            if let targetName = step.targetAnchor, let frame = anchors[targetName] {
                if frame.midY > screenHeight / 2 {
                    // Arrow points down toward target
                    EmptyView() // arrow at bottom
                }
            }

            // Step counter with back button
            HStack {
                if currentStep > 0 && !step.isFinalStep {
                    Button {
                        goBack()
                    } label: {
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

                // Balance the back button width
                if currentStep > 0 && !step.isFinalStep {
                    Color.clear
                        .frame(width: 12, height: 12)
                }
            }

            Text(step.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(step.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if step.isFinalStep {
                finalButtons
            } else if currentStep == 0 {
                // Tap hint for welcome screen
                Text("Tap anywhere to continue")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
            }

            // Arrow pointing to target below the card
            if let targetName = step.targetAnchor, let frame = anchors[targetName],
               frame.midY > screenHeight / 2 {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
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
        // Card tap advances on non-final steps (Button takes priority for back)
        .onTapGesture {
            if !step.isFinalStep {
                advanceStep()
            }
        }
    }

    // MARK: - Final Step Buttons

    private var finalButtons: some View {
        VStack(spacing: 12) {
            Button {
                completeOnboarding()
            } label: {
                Text("Keep Exploring")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Only show "Clear Sample Data" when sample data actually exists
            if SampleDataSeeder.hasSampleData {
                Button {
                    SampleDataSeeder.clearSampleData(in: viewContext)
                    completeOnboarding()
                } label: {
                    Text("Clear Sample Data")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func advanceStep() {
        guard currentStep < steps.count - 1 else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            cardVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentStep += 1
            applyTabSwitch()

            withAnimation(.easeOut(duration: 0.3)) {
                cardVisible = true
            }
        }
    }

    private func goBack() {
        guard currentStep > 0 else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            cardVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentStep -= 1
            applyTabSwitch()

            withAnimation(.easeOut(duration: 0.3)) {
                cardVisible = true
            }
        }
    }

    private func applyTabSwitch() {
        if let tab = step.switchToTab {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation(.easeOut(duration: 0.3)) {
            isActive = false
        }
    }
}
