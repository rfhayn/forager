//
//  CloudKitLogger.swift
//  forager
//
//  M7.3.4: Structured logging for CloudKit operations
//  M9.15.3: Added persistent DiagnosticLogger integration for Release builds
//  Uses OSLog for retrieval from TestFlight devices
//
//  Created on February 3, 2026.
//

import OSLog
import CloudKit

/// M7.3.4: Structured logging for CloudKit operations
///
/// Provides:
/// - OSLog-based logging retrievable from TestFlight devices
/// - M9.15.3: Persistent file logging via DiagnosticLogger (exportable from Settings)
/// - Structured logging for household, share, and sync operations
/// - Privacy-conscious logging (emails not logged)
/// - Integration with CloudKitErrorMapper for consistent error messages
struct CloudKitLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.richhayn.forager",
        category: "CloudKit"
    )

    /// M9.15.3: Write to persistent DiagnosticLogger alongside OSLog.
    /// Uses Task to hop to MainActor since DiagnosticLogger is @MainActor.
    private static func persist(_ message: String, level: DiagnosticLogger.Level = .info) {
        Task { @MainActor in
            DiagnosticLogger.shared.log(message, category: .cloudKit, level: level)
        }
    }

    // MARK: - Household Operations

    static func householdCreated(_ householdName: String?) {
        let msg = "Household created: \(householdName ?? "unnamed")"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func householdLeft(_ householdID: String) {
        let msg = "Left household: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func householdDeleted(_ householdID: String) {
        let msg = "Household deleted: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func householdLoaded(_ householdName: String?, householdID: String) {
        let msg = "Household loaded: \(householdName ?? "unnamed") (\(householdID))"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func memberInvited(householdID: String) {
        let msg = "Member invited to household: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func memberRemoved(householdID: String) {
        let msg = "Member removed from household: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func memberJoined(householdID: String) {
        let msg = "Member joined household: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func memberActivated(householdID: String) {
        let msg = "Member activated in household: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    // MARK: - Share Operations

    static func shareCreated(recordID: String) {
        let msg = "CKShare created: \(recordID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func shareAccepted(recordID: String) {
        let msg = "CKShare accepted: \(recordID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func shareLookup(found: Bool, householdID: String) {
        let msg = found
            ? "CKShare found for household: \(householdID)"
            : "CKShare NOT found for household: \(householdID)"
        if found {
            logger.debug("\(msg, privacy: .public)")
            persist(msg, level: .debug)
        } else {
            logger.warning("\(msg, privacy: .public)")
            persist(msg, level: .warning)
        }
    }

    static func shareFailed(operation: String, error: Error) {
        let msg: String
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            msg = "Share '\(operation)' failed: \(mapped.userMessage) (code: \(ckError.code.rawValue))"
        } else {
            msg = "Share '\(operation)' failed: \(error.localizedDescription)"
        }
        logger.error("\(msg, privacy: .public)")
        persist(msg, level: .error)
    }

    // MARK: - Leave/Delete Operations

    static func leaveAttemptStarted(householdID: String) {
        let msg = "Leave household started: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func leaveCompleted(householdID: String, migratedData: Bool) {
        let msg = "Leave household completed: \(householdID), migrated: \(migratedData)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func deleteAttemptStarted(householdID: String) {
        let msg = "Delete household started: \(householdID)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func deleteCompleted(householdID: String, migratedData: Bool) {
        let msg = "Delete household completed: \(householdID), migrated: \(migratedData)"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    // MARK: - Sync Events

    static func syncStarted() {
        logger.debug("Sync started")
        persist("Sync started", level: .debug)
    }

    static func syncCompleted(recordCount: Int) {
        let msg = "Sync completed: \(recordCount) records"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }

    static func syncFailed(error: Error) {
        let msg: String
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            msg = "Sync failed: \(mapped.userMessage) (code: \(ckError.code.rawValue))"
        } else {
            msg = "Sync failed: \(error.localizedDescription)"
        }
        logger.error("\(msg, privacy: .public)")
        persist(msg, level: .error)
    }

    // MARK: - Error Logging

    static func error(_ context: String, error: Error) {
        let msg: String
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            msg = "\(context): \(mapped.userMessage) (code: \(ckError.code.rawValue))"
        } else {
            msg = "\(context): \(error.localizedDescription)"
        }
        logger.error("\(msg, privacy: .public)")
        persist(msg, level: .error)
    }

    static func householdError(_ context: String, householdID: String?, error: Error) {
        let idString = householdID ?? "unknown"
        let msg: String
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            msg = "\(context) [household: \(idString)]: \(mapped.userMessage) (code: \(ckError.code.rawValue))"
        } else {
            msg = "\(context) [household: \(idString)]: \(error.localizedDescription)"
        }
        logger.error("\(msg, privacy: .public)")
        persist(msg, level: .error)
    }

    // MARK: - Debug/Warning

    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        persist(message, level: .debug)
    }

    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
        persist(message, level: .warning)
    }

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        persist(message)
    }

    // MARK: - Ghost Data Bug Specific (M7.3.4)

    static func ghostDataDetected(householdID: String) {
        let msg = "Ghost data detected: User marked as left but still CKShare participant [household: \(householdID)]"
        logger.warning("\(msg, privacy: .public)")
        persist(msg, level: .warning)
    }

    static func sharedStorePurged() {
        let msg = "Shared store objects purged"
        logger.info("\(msg, privacy: .public)")
        persist(msg)
    }
}
