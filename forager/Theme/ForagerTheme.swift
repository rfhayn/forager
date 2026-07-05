// ForagerTheme.swift
// M15.1: Centralized design token system for the forager app
// reskin-provisions-press: Provisions Press visual identity — bold editorial
// print grounded in grocery vernacular (butcher paper, ink, tomato, mustard,
// teal; crate-label display type, SF Mono quantities). Content layer only —
// Liquid Glass chrome is retained and picks up tint from these tokens.
//
// All semantic colors, typography helpers, spacing, and corner radii
// are defined here. Views reference ForagerTheme tokens instead of
// hardcoded values. Light/dark mode handled via UIColor dynamic provider.
// Dark mode is a deliberate ink-paper inversion (warm near-black, not grey).
//
// Contrast: every text-on-background and accent-on-surface pair verified
// against WCAG (AAA primary text, AA other text, 3:1 UI). Full map with
// computed ratios: openspec/changes/reskin-provisions-press/token-map.md

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

    // MARK: - Background Colors

    /// Full-screen base background — butcher paper / warm ink
    static var backgroundCanvas: Color {
        adaptiveColor(lightHex: "#E8E6DF", darkHex: "#191714")
    }

    /// Card/section backgrounds
    static var backgroundPrimary: Color {
        adaptiveColor(lightHex: "#E0DDD4", darkHex: "#201D19")
    }

    /// Grouped content
    static var backgroundSecondary: Color {
        adaptiveColor(lightHex: "#D8D4C9", darkHex: "#282420")
    }

    /// Nested groups
    static var backgroundTertiary: Color {
        adaptiveColor(lightHex: "#CFCBBE", darkHex: "#302B26")
    }

    // MARK: - Surface Colors

    /// Cards, list rows, inputs — raised paper
    static var surfacePrimary: Color {
        adaptiveColor(lightHex: "#F2F0EA", darkHex: "#262220")
    }

    /// Sheets, popovers
    static var surfaceSecondary: Color {
        adaptiveColor(lightHex: "#F7F5F0", darkHex: "#2E2A26")
    }

    /// Selected state highlight — tomato tint
    static var surfaceAccent: Color {
        adaptiveColor(lightHex: "#F2DCD7", darkHex: "#3A2A26")
    }

    /// Warning banners — mustard tint
    static var surfaceWarning: Color {
        adaptiveColor(lightHex: "#F4E7CC", darkHex: "#362D1A")
    }

    /// Error banners — tomato tint
    static var surfaceDanger: Color {
        adaptiveColor(lightHex: "#F4DAD4", darkHex: "#3A241F")
    }

    /// Success banners — print-green tint
    static var surfaceSuccess: Color {
        adaptiveColor(lightHex: "#DCE9DD", darkHex: "#22302A")
    }

    // MARK: - Text Colors

    /// Primary text — ink on paper (13.43:1 light, 13.68:1 dark — AAA)
    static var textPrimary: Color {
        adaptiveColor(lightHex: "#201D1A", darkHex: "#E4E1D8")
    }

    /// Secondary text (6.39:1 light, 8.56:1 dark — AA+)
    static var textSecondary: Color {
        adaptiveColor(lightHex: "#55504A", darkHex: "#B8B3A8")
    }

    /// Tertiary text, metadata (4.54:1 light, 5.94:1 dark — AA)
    static var textTertiary: Color {
        adaptiveColor(lightHex: "#6C665E", darkHex: "#9A948A")
    }

    /// Disabled text
    static var textDisabled: Color {
        adaptiveColor(lightHex: "#A39D92", darkHex: "#5E594F")
    }

    /// Link text — teal (5.94:1 light, 7.44:1 dark)
    static var textLink: Color {
        adaptiveColor(lightHex: "#1A5F5B", darkHex: "#6FB3AE")
    }

    // MARK: - Accent Colors

    /// Primary CTAs — Tomato
    static var accentPrimary: Color {
        adaptiveColor(lightHex: "#C8402E", darkHex: "#E05A44")
    }

    /// Secondary accents — Mustard (ink-weight in light mode for contrast)
    static var accentSecondary: Color {
        adaptiveColor(lightHex: "#A9761F", darkHex: "#D89A2B")
    }

    /// Icons, decorative — Teal
    static var accentTertiary: Color {
        adaptiveColor(lightHex: "#1F6E6A", darkHex: "#4E9B95")
    }

    /// Tinted backgrounds — tomato tint
    static var accentTint: Color {
        adaptiveColor(lightHex: "#F2DCD7", darkHex: "#3A2A26")
    }

    // MARK: - Status Colors

    /// Success foreground (5.12:1 on BG light, 5.35:1 dark)
    static var statusSuccessFG: Color {
        adaptiveColor(lightHex: "#266B45", darkHex: "#6FAF87")
    }

    /// Success background
    static var statusSuccessBG: Color {
        adaptiveColor(lightHex: "#DCE9DD", darkHex: "#22302A")
    }

    /// Warning foreground (5.36:1 on BG light, 6.12:1 dark)
    static var statusWarningFG: Color {
        adaptiveColor(lightHex: "#7A5710", darkHex: "#D8A64A")
    }

    /// Warning background
    static var statusWarningBG: Color {
        adaptiveColor(lightHex: "#F4E7CC", darkHex: "#362D1A")
    }

    /// Danger foreground (4.55:1 on BG light, 4.87:1 dark)
    static var statusDangerFG: Color {
        adaptiveColor(lightHex: "#B03A28", darkHex: "#E67560")
    }

    /// Danger background
    static var statusDangerBG: Color {
        adaptiveColor(lightHex: "#F4DAD4", darkHex: "#3A241F")
    }

    /// Info foreground (4.64:1 on BG light, 5.12:1 dark)
    static var statusInfoFG: Color {
        adaptiveColor(lightHex: "#34689A", darkHex: "#6E9EC8")
    }

    /// Info background
    static var statusInfoBG: Color {
        adaptiveColor(lightHex: "#DEE6EE", darkHex: "#202A34")
    }

    // MARK: - Border Colors

    /// Default border
    static var borderDefault: Color {
        adaptiveColor(lightHex: "#C6C2B6", darkHex: "#44403A")
    }

    /// Subtle border
    static var borderSubtle: Color {
        adaptiveColor(lightHex: "#D6D2C7", darkHex: "#38342E")
    }

    /// Strong border
    static var borderStrong: Color {
        adaptiveColor(lightHex: "#A9A497", darkHex: "#56524A")
    }

    /// Accent border
    static var borderAccent: Color {
        adaptiveColor(lightHex: "#C8402E", darkHex: "#E05A44")
    }

    // MARK: - Button States

    /// Primary button default background — tomato
    static var buttonPrimaryDefault: Color {
        adaptiveColor(lightHex: "#C8402E", darkHex: "#E05A44")
    }

    /// Primary button pressed background — darker in light, LIGHTER in dark
    /// (glass brightens under touch; keeps ink text at 6.38:1)
    static var buttonPrimaryPressed: Color {
        adaptiveColor(lightHex: "#A5301F", darkHex: "#EA7A64")
    }

    /// Primary button disabled background
    static var buttonPrimaryDisabled: Color {
        adaptiveColor(lightHex: "#D2CEC3", darkHex: "#38342E")
    }

    /// Primary button default text (4.97:1 light, 4.88:1 dark)
    static var buttonPrimaryText: Color {
        adaptiveColor(lightHex: "#FFFFFF", darkHex: "#1B1613")
    }

    /// Primary button disabled text
    static var buttonPrimaryDisabledText: Color {
        adaptiveColor(lightHex: "#8F897D", darkHex: "#5E594F")
    }

    // MARK: - Category Colors

    /// Returns the themed color for a Category, preferring the stored `color`
    /// hex (set by AddCategoryView / CategoryService when a user creates a
    /// custom category) and falling back to the name-based default when the
    /// stored hex is missing or empty. Use this overload for any rendering of
    /// a first-class Category object; the String overload below remains for
    /// callers that only have a name (e.g., pre-fetch preview chips).
    static func categoryColor(for category: Category) -> Color {
        if let hex = category.color, !hex.isEmpty {
            return Color(hex: hex)
        }
        return categoryColor(for: category.displayName)
    }

    /// Returns the themed color for a grocery category name.
    /// Re-derived for Provisions Press with hue-family continuity (produce
    /// stays green, dairy blue, meat red…) so learned associations survive.
    /// All fills verified ≥ 3:1 on canvas; white labels ≥ 3:1 on light fills.
    static func categoryColor(for name: String) -> Color {
        switch name.lowercased() {
        case "produce":
            return adaptiveColor(lightHex: "#2E7A52", darkHex: "#5FA97E")
        case "dairy & fridge", "dairy":
            return adaptiveColor(lightHex: "#34689A", darkHex: "#6E9EC8")
        case "deli & meat", "meat", "deli":
            return adaptiveColor(lightHex: "#C8402E", darkHex: "#E06A55")
        case "bread & frozen", "bread & bakery", "bakery", "bread":
            return adaptiveColor(lightHex: "#B0762A", darkHex: "#C9924A")
        case "boxed & canned", "pantry & canned", "pantry", "canned":
            return adaptiveColor(lightHex: "#77563A", darkHex: "#A5825F")
        case "frozen":
            return adaptiveColor(lightHex: "#3C7D96", darkHex: "#6BA7BE")
        case "beverages":
            return adaptiveColor(lightHex: "#6A4E92", darkHex: "#9C82C4")
        case "snacks, drinks, & other", "snacks & other", "snacks":
            return adaptiveColor(lightHex: "#C2662C", darkHex: "#D98A52")
        case "seafood":
            return adaptiveColor(lightHex: "#1F6E6A", darkHex: "#4E9B95")
        case "household":
            return adaptiveColor(lightHex: "#5E6E60", darkHex: "#8DA890")
        case "uncategorized":
            return adaptiveColor(lightHex: "#7A7368", darkHex: "#948D82")
        default:
            return adaptiveColor(lightHex: "#7A7368", darkHex: "#948D82")
        }
    }

    // MARK: - Typography
    // Crate-label voice: condensed heavy display for titles, SF Pro Text for
    // body, SF Mono for quantities. SF Pro Rounded is retired app-wide.

    /// 34pt Heavy Condensed — Top-level screen headers (crate-label display)
    static var screenTitle: Font {
        .system(.largeTitle, design: .default).weight(.heavy).width(.condensed)
    }

    /// 28pt Heavy Condensed — Recipe detail hero, detail headers
    /// (relative to .title so Dynamic Type scales it)
    static var detailTitle: Font {
        .system(.title, design: .default).weight(.heavy).width(.condensed)
    }

    /// 20pt Bold Condensed — Card titles, section headers
    /// (relative to .title3 so Dynamic Type scales it)
    static var cardTitle: Font {
        .system(.title3, design: .default).weight(.bold).width(.condensed)
    }

    /// 17pt Regular System — Content text, list items, instructions
    static var bodyFont: Font {
        .system(.body)
    }

    /// 15pt Regular System — Metadata, secondary info, timing
    static var secondaryFont: Font {
        .system(.subheadline)
    }

    /// 13pt Semibold Condensed — Filter pills, action buttons, small interactive
    static var footnoteFont: Font {
        .system(.footnote).weight(.semibold).width(.condensed)
    }

    /// 12pt Semibold Condensed — Badges, category labels, counts
    static var captionFont: Font {
        .system(.caption).weight(.semibold).width(.condensed)
    }

    /// 10pt Semibold Condensed — Tab bar labels only
    static var tabLabel: Font {
        .system(size: 10, weight: .semibold).width(.condensed)
    }

    /// 13pt Semibold Mono — Quantities, amounts, counts (the price-tag
    /// signature: tabular, scannable numerals wherever amounts render)
    static var quantityFont: Font {
        .system(.footnote, design: .monospaced).weight(.semibold)
    }

    /// 15pt Semibold Mono — Larger quantity contexts (recipe ingredient lists)
    /// (relative to .subheadline so Dynamic Type scales it with the item text)
    static var quantityFontLarge: Font {
        .system(.subheadline, design: .monospaced).weight(.semibold)
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
    // Print vocabulary: tags and blocks sit sharper than the old soft system.

    enum Radius {
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
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
