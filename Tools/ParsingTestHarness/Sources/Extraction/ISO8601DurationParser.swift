import Foundation

// MARK: - ISO 8601 Duration Parser

/// Parses ISO 8601 duration strings (e.g., "PT30M", "PT1H30M", "P0DT2H15M")
/// into total minutes. Also handles bare minute numbers.
enum ISO8601DurationParser {

    /// Parse an ISO 8601 duration string to total minutes.
    /// Returns nil if the string cannot be parsed.
    static func parseToMinutes(_ input: String) -> Int? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle bare numeric values (some sites just put "30" for 30 minutes)
        if let bareMinutes = Int(trimmed) {
            return bareMinutes
        }

        // ISO 8601 duration: P[nY][nM][nD]T[nH][nM][nS]
        // Common recipe patterns:
        //   PT30M        → 30 min
        //   PT1H30M      → 90 min
        //   PT1H         → 60 min
        //   P0DT0H30M    → 30 min
        //   PT2H15M00S   → 135 min
        guard trimmed.hasPrefix("P") else { return nil }

        var totalMinutes = 0
        var foundTime = false

        // Extract the time portion (after T)
        let parts = trimmed.dropFirst() // Remove "P"
        let components: String
        if let tIndex = parts.firstIndex(of: "T") {
            // Parse date portion for days
            let datePart = String(parts[parts.startIndex..<tIndex])
            if let daysMatch = extractNumber(from: datePart, before: "D") {
                totalMinutes += daysMatch * 24 * 60
            }
            components = String(parts[parts.index(after: tIndex)...])
            foundTime = true
        } else {
            // No T separator — might be just date components
            components = String(parts)
        }

        if foundTime || !components.isEmpty {
            if let hours = extractNumber(from: components, before: "H") {
                totalMinutes += hours * 60
            }
            if let minutes = extractNumber(from: components, before: "M") {
                totalMinutes += minutes
            }
            // Seconds — round up to nearest minute if > 0
            if let seconds = extractNumber(from: components, before: "S"), seconds > 0 {
                totalMinutes += max(1, seconds / 60)
            }
        }

        return totalMinutes > 0 ? totalMinutes : nil
    }

    /// Extract the integer before a given character (e.g., "30" before "M" in "1H30M").
    private static func extractNumber(from string: String, before char: Character) -> Int? {
        guard let charIndex = string.firstIndex(of: char) else { return nil }
        var numStr = ""
        var idx = string.index(before: charIndex)
        while idx >= string.startIndex {
            let c = string[idx]
            if c.isNumber {
                numStr = String(c) + numStr
            } else {
                break
            }
            if idx == string.startIndex { break }
            idx = string.index(before: idx)
        }
        return Int(numStr)
    }
}

// MARK: - Recipe Yield Parser

/// Parses various recipe yield/serving formats into an integer.
enum RecipeYieldParser {

    /// Parse a yield string like "4 servings", "Makes 12", "6-8", "4" into an Int.
    /// For ranges like "6-8", returns the lower bound.
    static func parse(_ input: String) -> Int? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle plain integer
        if let n = Int(trimmed) { return n }

        // Handle array-like input (some sites put yield as first element)
        // Already handled upstream — this parses individual strings

        // Extract first number from string
        // Handles: "4 servings", "Makes 12 cookies", "Serves 6", "6-8 servings", "Yield: 24"
        let pattern = #"(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let range = Range(match.range(at: 1), in: trimmed) else {
            return nil
        }

        return Int(trimmed[range])
    }
}
