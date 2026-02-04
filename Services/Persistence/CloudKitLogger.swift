//
//  CloudKitLogger.swift
//  forager
//
//  M7.3.4: Structured logging for CloudKit operations
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
/// - Structured logging for household, share, and sync operations
/// - Privacy-conscious logging (emails not logged)
/// - Integration with CloudKitErrorMapper for consistent error messages
///
/// Retrieving logs from TestFlight:
/// ```bash
/// # From Mac with device connected:
/// log show --predicate 'subsystem == "com.richhayn.forager"' --last 1h
///
/// # Or use Console.app → select device → filter by subsystem
/// ```
struct CloudKitLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.richhayn.forager",
        category: "CloudKit"
    )

    // MARK: - Household Operations

    /// Log household creation
    static func householdCreated(_ householdName: String?) {
        logger.info("Household created: \(householdName ?? "unnamed", privacy: .public)")
    }

    /// Log leaving a household
    static func householdLeft(_ householdID: String) {
        logger.info("Left household: \(householdID, privacy: .public)")
    }

    /// Log household deletion
    static func householdDeleted(_ householdID: String) {
        logger.info("Household deleted: \(householdID, privacy: .public)")
    }

    /// Log household loaded
    static func householdLoaded(_ householdName: String?, householdID: String) {
        logger.info("Household loaded: \(householdName ?? "unnamed", privacy: .public) (\(householdID, privacy: .public))")
    }

    /// Log member invited (email not logged for privacy)
    static func memberInvited(householdID: String) {
        logger.info("Member invited to household: \(householdID, privacy: .public)")
    }

    /// Log member removed
    static func memberRemoved(householdID: String) {
        logger.info("Member removed from household: \(householdID, privacy: .public)")
    }

    /// Log member joined
    static func memberJoined(householdID: String) {
        logger.info("Member joined household: \(householdID, privacy: .public)")
    }

    /// Log member activated (pending → active)
    static func memberActivated(householdID: String) {
        logger.info("Member activated in household: \(householdID, privacy: .public)")
    }

    // MARK: - Share Operations

    /// Log CKShare created
    static func shareCreated(recordID: String) {
        logger.info("CKShare created: \(recordID, privacy: .public)")
    }

    /// Log CKShare accepted
    static func shareAccepted(recordID: String) {
        logger.info("CKShare accepted: \(recordID, privacy: .public)")
    }

    /// Log share lookup result
    static func shareLookup(found: Bool, householdID: String) {
        if found {
            logger.debug("CKShare found for household: \(householdID, privacy: .public)")
        } else {
            logger.warning("CKShare not found for household: \(householdID, privacy: .public)")
        }
    }

    /// Log share operation failure
    static func shareFailed(operation: String, error: Error) {
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            logger.error("Share operation '\(operation, privacy: .public)' failed: \(mapped.userMessage, privacy: .public) (code: \(ckError.code.rawValue))")
        } else {
            logger.error("Share operation '\(operation, privacy: .public)' failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Leave/Delete Operations

    /// Log leave household attempt started
    static func leaveAttemptStarted(householdID: String) {
        logger.info("Leave household attempt started: \(householdID, privacy: .public)")
    }

    /// Log leave household completed
    static func leaveCompleted(householdID: String, migratedData: Bool) {
        logger.info("Leave household completed: \(householdID, privacy: .public), migrated: \(migratedData)")
    }

    /// Log delete household attempt started
    static func deleteAttemptStarted(householdID: String) {
        logger.info("Delete household attempt started: \(householdID, privacy: .public)")
    }

    /// Log delete household completed
    static func deleteCompleted(householdID: String, migratedData: Bool) {
        logger.info("Delete household completed: \(householdID, privacy: .public), migrated: \(migratedData)")
    }

    // MARK: - Sync Events

    /// Log sync started
    static func syncStarted() {
        logger.debug("Sync started")
    }

    /// Log sync completed
    static func syncCompleted(recordCount: Int) {
        logger.info("Sync completed: \(recordCount) records")
    }

    /// Log sync failed
    static func syncFailed(error: Error) {
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            logger.error("Sync failed: \(mapped.userMessage, privacy: .public) (code: \(ckError.code.rawValue))")
        } else {
            logger.error("Sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Error Logging

    /// Log a CloudKit error with context
    static func error(_ context: String, error: Error) {
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            logger.error("\(context, privacy: .public): \(mapped.userMessage, privacy: .public) (code: \(ckError.code.rawValue))")
        } else {
            logger.error("\(context, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Log a household-specific error
    static func householdError(_ context: String, householdID: String?, error: Error) {
        let idString = householdID ?? "unknown"
        if let ckError = error as? CKError {
            let mapped = CloudKitErrorMapper.map(ckError)
            logger.error("\(context, privacy: .public) [household: \(idString, privacy: .public)]: \(mapped.userMessage, privacy: .public) (code: \(ckError.code.rawValue))")
        } else {
            logger.error("\(context, privacy: .public) [household: \(idString, privacy: .public)]: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Debug/Warning

    /// Log debug message
    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    /// Log warning message
    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    /// Log info message
    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    // MARK: - Ghost Data Bug Specific (M7.3.4)

    /// Log when user is marked as left but still participant (ghost data scenario)
    static func ghostDataDetected(householdID: String) {
        logger.warning("Ghost data detected: User marked as left but still CKShare participant [household: \(householdID, privacy: .public)]")
    }

    /// Log when shared store is purged
    static func sharedStorePurged() {
        logger.info("Shared store objects purged")
    }
}
