//
//  ForagerTheme+StoreColors.swift
//  forager
//
//  M18.1.3: Store color palette and helpers for store-aware shopping.
//

import SwiftUI

extension ForagerTheme {

    /// Default palette of selectable store colors.
    /// 10 distinct hues that work on both light and dark backgrounds.
    static let storeColorPalette: [String] = [
        "#4CAF50", // Green
        "#2196F3", // Blue
        "#FF9800", // Orange
        "#E91E63", // Pink
        "#9C27B0", // Purple
        "#00BCD4", // Cyan
        "#F44336", // Red
        "#795548", // Brown
        "#FFC107", // Amber
        "#607D8B"  // Blue Grey
    ]

    /// Resolves a store's hex color string to a SwiftUI Color.
    /// Falls back to a neutral grey if the hex is nil or invalid.
    static func storeColor(hex: String?) -> Color {
        guard let hex = hex, !hex.isEmpty else {
            return Color(hex: "#757575")
        }
        return Color(hex: hex)
    }
}
