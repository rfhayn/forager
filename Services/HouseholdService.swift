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

    private var cancellables = Set<AnyCancellable>()

    // M7.2.2: Debounce timer to avoid processing leave requests on every sync event
    private var leaveRequestCheckTimer: Timer?
    // M7.2.2: Track known participant record IDs to detect departures
    private var knownParticipantRecordIDs: Set<String>?

    // M7.2.2: Keychain-backed left-household tracking (survives reinstalls)
    private func markHouseholdAsLeft(_ householdID: String) {
        KeychainHelper.markHouseholdAsLeft(householdID)
        print("📝 M7.2.2: Marked household \(householdID) as left (Keychain — survives reinstall)")
    }

    private func hasLeftHousehold(_ householdID: String) -> Bool {
        return KeychainHelper.hasLeftHousehold(householdID)
    }

    func clearLeftHouseholdFlag(_ householdID: String) {
        KeychainHelper.clearLeftHouseholdFlag(householdID)
        print("📝 M7.2.2: Cleared left flag for household \(householdID)")
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
            print("⚠️ M7.2.2: household.id is nil, derived key from recipe: \(derivedKey ?? "nil")")
            return derivedKey
        }

        // Try to get key from any related ingredient template
        if let templates = household.ingredientTemplates as? Set<IngredientTemplate>,
           let firstTemplate = templates.first(where: { $0.householdKey != nil }) {
            let derivedKey = firstTemplate.householdKey
            print("⚠️ M7.2.2: household.id is nil, derived key from template: \(derivedKey ?? "nil")")
            return derivedKey
        }

        print("⚠️ M7.2.2: Could not derive household key - no data with householdKey found")
        return nil
    }
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.container = CKContainer(identifier: "iCloud.com.richhayn.forager")

        // Load current household on init
        Task {
            await loadCurrentHousehold()
        }

        // M7.2.2: Listen for CloudKit sync events to process leave requests in real-time
        // Debounced to 5 seconds so we don't run on every sync event (100+ per session)
        setupSyncObserver()
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
        print("✅ M7.3.1: Household renamed to: \(trimmedName)")
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

        let householdName = household.name ?? "Unknown"
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
        do {
            let share = try await getShare(for: household)
            try await deleteCKShareFromSharedDatabase(share)
            CloudKitLogger.debug("Deleted CKShare from shared database (left share)")
        } catch {
            // Non-fatal — local cleanup still proceeds so the UI is correct on this device.
            // Owner will eventually detect departure or member can be manually removed.
            CloudKitLogger.shareFailed(operation: "leaveHousehold-deleteCKShare", error: error)
            CloudKitLogger.warning("Proceeding with local cleanup")
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

        let householdName = household.name ?? "Unknown"
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
    /// M7.3.4: Check connectivity first - skip if offline to avoid hanging
    private func deleteCKShareFromSharedDatabase(_ share: CKShare) async throws {
        // M7.3.4: Check network connectivity before attempting CloudKit operation
        // CKModifyRecordsOperation queues indefinitely when offline - skip and let caller proceed
        guard await hasNetworkConnectivity() else {
            CloudKitLogger.warning("No network connectivity - skipping CKShare delete (will sync when online)")
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

    /// Processes pending leave requests (owner-only)
    /// Call this on app launch and when CloudKit sync events occur
    /// M7.2.2: Checks for member departures via CKShare participant polling (owner-only).
    /// Replaces the old processLeaveRequests() — we no longer create or process LeaveRequest entities.
    /// Also cleans up any stale LeaveRequests from prior app versions.
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

        // Clean up any leftover LeaveRequests from prior app versions
        cleanupStaleLeaveRequests()
    }

    /// M7.3.3: Checks if the current user has been removed from the household
    /// Called on non-owner devices when sync events arrive
    private func checkIfRemovedFromHousehold(household: Household) async {
        let isParticipant = await isCurrentUserParticipant(in: household)

        if !isParticipant {
            print("👋 M7.3.3: Detected removal from household — cleaning up")

            // Capture householdKey before clearing currentHousehold
            let householdKey = household.id?.uuidString

            // Clear current household so UI shows "Create Household"
            currentHousehold = nil
            print("✅ M7.3.3: Household cleared — UI will show 'Create Household'")

            // Mark this household as "left" so we don't re-join on next sync
            if let householdID = householdKey {
                markHouseholdAsLeft(householdID)
            }

            // M7.3.3 FIX: Delete data by householdKey (not just purge shared store)
            // CloudKit may have already cleaned up the shared store, but orphaned
            // data with householdKey can remain and cause duplicates on rejoin
            if let key = householdKey {
                let deletedByKey = deleteHouseholdLinkedData(householdKey: key)
                print("✅ M7.3.3: Deleted \(deletedByKey) objects with householdKey=\(key)")
            }

            // Also purge any remaining shared store objects
            let deletedFromStore = PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
            print("✅ M7.3.3: Purged \(deletedFromStore) shared store objects")

            // M7.3.3 FIX: Reset context BEFORE destroying shared store
            // This clears all in-memory managed object references, preventing crashes
            // when SwiftUI tries to access objects from the destroyed store
            viewContext.reset()
            print("✅ M7.3.3: Reset viewContext to clear in-memory references")

            // M7.3.3 FIX: Destroy and recreate shared store to clear local SQLite cache
            // This is more aggressive but necessary to prevent duplicates on rejoin
            // CloudKit will re-sync fresh data when user rejoins
            do {
                try PersistenceController.shared.destroyAndRecreateSharedStore()
                print("✅ M7.3.3: Destroyed and recreated shared store")
            } catch {
                print("⚠️ M7.3.3: Failed to recreate shared store: \(error)")
            }
        }
    }

    /// Cleans up ALL leave requests from the shared zone.
    /// LeaveRequests are no longer created — this removes any leftover from prior app versions.
    private func cleanupStaleLeaveRequests() {
        let request: NSFetchRequest<LeaveRequest> = LeaveRequest.fetchRequest()

        do {
            let stale = try viewContext.fetch(request)
            if !stale.isEmpty {
                print("🧹 M7.2.2: Cleaning up \(stale.count) stale leave request(s) from prior versions")
                for lr in stale {
                    viewContext.delete(lr)
                }
                try viewContext.save()
            }
        } catch {
            print("⚠️ M7.2.2: Could not clean up leave requests: \(error.localizedDescription)")
        }
    }

    // M7.2.2: Primary mechanism for detecting member departures on owner's device.
    // Compares current CKShare participants against known set by record ID.
    // More reliable than LeaveRequests because it uses the CKShare as source of truth.
    private func detectParticipantDepartures(household: Household) async {
        do {
            let share = try await getShare(for: household)
            let currentIDs = Set(share.participants.compactMap {
                $0.userIdentity.userRecordID?.recordName
            })

            if let knownIDs = knownParticipantRecordIDs {
                let departed = knownIDs.subtracting(currentIDs)
                if !departed.isEmpty {
                    print("👋 M7.2.2: Detected \(departed.count) participant departure(s)")

                    // Log remaining participants
                    for p in share.participants {
                        let name = p.userIdentity.nameComponents.map {
                            PersonNameComponentsFormatter().string(from: $0)
                        } ?? p.userIdentity.userRecordID?.recordName ?? "Unknown"
                        print("   Remaining: \(name) (\(p.role == .owner ? "Owner" : "Member"))")
                    }

                    for departedID in departed {
                        print("   Departed: \(departedID)")
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
            print("⚠️ M7.2.2: Could not check participants: \(error.localizedDescription)")
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
            print("📬 M7.2.2: Sent member left notification")
        } catch {
            print("⚠️ M7.2.2: Failed to send notification: \(error)")
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
                newItem.isFromRecipe = false
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

        print("📊 M7.2.2: Migrated household data to personal:")
        print("   \(categorySet.count - skippedCategories) categories (\(skippedCategories) skipped — already exist)")
        print("   \(templateSet.count - skippedTemplates) ingredient templates (\(skippedTemplates) skipped — already exist)")
        print("   \(recipeSet.count - skippedRecipes) recipes (\(skippedRecipes) skipped — already exist)")
        print("   \(listSet.count - skippedLists) weekly lists (\(skippedLists) skipped — already exist)")
        print("   \(mealPlanSet.count - skippedPlans) meal plans (\(skippedPlans) skipped — already exist)")
    }


    /// Checks if current user is the owner of the household
    /// Uses userRecordID for reliable comparison without requiring discoverability
    func isOwner(household: Household) async -> Bool {
        guard let ownerEmail = household.ownerEmail else { return false }

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
            return currentRecordID.recordName == ownerEmail
        } catch {
            print("⚠️ Failed to verify ownership: \(error)")
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
        defer { isLoading = false }

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

        do {
            #if DEBUG
            print("\n🏗️ M7.2.3 Phase 4: Creating household and share")
            print("   Household: \(name)")
            print("   Owner: \(ownerName)")
            print("   Move existing data: \(moveExistingData)")
            #endif

            // 1. Get userRecordID as stable owner identifier
            // Note: recordID.recordName is always available without discoverability permissions
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

            // Use recordName as stable owner identifier (not email, but reliable)
            let ownerIdentifier = userRecordID.recordName

            print("📝 Owner identifier (userRecordID): \(ownerIdentifier)")

            // 2. Create Household entity in Private Store (will be shared after)
            let household = Household(context: viewContext)
            household.id = UUID()
            household.name = name
            household.ownerEmail = ownerIdentifier  // Stable userRecordID
            household.createdDate = Date()

            // 3. Create owner as first member
            let ownerMember = HouseholdMember(context: viewContext)
            ownerMember.id = UUID()
            ownerMember.email = ownerIdentifier  // Stable userRecordID
            ownerMember.displayName = ownerName  // User-provided display name
            ownerMember.role = "owner"
            ownerMember.status = "active"
            ownerMember.joinedDate = Date()
            ownerMember.household = household

            // 4. Migrate existing data if requested
            if moveExistingData {
                try migratePersonalDataToHousehold(household)
            }

            // 5. Save to Core Data (household in Private Store initially)
            try viewContext.save()

            #if DEBUG
            household.logStoreIdentity()  // Should show "Private Store"
            #endif

            // 6. CRITICAL: Share the household using container.share()
            // M7.2.2: With dual-store setup, let Core Data determine the correct store
            // Household is in viewContext, which will resolve to the appropriate store
            let persistenceController = PersistenceController.shared
            let (_, share, _) = try await persistenceController.container.share([household], to: nil)

            #if DEBUG
            print("✅ CKShare created: \(share.recordID.recordName)")
            #endif

            // 7. CRITICAL: Save context immediately to persist the share
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

        } catch {
            CloudKitLogger.householdError("Household creation failed", householdID: nil, error: error)
            throw HouseholdError.creationFailed(error.localizedDescription)
        }
    }
    
    /// Migrates ALL existing personal data to household
    /// Attaches recipes, lists, meal plans, categories, and ingredient templates
    /// Sets both household relationship AND householdKey for CloudKit sync
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
    
    // MARK: - CloudKit Integration

    /// Gets the current user's email from CloudKit
    /// Falls back to userRecordID if email is not available
    func getCurrentUserEmail() async throws -> String {
        let userInfo = try await getCurrentUserInfo()
        return userInfo.email
    }

    /// Gets the current user's information from CloudKit
    /// Returns email and display name (or fallback values)
    private func getCurrentUserInfo() async throws -> (email: String, displayName: String) {
        return try await withCheckedThrowingContinuation { continuation in
            // TODO: M7.2.2 - Update to modern CloudKit API (iOS 17+)
            container.fetchUserRecordID { recordID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let recordID = recordID else {
                    continuation.resume(throwing: HouseholdError.emailNotFound)
                    return
                }

                self.container.discoverUserIdentity(withUserRecordID: recordID) { identity, error in
                    if let error = error {
                        print("⚠️ Failed to discover identity: \(error)")
                        // Fallback to userRecordID as identifier
                        continuation.resume(returning: (recordID.recordName, "Me"))
                        return
                    }

                    guard let identity = identity else {
                        print("⚠️ No identity found, using fallback")
                        continuation.resume(returning: (recordID.recordName, "Me"))
                        return
                    }

                    // Get email (or fallback to recordName)
                    let email = identity.lookupInfo?.emailAddress ?? recordID.recordName

                    // Get display name from nameComponents
                    var displayName = "Me"
                    if let nameComponents = identity.nameComponents {
                        let formatter = PersonNameComponentsFormatter()
                        formatter.style = .medium
                        displayName = formatter.string(from: nameComponents)
                        print("✅ Retrieved display name: \(displayName)")
                    } else {
                        print("⚠️ Name components not available, using 'Me' as fallback")
                    }

                    print("✅ Retrieved email: \(email)")
                    continuation.resume(returning: (email, displayName))
                }
            }
        }
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

        print("📝 Creating shareable invitation URL...")
        print("   Current participants: \(share.participants.count)")
        print("   Current publicPermission: \(share.publicPermission.rawValue)")

        // Set share metadata for the recipient's acceptance dialog
        let householdName = household.name ?? "a household"
        share[CKShare.SystemFieldKey.title] = "Join \(householdName) on forager" as CKRecordValue

        // Enable public link sharing
        // This allows anyone with the URL to join (like a shared Google Doc link)
        // NOTE: SceneDelegate will handle the acceptance via acceptShareInvitations
        let needsPermissionUpdate = share.publicPermission == .none
        if needsPermissionUpdate {
            share.publicPermission = .readWrite
            print("✅ Enabled public link sharing (readWrite)")
        } else {
            print("ℹ️ Share already has public permissions")
        }

        // Persist share metadata and permission changes
        let persistenceController = PersistenceController.shared
        let privateStore = persistenceController.privateStore
        try await persistenceController.container.persistUpdatedShare(share, in: privateStore)
        print("✅ Share updated")

        // Get the invitation URL from the share itself
        // The share URL is what recipients will use to join
        guard let invitationURL = share.url else {
            print("❌ Share missing URL")
            throw HouseholdError.noInvitationURL
        }

        print("✅ One-time invitation URL created: \(invitationURL)")

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
            let participant = ShareParticipant(from: ckParticipant, isCurrentUser: isCurrentUser)
            participants.append(participant)
        }

        // Sort: owner first, then by display name
        participants.sort { p1, p2 in
            if p1.isOwner != p2.isOwner {
                return p1.isOwner  // Owner comes first
            }
            return p1.displayName < p2.displayName
        }

        print("📋 Got \(participants.count) participants from CKShare")
        for p in participants {
            print("   - \(p.displayName) (\(p.isOwner ? "Owner" : "Member"), \(p.acceptanceStatus.displayText))")
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
            print("⚠️ Could not get participant count: \(error)")
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
            print("🔍 isCurrentUserParticipant: \(isParticipant)")
            return isParticipant
        } catch HouseholdError.noShareRecord {
            // M7.3.3: noShareRecord means the share is gone — user was likely removed
            // Don't assume participant just because data is in shared store
            print("⚠️ Could not check participant status: noShareRecord")
            print("   Share not found — user was likely removed")
            return false
        } catch {
            print("⚠️ Could not check participant status: \(error)")
            // Network or transient error — if household is in shared store,
            // assume participant (data synced via CloudKit)
            let sharedStore = PersistenceController.shared.sharedStore
            if household.objectID.persistentStore == sharedStore {
                print("   Household is in shared store - assuming participant")
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
            print("⚠️ Could not get owner participant: \(error)")
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
            print("⚠️ Could not get current user participant: \(error)")
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

            print("✅ Invitation accepted")
            print("✅ Member activated: \(currentEmail)")
            print("✅ Joined household: \(household.name ?? "Unknown")")

        } catch {
            print("❌ Failed to accept invitation: \(error)")
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
            print("   Checking CloudKit shared database for shared zones...")
            let sharedDatabase = container.sharedCloudDatabase

            // Fetch all shared record zones
            let allZones = try await sharedDatabase.allRecordZones()
            print("   Found \(allZones.count) shared zone(s) in CloudKit")

            for zone in allZones {
                print("      Zone: \(zone.zoneID.zoneName) (owner: \(zone.zoneID.ownerName))")
            }

            // SECOND: Force a CloudKit sync to pull any new data
            print("   Forcing Core Data refresh...")
            viewContext.refreshAllObjects()

            // Wait a moment for sync to propagate
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // THIRD: Fetch all households from local database
            let fetchRequest: NSFetchRequest<Household> = Household.fetchRequest()
            let households = try viewContext.fetch(fetchRequest)

            print("   Found \(households.count) household(s) in local database")

            if households.isEmpty && allZones.count > 0 {
                print("   No households found in local database")
                print("   BUT found \(allZones.count) shared zones in CloudKit")
                print("   ⚠️ NSPersistentCloudKitContainer hasn't synced the shared zone yet")
                print("   ⚠️ This is a known limitation - shared zones require app restart to sync")
                print("   💡 Solution: Close the app completely and reopen it")
                return
            } else if households.isEmpty {
                print("   No households found - invitation may not have synced yet")
                print("   Try again in a few seconds or check CloudKit Dashboard")
                return
            }

            // M7.2.2 Refactor: Use CKShare.participants as source of truth
            // No need to create HouseholdMember records - CloudKit manages membership

            // Find a household where this user is a participant (via CKShare)
            for household in households {
                print("   Checking household: \(household.name ?? "Unnamed")")

                // Check if user is a participant via CKShare (the source of truth)
                let isParticipant = await isCurrentUserParticipant(in: household)

                // M7.2.2 FIX: Skip households the user has locally "left"
                // But only if they haven't re-joined (re-joining clears the flag below)
                if let householdID = household.id?.uuidString, hasLeftHousehold(householdID) {
                    if !isParticipant {
                        print("   ⏭️ Skipping - user has left this household locally")
                        continue
                    }
                    // User re-joined this household - clear the left flag
                    print("   🔄 User previously left but has re-joined - clearing left flag")
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
            print("🔄 Display name refresh: No household, skipping")
            return
        }

        do {
            // Get current user's email/identifier
            let currentEmail = try await getCurrentUserEmail()

            // Find current user's member record
            guard let currentMember = household.memberArray.first(where: { $0.email == currentEmail }) else {
                print("🔄 Display name refresh: Current user not found in household members")
                return
            }

            let oldName = currentMember.displayName ?? "Unknown"
            print("🔄 Refreshing display name for: \(oldName)")

            // Attempt to get latest display name from CloudKit
            var newDisplayName: String?

            // Try 1: Get from CloudKit user identity
            do {
                let userRecordID = try await container.userRecordID()
                if let identity = try await container.userIdentity(forUserRecordID: userRecordID),
                   let nameComponents = identity.nameComponents {
                    let formatter = PersonNameComponentsFormatter()
                    formatter.style = .medium
                    newDisplayName = formatter.string(from: nameComponents)
                    print("   ✅ Got display name from CloudKit identity: \(newDisplayName!)")
                }
            } catch {
                print("   ℹ️ CloudKit identity lookup failed: \(error.localizedDescription)")
            }

            // Try 2: Device name extraction
            if newDisplayName == nil {
                let deviceName = UIDevice.current.name

                // Pattern 1: "John's iPhone" -> "John"
                if let range = deviceName.range(of: "'s ") {
                    newDisplayName = String(deviceName[..<range.lowerBound])
                    print("   ✅ Extracted from device name: \(newDisplayName!)")
                }
                // Pattern 2: "Rich iPhone" -> "Rich"
                else if deviceName.contains("iPhone") || deviceName.contains("iPad") {
                    let components = deviceName.components(separatedBy: " ")
                    if components.count >= 2 && (components[1] == "iPhone" || components[1] == "iPad") {
                        newDisplayName = components[0]
                        print("   ✅ Extracted from device name: \(newDisplayName!)")
                    }
                }
            }

            // Try 3: Extract from email (if not a CloudKit user record ID)
            if newDisplayName == nil {
                if !currentEmail.hasPrefix("_") || currentEmail.count <= 20 {
                    newDisplayName = extractDisplayName(from: currentEmail)
                    print("   ✅ Extracted from email: \(newDisplayName!)")
                }
            }

            // Only update if we found a better name and it's different
            if let newDisplayName = newDisplayName, newDisplayName != oldName {
                currentMember.displayName = newDisplayName
                try viewContext.save()
                print("✅ Updated display name: '\(oldName)' → '\(newDisplayName)'")

                // Refresh household to trigger UI update
                viewContext.refresh(household, mergeChanges: true)

                // Trigger objectWillChange to update UI
                objectWillChange.send()
            } else if newDisplayName == nil {
                print("   ℹ️ No better name found, keeping: \(oldName)")
            } else {
                print("   ℹ️ Display name unchanged: \(oldName)")
            }

        } catch {
            print("❌ Error refreshing display name: \(error)")
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
            let shares = try await persistenceController.container.fetchShares(matching: [household.objectID])

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

        print("🔍 M7.3.3: deleteHouseholdLinkedData starting for key: \(householdKey)")

        // M7.3.3 FIX: Refresh context to ensure we see latest state from all stores
        viewContext.refreshAllObjects()

        // Delete recipes with this householdKey
        let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let recipes = try viewContext.fetch(recipeRequest)
            print("   Found \(recipes.count) recipes to delete")
            for recipe in recipes {
                viewContext.delete(recipe)
                deletedCount += 1
            }
        } catch {
            print("   ❌ Recipe fetch error: \(error)")
        }

        // Delete weekly lists with this householdKey
        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        listRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let lists = try viewContext.fetch(listRequest)
            print("   Found \(lists.count) weekly lists to delete")
            for list in lists {
                viewContext.delete(list)
                deletedCount += 1
            }
        } catch {
            print("   ❌ WeeklyList fetch error: \(error)")
        }

        // Delete meal plans with this householdKey
        let mealPlanRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        mealPlanRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let mealPlans = try viewContext.fetch(mealPlanRequest)
            print("   Found \(mealPlans.count) meal plans to delete")
            for mealPlan in mealPlans {
                viewContext.delete(mealPlan)
                deletedCount += 1
            }
        } catch {
            print("   ❌ MealPlan fetch error: \(error)")
        }

        // Delete categories with this householdKey
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let categories = try viewContext.fetch(categoryRequest)
            print("   Found \(categories.count) categories to delete")
            for category in categories {
                viewContext.delete(category)
                deletedCount += 1
            }
        } catch {
            print("   ❌ Category fetch error: \(error)")
        }

        // Delete ingredient templates with this householdKey
        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let templates = try viewContext.fetch(templateRequest)
            print("   Found \(templates.count) ingredient templates to delete")
            for template in templates {
                viewContext.delete(template)
                deletedCount += 1
            }
        } catch {
            print("   ❌ IngredientTemplate fetch error: \(error)")
        }

        if viewContext.hasChanges {
            do {
                try viewContext.save()
                print("   ✅ Context saved successfully")
            } catch {
                print("   ❌ Context save error: \(error)")
            }
        } else {
            print("   ⚠️ No changes to save")
        }

        print("🔍 M7.3.3: deleteHouseholdLinkedData complete, deleted \(deletedCount) objects")
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
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 M7.3.3 CATEGORY SYNC DIAGNOSTICS")
        print(String(repeating: "=", count: 60))

        // 1. Current household state
        print("\n📦 HOUSEHOLD STATE:")
        if let household = currentHousehold {
            print("   Name: \(household.name ?? "Unknown")")
            print("   ID (UUID): \(household.id?.uuidString ?? "NIL")")
            print("   Owner: \(household.ownerEmail ?? "Unknown")")
            if let store = household.objectID.persistentStore {
                print("   Store: \(store.url?.lastPathComponent ?? "unknown")")
            }
        } else {
            print("   No current household")
        }

        // 2. Derived household key
        print("\n🔑 HOUSEHOLD KEY:")
        print("   currentHouseholdKey: \(currentHouseholdKey ?? "NIL")")

        // 3. Fetch ALL categories (both stores)
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]

        do {
            let allCategories = try viewContext.fetch(categoryRequest)
            print("\n📂 ALL CATEGORIES IN DATABASE (\(allCategories.count) total):")

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
                print("   [\(storeName)] '\(category.name ?? "unnamed")' - householdKey: \(category.householdKey ?? "nil"), relationship: \(hasHouseholdRelation ? "YES" : "NO")")
            }

            print("\n📊 STORE SUMMARY:")
            print("   Private store categories: \(privateCount)")
            print("   Shared store categories: \(sharedCount)")
            print("   Unknown store categories: \(unknownStoreCount)")

            // 4. Check what the filter would show
            let filteredCategories = allCategories.filter { category in
                if let householdKey = currentHouseholdKey {
                    return category.householdKey == householdKey
                } else {
                    return category.householdKey == nil
                }
            }
            print("\n🎯 FILTER RESULT (\(filteredCategories.count) categories would show):")
            for category in filteredCategories {
                print("   '\(category.name ?? "unnamed")'")
            }

        } catch {
            print("   ❌ Error fetching categories: \(error)")
        }

        // 5. Check WeeklyLists for comparison
        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        if let allLists = try? viewContext.fetch(listRequest) {
            print("\n📋 WEEKLY LISTS FOR COMPARISON (\(allLists.count) total):")
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
                print("   [\(storeName)] '\(list.name ?? "unnamed")' - householdKey: \(list.householdKey ?? "nil")")
            }
        }

        print("\n" + String(repeating: "=", count: 60))
        print("END DIAGNOSTICS")
        print(String(repeating: "=", count: 60) + "\n")
    }
}
