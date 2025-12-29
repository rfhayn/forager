//
//  CloudKitSyncMonitor.swift
//  forager
//
//  Created for M7.1.2: CloudKitSyncMonitor Service
//  Purpose: Monitor CloudKit sync status, handle notifications, log events
//

import Foundation
import CoreData
import CloudKit
import Combine

// MARK: - CloudKitSyncMonitor Service

/// M7.1.2: Monitors CloudKit sync activity and status
/// Observes NSPersistentStoreRemoteChange notifications from NSPersistentCloudKitContainer
/// Tracks sync state and provides observable status for UI integration
class CloudKitSyncMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current sync state (idle, syncing, synced, error)
    @Published var syncState: SyncState = .idle
    
    /// Timestamp of last successful sync
    @Published var lastSyncDate: Date?
    
    /// Most recent sync error if any
    @Published var syncError: Error?
    
    /// Count of sync events observed (for debugging)
    @Published var syncEventCount: Int = 0
    
    // MARK: - Sync State Enum
    
    enum SyncState: Equatable {
        case idle           // No sync activity
        case syncing        // Sync in progress
        case synced         // Sync completed successfully
        case error(String)  // Sync failed with error
        
        static func == (lhs: SyncState, rhs: SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.syncing, .syncing), (.synced, .synced):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        print("📡 CloudKitSyncMonitor initialized - monitoring remote changes")
    }
    
    // MARK: - Notification Observers
    
    /// M7.1.2: Setup observers for NSPersistentStoreRemoteChange notifications
    /// These notifications are posted by NSPersistentCloudKitContainer when CloudKit sync occurs
    /// Includes both import (remote → local) and export (local → remote) events
    private func setupNotificationObservers() {
        // Observe remote change notifications from CloudKit
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRemoteChange(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Handlers
    
    /// M7.1.2: Handle remote change notifications from CloudKit
    /// These fire when NSPersistentCloudKitContainer syncs data
    /// Updates sync state and tracks successful sync timestamp
    private func handleRemoteChange(_ notification: Notification) {
        syncEventCount += 1
        
        // Extract notification details for debugging
        if let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String {
            print("📡 CloudKit sync event #\(syncEventCount) - Store: \(storeUUID.prefix(8))...")
        } else {
            print("📡 CloudKit sync event #\(syncEventCount)")
        }
        
        // Check for transaction details
        if let historyToken = notification.userInfo?[NSPersistentHistoryTokenKey] {
            print("   History token present: \(historyToken)")
        }
        
        // Update sync state
        syncState = .synced
        lastSyncDate = Date()
        syncError = nil
        
        print("   ✅ Sync state updated: synced at \(lastSyncDate!)")
    }
    
    // MARK: - Manual Sync Trigger
    
    /// M7.1.2: Manually trigger sync state check
    /// Forces CloudKit to sync by saving the context
    /// NSPersistentCloudKitContainer will detect changes and sync
    func triggerManualSync(context: NSManagedObjectContext) {
        print("🔄 Manual sync triggered")
        syncState = .syncing
        
        // Save context to trigger CloudKit sync
        // NSPersistentCloudKitContainer monitors context saves and syncs changes
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Context saved - CloudKit will sync changes")
            } catch {
                print("❌ Failed to save context: \(error)")
                handleSyncError(error)
            }
        } else {
            // No changes, but still notify CloudKit to check for remote updates
            print("⚠️ No local changes - waiting for remote sync notification")
        }
        
        // Reset to idle after brief UI feedback if no notification received
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.syncState == .syncing {
                // If no notification received within 2 seconds, assume idle
                self?.syncState = .idle
                print("⚠️ Manual sync timeout - no notification received")
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// M7.1.2: Handle CloudKit errors with user-friendly messages
    /// Maps technical CKError codes to understandable error states
    /// Provides guidance for common sync failures
    func handleSyncError(_ error: Error) {
        syncError = error
        
        // Extract CloudKit error if present
        let ckError = (error as NSError)
        let errorCode = ckError.code
        let errorDomain = ckError.domain
        
        print("❌ CloudKit sync error: \(errorDomain) code \(errorCode)")
        print("   Error: \(error.localizedDescription)")
        
        // Map common CloudKit errors to user-friendly messages
        if errorDomain == CKError.errorDomain {
            let friendlyMessage = mapCloudKitError(errorCode: errorCode)
            syncState = .error(friendlyMessage)
            print("   User message: \(friendlyMessage)")
        } else {
            // Generic error handling
            syncState = .error(error.localizedDescription)
        }
    }
    
    /// M7.1.2: Map CKError codes to user-friendly messages
    /// Provides actionable guidance for common sync failures
    /// Returns appropriate error message based on error type
    private func mapCloudKitError(errorCode: Int) -> String {
        // Map CKError.Code cases (CloudKit framework errors)
        switch errorCode {
        case 3: // CKError.networkUnavailable
            return "Network unavailable. Sync will resume when online."
        case 4: // CKError.networkFailure
            return "Network error. Will retry automatically."
        case 9: // CKError.notAuthenticated
            return "Not signed into iCloud. Please sign in to enable sync."
        case 25: // CKError.quotaExceeded
            return "iCloud storage full. Please free up space to continue syncing."
        case 26: // CKError.zoneNotFound
            return "Sync zone not found. Recreating..."
        case 14: // CKError.serverRecordChanged
            return "Conflict detected. Will resolve automatically."
        case 2: // CKError.internalError
            return "CloudKit internal error. Will retry shortly."
        case 6: // CKError.serverRejectedRequest
            return "Server rejected request. Check CloudKit configuration."
        default:
            return "Sync error (code \(errorCode)). Will retry automatically."
        }
    }
    
    // MARK: - Testing Helpers
    
    /// M7.1.2: Reset sync state (for testing)
    /// Clears all sync tracking data
    func resetSyncState() {
        syncState = .idle
        lastSyncDate = nil
        syncError = nil
        syncEventCount = 0
        print("🔄 CloudKit sync state reset")
    }
    
    // MARK: - Debugging Helpers
    
    /// M7.1.2: Get formatted sync status for debugging
    /// Returns human-readable sync state summary
    func getDebugStatus() -> String {
        var status = "CloudKitSyncMonitor Status:\n"
        status += "  State: \(syncState)\n"
        status += "  Events: \(syncEventCount)\n"
        status += "  Last Sync: \(lastSyncDate?.formatted() ?? "Never")\n"
        if let error = syncError {
            status += "  Error: \(error.localizedDescription)\n"
        }
        return status
    }
}

// MARK: - PersistenceController Integration

extension PersistenceController {
    
    /// M7.1.2: Create CloudKitSyncMonitor for the main container
    /// Should be initialized once and shared across the app
    /// Access via PersistenceController.shared.syncMonitor
    static var syncMonitor: CloudKitSyncMonitor = {
        let monitor = CloudKitSyncMonitor()
        print("📡 CloudKitSyncMonitor created for PersistenceController")
        return monitor
    }()
}
