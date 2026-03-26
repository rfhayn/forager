import Foundation

/// No-op stub for DebugLogService used by ClaudeIngredientParser in #if DEBUG blocks
@MainActor
final class DebugLogService: Sendable {
    static let shared = DebugLogService()
    func log(_ message: String, category: String = "General") {
        // No-op in harness
    }
}
