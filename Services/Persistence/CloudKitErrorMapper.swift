//
//  CloudKitErrorMapper.swift
//  forager
//
//  M7.3.4: Single source of truth for CloudKit error messages
//  Replaces duplicate mapping in CloudKitSyncMonitor and CloudKitDiagnostics
//
//  Created on February 3, 2026.
//

import CloudKit
import Foundation

/// M7.3.4: Centralized CloudKit error mapping
///
/// Provides:
/// - Consistent user-friendly messages across the app
/// - Error classification for retry behavior
/// - Suggested actions for recoverable errors
struct CloudKitErrorMapper {

    // MARK: - Error Classification

    /// Classification for retry behavior and UI presentation
    enum ErrorType {
        case transient      // Will resolve itself, CloudKit retries automatically
        case userAction     // Requires user action (sign in, free storage)
        case permanent      // Won't resolve without code change or data fix
    }

    // MARK: - Mapped Error Result

    /// Result of mapping a CKError to user-friendly information
    struct MappedError {
        let userMessage: String
        let type: ErrorType
        let suggestedAction: String?

        /// Whether this error type should trigger automatic retry
        var isRetryable: Bool {
            type == .transient
        }
    }

    // MARK: - Main Mapping Function

    /// Maps CKError to user-friendly message and classification
    /// - Parameter error: The CloudKit error to map
    /// - Returns: A MappedError with user message, type, and optional action
    static func map(_ error: CKError) -> MappedError {
        switch error.code {
        case .networkUnavailable:
            return MappedError(
                userMessage: "No internet connection. Changes will sync when you're back online.",
                type: .transient,
                suggestedAction: nil
            )

        case .networkFailure:
            return MappedError(
                userMessage: "Network error. Will retry automatically.",
                type: .transient,
                suggestedAction: nil
            )

        case .notAuthenticated:
            return MappedError(
                userMessage: "Not signed into iCloud. Please sign in to enable sync.",
                type: .userAction,
                suggestedAction: "Open Settings → [Your Name] → iCloud"
            )

        case .quotaExceeded:
            return MappedError(
                userMessage: "iCloud storage full. Please free up space to continue syncing.",
                type: .userAction,
                suggestedAction: "Open Settings → [Your Name] → iCloud → Manage Storage"
            )

        case .zoneBusy:
            return MappedError(
                userMessage: "iCloud is busy. Will retry automatically.",
                type: .transient,
                suggestedAction: nil
            )

        case .serviceUnavailable:
            return MappedError(
                userMessage: "iCloud service temporarily unavailable. Will retry shortly.",
                type: .transient,
                suggestedAction: nil
            )

        case .serverRecordChanged:
            return MappedError(
                userMessage: "Someone else edited this. Changes merged automatically.",
                type: .transient,
                suggestedAction: nil
            )

        case .zoneNotFound:
            return MappedError(
                userMessage: "Sync zone not found. Recreating...",
                type: .transient,
                suggestedAction: nil
            )

        case .unknownItem:
            return MappedError(
                userMessage: "Item not found. It may have been deleted.",
                type: .permanent,
                suggestedAction: nil
            )

        case .internalError:
            return MappedError(
                userMessage: "iCloud internal error. Will retry shortly.",
                type: .transient,
                suggestedAction: nil
            )

        case .serverRejectedRequest:
            return MappedError(
                userMessage: "Server rejected request. Please try again later.",
                type: .transient,
                suggestedAction: nil
            )

        case .participantMayNeedVerification:
            return MappedError(
                userMessage: "Invitation recipient needs to verify their iCloud account.",
                type: .userAction,
                suggestedAction: "Ask them to check their iCloud settings"
            )

        case .requestRateLimited:
            return MappedError(
                userMessage: "Too many requests. Will retry shortly.",
                type: .transient,
                suggestedAction: nil
            )

        case .incompatibleVersion:
            return MappedError(
                userMessage: "App version incompatible. Please update the app.",
                type: .userAction,
                suggestedAction: "Check the App Store for updates"
            )

        case .permissionFailure:
            return MappedError(
                userMessage: "Permission denied. You may not have access to this data.",
                type: .permanent,
                suggestedAction: nil
            )

        default:
            return MappedError(
                userMessage: "Sync error (\(error.code.rawValue)). Will retry automatically.",
                type: .transient,
                suggestedAction: nil
            )
        }
    }

    // MARK: - Convenience Methods

    /// Convenience method for extracting CKError from any Error
    /// - Parameter error: Any error that might contain a CKError
    /// - Returns: MappedError if the error is a CKError, nil otherwise
    static func map(_ error: Error) -> MappedError? {
        if let ckError = error as? CKError {
            return map(ckError)
        }
        return nil
    }

    /// Get just the user message for a CKError (convenience for UI)
    /// - Parameter error: The CloudKit error
    /// - Returns: User-friendly message string
    static func message(for error: CKError) -> String {
        return map(error).userMessage
    }

    /// Get just the user message for an error code (convenience for legacy code)
    /// - Parameter errorCode: Raw error code from NSError
    /// - Returns: User-friendly message string
    static func message(forCode errorCode: Int) -> String {
        // Map common codes - used for legacy Int-based error handling
        switch errorCode {
        case CKError.networkUnavailable.rawValue:
            return "No internet connection. Changes will sync when you're back online."
        case CKError.networkFailure.rawValue:
            return "Network error. Will retry automatically."
        case CKError.notAuthenticated.rawValue:
            return "Not signed into iCloud. Please sign in to enable sync."
        case CKError.quotaExceeded.rawValue:
            return "iCloud storage full. Please free up space to continue syncing."
        case CKError.zoneBusy.rawValue:
            return "iCloud is busy. Will retry automatically."
        case CKError.serviceUnavailable.rawValue:
            return "iCloud service temporarily unavailable. Will retry shortly."
        case CKError.serverRecordChanged.rawValue:
            return "Someone else edited this. Changes merged automatically."
        case CKError.zoneNotFound.rawValue:
            return "Sync zone not found. Recreating..."
        case CKError.internalError.rawValue:
            return "iCloud internal error. Will retry shortly."
        case CKError.serverRejectedRequest.rawValue:
            return "Server rejected request. Please try again later."
        default:
            return "Sync error (code \(errorCode)). Will retry automatically."
        }
    }
}
