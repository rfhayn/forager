//
//  DebugLogService.swift
//  forager
//
//  M10.6.5: In-memory debug log for testing AI parsing flow.
//
//  Gating history:
//   - M9.28: gated behind `#if DEBUG`; no-op stub in Release for App Store.
//   - architecture-compliance-sweep (2026-04-19): un-gated for TestFlight beta
//     builds. Default stays OFF — users must opt in via Settings > Diagnostics.
//     TODO before next App Store submission: re-evaluate (see DiagnosticLogger.swift
//     header for the same note).
//

import Foundation

@MainActor
class DebugLogService: ObservableObject {

    static let shared = DebugLogService()

    @Published var isEnabled: Bool = false {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "debugLogEnabled") }
    }

    @Published private(set) var entries: [String] = []

    private let maxEntries = 500
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()

    init() {
        // Default OFF — users explicitly enable. No conditional default; this
        // matches the prior DEBUG impl's default.
        self.isEnabled = UserDefaults.standard.bool(forKey: "debugLogEnabled")
    }

    func log(_ message: String, category: String = "General") {
        guard isEnabled else { return }
        let timestamp = dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] [\(category)] \(message)"
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func clear() {
        entries.removeAll()
    }

    var fullLog: String {
        entries.joined(separator: "\n")
    }
}
