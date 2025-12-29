//
//  CloudKitSyncTestView.swift
//  forager
//
//  Created for M7.1.2: CloudKitSyncMonitor Service Testing
//  Purpose: Visual interface for testing sync monitoring and observing CloudKit events
//

import SwiftUI
import CoreData

// MARK: - CloudKitSyncTestView

/// M7.1.2: Test interface for CloudKitSyncMonitor
/// Displays sync status, event count, and error messages
/// Provides controls for manual sync trigger and state reset
struct CloudKitSyncTestView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // M7.1.2: Access sync monitor from environment (injected in foragerApp)
    @EnvironmentObject private var syncMonitor: CloudKitSyncMonitor
    
    // MARK: - State Variables
    
    @State private var testDataResult = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Sync Status Section
                Section("Sync Status") {
                    syncStatusRow
                    lastSyncRow
                    eventCountRow
                }
                
                // Error Section (if present)
                if syncMonitor.syncError != nil {
                    Section("Sync Error") {
                        errorRow
                    }
                }
                
                // Controls Section
                Section("Actions") {
                    manualSyncButton
                    resetStateButton
                    createTestDataButton
                }
                
                // Debug Info Section
                Section("Debug Information") {
                    debugInfoRow
                }
                
                // Instructions Section
                Section("Testing Instructions") {
                    instructionsText
                }
            }
            .navigationTitle("CloudKit Sync Monitor")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - View Components
    
    /// Sync status indicator with color-coded badge
    private var syncStatusRow: some View {
        HStack {
            Text("Status")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(syncStateColor)
                    .frame(width: 12, height: 12)
                
                Text(syncStateText)
                    .font(.headline)
            }
        }
    }
    
    /// Last sync timestamp
    private var lastSyncRow: some View {
        HStack {
            Text("Last Sync")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let lastSync = syncMonitor.lastSyncDate {
                Text(lastSync, style: .relative)
                    .font(.subheadline)
            } else {
                Text("Never")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    /// Sync event counter
    private var eventCountRow: some View {
        HStack {
            Text("Events Observed")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(syncMonitor.syncEventCount)")
                .font(.headline)
                .foregroundStyle(.blue)
        }
    }
    
    /// Error message display
    private var errorRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            if case .error(let message) = syncMonitor.syncState {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            
            if let error = syncMonitor.syncError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// Manual sync trigger button
    private var manualSyncButton: some View {
        Button {
            syncMonitor.triggerManualSync(context: viewContext)
        } label: {
            Label("Trigger Manual Sync", systemImage: "arrow.triangle.2.circlepath")
        }
    }
    
    /// Reset sync state button
    private var resetStateButton: some View {
        Button(role: .destructive) {
            syncMonitor.resetSyncState()
        } label: {
            Label("Reset Sync State", systemImage: "arrow.counterclockwise")
        }
    }
    
    /// Create test data button
    private var createTestDataButton: some View {
        Button {
            createTestData()
        } label: {
            Label("Create Test Data", systemImage: "plus.circle")
        }
    }
    
    /// Debug information text
    private var debugInfoRow: some View {
        Text(syncMonitor.getDebugStatus())
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
    }
    
    /// Testing instructions
    private var instructionsText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Single-Device Sync Testing:")
                .font(.headline)
            
            Group {
                Text("1. Tap 'Create Test Data' to add a weekly list")
                Text("2. Watch for sync status change to 'Synced'")
                Text("3. Check CloudKit Dashboard for CD_WeeklyList records")
                Text("4. Delete the list and verify deletion syncs")
                Text("5. Observe event count incrementing with each sync")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Color for sync state indicator
    private var syncStateColor: Color {
        switch syncMonitor.syncState {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .error:
            return .red
        }
    }
    
    /// Text for sync state display
    private var syncStateText: String {
        switch syncMonitor.syncState {
        case .idle:
            return "Idle"
        case .syncing:
            return "Syncing"
        case .synced:
            return "Synced"
        case .error:
            return "Error"
        }
    }
    
    // MARK: - Test Data Creation
    
    /// M7.1.2: Create test weekly list for sync validation
    /// Creates list with items to trigger CloudKit sync
    /// Should observe sync notification after save
    private func createTestData() {
        // Create WeeklyList
        let list = WeeklyList(context: viewContext)
        list.id = UUID()
        list.name = "CloudKit Test List"
        list.dateCreated = Date()
        list.isCompleted = false
        
        // Add test items using GroceryItem entity
        let item1 = GroceryItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Test Item 1"
        item1.category = "Produce"
        item1.isStaple = false
        item1.dateCreated = Date()
        
        let item2 = GroceryItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Test Item 2"
        item2.category = "Dairy & Fridge"
        item2.isStaple = false
        item2.dateCreated = Date()
        
        do {
            try viewContext.save()
            testDataResult = "✅ Test list created - watch for sync!"
            print("✅ Created test weekly list with 2 items")
            print("   Waiting for CloudKit sync notification...")
        } catch {
            testDataResult = "❌ Failed to create test data: \(error.localizedDescription)"
            print("❌ Failed to create test data: \(error)")
            syncMonitor.handleSyncError(error)
        }
    }
}

struct CloudKitSyncTestView_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitSyncTestView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(CloudKitSyncMonitor())
    }
}
