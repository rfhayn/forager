//
//  CloudKitSyncMonitor.swift
//  forager
//
//  Created for M7.1.2: CloudKitSyncMonitor Service
//  M7.2.3 Phase 3.8: Added automatic category deduplication
//  Purpose: Monitor CloudKit sync status, handle notifications, log events, remove duplicates
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
        #if DEBUG
        print("📡 CloudKitSyncMonitor initialized - monitoring remote changes")
        #endif
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

        // Observe mirroring delegate events (setup / import / export).
        // fix-groceryitem-multi-zone-assignment: emits a structured diagnostic
        // entry when the delegate fails with a zone-assignment error
        // (CoreData 134040 "objects assigned to multiple zones"), which is
        // fatal for CloudKit sync. Runs in both Debug and Release — catching
        // a zone conflict in a Release build is exactly when we want telemetry.
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Handlers
    
    /// M7.1.2: Handle remote change notifications from CloudKit
    /// M7.2.3 Phase 3.8: Added automatic deduplication after sync
    /// These fire when NSPersistentCloudKitContainer syncs data
    /// Updates sync state and tracks successful sync timestamp
    private func handleRemoteChange(_ notification: Notification) {
        syncEventCount += 1
        
        // Extract notification details for debugging
        if let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String {
            #if DEBUG
            print("📡 CloudKit sync event #\(syncEventCount) - Store: \(storeUUID.prefix(8))...")
            #endif
        } else {
            #if DEBUG
            print("📡 CloudKit sync event #\(syncEventCount)")
            #endif
        }
        
        // Check for transaction details
        if let historyToken = notification.userInfo?[NSPersistentHistoryTokenKey] {
            #if DEBUG
            print("   History token present: \(historyToken)")
            #endif
        }
        
        // Update sync state
        syncState = .synced
        lastSyncDate = Date()
        syncError = nil
        
        #if DEBUG
        print("   ✅ Sync state updated: synced at \(lastSyncDate!)")
        #endif
        
        // Run deduplication after import events (Category + Store).
        // Handles the case where multiple devices seeded simultaneously OR where
        // CloudKit sync races with DefaultSeeder's single-shot check produced
        // duplicate default rows.
        runAllDeduplication()
    }

    // MARK: - CloudKit Event Diagnostics
    //
    // fix-groceryitem-multi-zone-assignment (2026-04-21): detect mirroring
    // delegate failures that indicate zone-assignment corruption. This is the
    // class of bug that caused CoreData error 134040 "Object graph corruption
    // detected — objects assigned to multiple zones" on 2026-04-21. When that
    // error surfaces the delegate refuses to initialize and NO CloudKit sync
    // works at all. The diagnostic below logs the details so the user's log
    // file (shareable from Settings > Diagnostics) shows exactly which object
    // was in conflict.
    //
    // Does NOT attempt auto-repair — safer to surface for manual triage.

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }
        guard let error = event.error as NSError? else {
            return  // Success events are tracked by the remote-change observer
        }

        // Only surface zone-assignment failures here. Other sync errors are
        // logged by Apple's frameworks and handled elsewhere.
        let isZoneConflict = error.code == 134040 ||
            error.code == 134060 ||
            error.localizedDescription.lowercased().contains("multiple zones") ||
            (error.userInfo[NSLocalizedFailureReasonErrorKey] as? String)?
                .lowercased().contains("multiple zones") == true

        guard isZoneConflict else { return }

        let storeName = "store-\(event.storeIdentifier.prefix(8))"
        let eventKind: String = {
            switch event.type {
            case .setup: return "setup"
            case .import: return "import"
            case .export: return "export"
            @unknown default: return "unknown"
            }
        }()

        // Extract every piece of useful context from the NSError. Build 138's
        // diagnostic only grepped NSLocalizedFailureReasonErrorKey — that key is
        // populated for the setup-time alert flavor but NOT for the export-path
        // event we hit in the wild. Dump the fuller picture: domain, code,
        // localizedDescription, all userInfo keys, plus any NSUnderlyingError.
        // The persistent ID we need for targeted remediation often shows up in
        // the localizedDescription or an underlying error rather than the
        // top-level reason.
        let domain = error.domain
        let localizedDesc = error.localizedDescription
        let reason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? "(absent)"
        let userInfoKeys = error.userInfo.keys
            .map { String(describing: $0) }
            .sorted()
            .joined(separator: ",")
        let underlying: String = {
            guard let nested = error.userInfo[NSUnderlyingErrorKey] as? NSError else { return "nil" }
            return "{domain=\(nested.domain) code=\(nested.code) desc=\(nested.localizedDescription)}"
        }()
        // If any userInfo value names a Core Data URI, surface it — that's the
        // persistent ID we target for remediation.
        let uriHits: String = error.userInfo
            .compactMap { (_, value) -> String? in
                let str = String(describing: value)
                guard str.contains("x-coredata://") else { return nil }
                return str
            }
            .joined(separator: " | ")
        let uriSection = uriHits.isEmpty ? "" : " uris=[\(uriHits)]"

        // DiagnosticLogger is @MainActor; bounce through MainActor.run to log.
        // The enclosing sink already delivers on the main queue, but Swift
        // concurrency still requires an explicit isolation hop here.
        let logMessage = """
            🚨 Zone conflict detected — event=\(eventKind) store=\(storeName) \
            domain=\(domain) code=\(error.code) \
            desc=\"\(localizedDesc)\" \
            reason=\"\(reason)\" \
            userInfoKeys=[\(userInfoKeys)] \
            underlying=\(underlying)\(uriSection)
            """
        Task { @MainActor in
            DiagnosticLogger.shared.log(logMessage, category: .cloudKit, level: .error)
        }

        // Update UI-observable state so any diagnostic view can surface it.
        syncState = .error("CloudKit zone conflict (code \(error.code)). Check Settings > Diagnostics.")
        syncError = error

        #if DEBUG
        print("🚨 CloudKit zone conflict: \(localizedDesc)")
        #endif
    }

    // MARK: - Deduplication
    //
    // Registered deduplicators run on each remote-change notification on a
    // background context. All are best-effort: errors log and swallow so a
    // failing deduplicator never wedges sync. Add future deduplicators by
    // creating the service + a runXxxDeduplication() method + a call inside
    // runAllDeduplication().

    /// Run every registered deduplicator in sequence.
    /// Order: Category first (oldest service, M7.2.3), then Store (M18.2 /
    /// fix-no-store-default-duplicates). Sequencing isn't strictly required
    /// but it keeps log output predictable for debugging.
    private func runAllDeduplication() {
        runCategoryDeduplication()
        runStoreDeduplication()
    }

    /// Run CategoryDeduplicator on a background context. Idempotent.
    private func runCategoryDeduplication() {
        DispatchQueue.global(qos: .utility).async {
            let context = PersistenceController.shared.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true

            context.performAndWait {
                do {
                    let deduplicator = CategoryDeduplicator(context: context)
                    let deletedCount = try deduplicator.removeDuplicates()

                    if deletedCount > 0 {
                        DispatchQueue.main.async {
                            #if DEBUG
                            print("🧹 Auto-deduplication removed \(deletedCount) duplicate Categories")
                            #endif
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        #if DEBUG
                        print("⚠️ CategoryDeduplicator failed: \(error)")
                        #endif
                    }
                }
            }
        }
    }

    /// Run StoreDeduplicator on a background context. Idempotent.
    /// Introduced by fix-no-store-default-duplicates (2026-04-23) after a
    /// device accumulated 5 duplicate "No Store" default rows through a
    /// combination of DefaultSeeder CloudKit-import races and the old
    /// HouseholdService.copyPersonalDataToHousehold blind-clone bug.
    private func runStoreDeduplication() {
        DispatchQueue.global(qos: .utility).async {
            let context = PersistenceController.shared.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true

            context.performAndWait {
                do {
                    let deduplicator = StoreDeduplicator(context: context)
                    let deletedCount = try deduplicator.removeDuplicates()

                    if deletedCount > 0 {
                        DispatchQueue.main.async {
                            #if DEBUG
                            print("🧹 Auto-deduplication removed \(deletedCount) duplicate Stores")
                            #endif
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        #if DEBUG
                        print("⚠️ StoreDeduplicator failed: \(error)")
                        #endif
                    }
                }
            }
        }
    }
    
    // MARK: - Manual Sync Trigger
    
    /// M7.1.2: Manually trigger sync state check
    /// Forces CloudKit to sync by saving the context
    /// NSPersistentCloudKitContainer will detect changes and sync
    func triggerManualSync(context: NSManagedObjectContext) {
        #if DEBUG
        print("🔄 Manual sync triggered")
        #endif
        syncState = .syncing
        
        // Save context to trigger CloudKit sync
        // NSPersistentCloudKitContainer monitors context saves and syncs changes
        if context.hasChanges {
            do {
                try context.save()
                #if DEBUG
                print("✅ Context saved - CloudKit will sync changes")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to save context: \(error)")
                #endif
                handleSyncError(error)
            }
        } else {
            // No changes, but still notify CloudKit to check for remote updates
            #if DEBUG
            print("⚠️ No local changes - waiting for remote sync notification")
            #endif
        }
        
        // Reset to idle after brief UI feedback if no notification received
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.syncState == .syncing {
                // If no notification received within 2 seconds, assume idle
                self?.syncState = .idle
                #if DEBUG
                print("⚠️ Manual sync timeout - no notification received")
                #endif
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
        
        #if DEBUG
        print("❌ CloudKit sync error: \(errorDomain) code \(errorCode)")
        print("   Error: \(error.localizedDescription)")
        #endif
        
        // Map common CloudKit errors to user-friendly messages
        if errorDomain == CKError.errorDomain {
            let friendlyMessage = mapCloudKitError(errorCode: errorCode)
            syncState = .error(friendlyMessage)
            #if DEBUG
            print("   User message: \(friendlyMessage)")
            #endif
        } else {
            // Generic error handling
            syncState = .error(error.localizedDescription)
        }
    }
    
    /// M7.3.4: Map CKError codes to user-friendly messages (updated to use CloudKitErrorMapper)
    /// Provides actionable guidance for common sync failures
    /// Returns appropriate error message based on error type
    private func mapCloudKitError(errorCode: Int) -> String {
        // M7.3.4: Delegate to centralized mapper to avoid duplicate code and magic numbers
        return CloudKitErrorMapper.message(forCode: errorCode)
    }
    
    // MARK: - Testing Helpers
    
    /// M7.1.2: Reset sync state (for testing)
    /// Clears all sync tracking data
    func resetSyncState() {
        syncState = .idle
        lastSyncDate = nil
        syncError = nil
        syncEventCount = 0
        #if DEBUG
        print("🔄 CloudKit sync state reset")
        #endif
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
        #if DEBUG
        print("📡 CloudKitSyncMonitor created for PersistenceController")
        #endif
        return monitor
    }()
}
