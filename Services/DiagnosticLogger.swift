//
//  DiagnosticLogger.swift
//  forager
//
//  M9.15.3: Persistent file-based diagnostic logger for CloudKit troubleshooting.
//  Works in Release builds. Writes to Documents/forager-diagnostics.log.
//  Exportable from Settings > Diagnostic Log.
//

import Foundation
import UIKit

/// Persistent diagnostic logger that writes to a file on disk.
/// Unlike DebugLogService (in-memory, 500 entries), this survives app restarts
/// and can be shared via the system share sheet from Settings.
///
/// Usage: `DiagnosticLogger.shared.log("message", category: .cloudKit)`
@MainActor
class DiagnosticLogger: ObservableObject {

    static let shared = DiagnosticLogger()

    enum Category: String {
        case cloudKit = "CloudKit"
        case household = "Household"
        case sync = "Sync"
        case schema = "Schema"
        case store = "Store"
        case discovery = "Discovery"
        case app = "App"
        case import_ = "Import"
        case error = "ERROR"
    }

    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }

    @Published var isEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "diagnosticLogEnabled") }
    }

    /// Approximate line count for UI display
    @Published private(set) var lineCount: Int = 0

    private let logFileURL: URL
    private let maxFileSize: Int = 2 * 1024 * 1024 // 2 MB cap
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    private var fileHandle: FileHandle?

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = docs.appendingPathComponent("forager-diagnostics.log")
        self.isEnabled = UserDefaults.standard.object(forKey: "diagnosticLogEnabled") as? Bool ?? true

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }

        // Open for appending
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()

        // Count existing lines
        lineCount = countLines()

        // Write session header
        let device = UIDevice.current
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let isDebug: String
        #if DEBUG
        isDebug = "Debug"
        #else
        isDebug = "Release"
        #endif

        writeRaw("\n══════════════════════════════════════════")
        writeRaw("SESSION START: \(dateFormatter.string(from: Date()))")
        writeRaw("Version: \(version) (\(build)) [\(isDebug)]")
        writeRaw("Device: \(device.name) (\(device.systemName) \(device.systemVersion))")
        writeRaw("══════════════════════════════════════════")
    }

    deinit {
        fileHandle?.closeFile()
    }

    // MARK: - Logging

    func log(_ message: String, category: Category = .app, level: Level = .info) {
        guard isEnabled else { return }
        let timestamp = dateFormatter.string(from: Date())
        let line = "[\(timestamp)] [\(level.rawValue)] [\(category.rawValue)] \(message)"
        writeRaw(line)
    }

    func debug(_ message: String, category: Category = .app) {
        log(message, category: category, level: .debug)
    }

    func info(_ message: String, category: Category = .app) {
        log(message, category: category, level: .info)
    }

    func warning(_ message: String, category: Category = .app) {
        log(message, category: category, level: .warning)
    }

    func error(_ message: String, category: Category = .app) {
        log(message, category: category, level: .error)
    }

    // MARK: - File Operations

    /// Read the full log contents
    func readLog() -> String {
        (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "(empty log)"
    }

    /// Get the file URL for sharing
    var fileURL: URL { logFileURL }

    /// File size in bytes
    var fileSize: Int {
        (try? FileManager.default.attributesOfItem(atPath: logFileURL.path)[.size] as? Int) ?? 0
    }

    /// Human-readable file size
    var formattedFileSize: String {
        let bytes = fileSize
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    /// Clear the log file
    func clear() {
        fileHandle?.closeFile()
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        lineCount = 0
    }

    // MARK: - Private

    private func writeRaw(_ line: String) {
        guard let data = (line + "\n").data(using: .utf8) else { return }

        // Rotate if file is too large
        if fileSize > maxFileSize {
            rotateLog()
        }

        fileHandle?.write(data)
        lineCount += 1
    }

    private func rotateLog() {
        fileHandle?.closeFile()
        // Keep last half of the file
        if var content = try? String(contentsOf: logFileURL, encoding: .utf8) {
            let lines = content.components(separatedBy: "\n")
            let keepFrom = lines.count / 2
            content = lines.suffix(from: keepFrom).joined(separator: "\n")
            try? content.write(to: logFileURL, atomically: true, encoding: .utf8)
            lineCount = lines.count - keepFrom
        }
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
    }

    private func countLines() -> Int {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else { return 0 }
        return content.components(separatedBy: "\n").count
    }
}
