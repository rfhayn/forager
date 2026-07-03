//
//  ForagerTheme+StoreColors.swift
//  forager
//
//  M18.1.3: Store color palette and helpers for store-aware shopping.
//

import SwiftUI

extension ForagerTheme {

    /// Default palette of selectable store colors.
    /// reskin-provisions-press: 10 distinct hues in the print gamut —
    /// deep, inky, flat — all ≥ 3:1 on the butcher-paper canvas.
    /// Existing stores keep their persisted hex; this palette only
    /// affects new color picks.
    static let storeColorPalette: [String] = [
        "#2E7A52", // Print Green
        "#34689A", // Label Blue
        "#C8402E", // Tomato
        "#6A4E92", // Plum
        "#1F6E6A", // Teal
        "#C2662C", // Crate Orange
        "#77563A", // Kraft Brown
        "#A9761F", // Mustard Ink
        "#3C7D96", // Ice Blue
        "#5E6E60"  // Market Grey-Green
    ]

    /// Resolves a store's hex color string to a SwiftUI Color.
    /// Falls back to a neutral print grey if the hex is nil or invalid.
    static func storeColor(hex: String?) -> Color {
        guard let hex = hex, !hex.isEmpty else {
            return Color(hex: "#7A7368")
        }
        return Color(hex: hex)
    }
}
