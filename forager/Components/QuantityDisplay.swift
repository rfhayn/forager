//
//  QuantityDisplay.swift
//  forager
//
//  reskin-provisions-press: display-layer decimal→kitchen-fraction
//  conversion for quantity text ("0.25 cup" → "1/4 cup", "1.5 lb" →
//  "1 1/2 lb"). Slash form matches the app's existing convention
//  (recipe text + RecipeScalingService output). Stored values are
//  untouched; only exact kitchen fractions convert — oddball decimals
//  (e.g. "0.3") pass through unchanged.
//

import Foundation

extension String {
    /// Same fraction table as RecipeScalingService.formatToFraction,
    /// with a tight tolerance so only true kitchen fractions convert.
    private static let kitchenFractions: [(value: Double, display: String)] = [
        (0.125, "1/8"),
        (0.166, "1/6"),
        (0.25, "1/4"),
        (0.333, "1/3"),
        (0.375, "3/8"),
        (0.5, "1/2"),
        (0.625, "5/8"),
        (0.666, "2/3"),
        (0.75, "3/4"),
        (0.833, "5/6"),
        (0.875, "7/8")
    ]

    var displayingKitchenFractions: String {
        guard let regex = try? NSRegularExpression(pattern: #"\b(\d+)\.(\d+)\b"#) else { return self }
        let nsRange = NSRange(startIndex..., in: self)
        var result = self

        // Replace right-to-left so earlier ranges stay valid
        for match in regex.matches(in: self, range: nsRange).reversed() {
            guard let range = Range(match.range, in: self),
                  let value = Double(self[range]) else { continue }

            let whole = Int(value)
            let fractional = value - Double(whole)

            let replacement: String
            if fractional < 0.01 {
                replacement = "\(whole)"
            } else if let fraction = Self.kitchenFractions.first(where: { abs(fractional - $0.value) < 0.02 }) {
                replacement = whole > 0 ? "\(whole) \(fraction.display)" : fraction.display
            } else {
                continue // not a kitchen fraction — leave the decimal alone
            }

            result.replaceSubrange(Range(match.range, in: result)!, with: replacement)
        }
        return result
    }
}
