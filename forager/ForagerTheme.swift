// ForagerTheme.swift
// M15.1: Centralized design token system for the forager app
//
// All semantic colors, typography helpers, spacing, and corner radii
// are defined here. Views reference ForagerTheme tokens instead of
// hardcoded values. Light/dark mode handled via UIColor dynamic provider.

import SwiftUI
import UIKit

// MARK: - ForagerTheme

enum ForagerTheme {

    // MARK: - Adaptive Color Helper

    /// Creates a SwiftUI Color that resolves to different values in light vs dark mode.
    /// Uses UIColor's dynamic provider, which responds to trait collection changes.
    static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    /// Convenience: create adaptive color from hex strings
    static func adaptiveColor(lightHex: String, darkHex: String) -> Color {
        adaptiveColor(light: UIColor(hex: lightHex), dark: UIColor(hex: darkHex))
    }

    // MARK: - Background Colors (§4.1.2)

    /// Full-screen base background
    static var backgroundCanvas: Color {
        adaptiveColor(lightHex: "#FDFBF7", darkHex: "#1C1A14")
    }

    /// Card/section backgrounds
    static var backgroundPrimary: Color {
        adaptiveColor(lightHex: "#F5F0E8", darkHex: "#221E16")
    }

    /// Grouped content
    static var backgroundSecondary: Color {
        adaptiveColor(lightHex: "#EDE6D8", darkHex: "#2A251C")
    }

    /// Nested groups
    static var backgroundTertiary: Color {
        adaptiveColor(lightHex: "#E4DDD0", darkHex: "#332E24")
    }

    // MARK: - Surface Colors (§4.1.3)

    /// Cards, list rows, inputs
    static var surfacePrimary: Color {
        adaptiveColor(lightHex: "#FFFFFF", darkHex: "#2E2A1F")
    }

    /// Sheets, popovers
    static var surfaceSecondary: Color {
        adaptiveColor(lightHex: "#F8F4EE", darkHex: "#363127")
    }

    /// Selected state highlight
    static var surfaceAccent: Color {
        adaptiveColor(lightHex: "#E8F0E0", darkHex: "#2A3520")
    }

    /// Warning banners
    static var surfaceWarning: Color {
        adaptiveColor(lightHex: "#FFF8E6", darkHex: "#332B18")
    }

    /// Error banners
    static var surfaceDanger: Color {
        adaptiveColor(lightHex: "#FFF0EE", darkHex: "#331E1A")
    }

    /// Success banners
    static var surfaceSuccess: Color {
        adaptiveColor(lightHex: "#EEF6EE", darkHex: "#1E3020")
    }

    // MARK: - Text Colors (§4.1.4)

    /// Primary text (14.80:1 light, 14.66:1 dark — AAA)
    static var textPrimary: Color {
        adaptiveColor(lightHex: "#2C2418", darkHex: "#F0EBE3")
    }

    /// Secondary text (7.35:1 light, 9.33:1 dark — AAA)
    static var textSecondary: Color {
        adaptiveColor(lightHex: "#5A5347", darkHex: "#C4BDB2")
    }

    /// Tertiary text, metadata (5.8:1 light, 5.5:1 dark — AA)
    static var textTertiary: Color {
        adaptiveColor(lightHex: "#6A6057", darkHex: "#A09A90")
    }

    /// Disabled text
    static var textDisabled: Color {
        adaptiveColor(lightHex: "#B0A89E", darkHex: "#5A5650")
    }

    /// Link text
    static var textLink: Color {
        adaptiveColor(lightHex: "#2D6A3F", darkHex: "#7BC08A")
    }

    // MARK: - Accent Colors (§4.1.5)

    /// Primary CTAs — Forest Green
    static var accentPrimary: Color {
        adaptiveColor(lightHex: "#2D5016", darkHex: "#7BC08A")
    }

    /// Secondary buttons — Leaf Green
    static var accentSecondary: Color {
        adaptiveColor(lightHex: "#4A7C2E", darkHex: "#5AAD5A")
    }

    /// Icons, decorative — Spring Green
    static var accentTertiary: Color {
        adaptiveColor(lightHex: "#6B9B37", darkHex: "#3D8B37")
    }

    /// Tinted backgrounds
    static var accentTint: Color {
        adaptiveColor(lightHex: "#E8F0E0", darkHex: "#2A3520")
    }

    // MARK: - Status Colors (§4.1.6)

    /// Success foreground
    static var statusSuccessFG: Color {
        adaptiveColor(lightHex: "#2D7A2D", darkHex: "#5AAD5A")
    }

    /// Success background
    static var statusSuccessBG: Color {
        adaptiveColor(lightHex: "#EEF6EE", darkHex: "#1E3020")
    }

    /// Warning foreground (validated: 5.25:1 AA pass)
    static var statusWarningFG: Color {
        adaptiveColor(lightHex: "#8B6607", darkHex: "#D4A62B")
    }

    /// Warning background
    static var statusWarningBG: Color {
        adaptiveColor(lightHex: "#FFF8E6", darkHex: "#332B18")
    }

    /// Danger foreground
    static var statusDangerFG: Color {
        adaptiveColor(lightHex: "#C4402F", darkHex: "#E06050")
    }

    /// Danger background
    static var statusDangerBG: Color {
        adaptiveColor(lightHex: "#FFF0EE", darkHex: "#331E1A")
    }

    /// Info foreground
    static var statusInfoFG: Color {
        adaptiveColor(lightHex: "#3D7A9C", darkHex: "#5A9BBD")
    }

    /// Info background
    static var statusInfoBG: Color {
        adaptiveColor(lightHex: "#EEF6FA", darkHex: "#1A2830")
    }

    // MARK: - Border Colors (§4.1.7)

    /// Default border
    static var borderDefault: Color {
        adaptiveColor(lightHex: "#D4CBC0", darkHex: "#443F38")
    }

    /// Subtle border
    static var borderSubtle: Color {
        adaptiveColor(lightHex: "#E0D8CC", darkHex: "#3A3630")
    }

    /// Strong border
    static var borderStrong: Color {
        adaptiveColor(lightHex: "#C8BFB3", darkHex: "#4E4840")
    }

    /// Accent border
    static var borderAccent: Color {
        adaptiveColor(lightHex: "#4A7C2E", darkHex: "#5AAD5A")
    }

    // MARK: - Button States (§4.1.9)

    /// Primary button default background
    static var buttonPrimaryDefault: Color {
        adaptiveColor(lightHex: "#2D5016", darkHex: "#7BC08A")
    }

    /// Primary button pressed background
    static var buttonPrimaryPressed: Color {
        adaptiveColor(lightHex: "#1F3A0F", darkHex: "#5AAD5A")
    }

    /// Primary button disabled background
    static var buttonPrimaryDisabled: Color {
        adaptiveColor(lightHex: "#D4CBC0", darkHex: "#3A3630")
    }

    /// Primary button default text
    static var buttonPrimaryText: Color {
        adaptiveColor(lightHex: "#FFFFFF", darkHex: "#1C1A14")
    }

    /// Primary button disabled text
    static var buttonPrimaryDisabledText: Color {
        adaptiveColor(lightHex: "#FFFFFF", darkHex: "#5A5650")
    }

    // MARK: - Category Colors (§4.1.8)

    /// Returns the themed color for a grocery category name.
    /// All colors verified ≥ 3:1 on their respective backgrounds.
    static func categoryColor(for name: String) -> Color {
        switch name.lowercased() {
        case "produce":
            return adaptiveColor(lightHex: "#357A30", darkHex: "#5AAD54")
        case "dairy & fridge", "dairy":
            return adaptiveColor(lightHex: "#3A7CA5", darkHex: "#5AADCF")
        case "deli & meat", "meat", "deli":
            return adaptiveColor(lightHex: "#A8382E", darkHex: "#D4605A")
        case "bread & frozen", "bread & bakery", "bakery", "bread":
            return adaptiveColor(lightHex: "#B07828", darkHex: "#D4A04A")
        case "boxed & canned", "pantry & canned", "pantry", "canned":
            return adaptiveColor(lightHex: "#7A5D3F", darkHex: "#B09070")
        case "frozen":
            return adaptiveColor(lightHex: "#4A7D95", darkHex: "#6AADC0")
        case "beverages":
            return adaptiveColor(lightHex: "#6D5098", darkHex: "#9A7DC8")
        case "snacks, drinks, & other", "snacks & other", "snacks":
            return adaptiveColor(lightHex: "#C06A2F", darkHex: "#E08A50")
        case "seafood":
            return adaptiveColor(lightHex: "#267080", darkHex: "#45A0B0")
        case "household":
            return adaptiveColor(lightHex: "#5E6E60", darkHex: "#8DA890")
        case "uncategorized":
            return adaptiveColor(lightHex: "#7A7067", darkHex: "#938D83")
        default:
            return adaptiveColor(lightHex: "#7A7067", darkHex: "#938D83")
        }
    }

    // MARK: - Typography (§4.2.2)

    /// 34pt Bold Rounded — Top-level screen headers
    static var screenTitle: Font {
        .system(.largeTitle, design: .rounded).bold()
    }

    /// 28pt Bold Rounded — Recipe detail hero, detail headers
    static var detailTitle: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    /// 20pt Semibold Rounded — Card titles, section headers
    static var cardTitle: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    /// 17pt Regular System — Content text, list items, instructions
    static var bodyFont: Font {
        .system(.body)
    }

    /// 15pt Regular System — Metadata, secondary info, timing
    static var secondaryFont: Font {
        .system(.subheadline)
    }

    /// 13pt Semibold Rounded — Filter pills, action buttons, small interactive
    static var footnoteFont: Font {
        .system(.footnote, design: .rounded).weight(.semibold)
    }

    /// 12pt Semibold Rounded — Badges, category labels, counts
    static var captionFont: Font {
        .system(.caption, design: .rounded).weight(.semibold)
    }

    /// 10pt Medium Rounded — Tab bar labels only
    static var tabLabel: Font {
        .system(size: 10, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing (4-point grid)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let full: CGFloat = 999
    }
}

// MARK: - UIColor Hex Initializer (internal helper)

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
