//
// HouseholdService.swift
// forager
//
// M7.2.1: Household management service
// Handles household creation, member invitation, and CloudKit shared zone setup
//

import Foundation
import CoreData
import CloudKit
import UIKit  // For UIDevice.current.name
import UserNotifications  // M7.2.2: For member left notifications
import Combine  // M7.2.2: For real-time sync observation
import Network  // M7.3.4: For connectivity check before CloudKit operations

// MARK: - Household Errors

enum HouseholdError: LocalizedError {
    case noShareRecord
    case notOwner
    case cloudKitUnavailable
    case emailNotFound
    case creationFailed(String)
    case invitationFailed(String)
    case alreadyMember
    case invitationPending
    case noInvitation
    case noInvitationURL
    case emptyName
    case nameTooLong
    case notMember
    case ownerCannotLeave
    case cannotRemoveSelf
    case cannotRemoveOwner
    case alreadyInHousehold

    var errorDescription: String? {
        switch self {
        case .noShareRecord:
            return "Household does not have a CloudKit share record"
        case .notOwner:
            return "Only the household owner can perform this action"
        case .cloudKitUnavailable:
            return "CloudKit is not available. Please check iCloud settings."
        case .emailNotFound:
            return "Could not retrieve user email from iCloud"
        case .creationFailed(let reason):
            return "Failed to create household: \(reason)"
        case .invitationFailed(let reason):
            return "Failed to send invitation: \(reason)"
        case .alreadyMember:
            return "This person is already a member of the household"
        case .invitationPending:
            return "An invitation is already pending for this email"
        case .noInvitation:
            return "No pending invitation found"
        case .noInvitationURL:
            return "Failed to generate invitation URL"
        case .emptyName:
            return "Household name cannot be empty"
        case .nameTooLong:
            return "Household name must be 50 characters or less"
        case .notMember:
            return "You are not a member of this household"
        case .ownerCannotLeave:
            return "Owners cannot leave. Delete the household instead."
        case .cannotRemoveSelf:
            return "You cannot remove yourself. Use 'Leave Household' instead."
        case .cannotRemoveOwner:
            return "The household owner cannot be removed."
        case .alreadyInHousehold:
            return "You are already in a household. Leave or delete it first before joining another."
        }
    }
}

// MARK: - Household Service

@MainActor
class HouseholdService: ObservableObject {
    
    // MARK: - Properties

    private let viewContext: NSManagedObjectContext
    private let container: CKContainer

    @Published var currentHousehold: Household?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var creationStatus: String?

    private var cancellables = Set<AnyCancellable>()

    // M7.2.2: Debounce timer to avoid processing leave requests on every sync event
    private var leaveRequestCheckTimer: Timer?
    // M7.2.2: Track known participant record IDs to detect departures
    private var knownParticipantRecordIDs: Set<String>?
    // M7.3.4: Network monitor for processing pending leaves when connectivity returns
    private var networkMonitor: NWPathMonitor?

    // M7.2.2: Keychain-backed left-household tracking (survives reinstalls)
    private func markHouseholdAsLeft(_ householdID: String) {
        KeychainHelper.markHouseholdAsLeft(householdID)
        #if DEBUG
        print("📝 M7.2.2: Marked household \(householdID) as left (Keychain — survives reinstall)")
        #endif
    }

    private func hasLeftHousehold(_ householdID: String) -> Bool {
        return KeychainHelper.hasLeftHousehold(householdID)
    }

    func clearLeftHouseholdFlag(_ householdID: String) {
        KeychainHelper.clearLeftHouseholdFlag(householdID)
        #if DEBUG
        print("📝 M7.2.2: Cleared left flag for household \(householdID)")
        #endif
    }

    // M7.2.2 FIX: Derived household key with fallback
    // When household syncs from CloudKit, the UUID `id` attribute may be nil
    // but related data (recipes, etc.) have the correct householdKey string
    // This computed property provides a reliable key even when household.id is nil
    var currentHouseholdKey: String? {
        // First try: household.id (the direct way)
        if let key = currentHousehold?.id?.uuidString {
            return key
        }

        // Fallback: derive key from synced recipes that have householdKey set
        // This works because householdKey is a STRING that syncs correctly
        guard let household = currentHousehold else { return nil }

        // Try to get key from any related recipe
        if let recipes = household.recipes as? Set<Recipe>,
           let firstRecipe = recipes.first(where: { $0.householdKey != nil }) {
            let derivedKey = firstRecipe.householdKey
            #if DEBUG
            print("⚠️ M7.2.2: household.id is nil, derived key from recipe: \(derivedKey ?? "nil")")
            #endif
            return derivedKey
        }

        // Try to get key from any related ingredient template
        if let templates = household.ingredientTemplates as? Set<IngredientTemplate>,
           let firstTemplate = templates.first(where: { $0.householdKey != nil }) {
            let derivedKey = firstTemplate.householdKey
            #if DEBUG
            print("⚠️ M7.2.2: household.id is nil, derived key from template: \(derivedKey ?? "nil")")
            #endif
            return derivedKey
        }

        #if DEBUG
        print("⚠️ M7.2.2: Could not derive household key - no data with householdKey found")
        #endif
        return nil
    }
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.container = CKContainer(identifier: "iCloud.com.richhayn.forager")

        // Load current household on init
        Task {
            await loadCurrentHousehold()
            // M7.3.4: Process any pending leaves from offline sessions
            await processPendingLeaves()
        }

        // M7.2.2: Listen for CloudKit sync events to process leave requests in real-time
        // Debounced to 5 seconds so we don't run on every sync event (100+ per session)
        setupSyncObserver()

        // M7.3.4: Monitor connectivity to process pending leaves when online
        setupConnectivityMonitor()
    }

    // M7.3.4: Monitor network connectivity to process pending leaves when coming online
    private func setupConnectivityMonitor() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { @MainActor [weak self] in
                    await self?.processPendingLeaves()
                }
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global(qos: .utility))
    }

    // M7.2.2: Observe CloudKit sync events and check for member departures
    // Uses debounce so rapid sync events (common during initial sync) don't trigger
    // repeated processing — only fires once after sync activity settles
    private func setupSyncObserver() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scheduleMemberDepartureCheck()
            }
            .store(in: &cancellables)
    }

    // M7.2.2: Debounced departure check — waits 5 seconds after last sync event
    private func scheduleMemberDepartureCheck() {
        leaveRequestCheckTimer?.invalidate()
        leaveRequestCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForMemberDepartures()
            }
        }
    }
    
    // MARK: - Household Management
    
    /// Loads the current user's household (if any)
    /// M7.2.2 Refactor: Uses CKShare.participants as source of truth for membership
    /// Fallback: If household is in shared store, user is a participant (CloudKit synced it)
    /// Also checks local "left households" list to prevent re-joining after leaving
    func loadCurrentHousehold() async {
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1

        do {
            let households = try viewContext.fetch(request)

            if let household = households.first {
                // M7.2.2 FIX: Check if user has locally "left" this household
                // CloudKit limitation: Members can't remove themselves from CKShare.participants
                // So we track left households locally to prevent re-joining
                if let householdID = household.id?.uuidString, hasLeftHousehold(householdID) {
                    // M7.3.4 FIX: Check if user is still CKShare participant
                    // If they are, it means server-side leave failed - DON'T auto-rejoin
                    let isParticipant = await isCurrentUserParticipant(in: household)
                    if isParticipant {
                        // M7.3.4: User marked as left but still participant on server
                        // This means server-side leave failed. Don't auto-clear flag.
                        // User must explicitly accept a new invitation to rejoin.
                        CloudKitLogger.ghostDataDetected(householdID: householdID)
                        CloudKitLogger.warning("Server-side leave may have failed. User must accept new invitation to rejoin")
                        currentHousehold = nil
                        return
                    } else {
                        // Genuinely left — purge ghost data
                        currentHousehold = nil
                        CloudKitLogger.info("Household '\(household.name ?? "Unknown")' found but user has left it locally")
                        // Purge shared store objects from context
                        // Don't destroy store - causes crashes when re-joining
                        PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
                        CloudKitLogger.sharedStorePurged()
                        return
                    }
                }

                // M7.2.2 Refactor: Check membership via CKShare, not HouseholdMember records
                let isMember = await isCurrentUserParticipant(in: household)

                if isMember {
                    currentHousehold = household

                    // M7.6.5: One-time migration from ownerEmail to ownerRecordName
                    if household.ownerRecordName == nil, let legacy = household.ownerEmail, !legacy.isEmpty {
                        household.ownerRecordName = legacy
                        try? viewContext.save()
                    }

                    // M7.6.8: Migrate ownerEmail from recordName to display name
                    // Pre-M7.6.8 households stored ownerIdentifier in ownerEmail.
                    // If it still looks like a recordName (starts with "_"), overwrite
                    // with the cached display name so the shared root record carries a
                    // human-readable name for other participants to see.
                    if let current = household.ownerDisplayName,
                       current.hasPrefix("_"),
                       let cached = UserDefaults.standard.string(forKey: "cachedOwnerDisplayName"),
                       !cached.isEmpty, cached != "Me", cached != "You", cached != "User" {
                        household.ownerDisplayName = cached
                        try? viewContext.save()
                    }

                    CloudKitLogger.householdLoaded(household.name, householdID: household.id?.uuidString ?? "NIL")

                    if let storeURL = household.objectID.persistentStore?.url {
                        CloudKitLogger.debug("Store: \(storeURL.lastPathComponent)")
                    }

                    // Initialize known participants for departure detection
                    do {
                        let share = try await getShare(for: household)
                        let ids = Set(share.participants.compactMap {
                            $0.userIdentity.userRecordID?.recordName
                        })
                        knownParticipantRecordIDs = ids
                        CloudKitLogger.debug("Participants: \(share.participants.count)")
                    } catch {
                        let participantCount = await getParticipantCount(for: household)
                        CloudKitLogger.debug("Participants: \(participantCount) (could not init departure tracking)")
                    }

                    // M7.2.2: Check for member departures via CKShare polling (owner-only)
                    await checkForMemberDepartures()
                } else {
                    currentHousehold = nil
                    CloudKitLogger.info("Household exists but user is not a participant (left or removed)")
                }
            } else {
                currentHousehold = nil
            }
        } catch {
            CloudKitLogger.error("Error loading household", error: error)
            errorMessage = "Failed to load household"
            currentHousehold = nil
        }
    }

    /// M7.3.1: Renames a household (owner-only operation)
    /// - Parameters:
    ///   - household: The household to rename
    ///   - newName: The new household name (1-50 characters)
    /// - Throws: HouseholdError if not owner or invalid name
    func renameHousehold(_ household: Household, to newName: String) async throws {
        // Verify owner
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        // Validate name
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw HouseholdError.emptyName
        }

        guard trimmedName.count <= 50 else {
            throw HouseholdError.nameTooLong
        }

        // Update name
        household.name = trimmedName
        try viewContext.save()

        // CloudKit syncs automatically via NSPersistentCloudKitContainer
        #if DEBUG
        print("✅ M7.3.1: Household renamed to: \(trimmedName)")
        #endif
    }

    /// M10.6.7: Saves or clears the shared LLM API key for the household
    /// Only the household owner can set this — the key syncs to all members via CloudKit
    /// - Parameters:
    ///   - key: The API key to save, or nil/empty to clear
    ///   - household: The household to update
    /// - Throws: HouseholdError if not owner
    func saveLLMAPIKey(_ key: String?, to household: Household) async throws {
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines)
        household.llmAPIKey = (trimmed?.isEmpty == false) ? trimmed : nil
        try viewContext.save()

        // CloudKit syncs automatically via NSPersistentCloudKitContainer
        #if DEBUG
        print("✅ M10.6.7: Household LLM API key \(household.llmAPIKey != nil ? "saved" : "cleared")")
        #endif
    }

    /// M7.3.2: Allows a member to leave a household
    /// M7.2.2 Refactor: Now uses CKShare.participants instead of HouseholdMember records
    /// - Parameters:
    ///   - household: The household to leave
    ///   - migrateData: Whether to migrate household data to personal store
    /// - Throws: HouseholdError if user is owner or not a member
    func leaveHousehold(_ household: Household, migrateData: Bool) async throws {
        // M7.2.2 Refactor: Verify membership via CKShare.participants (source of truth)
        guard await isCurrentUserParticipant(in: household) else {
            throw HouseholdError.notMember
        }

        // Prevent owner from leaving (must delete household instead)
        // M7.2.2 Refactor: Use isOwner() which checks CKShare.currentUserParticipant.role
        guard await !isOwner(household: household) else {
            throw HouseholdError.ownerCannotLeave
        }

        let householdID = household.id?.uuidString ?? "unknown"
        CloudKitLogger.leaveAttemptStarted(householdID: householdID)

        // Step 1: Migrate data BEFORE stopping participation (while we still have access)
        if migrateData {
            try await migrateHouseholdDataToPersonal(household)
            try viewContext.save()
            CloudKitLogger.debug("Migrated household data to personal store")
        }

        // Step 2: Delete the CKShare record from the member's shared database.
        // This is CloudKit's intended mechanism for a participant to leave a share.
        // It bypasses NSPersistentCloudKitContainer's mirroring delegate entirely (direct CKDatabase op)
        // and automatically updates the owner's CKShare.participants list.
        // M7.3.4: If offline, this queues the operation for when connectivity returns.
        do {
            let share = try await getShare(for: household)
            try await deleteCKShareFromSharedDatabase(share, householdID: householdID)
            CloudKitLogger.debug("Deleted CKShare from shared database (left share)")
        } catch {
            // Non-fatal — local cleanup still proceeds so the UI is correct on this device.
            // M7.3.4: If offline, the leave was queued and will execute when online.
            // Owner will eventually detect departure or member can be manually removed.
            CloudKitLogger.shareFailed(operation: "leaveHousehold-deleteCKShare", error: error)
            CloudKitLogger.warning("Proceeding with local cleanup (pending leave queued if offline)")
        }

        // Step 3: Clear current household FIRST so UI stops referencing shared objects
        currentHousehold = nil

        // Step 4: Mark household as "left" in Keychain (survives app reinstall)
        markHouseholdAsLeft(householdID)

        // Step 5: Delete data by householdKey (M7.3.3 FIX)
        // This ensures orphaned data is cleaned up regardless of store location
        // Prevents duplicates if user rejoins the same household later
        let deletedByKey = deleteHouseholdLinkedData(householdKey: householdID)
        CloudKitLogger.debug("Deleted \(deletedByKey) objects with householdKey=\(householdID)")

        // Step 6: Also purge any remaining shared store objects
        let deletedFromStore = PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
        CloudKitLogger.debug("Purged \(deletedFromStore) shared store objects")

        // Step 7: Reset context BEFORE destroying shared store (M7.3.3)
        // This clears all in-memory managed object references, preventing crashes
        // when SwiftUI tries to access objects from the destroyed store
        viewContext.reset()
        CloudKitLogger.debug("Reset viewContext to clear in-memory references")

        // Step 8: Destroy and recreate shared store to clear local SQLite cache (M7.3.3)
        do {
            try PersistenceController.shared.destroyAndRecreateSharedStore()
            CloudKitLogger.debug("Destroyed and recreated shared store")
        } catch {
            CloudKitLogger.error("Failed to recreate shared store", error: error)
        }

        CloudKitLogger.leaveCompleted(householdID: householdID, migratedData: migrateData)
    }

    // MARK: - M7.3.3: Remove Member & Delete Household

    /// M7.3.3: Removes a member from the household (owner-only)
    /// Uses CKShare participant removal — CloudKit revokes the member's access
    /// - Parameters:
    ///   - participant: The ShareParticipant to remove
    ///   - household: The household to remove them from
    func removeMember(_ participant: ShareParticipant, from household: Household) async throws {
        // Verify current user is owner
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        // Cannot remove the owner
        guard !participant.isOwner else {
            throw HouseholdError.cannotRemoveOwner
        }

        // Cannot remove yourself (use leave instead)
        guard !participant.isCurrentUser else {
            throw HouseholdError.cannotRemoveSelf
        }

        let share = try await getShare(for: household)

        // Find matching CKShare.Participant by userRecordID
        guard let ckParticipant = share.participants.first(where: {
            $0.userIdentity.userRecordID?.recordName == participant.id
        }) else {
            CloudKitLogger.warning("Could not find CKShare participant for \(participant.displayName)")
            throw HouseholdError.notMember
        }

        // Remove participant from share
        share.removeParticipant(ckParticipant)

        // Persist updated share
        let persistenceController = PersistenceController.shared
        let privateStore = persistenceController.privateStore
        try await persistenceController.container.persistUpdatedShare(share, in: privateStore)

        CloudKitLogger.memberRemoved(householdID: household.id?.uuidString ?? "unknown")

        // Update known participants for departure detection
        knownParticipantRecordIDs?.remove(participant.id)
    }

    /// M7.3.3: Deletes a household entirely (owner-only)
    /// Removes CloudKit share (revokes all participants), deletes household entity,
    /// and purges the shared store
    /// - Parameters:
    ///   - household: The household to delete
    ///   - migrateData: Whether to migrate household data to personal store first
    func deleteHousehold(_ household: Household, migrateData: Bool) async throws {
        // Verify current user is owner
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        let householdKey = household.id?.uuidString ?? "unknown"
        CloudKitLogger.deleteAttemptStarted(householdID: householdKey)

        // Step 1: Migrate data if requested, otherwise delete household-linked data
        if migrateData {
            try await migrateHouseholdDataToPersonal(household)
            try viewContext.save()
            CloudKitLogger.debug("Migrated household data to personal store")

            // M7.3.3 FIX: Delete old household-keyed data AFTER migration
            // This prevents CategoryDeduplicator from finding duplicates between
            // the new personal copies (householdKey=nil) and old household copies
            let deletedOld = deleteHouseholdLinkedData(householdKey: householdKey)
            CloudKitLogger.debug("Cleaned up \(deletedOld) old household-keyed objects")
        } else {
            // Clean delete: remove all data with this householdKey from private store
            let deletedCount = deleteHouseholdLinkedData(householdKey: householdKey)
            CloudKitLogger.debug("Deleted \(deletedCount) household-linked objects (clean delete)")
        }

        // Step 2: Delete CKShare from private database (revokes all participants' access)
        do {
            let share = try await getShare(for: household)
            let privateDB = container.privateCloudDatabase

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [share.recordID])
                deleteOp.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        if let ckError = error as? CKError,
                           ckError.code == .unknownItem || ckError.code == .zoneNotFound {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                privateDB.add(deleteOp)
            }
            CloudKitLogger.debug("Deleted CKShare from private database")
        } catch {
            CloudKitLogger.shareFailed(operation: "deleteHousehold-deleteCKShare", error: error)
            CloudKitLogger.warning("Proceeding with local cleanup")
        }

        // Step 3: Clear current household FIRST so UI stops referencing shared objects
        currentHousehold = nil
        knownParticipantRecordIDs = nil

        // Step 4: Delete household entity
        viewContext.delete(household)
        try viewContext.save()

        // Step 5: Purge shared store objects from context
        // Don't destroy store - causes crashes if user creates a new household later
        let deletedCount = PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
        CloudKitLogger.debug("Purged \(deletedCount) shared store objects")

        CloudKitLogger.deleteCompleted(householdID: householdKey, migratedData: migrateData)
    }

    /// M7.2.2: Deletes the CKShare record from the member's shared database.
    /// This is CloudKit's intended mechanism for a non-owner to leave a share.
    /// Bypasses NSPersistentCloudKitContainer (direct CKDatabase operation) so it
    /// cannot poison the mirroring delegate. CloudKit automatically updates the
    /// owner's CKShare.participants list when the member deletes their copy.
    /// M7.3.4: Check connectivity first - if offline, queue for later and skip
    private func deleteCKShareFromSharedDatabase(_ share: CKShare, householdID: String) async throws {
        // M7.3.4: Check network connectivity before attempting CloudKit operation
        // CKModifyRecordsOperation queues indefinitely when offline - queue for later
        guard await hasNetworkConnectivity() else {
            CloudKitLogger.warning("No network connectivity - queuing CKShare delete for later")
            KeychainHelper.addPendingLeave(householdID: householdID, share: share)
            throw CKError(.networkUnavailable)
        }

        let sharedDB = container.sharedCloudDatabase

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [share.recordID])
            deleteOp.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    // "Unknown item" or "zone not found" means already left — treat as success
                    if let ckError = error as? CKError,
                       ckError.code == .unknownItem || ckError.code == .zoneNotFound {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
            sharedDB.add(deleteOp)
        }
    }

    /// M7.3.4: Quick network connectivity check using NWPathMonitor
    /// Returns true if device has network connectivity, false if offline
    /// Used to skip CloudKit operations that would hang when offline
    private func hasNetworkConnectivity() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: DispatchQueue.global(qos: .utility))
        }
    }

    /// M7.3.4: Process any pending leave operations that were queued while offline
    /// Call this on app launch and when connectivity is restored
    func processPendingLeaves() async {
        let pending = KeychainHelper.pendingLeaves()
        guard !pending.isEmpty else { return }

        CloudKitLogger.info("Processing \(pending.count) pending leave(s)...")

        // Check connectivity first
        guard await hasNetworkConnectivity() else {
            CloudKitLogger.debug("Still offline - pending leaves will be processed when online")
            return
        }

        let sharedDB = container.sharedCloudDatabase

        for leave in pending {
            let zoneID = CKRecordZone.ID(zoneName: leave.shareZoneName, ownerName: leave.shareZoneOwner)
            let recordID = CKRecord.ID(recordName: leave.shareRecordName, zoneID: zoneID)

            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
                    deleteOp.modifyRecordsResultBlock = { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            // "Unknown item" or "zone not found" means already processed
                            if let ckError = error as? CKError,
                               ckError.code == .unknownItem || ckError.code == .zoneNotFound {
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                    sharedDB.add(deleteOp)
                }
                CloudKitLogger.info("Processed pending leave for household \(leave.householdID)")
                KeychainHelper.removePendingLeave(householdID: leave.householdID)
            } catch {
                CloudKitLogger.error("Failed to process pending leave for \(leave.householdID)", error: error)
                // Keep in queue to retry later
            }
        }
    }

    // MARK: - Member Departure Detection (M7.2.2)

    /// Gets the current user's CloudKit record ID
    private func getCurrentUserRecordID() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            container.fetchUserRecordID { recordID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let recordID = recordID else {
                    continuation.resume(throwing: HouseholdError.emailNotFound)
                    return
                }
                continuation.resume(returning: recordID.recordName)
            }
        }
    }

    /// M7.2.2: Checks for member departures via CKShare participant polling (owner-only).
    /// Non-owners check if they've been removed from the household.
    func checkForMemberDepartures() async {
        guard let household = currentHousehold else {
            return
        }

        // M7.3.3: Non-owners check if they've been removed
        if await !isOwner(household: household) {
            await checkIfRemovedFromHousehold(household: household)
            return
        }

        // Primary departure detection — check CKShare participants directly (owner-only)
        await detectParticipantDepartures(household: household)
    }

    /// M7.3.3: Checks if the current user has been removed from the household
    /// Called on non-owner devices when sync events arrive
    private func checkIfRemovedFromHousehold(household: Household) async {
        let isParticipant = await isCurrentUserParticipant(in: household)

        if !isParticipant {
            #if DEBUG
            print("👋 M7.3.3: Detected removal from household — cleaning up")
            #endif

            // Capture householdKey before clearing currentHousehold
            let householdKey = household.id?.uuidString

            // Clear current household so UI shows "Create Household"
            currentHousehold = nil
            #if DEBUG
            print("✅ M7.3.3: Household cleared — UI will show 'Create Household'")
            #endif

            // Mark this household as "left" so we don't re-join on next sync
            if let householdID = householdKey {
                markHouseholdAsLeft(householdID)
            }

            // M7.3.3 FIX: Delete data by householdKey (not just purge shared store)
            // CloudKit may have already cleaned up the shared store, but orphaned
            // data with householdKey can remain and cause duplicates on rejoin
            if let key = householdKey {
                let deletedByKey = deleteHouseholdLinkedData(householdKey: key)
                #if DEBUG
                print("✅ M7.3.3: Deleted \(deletedByKey) objects with householdKey=\(key)")
                #endif
            }

            // Also purge any remaining shared store objects
            let deletedFromStore = PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
            #if DEBUG
            print("✅ M7.3.3: Purged \(deletedFromStore) shared store objects")
            #endif

            // M7.3.3 FIX: Reset context BEFORE destroying shared store
            // This clears all in-memory managed object references, preventing crashes
            // when SwiftUI tries to access objects from the destroyed store
            viewContext.reset()
            #if DEBUG
            print("✅ M7.3.3: Reset viewContext to clear in-memory references")
            #endif

            // M7.3.3 FIX: Destroy and recreate shared store to clear local SQLite cache
            // This is more aggressive but necessary to prevent duplicates on rejoin
            // CloudKit will re-sync fresh data when user rejoins
            do {
                try PersistenceController.shared.destroyAndRecreateSharedStore()
                #if DEBUG
                print("✅ M7.3.3: Destroyed and recreated shared store")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ M7.3.3: Failed to recreate shared store: \(error)")
                #endif
            }
        }
    }

    // M7.2.2: Primary mechanism for detecting member departures on owner's device.
    // Compares current CKShare participants against known set by record ID.
    private func detectParticipantDepartures(household: Household) async {
        do {
            let share = try await getShare(for: household)
            let currentIDs = Set(share.participants.compactMap {
                $0.userIdentity.userRecordID?.recordName
            })

            if let knownIDs = knownParticipantRecordIDs {
                let departed = knownIDs.subtracting(currentIDs)
                if !departed.isEmpty {
                    #if DEBUG
                    print("👋 M7.2.2: Detected \(departed.count) participant departure(s)")
                    #endif

                    // Log remaining participants
                    for p in share.participants {
                        let name = p.userIdentity.nameComponents.map {
                            PersonNameComponentsFormatter().string(from: $0)
                        } ?? p.userIdentity.userRecordID?.recordName ?? "Unknown"
                        #if DEBUG
                        print("   Remaining: \(name) (\(p.role == .owner ? "Owner" : "Member"))")
                        #endif
                    }

                    for departedID in departed {
                        #if DEBUG
                        print("   Departed: \(departedID)")
                        #endif
                    }

                    await sendMemberLeftNotification(
                        memberName: departed.count == 1 ? "A member" : "\(departed.count) members",
                        householdName: household.name ?? "household"
                    )
                }
            }

            knownParticipantRecordIDs = currentIDs
        } catch {
            // Non-fatal — CKShare fetch can fail if network is unavailable
            #if DEBUG
            print("⚠️ M7.2.2: Could not check participants: \(error.localizedDescription)")
            #endif
        }
    }

    /// Sends a local notification when a member leaves
    private func sendMemberLeftNotification(memberName: String, householdName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Member Left"
        content.body = "\(memberName) has left \(householdName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            #if DEBUG
            print("📬 M7.2.2: Sent member left notification")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ M7.2.2: Failed to send notification: \(error)")
            #endif
        }
    }

    /// M7.3.2: Migrates household data to personal store
    /// M7.2.2 FIX: Now includes categories and ingredient templates
    /// - Parameter household: The household to migrate from
    private func migrateHouseholdDataToPersonal(_ household: Household) async throws {
        let recipeSet = household.recipes as? Set<Recipe> ?? []
        let listSet = household.weeklyLists as? Set<WeeklyList> ?? []
        let mealPlanSet = household.mealPlans as? Set<MealPlan> ?? []
        let categorySet = household.categories as? Set<Category> ?? []
        let templateSet = household.ingredientTemplates as? Set<IngredientTemplate> ?? []

        // M7.2.2: Fetch existing personal categories and templates to avoid duplicates
        // When a user joins a household, their personal data stays in the private store.
        // Migrating without dedup would create duplicates of everything they already had.
        let existingCategoryNames: Set<String> = {
            let req: NSFetchRequest<Category> = Category.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.normalizedName ?? $0.name?.lowercased() })
        }()

        let existingTemplateNames: Set<String> = {
            let req: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.canonicalName ?? $0.name?.lowercased() })
        }()

        // Migrate categories first (needed for ingredient templates)
        // Skip categories that already exist in personal store by normalized name
        var categoryMapping: [UUID: Category] = [:]
        var skippedCategories = 0
        for oldCategory in categorySet {
            let normalizedName = oldCategory.normalizedName ?? oldCategory.name?.lowercased() ?? ""
            if existingCategoryNames.contains(normalizedName) {
                skippedCategories += 1
                continue
            }

            let newCategory = Category(context: viewContext)
            newCategory.id = UUID()
            newCategory.name = oldCategory.name
            newCategory.sortOrder = oldCategory.sortOrder
            newCategory.color = oldCategory.color
            newCategory.isDefault = oldCategory.isDefault
            newCategory.dateCreated = oldCategory.dateCreated
            newCategory.normalizedName = oldCategory.normalizedName
            newCategory.updatedAt = oldCategory.updatedAt
            newCategory.household = nil
            newCategory.householdKey = nil

            if let oldId = oldCategory.id {
                categoryMapping[oldId] = newCategory
            }
        }

        // Migrate ingredient templates, skipping those that already exist by canonical name
        var templateMapping: [UUID: IngredientTemplate] = [:]
        var skippedTemplates = 0
        for oldTemplate in templateSet {
            let canonicalName = oldTemplate.canonicalName ?? oldTemplate.name?.lowercased() ?? ""
            if existingTemplateNames.contains(canonicalName) {
                skippedTemplates += 1
                continue
            }

            let newTemplate = IngredientTemplate(context: viewContext)
            newTemplate.id = UUID()
            newTemplate.name = oldTemplate.name
            newTemplate.canonicalName = oldTemplate.canonicalName
            newTemplate.usageCount = oldTemplate.usageCount
            newTemplate.dateCreated = oldTemplate.dateCreated
            newTemplate.updatedAt = oldTemplate.updatedAt
            newTemplate.isStaple = oldTemplate.isStaple
            newTemplate.household = nil
            newTemplate.householdKey = nil

            newTemplate.category = oldTemplate.category

            if let oldId = oldTemplate.id {
                templateMapping[oldId] = newTemplate
            }
        }

        // Fetch existing personal recipe titles to avoid duplicates
        let existingRecipeTitles: Set<String> = {
            let req: NSFetchRequest<Recipe> = Recipe.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.title?.lowercased() })
        }()

        // Migrate recipes with ingredients, skipping duplicates by title
        var skippedRecipes = 0
        for oldRecipe in recipeSet {
            let title = oldRecipe.title?.lowercased() ?? ""
            if existingRecipeTitles.contains(title) {
                skippedRecipes += 1
                continue
            }

            let newRecipe = Recipe(context: viewContext)
            newRecipe.id = UUID()
            newRecipe.title = oldRecipe.title
            newRecipe.instructions = oldRecipe.instructions
            newRecipe.servings = oldRecipe.servings
            newRecipe.cookTime = oldRecipe.cookTime
            newRecipe.prepTime = oldRecipe.prepTime
            newRecipe.sourceURL = oldRecipe.sourceURL
            newRecipe.tags = oldRecipe.tags
            newRecipe.dateCreated = Date()
            newRecipe.isFavorite = oldRecipe.isFavorite
            newRecipe.usageCount = 0
            newRecipe.household = nil
            newRecipe.householdKey = nil

            // Copy ingredients
            let ingredientSet = oldRecipe.ingredients as? Set<Ingredient> ?? []
            for oldIngredient in ingredientSet {
                let newIngredient = Ingredient(context: viewContext)
                newIngredient.id = UUID()
                newIngredient.name = oldIngredient.name
                newIngredient.displayText = oldIngredient.displayText
                newIngredient.numericValue = oldIngredient.numericValue
                newIngredient.standardUnit = oldIngredient.standardUnit
                newIngredient.notes = oldIngredient.notes
                newIngredient.sortOrder = oldIngredient.sortOrder
                newIngredient.isParseable = oldIngredient.isParseable
                newIngredient.parseConfidence = oldIngredient.parseConfidence
                newIngredient.recipe = newRecipe

                // M7.2.2 FIX: Link to migrated template if it exists
                if let oldTemplateId = oldIngredient.ingredientTemplate?.id,
                   let newTemplate = templateMapping[oldTemplateId] {
                    newIngredient.ingredientTemplate = newTemplate
                }
            }
        }

        // Fetch existing personal weekly list names to avoid duplicates
        let existingListNames: Set<String> = {
            let req: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.name?.lowercased() })
        }()

        // Migrate weekly lists with items, skipping duplicates by name
        var skippedLists = 0
        for oldList in listSet {
            let name = oldList.name?.lowercased() ?? ""
            if existingListNames.contains(name) {
                skippedLists += 1
                continue
            }

            let newList = WeeklyList(context: viewContext)
            newList.id = UUID()
            newList.name = oldList.name
            newList.notes = oldList.notes
            newList.dateCreated = Date()
            newList.isCompleted = oldList.isCompleted
            newList.household = nil
            newList.householdKey = nil

            // Copy items
            let itemSet = oldList.items as? Set<GroceryListItem> ?? []
            for oldItem in itemSet {
                let newItem = GroceryListItem(context: viewContext)
                newItem.id = UUID()
                newItem.name = oldItem.name
                newItem.displayText = oldItem.displayText
                newItem.numericValue = oldItem.numericValue
                newItem.standardUnit = oldItem.standardUnit
                newItem.categoryName = oldItem.categoryName
                newItem.sortOrder = oldItem.sortOrder
                newItem.isCompleted = oldItem.isCompleted
                newItem.isParseable = oldItem.isParseable
                newItem.parseConfidence = oldItem.parseConfidence
                newItem.weeklyList = newList
            }
        }

        // Fetch existing personal meal plan names to avoid duplicates
        let existingPlanNames: Set<String> = {
            let req: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.name?.lowercased() })
        }()

        // Migrate meal plans, skipping duplicates by name
        var skippedPlans = 0
        for oldPlan in mealPlanSet {
            let name = oldPlan.name?.lowercased() ?? ""
            if existingPlanNames.contains(name) {
                skippedPlans += 1
                continue
            }

            let newPlan = MealPlan(context: viewContext)
            newPlan.id = UUID()
            newPlan.name = oldPlan.name
            newPlan.startDate = oldPlan.startDate
            newPlan.createdDate = Date()
            newPlan.duration = oldPlan.duration
            newPlan.isActive = false
            newPlan.isCompleted = oldPlan.isCompleted
            newPlan.household = nil
            newPlan.householdKey = nil

            // Note: PlannedMeal copying would require recipe mapping
            // For now, skip planned meals as they reference recipes
            // User can recreate meal assignments manually
        }

        #if DEBUG
        print("📊 M7.2.2: Migrated household data to personal:")
        print("   \(categorySet.count - skippedCategories) categories (\(skippedCategories) skipped — already exist)")
        print("   \(templateSet.count - skippedTemplates) ingredient templates (\(skippedTemplates) skipped — already exist)")
        print("   \(recipeSet.count - skippedRecipes) recipes (\(skippedRecipes) skipped — already exist)")
        print("   \(listSet.count - skippedLists) weekly lists (\(skippedLists) skipped — already exist)")
        print("   \(mealPlanSet.count - skippedPlans) meal plans (\(skippedPlans) skipped — already exist)")
        #endif
    }


    /// Checks if current user is the owner of the household
    /// Uses userRecordID for reliable comparison without requiring discoverability
    func isOwner(household: Household) async -> Bool {
        // M7.6.8: Use ownerRecordName only (ownerEmail repurposed for display name)
        guard let ownerIdentifier = household.ownerRecordName else { return false }

        do {
            // Get current user's recordID (always available, no discoverability required)
            let currentRecordID = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord.ID, Error>) in
                container.fetchUserRecordID { recordID, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let recordID = recordID else {
                        continuation.resume(throwing: HouseholdError.emailNotFound)
                        return
                    }
                    continuation.resume(returning: recordID)
                }
            }

            // Compare recordNames (stable identifiers)
            return currentRecordID.recordName == ownerIdentifier
        } catch {
            #if DEBUG
            print("⚠️ Failed to verify ownership: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - M7.2.3 Phase 4: Data Migration
    
    /// Counts existing personal data for migration prompt
    /// Returns tuple of (recipeCount, listCount, mealPlanCount, categoryCount, templateCount)
    func countPersonalData() -> (recipes: Int, lists: Int, mealPlans: Int, categories: Int, templates: Int) {
        var recipeCount = 0
        var listCount = 0
        var mealPlanCount = 0
        var categoryCount = 0
        var templateCount = 0
        
        // Count recipes without household
        let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeRequest.predicate = NSPredicate(format: "household == nil")
        recipeCount = (try? viewContext.count(for: recipeRequest)) ?? 0
        
        // Count weekly lists without household
        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        listRequest.predicate = NSPredicate(format: "household == nil")
        listCount = (try? viewContext.count(for: listRequest)) ?? 0
        
        // Count meal plans without household (MealPlan, not PlannedMeal!)
        let mealPlanRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        mealPlanRequest.predicate = NSPredicate(format: "household == nil")
        mealPlanCount = (try? viewContext.count(for: mealPlanRequest)) ?? 0
        
        // Count categories without household
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "household == nil")
        categoryCount = (try? viewContext.count(for: categoryRequest)) ?? 0
        
        // Count ingredient templates without household
        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "household == nil")
        templateCount = (try? viewContext.count(for: templateRequest)) ?? 0
        
        #if DEBUG
        print("📊 Personal data counts:")
        print("   Recipes: \(recipeCount)")
        print("   Weekly Lists: \(listCount)")
        print("   Meal Plans: \(mealPlanCount)")
        print("   Categories: \(categoryCount)")
        print("   Ingredient Templates: \(templateCount)")
        #endif
        
        return (recipeCount, listCount, mealPlanCount, categoryCount, templateCount)
    }
    
    /// Creates household and migrates existing personal data if requested
    /// - Parameters:
    ///   - name: Name of the household
    ///   - ownerName: Display name for the owner
    ///   - moveExistingData: Whether to migrate existing personal data to household
    /// - Returns: The newly created Household
    func createHouseholdAndShare(name: String, ownerName: String, moveExistingData: Bool) async throws -> Household {
        isLoading = true
        creationStatus = "Checking iCloud account…"
        defer {
            isLoading = false
            creationStatus = nil
        }

        // M7.3.3: Prevent creating a household when already in one
        // User must leave/delete their current household first
        if currentHousehold != nil {
            CloudKitLogger.warning("Cannot create household - already in one")
            throw HouseholdError.alreadyInHousehold
        }

        // Also check for any existing households in the database
        let existingRequest: NSFetchRequest<Household> = Household.fetchRequest()
        existingRequest.fetchLimit = 1
        if let existingHouseholds = try? viewContext.fetch(existingRequest),
           !existingHouseholds.isEmpty {
            // Check if user is actually a participant in any of them
            for existing in existingHouseholds {
                if await isCurrentUserParticipant(in: existing) {
                    CloudKitLogger.warning("Cannot create household - already a participant in '\(existing.name ?? "Unknown")'")
                    throw HouseholdError.alreadyInHousehold
                }
            }
        }

        // M7.6.8: Pre-flight check — verify iCloud account is available
        let accountStatus = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKAccountStatus, Error>) in
            container.accountStatus { status, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }

        guard accountStatus == .available else {
            let statusName: String
            switch accountStatus {
            case .available: statusName = "iCloud available" // Unreachable due to guard, but required for exhaustiveness
            case .noAccount: statusName = "No iCloud account signed in"
            case .restricted: statusName = "iCloud access is restricted"
            case .couldNotDetermine: statusName = "Could not determine iCloud status"
            case .temporarilyUnavailable: statusName = "iCloud is temporarily unavailable"
            @unknown default: statusName = "iCloud unavailable (status: \(accountStatus.rawValue))"
            }
            throw HouseholdError.creationFailed(statusName)
        }

        do {
            #if DEBUG
            print("\n🏗️ M7.2.3 Phase 4: Creating household and share")
            print("   Household: \(name)")
            print("   Move existing data: \(moveExistingData)")
            #endif

            // 1. Get userRecordID as stable owner identifier
            creationStatus = "Connecting to iCloud…"
            let userRecordID = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord.ID, Error>) in
                container.fetchUserRecordID { recordID, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let recordID = recordID else {
                        continuation.resume(throwing: HouseholdError.emailNotFound)
                        return
                    }
                    continuation.resume(returning: recordID)
                }
            }
            let ownerIdentifier = userRecordID.recordName

            #if DEBUG
            print("📝 Owner identifier (userRecordID): \(ownerIdentifier)")
            print("📝 Owner display name: \(ownerName)")
            #endif

            // 2. Create Household entity in Private Store (will be shared after)
            creationStatus = "Creating household…"
            let household = Household(context: viewContext)
            household.id = UUID()
            household.name = name
            household.ownerRecordName = ownerIdentifier
            household.ownerDisplayName = ownerName  // M7.6.8: Store display name on shared root record
            household.createdDate = Date()

            // 3. Create owner as first member
            let ownerMember = HouseholdMember(context: viewContext)
            ownerMember.id = UUID()
            ownerMember.email = ownerIdentifier  // Stable userRecordID
            ownerMember.displayName = ownerName  // From UI (auto-populated or user-entered)
            // Cache for fallback when CKShare and member lookup both fail
            UserDefaults.standard.set(ownerName, forKey: "cachedOwnerDisplayName")
            ownerMember.role = "owner"
            ownerMember.status = "active"
            ownerMember.joinedDate = Date()
            ownerMember.household = household

            // 4. Migrate existing data if requested
            if moveExistingData {
                creationStatus = "Migrating your data…"
                try migratePersonalDataToHousehold(household)
            }

            // 5. Save to Core Data (household in Private Store initially)
            creationStatus = "Saving to device…"
            do {
                try viewContext.save()
            } catch {
                throw HouseholdError.creationFailed("Failed to save household locally: \(Self.extractDetailedError(error))")
            }

            #if DEBUG
            household.logStoreIdentity()  // Should show "Private Store"
            #endif

            // 6. Share the household via CloudKit with retry
            // M7.6.8: On fresh installs, CloudKit may not have finished exporting the
            // household record before share() runs. Retry with backoff to allow export.
            let persistenceController = PersistenceController.shared
            creationStatus = "Setting up CloudKit sharing…"
            let share: CKShare
            do {
                share = try await shareWithRetry(household: household, persistence: persistenceController) { status in
                    self.creationStatus = status
                }
            } catch {
                // Share failed even after retries — rollback the ghost household
                CloudKitLogger.householdError("CloudKit sharing failed after retries, rolling back", householdID: household.id?.uuidString, error: error)
                #if DEBUG
                print("🔙 Rolling back ghost household and migrated data...")
                #endif
                rollbackMigratedData(household)
                viewContext.delete(ownerMember)
                viewContext.delete(household)
                try? viewContext.save()
                throw HouseholdError.creationFailed("CloudKit sharing failed: \(Self.extractDetailedError(error))")
            }

            #if DEBUG
            print("✅ CKShare created: \(share.recordID.recordName)")
            #endif

            // 7. CRITICAL: Save context immediately to persist the share
            creationStatus = "Finalizing…"
            // M7.2.3 Phase 4.4 FIX: Without this save, CKShare exists in-memory but never syncs to CloudKit!
            try viewContext.save()

            #if DEBUG
            print("✅ Context saved - CKShare should sync to CloudKit now")
            household.logStoreIdentity()  // Should show "Shared Store" after share
            #endif

            // 8. Store share record reference for future access
            household.shareRecord = try NSKeyedArchiver.archivedData(
                withRootObject: share,
                requiringSecureCoding: true
            )

            // 9. CRITICAL: Refresh all household-related objects to get updated store assignments
            viewContext.refreshAllObjects()

            // 10. Save share record
            try viewContext.save()

            // 11. Update current household
            currentHousehold = household

            CloudKitLogger.householdCreated(name)
            CloudKitLogger.shareCreated(recordID: share.recordID.recordName)
            if moveExistingData {
                CloudKitLogger.debug("Personal data migrated to household")
            }

            return household

        } catch let householdError as HouseholdError {
            // Re-throw already-formatted household errors
            throw householdError
        } catch {
            CloudKitLogger.householdError("Household creation failed", householdID: nil, error: error)
            throw HouseholdError.creationFailed(Self.extractDetailedError(error))
        }
    }
    
    /// Migrates ALL existing personal data to household
    /// Attaches recipes, lists, meal plans, categories, and ingredient templates
    /// Sets both household relationship AND householdKey for CloudKit sync
    // M7.6.8: Drill into NSError chain to find the actual underlying error message.
    // CloudKit errors from NSPersistentCloudKitContainer are often wrapped in
    // multiple NSError layers where localizedDescription just shows "Cocoa error XXXXX".
    private static func extractDetailedError(_ error: Error) -> String {
        let nsError = error as NSError

        // Check for underlying CloudKit error
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            let underlyingNS = underlying as NSError
            if underlyingNS.domain == CKErrorDomain {
                // Found the actual CloudKit error
                return underlyingNS.localizedDescription
            }
            // Recurse into deeper layers
            return extractDetailedError(underlying)
        }

        // Check for multiple underlying errors
        if let underlyingErrors = nsError.userInfo["NSDetailedErrors"] as? [Error], let first = underlyingErrors.first {
            return extractDetailedError(first)
        }

        // Fall back to the best available description
        let description = nsError.localizedDescription
        if description.contains("Cocoa error") {
            // Generic Cocoa error — add the domain and code for diagnostics
            return "\(description) [domain: \(nsError.domain), code: \(nsError.code)]"
        }
        return description
    }

    private func migratePersonalDataToHousehold(_ household: Household) throws {
        #if DEBUG
        print("\n🔄 Migrating ALL personal data to household...")
        #endif

        guard let householdId = household.id else {
            throw HouseholdError.creationFailed("Household missing ID")
        }

        let householdKey = householdId.uuidString
        var migratedCount = 0

        // Migrate recipes
        let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeRequest.predicate = NSPredicate(format: "household == nil")
        let recipes = try viewContext.fetch(recipeRequest)
        for recipe in recipes {
            recipe.household = household
            recipe.householdKey = householdKey
            migratedCount += 1
        }

        // Migrate weekly lists
        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        listRequest.predicate = NSPredicate(format: "household == nil")
        let lists = try viewContext.fetch(listRequest)
        for list in lists {
            list.household = household
            list.householdKey = householdKey
            migratedCount += 1
        }

        // Migrate meal plans (MealPlan, not PlannedMeal!)
        let mealPlanRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        mealPlanRequest.predicate = NSPredicate(format: "household == nil")
        let mealPlans = try viewContext.fetch(mealPlanRequest)
        for mealPlan in mealPlans {
            mealPlan.household = household
            mealPlan.householdKey = householdKey
            migratedCount += 1
        }

        // Migrate categories
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "household == nil")
        let categories = try viewContext.fetch(categoryRequest)
        for category in categories {
            category.household = household
            category.householdKey = householdKey
            migratedCount += 1
        }

        // Migrate ingredient templates
        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "household == nil")
        let templates = try viewContext.fetch(templateRequest)
        for template in templates {
            template.household = household
            template.householdKey = householdKey
            migratedCount += 1
        }

        #if DEBUG
        print("✅ Migrated \(migratedCount) items:")
        print("   \(recipes.count) recipes")
        print("   \(lists.count) weekly lists")
        print("   \(mealPlans.count) meal plans")
        print("   \(categories.count) categories")
        print("   \(templates.count) ingredient templates")
        print("   Household key: \(householdKey)")
        #endif
    }
    
    /// M7.6.8: Undo migratePersonalDataToHousehold by clearing household references.
    /// Called when container.share() fails after the local save succeeded,
    /// so the user's personal data isn't left orphaned on a ghost household.
    private func rollbackMigratedData(_ household: Household) {
        let entities: [(NSFetchRequest<NSManagedObject>, String)] = [
            (NSFetchRequest<NSManagedObject>(entityName: "Recipe"), "Recipe"),
            (NSFetchRequest<NSManagedObject>(entityName: "WeeklyList"), "WeeklyList"),
            (NSFetchRequest<NSManagedObject>(entityName: "MealPlan"), "MealPlan"),
            (NSFetchRequest<NSManagedObject>(entityName: "Category"), "Category"),
            (NSFetchRequest<NSManagedObject>(entityName: "IngredientTemplate"), "IngredientTemplate"),
        ]

        for (request, name) in entities {
            request.predicate = NSPredicate(format: "household == %@", household)
            if let objects = try? viewContext.fetch(request) {
                for obj in objects {
                    obj.setValue(nil, forKey: "household")
                    obj.setValue(nil, forKey: "householdKey")
                }
                #if DEBUG
                if !objects.isEmpty {
                    print("   Rolled back \(objects.count) \(name)(s)")
                }
                #endif
            }
        }
    }

    // MARK: - User Name Resolution

    /// M7.6.8: Look up a HouseholdMember's displayName using multiple matching strategies.
    /// Tries: relationship, direct fetch, UserDefaults cache, then any non-empty member name.
    private func lookupMemberName(
        participantID: String,
        participantEmail: String?,
        isOwner: Bool,
        household: Household
    ) -> String? {
        // Find the member via relationship or direct fetch
        let member: HouseholdMember? = {
            // Strategy 1: Match via relationship
            if let m = household.memberArray.first(where: {
                $0.email == participantID ||
                (participantEmail != nil && $0.email == participantEmail) ||
                (isOwner && $0.role == "owner")
            }) {
                return m
            }

            // Strategy 2: Direct Core Data fetch
            let request: NSFetchRequest<HouseholdMember> = HouseholdMember.fetchRequest()
            request.predicate = NSPredicate(
                format: "household == %@ AND (email == %@ OR role == %@)",
                household, participantID, isOwner ? "owner" : ""
            )
            request.fetchLimit = 1
            return try? viewContext.fetch(request).first
        }()

        // Strategy 3: Household entity field (shared root record, works cross-device)
        if isOwner, let name = household.ownerDisplayName, !name.isEmpty,
           name != "Me", name != "You", name != "User" {
            return name
        }

        // Use member's displayName if it's a real name
        if let name = member?.displayName, !name.isEmpty, name != "Me", name != "You", name != "User" {
            return name
        }

        // Strategy 4: UserDefaults cache (set during household creation)
        if isOwner, let cached = UserDefaults.standard.string(forKey: "cachedOwnerDisplayName"),
           !cached.isEmpty, cached != "Me" {
            // Also update the member record so future lookups work directly
            if let member = member {
                member.displayName = cached
                try? viewContext.save()
            }
            return cached
        }

        return nil
    }

    /// M7.6.8: Resolve the current user's display name for household creation.
    /// Tries iCloud identity first, falls back to "Me".
    /// Called by CreateHouseholdSheet to auto-populate the name field.
    func resolveCurrentUserName() async throws -> String {
        let userInfo = try await getCurrentUserInfo()
        return userInfo.displayName
    }

    // MARK: - CloudKit Share Retry

    /// M7.6.8: Retry container.share() with exponential backoff.
    /// On fresh installs, CloudKit may not have finished exporting records
    /// when share() is called immediately after a local save. Retries up to
    /// 3 times with 2s/4s delays to allow the export to complete.
    /// The onStatus closure updates the UI with progress messages.
    private func shareWithRetry(
        household: Household,
        persistence: PersistenceController,
        maxAttempts: Int = 3,
        onStatus: @MainActor (String) -> Void
    ) async throws -> CKShare {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                let (_, share, _) = try await persistence.container.share(
                    [household], to: nil
                )
                #if DEBUG
                if attempt > 1 {
                    print("✅ share() succeeded on attempt \(attempt)/\(maxAttempts)")
                }
                #endif
                return share
            } catch {
                lastError = error
                #if DEBUG
                print("⚠️ share() attempt \(attempt)/\(maxAttempts) failed: \(Self.extractDetailedError(error))")
                #endif

                if attempt < maxAttempts {
                    let delaySeconds = Int(pow(2.0, Double(attempt))) // 2s, 4s
                    onStatus("Waiting for CloudKit sync… (retry \(attempt) of \(maxAttempts - 1))")
                    #if DEBUG
                    print("   Retrying in \(delaySeconds)s...")
                    #endif
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
                    onStatus("Retrying CloudKit share…")
                }
            }
        }

        throw lastError!
    }

    // MARK: - CloudKit Integration

    /// Gets the current user's email from CloudKit
    /// Falls back to userRecordID if email is not available
    func getCurrentUserEmail() async throws -> String {
        let userInfo = try await getCurrentUserInfo()
        return userInfo.email
    }

    /// Gets the current user's information from CloudKit
    /// Returns recordName as identifier and "Me" as display name.
    /// M9.0: Removed deprecated discoverUserIdentity (iOS 17, no replacement API).
    /// The app prompts for display name during household creation — the deprecated
    /// API was just a pre-fill that usually returned nil nameComponents anyway.
    private func getCurrentUserInfo() async throws -> (email: String, displayName: String) {
        let recordID = try await container.userRecordID()
        #if DEBUG
        print("✅ Retrieved user record: \(recordID.recordName)")
        #endif
        return (recordID.recordName, "Me")
    }
    
    // MARK: - Member Management
    
    /// Gets the live CKShare for inviting members
    /// Returns share ready to present in UICloudSharingController
    /// - Parameter household: Household to get share for
    /// - Returns: Live CKShare from CloudKit
    func getShareForInvitation(household: Household) async throws -> CKShare {
        // Verify caller is owner
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        // Get and return live share from CloudKit
        return try await getShare(for: household)
    }

    /// Creates a shareable invitation URL for inviting members
    /// This approach works around UICloudSharingController issues by enabling
    /// public link sharing (like Google Docs) with UIActivityViewController
    /// - Parameter household: Household to create invitation for
    /// - Returns: Shareable URL that can be sent via Messages, Mail, etc.
    /// - Note: Enables publicPermission = .readWrite so anyone with URL can join
    func createOneTimeInvitationURL(household: Household) async throws -> URL {
        // Verify caller is owner
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        // Get live share from CloudKit
        let share = try await getShare(for: household)

        #if DEBUG
        print("📝 Creating shareable invitation URL...")
        print("   Current participants: \(share.participants.count)")
        print("   Current publicPermission: \(share.publicPermission.rawValue)")
        #endif

        // Set share metadata for the recipient's acceptance dialog
        let householdName = household.name ?? "a household"
        share[CKShare.SystemFieldKey.title] = "Join \(householdName) on forager" as CKRecordValue

        // Enable public link sharing
        // This allows anyone with the URL to join (like a shared Google Doc link)
        // NOTE: SceneDelegate will handle the acceptance via acceptShareInvitations
        let needsPermissionUpdate = share.publicPermission == .none
        if needsPermissionUpdate {
            share.publicPermission = .readWrite
            #if DEBUG
            print("✅ Enabled public link sharing (readWrite)")
            #endif
        } else {
            #if DEBUG
            print("ℹ️ Share already has public permissions")
            #endif
        }

        // Persist share metadata and permission changes
        let persistenceController = PersistenceController.shared
        let privateStore = persistenceController.privateStore
        try await persistenceController.container.persistUpdatedShare(share, in: privateStore)
        #if DEBUG
        print("✅ Share updated")
        #endif

        // Get the invitation URL from the share itself
        // The share URL is what recipients will use to join
        guard let invitationURL = share.url else {
            #if DEBUG
            print("❌ Share missing URL")
            #endif
            throw HouseholdError.noInvitationURL
        }

        #if DEBUG
        print("✅ One-time invitation URL created: \(invitationURL)")
        #endif

        return invitationURL
    }

    // MARK: - M7.2.2 Refactor: CKShare-based Participant Access
    // These methods use CKShare.participants as the source of truth
    // No more HouseholdMember records needed - CloudKit manages membership

    /// Gets all participants from the household's CKShare
    /// This is the source of truth for who's in the household
    /// - Parameter household: Household to get participants for
    /// - Returns: Array of ShareParticipant structs for UI display
    func getParticipants(for household: Household) async throws -> [ShareParticipant] {
        let share = try await getShare(for: household)

        var participants: [ShareParticipant] = []

        for ckParticipant in share.participants {
            let isCurrentUser = (ckParticipant == share.currentUserParticipant)
            var participant = ShareParticipant(from: ckParticipant, isCurrentUser: isCurrentUser)

            // M7.6.8: CKShare often provides empty or generic names for the current
            // user on their own device (nameComponents may be present but empty).
            // Fall back to Household entity, HouseholdMember, or UserDefaults cache.
            let needsNameLookup = participant.displayName.trimmingCharacters(in: .whitespaces).isEmpty
                || participant.displayName == "You"
                || participant.displayName == "User"
            if needsNameLookup {
                let betterName = lookupMemberName(
                    participantID: participant.id,
                    participantEmail: participant.email,
                    isOwner: participant.isOwner,
                    household: household
                )
                if let name = betterName {
                    participant = ShareParticipant(
                        id: participant.id,
                        displayName: name,
                        email: participant.email,
                        isOwner: participant.isOwner,
                        isCurrentUser: participant.isCurrentUser,
                        acceptanceStatus: participant.acceptanceStatus
                    )
                }
            }

            participants.append(participant)
        }

        // Sort: owner first, then by display name
        participants.sort { p1, p2 in
            if p1.isOwner != p2.isOwner {
                return p1.isOwner  // Owner comes first
            }
            return p1.displayName < p2.displayName
        }

        #if DEBUG
        print("📋 Got \(participants.count) participants from CKShare")
        #endif
        for p in participants {
            #if DEBUG
            print("   - \(p.displayName) (\(p.isOwner ? "Owner" : "Member"), \(p.acceptanceStatus.displayText))")
            #endif
        }

        return participants
    }

    /// Gets the count of participants in the household's CKShare
    /// - Parameter household: Household to count participants for
    /// - Returns: Number of participants
    func getParticipantCount(for household: Household) async -> Int {
        do {
            let share = try await getShare(for: household)
            return share.participants.count
        } catch {
            #if DEBUG
            print("⚠️ Could not get participant count: \(error)")
            #endif
            return 0
        }
    }

    /// Checks if the current user is a participant in the household's CKShare
    /// This is the source of truth for membership - not HouseholdMember records
    /// - Parameter household: Household to check membership for
    /// - Returns: True if current user is a participant (owner or member)
    func isCurrentUserParticipant(in household: Household) async -> Bool {
        do {
            let share = try await getShare(for: household)
            // currentUserParticipant is non-nil if user is in the share
            let isParticipant = share.currentUserParticipant != nil
            #if DEBUG
            print("🔍 isCurrentUserParticipant: \(isParticipant)")
            #endif
            return isParticipant
        } catch HouseholdError.noShareRecord {
            // M7.3.3: noShareRecord means the share is gone — user was likely removed
            // Don't assume participant just because data is in shared store
            #if DEBUG
            print("⚠️ Could not check participant status: noShareRecord")
            print("   Share not found — user was likely removed")
            #endif
            return false
        } catch {
            #if DEBUG
            print("⚠️ Could not check participant status: \(error)")
            #endif
            // Network or transient error — if household is in shared store,
            // assume participant (data synced via CloudKit)
            let sharedStore = PersistenceController.shared.sharedStore
            if household.objectID.persistentStore == sharedStore {
                #if DEBUG
                print("   Household is in shared store - assuming participant")
                #endif
                return true
            }
            return false
        }
    }

    /// Gets the owner participant from the household's CKShare
    /// - Parameter household: Household to get owner for
    /// - Returns: ShareParticipant representing the owner, or nil if share unavailable
    func getOwnerParticipant(for household: Household) async -> ShareParticipant? {
        do {
            let share = try await getShare(for: household)
            let owner = share.owner
            let isCurrentUser = (owner == share.currentUserParticipant)
            return ShareParticipant(from: owner, isCurrentUser: isCurrentUser)
        } catch {
            #if DEBUG
            print("⚠️ Could not get owner participant: \(error)")
            #endif
            return nil
        }
    }

    /// Gets the current user's participant info from the household's CKShare
    /// - Parameter household: Household to get current user info for
    /// - Returns: ShareParticipant for current user, or nil if not a participant
    func getCurrentUserParticipant(in household: Household) async -> ShareParticipant? {
        do {
            let share = try await getShare(for: household)
            if let currentParticipant = share.currentUserParticipant {
                return ShareParticipant(from: currentParticipant, isCurrentUser: true)
            }
            return nil
        } catch {
            #if DEBUG
            print("⚠️ Could not get current user participant: \(error)")
            #endif
            return nil
        }
    }

    /// Accepts a household invitation
    /// Called when user taps "Join Household" after receiving invitation
    /// - Parameter household: Household being joined
    func acceptInvitation(for household: Household) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Get current user's email
            let currentEmail = try await getCurrentUserEmail()

            // 2. Find pending member record
            guard let pendingMember = household.memberArray.first(where: {
                $0.email == currentEmail && $0.isPending
            }) else {
                throw HouseholdError.noInvitation
            }

            // 3. Activate member
            pendingMember.status = "active"
            pendingMember.joinedDate = Date()

            // 4. Save changes
            try viewContext.save()

            // 5. Update current household
            currentHousehold = household

            #if DEBUG
            print("✅ Invitation accepted")
            print("✅ Member activated: \(currentEmail)")
            print("✅ Joined household: \(household.name ?? "Unknown")")
            #endif

        } catch {
            #if DEBUG
            print("❌ Failed to accept invitation: \(error)")
            #endif
            throw HouseholdError.invitationFailed(error.localizedDescription)
        }
    }

    /// M7.2.2: Manually checks CloudKit for accepted invitations
    /// This is a workaround for when URL handling doesn't trigger (app already running)
    /// Call this when user taps "Check for Invitations" button
    func checkForAcceptedInvitations() async {
        CloudKitLogger.debug("Manually checking for accepted invitations...")

        // M7.3.3: If user already has a household, don't auto-join another
        // This prevents data integrity issues where householdKey doesn't match household.id
        if let existingHousehold = currentHousehold {
            CloudKitLogger.warning("User already in household '\(existingHousehold.name ?? "Unknown")'. Cannot auto-join a new household.")
            errorMessage = "You are already in a household. Leave or delete it before joining another."
            return
        }

        do {
            // FIRST: Check CloudKit shared database directly
            #if DEBUG
            print("   Checking CloudKit shared database for shared zones...")
            #endif
            let sharedDatabase = container.sharedCloudDatabase

            // Fetch all shared record zones
            let allZones = try await sharedDatabase.allRecordZones()
            #if DEBUG
            print("   Found \(allZones.count) shared zone(s) in CloudKit")
            #endif

            for zone in allZones {
                #if DEBUG
                print("      Zone: \(zone.zoneID.zoneName) (owner: \(zone.zoneID.ownerName))")
                #endif
            }

            // SECOND: Force a CloudKit sync to pull any new data
            #if DEBUG
            print("   Forcing Core Data refresh...")
            #endif
            viewContext.refreshAllObjects()

            // Wait a moment for sync to propagate
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // THIRD: Fetch all households from local database
            let fetchRequest: NSFetchRequest<Household> = Household.fetchRequest()
            let households = try viewContext.fetch(fetchRequest)

            #if DEBUG
            print("   Found \(households.count) household(s) in local database")
            #endif

            if households.isEmpty && allZones.count > 0 {
                #if DEBUG
                print("   No households found in local database")
                print("   BUT found \(allZones.count) shared zones in CloudKit")
                print("   ⚠️ NSPersistentCloudKitContainer hasn't synced the shared zone yet")
                print("   ⚠️ This is a known limitation - shared zones require app restart to sync")
                print("   💡 Solution: Close the app completely and reopen it")
                #endif
                return
            } else if households.isEmpty {
                #if DEBUG
                print("   No households found - invitation may not have synced yet")
                print("   Try again in a few seconds or check CloudKit Dashboard")
                #endif
                return
            }

            // M7.2.2 Refactor: Use CKShare.participants as source of truth
            // No need to create HouseholdMember records - CloudKit manages membership

            // Find a household where this user is a participant (via CKShare)
            for household in households {
                #if DEBUG
                print("   Checking household: \(household.name ?? "Unnamed")")
                #endif

                // Check if user is a participant via CKShare (the source of truth)
                let isParticipant = await isCurrentUserParticipant(in: household)

                // M7.2.2 FIX: Skip households the user has locally "left"
                // But only if they haven't re-joined (re-joining clears the flag below)
                if let householdID = household.id?.uuidString, hasLeftHousehold(householdID) {
                    if !isParticipant {
                        #if DEBUG
                        print("   ⏭️ Skipping - user has left this household locally")
                        #endif
                        continue
                    }
                    // User re-joined this household - clear the left flag
                    #if DEBUG
                    print("   🔄 User previously left but has re-joined - clearing left flag")
                    #endif
                    clearLeftHouseholdFlag(householdID)
                }

                if isParticipant {
                    let householdID = household.id?.uuidString ?? "unknown"
                    CloudKitLogger.memberJoined(householdID: householdID)
                    CloudKitLogger.debug("Household: \(household.name ?? "Unnamed"), Participants: \(await getParticipantCount(for: household))")

                    // Set as current household (this triggers UI update via @Published)
                    currentHousehold = household

                    return
                }
            }

            CloudKitLogger.debug("No households found where you're a participant - share may not have synced yet")

        } catch {
            CloudKitLogger.error("Error checking for invitations", error: error)
        }
    }

    // MARK: - M7.2.2: Display Name Management

    /// Refreshes the current user's display name from CloudKit
    /// Called on app launch to ensure name is up-to-date
    /// Handles: permission grants, iCloud name changes, device name changes
    func refreshCurrentMemberDisplayName() async {
        guard let household = currentHousehold else {
            #if DEBUG
            print("🔄 Display name refresh: No household, skipping")
            #endif
            return
        }

        do {
            // M7.6.8: Get both recordName and email for robust member lookup.
            // HouseholdMember.email may store either the recordName or an email,
            // depending on which version of createHouseholdAndShare created it.
            let userRecordID = try await container.userRecordID()
            let recordName = userRecordID.recordName
            let currentEmail = try await getCurrentUserEmail()

            // Find current user's member record by either identifier
            guard let currentMember = household.memberArray.first(where: {
                $0.email == currentEmail || $0.email == recordName
            }) else {
                #if DEBUG
                print("🔄 Display name refresh: Current user not found (tried email=\(currentEmail), recordName=\(recordName))")
                #endif
                return
            }

            let oldName = currentMember.displayName ?? "Unknown"
            #if DEBUG
            print("🔄 Refreshing display name for: \(oldName)")
            #endif

            // Attempt to get latest display name
            // M9.0: Removed deprecated userIdentity(forUserRecordID:) (iOS 17, no replacement).
            // Device name extraction is now the primary strategy.
            var newDisplayName: String?

            // Try 1: Device name extraction
            if newDisplayName == nil {
                let deviceName = UIDevice.current.name

                // Pattern 1: "John's iPhone" -> "John"
                if let range = deviceName.range(of: "'s ") {
                    newDisplayName = String(deviceName[..<range.lowerBound])
                    #if DEBUG
                    print("   ✅ Extracted from device name: \(newDisplayName!)")
                    #endif
                }
                // Pattern 2: "Rich iPhone" -> "Rich"
                else if deviceName.contains("iPhone") || deviceName.contains("iPad") {
                    let components = deviceName.components(separatedBy: " ")
                    if components.count >= 2 && (components[1] == "iPhone" || components[1] == "iPad") {
                        newDisplayName = components[0]
                        #if DEBUG
                        print("   ✅ Extracted from device name: \(newDisplayName!)")
                        #endif
                    }
                }
            }

            // Try 2: Extract from email (if not a CloudKit user record ID)
            if newDisplayName == nil {
                if !currentEmail.hasPrefix("_") || currentEmail.count <= 20 {
                    newDisplayName = extractDisplayName(from: currentEmail)
                    #if DEBUG
                    print("   ✅ Extracted from email: \(newDisplayName!)")
                    #endif
                }
            }

            // Try 3: UserDefaults cache (set during household creation)
            if newDisplayName == nil,
               let cached = UserDefaults.standard.string(forKey: "cachedOwnerDisplayName"),
               !cached.isEmpty, cached != "Me" {
                newDisplayName = cached
                #if DEBUG
                print("   ✅ Got display name from UserDefaults cache: \(cached)")
                #endif
            }

            // Only update if we found a better name and it's different
            if let newDisplayName = newDisplayName, newDisplayName != oldName {
                currentMember.displayName = newDisplayName
                try viewContext.save()
                #if DEBUG
                print("✅ Updated display name: '\(oldName)' → '\(newDisplayName)'")
                #endif

                // Refresh household to trigger UI update
                viewContext.refresh(household, mergeChanges: true)

                // Trigger objectWillChange to update UI
                objectWillChange.send()
            } else if newDisplayName == nil {
                #if DEBUG
                print("   ℹ️ No better name found, keeping: \(oldName)")
                #endif
            } else {
                #if DEBUG
                print("   ℹ️ Display name unchanged: \(oldName)")
                #endif
            }

        } catch {
            #if DEBUG
            print("❌ Error refreshing display name: \(error)")
            #endif
        }
    }

    // MARK: - Helper Methods
    
    /// Gets the LIVE CKShare record for the household from CloudKit
    /// Used for invitation and share management
    /// CRITICAL: Must fetch live record, not archived snapshot, for UICloudSharingController
    private func getShare(for household: Household) async throws -> CKShare {
        // APPROACH 1: Use NSPersistentCloudKitContainer to get live share
        // This is the recommended approach when using Core Data + CloudKit
        let persistenceController = PersistenceController.shared

        // Fetch shares for this household
        do {
            let shares = try persistenceController.container.fetchShares(matching: [household.objectID])

            guard let share = shares.first?.1 else {
                throw HouseholdError.noShareRecord
            }

            // M7.3.3: For owner, fetch directly from private database to get latest participants
            // fetchShares(matching:) may return cached data that doesn't include new participants
            let isOwnerUser = await isOwner(household: household)
            if isOwnerUser {
                let privateDB = container.privateCloudDatabase
                do {
                    let freshRecord = try await privateDB.record(for: share.recordID)
                    if let freshShare = freshRecord as? CKShare {
                        CloudKitLogger.shareLookup(found: true, householdID: household.id?.uuidString ?? "unknown")
                        CloudKitLogger.debug("Fresh CKShare participants: \(freshShare.participants.count)")
                        return freshShare
                    }
                } catch {
                    CloudKitLogger.debug("Could not fetch fresh share from private DB, using cached: \(error.localizedDescription)")
                }
            }

            CloudKitLogger.shareLookup(found: true, householdID: household.id?.uuidString ?? "unknown")
            CloudKitLogger.debug("CKShare participants: \(share.participants.count)")

            return share

        } catch {
            CloudKitLogger.shareFailed(operation: "getShare-fetchShares", error: error)

            // FALLBACK: Try to get share record ID from archived data and fetch manually
            guard let shareData = household.shareRecord,
                  let archivedShare = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClass: CKShare.self,
                    from: shareData
                  ) else {
                throw HouseholdError.noShareRecord
            }

            // Fetch the live record from CloudKit using the recordID
            let database = container.sharedCloudDatabase
            let shareRecordID = archivedShare.recordID

            do {
                let fetchedRecord = try await database.record(for: shareRecordID)

                guard let liveShare = fetchedRecord as? CKShare else {
                    throw HouseholdError.noShareRecord
                }

                CloudKitLogger.debug("Fetched live CKShare via fallback: \(liveShare.recordID.recordName)")
                return liveShare
            } catch {
                // M7.3.3: CKError from shared database means user was removed
                // "Invalid Arguments" / "Only shared zones can be accessed" = no access
                CloudKitLogger.shareFailed(operation: "getShare-fallback", error: error)
                throw HouseholdError.noShareRecord
            }
        }
    }
    
    /// M7.3.3: Deletes all objects linked to a household by householdKey
    /// Used during "Clean Delete" to remove data that may be in private store
    /// (due to attach-then-share pattern not moving related objects to shared store)
    @discardableResult
    private func deleteHouseholdLinkedData(householdKey: String) -> Int {
        var deletedCount = 0

        #if DEBUG
        print("🔍 M7.3.3: deleteHouseholdLinkedData starting for key: \(householdKey)")
        #endif

        // M7.3.3 FIX: Refresh context to ensure we see latest state from all stores
        viewContext.refreshAllObjects()

        // Delete recipes with this householdKey
        let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let recipes = try viewContext.fetch(recipeRequest)
            #if DEBUG
            print("   Found \(recipes.count) recipes to delete")
            #endif
            for recipe in recipes {
                viewContext.delete(recipe)
                deletedCount += 1
            }
        } catch {
            #if DEBUG
            print("   ❌ Recipe fetch error: \(error)")
            #endif
        }

        // Delete weekly lists with this householdKey
        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        listRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let lists = try viewContext.fetch(listRequest)
            #if DEBUG
            print("   Found \(lists.count) weekly lists to delete")
            #endif
            for list in lists {
                viewContext.delete(list)
                deletedCount += 1
            }
        } catch {
            #if DEBUG
            print("   ❌ WeeklyList fetch error: \(error)")
            #endif
        }

        // Delete meal plans with this householdKey
        let mealPlanRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        mealPlanRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let mealPlans = try viewContext.fetch(mealPlanRequest)
            #if DEBUG
            print("   Found \(mealPlans.count) meal plans to delete")
            #endif
            for mealPlan in mealPlans {
                viewContext.delete(mealPlan)
                deletedCount += 1
            }
        } catch {
            #if DEBUG
            print("   ❌ MealPlan fetch error: \(error)")
            #endif
        }

        // Delete categories with this householdKey
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let categories = try viewContext.fetch(categoryRequest)
            #if DEBUG
            print("   Found \(categories.count) categories to delete")
            #endif
            for category in categories {
                viewContext.delete(category)
                deletedCount += 1
            }
        } catch {
            #if DEBUG
            print("   ❌ Category fetch error: \(error)")
            #endif
        }

        // Delete ingredient templates with this householdKey
        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let templates = try viewContext.fetch(templateRequest)
            #if DEBUG
            print("   Found \(templates.count) ingredient templates to delete")
            #endif
            for template in templates {
                viewContext.delete(template)
                deletedCount += 1
            }
        } catch {
            #if DEBUG
            print("   ❌ IngredientTemplate fetch error: \(error)")
            #endif
        }

        if viewContext.hasChanges {
            do {
                try viewContext.save()
                #if DEBUG
                print("   ✅ Context saved successfully")
                #endif
            } catch {
                #if DEBUG
                print("   ❌ Context save error: \(error)")
                #endif
            }
        } else {
            #if DEBUG
            print("   ⚠️ No changes to save")
            #endif
        }

        #if DEBUG
        print("🔍 M7.3.3: deleteHouseholdLinkedData complete, deleted \(deletedCount) objects")
        #endif
        return deletedCount
    }

    /// Extracts display name from email address
    /// Example: "sarah.smith@icloud.com" → "Sarah Smith"
    private func extractDisplayName(from email: String) -> String {
        // Get part before @
        let localPart = email.components(separatedBy: "@").first ?? email

        // Split by dots and capitalize each part
        let parts = localPart.components(separatedBy: ".")
        let capitalized = parts.map { $0.capitalized }

        return capitalized.joined(separator: " ")
    }

    // MARK: - M7.3.3: Diagnostic Methods

    /// M7.3.3: Comprehensive diagnostic dump for troubleshooting sync issues
    /// Call this from Settings or debug view to understand what data is where
    func dumpCategorySyncDiagnostics() {
        #if DEBUG
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 M7.3.3 CATEGORY SYNC DIAGNOSTICS")
        print(String(repeating: "=", count: 60))
        #endif

        // 1. Current household state
        #if DEBUG
        print("\n📦 HOUSEHOLD STATE:")
        #endif
        if let household = currentHousehold {
            #if DEBUG
            print("   Name: \(household.name ?? "Unknown")")
            print("   ID (UUID): \(household.id?.uuidString ?? "NIL")")
            print("   Owner ID: \(household.ownerRecordName ?? "Unknown")")
            print("   Owner Name: \(household.ownerDisplayName ?? "Not set")")
            #endif
            if let store = household.objectID.persistentStore {
                #if DEBUG
                print("   Store: \(store.url?.lastPathComponent ?? "unknown")")
                #endif
            }
        } else {
            #if DEBUG
            print("   No current household")
            #endif
        }

        // 2. Derived household key
        #if DEBUG
        print("\n🔑 HOUSEHOLD KEY:")
        print("   currentHouseholdKey: \(currentHouseholdKey ?? "NIL")")
        #endif

        // 3. Fetch ALL categories (both stores)
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]

        do {
            let allCategories = try viewContext.fetch(categoryRequest)
            #if DEBUG
            print("\n📂 ALL CATEGORIES IN DATABASE (\(allCategories.count) total):")
            #endif

            let persistenceController = PersistenceController.shared
            let privateStore = persistenceController.privateStore
            let sharedStore = persistenceController.sharedStore

            var privateCount = 0
            var sharedCount = 0
            var unknownStoreCount = 0

            for category in allCategories {
                let storeName: String
                if category.objectID.persistentStore == privateStore {
                    storeName = "PRIVATE"
                    privateCount += 1
                } else if category.objectID.persistentStore == sharedStore {
                    storeName = "SHARED"
                    sharedCount += 1
                } else {
                    storeName = "UNKNOWN"
                    unknownStoreCount += 1
                }

                let hasHouseholdRelation = category.household != nil
                #if DEBUG
                print("   [\(storeName)] '\(category.name ?? "unnamed")' - householdKey: \(category.householdKey ?? "nil"), relationship: \(hasHouseholdRelation ? "YES" : "NO")")
                #endif
            }

            #if DEBUG
            print("\n📊 STORE SUMMARY:")
            print("   Private store categories: \(privateCount)")
            print("   Shared store categories: \(sharedCount)")
            print("   Unknown store categories: \(unknownStoreCount)")
            #endif

            // 4. Check what the filter would show
            let filteredCategories = allCategories.filter { category in
                if let householdKey = currentHouseholdKey {
                    return category.householdKey == householdKey
                } else {
                    return category.householdKey == nil
                }
            }
            #if DEBUG
            print("\n🎯 FILTER RESULT (\(filteredCategories.count) categories would show):")
            #endif
            for category in filteredCategories {
                #if DEBUG
                print("   '\(category.name ?? "unnamed")'")
                #endif
            }

        } catch {
            #if DEBUG
            print("   ❌ Error fetching categories: \(error)")
            #endif
        }

        // 5. Check WeeklyLists for comparison
        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        if let allLists = try? viewContext.fetch(listRequest) {
            #if DEBUG
            print("\n📋 WEEKLY LISTS FOR COMPARISON (\(allLists.count) total):")
            #endif
            let persistenceController = PersistenceController.shared
            for list in allLists.prefix(10) {
                let storeName: String
                if list.objectID.persistentStore == persistenceController.privateStore {
                    storeName = "PRIVATE"
                } else if list.objectID.persistentStore == persistenceController.sharedStore {
                    storeName = "SHARED"
                } else {
                    storeName = "UNKNOWN"
                }
                #if DEBUG
                print("   [\(storeName)] '\(list.name ?? "unnamed")' - householdKey: \(list.householdKey ?? "nil")")
                #endif
            }
        }

        #if DEBUG
        print("\n" + String(repeating: "=", count: 60))
        print("END DIAGNOSTICS")
        print(String(repeating: "=", count: 60) + "\n")
        #endif
    }
}
