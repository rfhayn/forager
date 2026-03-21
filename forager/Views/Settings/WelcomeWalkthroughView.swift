//
//  WelcomeWalkthroughView.swift
//  forager
//
//  M9.27: 3-screen welcome carousel for first launch.
//  Replaces the coach mark overlay as the first-launch experience.
//  Coach marks remain available for "Replay Onboarding" from Settings.
//

import SwiftUI

struct WelcomeWalkthroughView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            ForagerTheme.backgroundCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        completeAndDismiss()
                    } label: {
                        Text("Skip")
                            .font(ForagerTheme.bodyFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                    .padding(.trailing, ForagerTheme.Spacing.lg)
                    .padding(.top, ForagerTheme.Spacing.md)
                }

                // Page content
                TabView(selection: $currentPage) {
                    welcomeScreen.tag(0)
                    howItWorksScreen.tag(1)
                    powerUpScreen.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? ForagerTheme.accentPrimary : ForagerTheme.textDisabled)
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, ForagerTheme.Spacing.lg)

                // CTA button
                Button {
                    if currentPage < 2 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        completeAndDismiss()
                    }
                } label: {
                    Text(ctaText)
                        .font(ForagerTheme.bodyFont.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ForagerTheme.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
                }
                .padding(.horizontal, ForagerTheme.Spacing.xl)
                .padding(.bottom, ForagerTheme.Spacing.xl)
            }
        }
    }

    private var ctaText: String {
        switch currentPage {
        case 0: return "Get Started"
        case 1: return "Continue"
        default: return "Let's Go"
        }
    }

    private func completeAndDismiss() {
        hasCompletedOnboarding = true
        dismiss()
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon — uses the existing LaunchIcon asset (light/dark adaptive)
            Image("LaunchIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: ForagerTheme.accentPrimary.opacity(0.3), radius: 16, y: 8)

            Text("Welcome to")
                .font(.system(size: 28, weight: .regular, design: .rounded))
                .foregroundStyle(ForagerTheme.textSecondary)
                .padding(.top, 32)

            Text("forager")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(ForagerTheme.textPrimary)
                .padding(.top, 4)

            Text("Plan meals, build grocery lists,\nand cook together.")
                .font(.system(size: 19, weight: .regular, design: .rounded))
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, ForagerTheme.Spacing.xl)
    }

    // MARK: - Screen 2: How It Works

    private var howItWorksScreen: some View {
        VStack(spacing: 0) {
            Text("How Forager Works")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(ForagerTheme.textPrimary)
                .padding(.top, 40)

            Text("Import, plan, and shop \u{2014} all connected")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(ForagerTheme.textTertiary)
                .padding(.top, 8)

            VStack(spacing: 0) {
                flowCard(
                    icon: "book.fill",
                    iconColor: ForagerTheme.accentPrimary,
                    title: "Import Recipes",
                    description: "Paste a URL and AI parses every ingredient automatically. Or create from scratch."
                )

                flowArrow

                flowCard(
                    icon: "calendar",
                    iconColor: ForagerTheme.accentSecondary,
                    title: "Plan Your Week",
                    description: "Add recipes to your meal plan. Quick options for takeout or leftovers."
                )

                flowArrow

                flowCard(
                    icon: "cart.fill",
                    iconColor: ForagerTheme.accentTertiary,
                    title: "Shop Smart",
                    description: "Grocery list auto-generated from your plan, organized by store aisle."
                )
            }
            .padding(.top, 24)

            Spacer()
        }
        .padding(.horizontal, ForagerTheme.Spacing.lg)
    }

    private func flowCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 52, height: 52)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ForagerTheme.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.down")
            .font(.caption.bold())
            .foregroundStyle(ForagerTheme.accentPrimary.opacity(0.4))
            .padding(.vertical, 6)
    }

    // MARK: - Screen 3: Power Up

    private var powerUpScreen: some View {
        VStack(spacing: 0) {
            Text("Power Up")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(ForagerTheme.textPrimary)
                .padding(.top, 40)

            Text("Set up anytime in Settings")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(ForagerTheme.textTertiary)
                .padding(.top, 8)

            VStack(spacing: ForagerTheme.Spacing.md) {
                // AI Parsing card
                featureCard(
                    icon: "sparkles",
                    iconColor: ForagerTheme.accentPrimary,
                    title: "AI Ingredient Parsing",
                    badge: "Optional",
                    description: "Add an API key to unlock smarter ingredient recognition when importing recipes. Parses quantities, units, and categories automatically.",
                    settingsHint: "Settings \u{2192} AI Integration"
                )

                // Household Sharing card
                featureCard(
                    icon: "person.3.fill",
                    iconColor: ForagerTheme.accentSecondary,
                    title: "Household Sharing",
                    badge: nil,
                    description: "Share grocery lists, recipes, and meal plans with your household. Everyone stays in sync via iCloud.",
                    settingsHint: "Settings \u{2192} Household"
                )
            }
            .padding(.top, 24)

            Spacer()
        }
        .padding(.horizontal, ForagerTheme.Spacing.lg)
    }

    private func featureCard(
        icon: String,
        iconColor: Color,
        title: String,
        badge: String?,
        description: String,
        settingsHint: String
    ) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ForagerTheme.textPrimary)

                if let badge {
                    Text(badge.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(ForagerTheme.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Text(description)
                .font(.system(size: 15))
                .foregroundStyle(ForagerTheme.textSecondary)
                .lineSpacing(3)

            HStack(spacing: 4) {
                Image(systemName: "gearshape")
                    .font(.caption)
                Text(settingsHint)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(ForagerTheme.accentPrimary)
            .padding(.top, 4)
        }
        .padding(ForagerTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
    }
}
