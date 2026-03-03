//
//  DebugLogService.swift
//  forager
//
//  M10.6.5: In-memory debug log for testing AI parsing flow.
//  Gated behind #if DEBUG — compiles out of Release builds entirely.
//  Toggle on in Settings > Developer Tools, copy logs to share.
//

import Foundation

#if DEBUG

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

#endif
