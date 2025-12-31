//
//  CloudKitDiagnostics.swift
//  forager
//
//  M7.2.3 Phase 1.4: Extracted from Persistence.swift
//  Single responsibility: CloudKit event observation and diagnostics
//
//  Created on December 30, 2025.
//

import CoreData
import CloudKit
import Combine

/// M7.2.3 Phase 1.4: CloudKit event observation and diagnostics
///
/// Responsibilities:
/// - Observe NSPersistentCloudKitContainer events
/// - Track sync progress, errors, and completion
/// - Provide UI-ready sync status information
/// - Support debug test harness
///
/// Does NOT handle:
/// - Container setup (see PersistenceCore)
/// - Default seeding (see DefaultSeeder)
/// - Data storage or modification
final class CloudKitDiagnostics: ObservableObject {
    
    // MARK: - Published Properties (UI-ready)
    
    /// Current sync status
    @Published private(set) var isSyncing: Bool = false
    
    /// Last sync error message (user-friendly)
    @Published private(set) var lastError: String?
    
    /// Last successful sync date
    @Published private(set) var lastSyncDate: Date?
    
    /// Total number of sync events observed
    @Published private(set) var eventCount: Int = 0
    
    /// Recent sync events (max 20)
    @Published private(set) var recentEvents: [SyncEvent] = []
    
    // MARK: - Sync Event Model
    
    /// Represents a CloudKit sync event for debugging
    struct SyncEvent: Identifiable {
        let id = UUID()
        let type: EventType
        let timestamp: Date
        let success: Bool
        let errorMessage: String?
        
        enum EventType: String {
            case setup = "Setup"
            case export = "Export"
            case importEvent = "Import"
            case unknown = "Unknown"
        }
    }
    
    // MARK: - Private Properties
    
    private var observer: NSObjectProtocol?
    private let container: NSPersistentCloudKitContainer
    
    // MARK: - Initialization
    
    /// Initialize diagnostics for a CloudKit container
    /// - Parameter container: The NSPersistentCloudKitContainer to observe
    init(container: NSPersistentCloudKitContainer) {
        self.container = container
        setupObserver()
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Event Observation
    
    /// Set up observer for CloudKit events
    private func setupObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { [weak self] notification in
            self?.handleCloudKitEvent(notification)
        }
        
        print("☁️ M7.2.3: CloudKit diagnostics observer active")
    }
    
    /// Handle incoming CloudKit event notification
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        // Update sync status
        if event.endDate == nil {
            isSyncing = true
        } else {
            isSyncing = false
            
            if event.succeeded {
                lastSyncDate = Date()
                lastError = nil
            } else if let error = event.error {
                lastError = userFriendlyError(from: error)
            }
        }
        
        // Track event
        eventCount += 1
        
        // Create sync event record
        let eventType = mapEventType(event.type)
        let syncEvent = SyncEvent(
            type: eventType,
            timestamp: Date(),
            success: event.succeeded,
            errorMessage: event.error?.localizedDescription
        )
        
        // Add to recent events (keep last 20)
        recentEvents.insert(syncEvent, at: 0)
        if recentEvents.count > 20 {
            recentEvents.removeLast()
        }
        
        // Log event
        logEvent(event)
    }
    
    // MARK: - Event Type Mapping
    
    /// Map CloudKit event type to our enum
    private func mapEventType(_ type: NSPersistentCloudKitContainer.EventType) -> SyncEvent.EventType {
        switch type {
        case .setup:
            return .setup
        case .export:
            return .export
        case .import:
            return .importEvent
        @unknown default:
            return .unknown
        }
    }
    
    // MARK: - Error Handling
    
    /// Convert CloudKit error to user-friendly message
    private func userFriendlyError(from error: Error) -> String {
        let nsError = error as NSError
        
        // Check for CloudKit-specific errors
        if nsError.domain == CKErrorDomain {
            return cloudKitErrorMessage(for: nsError.code)
        }
        
        // Default to localized description
        return error.localizedDescription
    }
    
    /// Get user-friendly message for CloudKit error codes
    private func cloudKitErrorMessage(for code: Int) -> String {
        switch code {
        case CKError.networkUnavailable.rawValue:
            return "No internet connection"
        case CKError.networkFailure.rawValue:
            return "Network error - please try again"
        case CKError.notAuthenticated.rawValue:
            return "Not signed into iCloud"
        case CKError.quotaExceeded.rawValue:
            return "iCloud storage full"
        case CKError.zoneBusy.rawValue:
            return "CloudKit busy - will retry automatically"
        case CKError.serviceUnavailable.rawValue:
            return "CloudKit service temporarily unavailable"
        default:
            return "Sync error (code \(code))"
        }
    }
    
    // MARK: - Logging
    
    /// Log CloudKit event to console
    private func logEvent(_ event: NSPersistentCloudKitContainer.Event) {
        let typeString = mapEventType(event.type).rawValue
        let statusString = event.succeeded ? "✅" : "❌"
        
        if let endDate = event.endDate {
            let duration = endDate.timeIntervalSince(event.startDate)
            print("☁️ M7.2.3: CloudKit \(typeString) \(statusString) (\(String(format: "%.2f", duration))s)")
        } else {
            print("☁️ M7.2.3: CloudKit \(typeString) started...")
        }
        
        if let error = event.error {
            print("   Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Helper Methods
    
    /// Manually trigger sync (for testing)
    func triggerSync() {
        print("☁️ M7.2.3: Manual sync trigger requested")
        // Note: NSPersistentCloudKitContainer doesn't have a public sync trigger
        // Sync happens automatically based on save operations
        // This is here for potential future use or custom sync logic
    }
    
    /// Clear recent events history
    func clearHistory() {
        recentEvents.removeAll()
        print("☁️ M7.2.3: Event history cleared")
    }
    
    /// Get sync status summary for debugging
    func getStatusSummary() -> String {
        var summary = "☁️ CLOUDKIT DIAGNOSTICS\n\n"
        
        summary += "Status: \(isSyncing ? "🔄 Syncing..." : "✅ Idle")\n"
        
        if let lastSync = lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            summary += "Last Sync: \(formatter.string(from: lastSync))\n"
        } else {
            summary += "Last Sync: Never\n"
        }
        
        if let error = lastError {
            summary += "Last Error: \(error)\n"
        } else {
            summary += "Last Error: None\n"
        }
        
        summary += "Total Events: \(eventCount)\n"
        summary += "Recent Events: \(recentEvents.count)\n"
        
        return summary
    }
}
