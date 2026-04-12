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
    case sharedStoreTimeout
    case copyFailed(String)
    case memberCapReached(Int)    // M9.30: Household at maximum capacity
    case invitationExpired        // M9.30: Invitation older than 24 hours

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
        case .sharedStoreTimeout:
            return "iCloud took too long to set up sharing. Please try again."
        case .copyFailed(let reason):
            return "Failed to move data to household: \(reason)"
        case .memberCapReached(let max):
            return "Household has reached the maximum of \(max) members"
        case .invitationExpired:
            return "This invitation has expired. Ask the household owner for a new one."
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

    // M9.15.3: Returning user detection — background discovery state
    enum DiscoveryState: Equatable {
        case idle           // Not running (already has household or never started)
        case checking       // Actively checking for existing household
        case found          // Household discovered and restored
        case notFound       // Timed out with no household found
        case error(String)  // CloudKit error during discovery
    }
    @Published var discoveryState: DiscoveryState = .idle
    private var discoveryTask: Task<Void, Never>?

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

    // M9.13: Resolved DataScope for current household state.
    // Used by views that need to create entities via performScopedWrite.
    // M9.15.3: Returns .household scope based on whichever store the Household
    // currently lives in. After creation, the Household starts in the private store;
    // CloudKit migrates it to the shared store asynchronously. Both are valid.
    var currentScope: DataScope {
        guard let household = currentHousehold,
              let store = household.objectID.persistentStore else {
            return .personal
        }
        let isShared = store.url?.absoluteString.contains("shared") ?? false
        let storeID: StoreID = isShared ? .shared : .private
        return .household(id: household.objectID, storeID: storeID)
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
            // M9.15: Backfill householdKey on Ingredient/GroceryListItem for existing household users
            backfillChildEntityHouseholdKeys()
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
        let diag = DiagnosticLogger.shared
        diag.debug("loadCurrentHousehold() called", category: .household)
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1

        do {
            let households = try viewContext.fetch(request)

            if let household = households.first {
                diag.info("Found Household: '\(household.name ?? "unnamed")' id=\(household.id?.uuidString ?? "nil")", category: .household)
                // M7.2.2 FIX: Check if user has locally "left" this household
                // CloudKit limitation: Members can't remove themselves from CKShare.participants
                // So we track left households locally to prevent re-joining
                if let householdID = household.id?.uuidString, hasLeftHousehold(householdID) {
                    diag.info("Household marked as left in Keychain — checking CKShare", category: .household)
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
                diag.info("CKShare membership check: \(isMember ? "IS member" : "NOT member")", category: .household)

                if isMember {
                    currentHousehold = household

                    // M9.31: Clear ghost detection counter on successful membership check
                    if let householdID = household.id?.uuidString {
                        UserDefaults.standard.removeObject(forKey: "ghostDetectionCount_\(householdID)")
                    }

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

                    // M9.30: Clean expired invitations and auto-revert public permission
                    cleanExpiredInvitations(household: household)
                    await revertPublicPermissionIfNeeded(household: household)

                    // M7.2.2: Check for member departures via CKShare polling (owner-only)
                    await checkForMemberDepartures()
                } else {
                    // M9.31: Layered ghost detection — prevent false positives from
                    // transient fetchShares failures (e.g., during share acceptance sync).

                    // Fix 1: Owner's household is NEVER ghost-detected
                    // Use the isOwner() method which already handles the CKContainer lookup
                    let isOwnerDevice = await isOwner(household: household)
                    if isOwnerDevice {
                        diag.warning("M9.31: Owner's getShare failed but household is ours — loading anyway", category: .household)
                        currentHousehold = household
                        return
                    }

                    // Fix 3: Never ghost-delete a household with real data
                    let hasData = (household.recipes?.count ?? 0) > 0
                        || (household.weeklyLists?.count ?? 0) > 0
                        || (household.categories?.count ?? 0) > 0
                    if hasData {
                        diag.warning("M9.31: Household has data (\(household.recipes?.count ?? 0) recipes) — not a ghost, loading anyway", category: .household)
                        currentHousehold = household
                        return
                    }

                    // Fix 4: Require 3 consecutive launch failures before ghost deletion
                    let ghostKey = "ghostDetectionCount_\(household.id?.uuidString ?? "unknown")"
                    let consecutiveFailures = UserDefaults.standard.integer(forKey: ghostKey) + 1
                    if consecutiveFailures < 3 {
                        UserDefaults.standard.set(consecutiveFailures, forKey: ghostKey)
                        diag.warning("M9.31: Ghost detection attempt \(consecutiveFailures)/3 — loading anyway", category: .household)
                        currentHousehold = household
                        return
                    }

                    // 3+ consecutive failures on an empty, non-owner household — genuinely a ghost
                    UserDefaults.standard.removeObject(forKey: ghostKey)
                    diag.warning("M9.31: Ghost confirmed after 3 launches — deleting '\(household.name ?? "Unknown")'", category: .household)
                    CloudKitLogger.warning("Deleting ghost Household '\(household.name ?? "Unknown")' — no CKShare after 3 attempts")
                    viewContext.delete(household)
                    let memberRequest: NSFetchRequest<HouseholdMember> = HouseholdMember.fetchRequest()
                    if let members = try? viewContext.fetch(memberRequest) {
                        for member in members { viewContext.delete(member) }
                    }
                    try? viewContext.save()
                    currentHousehold = nil
                }
            } else {
                diag.debug("No Household entity found in store", category: .household)
                currentHousehold = nil
            }
        } catch {
            diag.error("loadCurrentHousehold() failed: \(error.localizedDescription)", category: .household)
            CloudKitLogger.error("Error loading household", error: error)
            errorMessage = "Failed to load household"
            currentHousehold = nil
        }
    }

    // MARK: - M9.15.3: Returning User Detection

    /// Background discovery for returning users after app reinstall.
    /// CloudKit re-downloads Household to shared store, but UserDefaults is gone
    /// so currentHousehold is nil. This listens for sync events and re-checks.
    /// Non-blocking — app is fully usable while this runs.
    func discoverExistingHousehold() {
        let diag = DiagnosticLogger.shared
        // Only run if no household is known
        guard currentHousehold == nil else {
            discoveryState = .idle
            return
        }

        diag.info("=== DISCOVERY START ===", category: .discovery)
        discoveryState = .checking

        discoveryTask = Task { [weak self] in
            guard let self else { return }

            // Immediate check — shared store may already have data from a prior sync
            await self.loadCurrentHousehold()
            if self.currentHousehold != nil {
                self.discoveryState = .found
                diag.info("Household discovered immediately", category: .discovery)
                return
            }

            // Listen for sync events with timeout — CloudKit may still be syncing
            // 30 attempts × 2s = 60s max wait
            for attempt in 1...30 {
                guard !Task.isCancelled else {
                    diag.info("Discovery cancelled at attempt \(attempt)", category: .discovery)
                    return
                }

                try? await Task.sleep(nanoseconds: 2_000_000_000)

                guard !Task.isCancelled else {
                    diag.info("Discovery cancelled at attempt \(attempt)", category: .discovery)
                    return
                }
                guard self.currentHousehold == nil else {
                    self.discoveryState = .found
                    diag.info("Household found externally at attempt \(attempt)", category: .discovery)
                    return
                }

                await self.loadCurrentHousehold()
                if self.currentHousehold != nil {
                    self.discoveryState = .found
                    diag.info("Household discovered on attempt \(attempt)/30", category: .discovery)
                    return
                }

                if attempt % 5 == 0 {
                    diag.debug("Discovery polling... attempt \(attempt)/30", category: .discovery)
                }
            }

            // Timed out
            if self.currentHousehold == nil {
                self.discoveryState = .notFound
                diag.info("=== DISCOVERY TIMEOUT — no household found after 60s ===", category: .discovery)
            }
        }
    }

    /// Cancel background discovery (e.g., user taps Create Household)
    func cancelDiscovery() {
        discoveryTask?.cancel()
        discoveryTask = nil
        if discoveryState == .checking {
            discoveryState = .idle
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

        // Step 5: Delete the Household entity itself (M10.6.17 FIX)
        // The Household lives in the PRIVATE store (attach-then-share pattern) and survives
        // shared store cleanup. Without this, ghost Household triggers awakeFromInsert auto-assign.
        viewContext.delete(household)
        CloudKitLogger.debug("Deleted Household entity from private store")

        // Step 5b: Delete HouseholdMember entities
        let memberRequest: NSFetchRequest<HouseholdMember> = HouseholdMember.fetchRequest()
        if let members = try? viewContext.fetch(memberRequest) {
            for member in members { viewContext.delete(member) }
            CloudKitLogger.debug("Deleted \(members.count) HouseholdMember entities")
        }

        // Step 6: Delete data by householdKey (M7.3.3 FIX)
        // This ensures orphaned data is cleaned up regardless of store location
        // Prevents duplicates if user rejoins the same household later
        let deletedByKey = deleteHouseholdLinkedData(householdKey: householdID)
        CloudKitLogger.debug("Deleted \(deletedByKey) objects with householdKey=\(householdID)")

        // Step 7: Also purge any remaining shared store objects
        let deletedFromStore = PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
        CloudKitLogger.debug("Purged \(deletedFromStore) shared store objects")

        // Step 8: Reset context BEFORE destroying shared store (M7.3.3)
        // This clears all in-memory managed object references, preventing crashes
        // when SwiftUI tries to access objects from the destroyed store
        viewContext.reset()
        CloudKitLogger.debug("Reset viewContext to clear in-memory references")

        // Step 9: Destroy and recreate shared store to clear local SQLite cache (M7.3.3)
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

            // M9.15.3: Restore default categories after clean delete
            // copyPersonalDataToHousehold moved all personal categories into the household,
            // so a clean delete leaves zero categories. Re-seed so the user has defaults.
            try DefaultSeeder.ensureUncategorizedExists(in: viewContext)
            try DefaultSeeder.ensureNoStoreExists(in: viewContext)
            DefaultSeeder.resetSeedingForRestore()
            try DefaultSeeder.seedDefaultsIfNeeded(in: viewContext)
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

        // Step 3: Mark household as deleted in Keychain so ghost detection
        // treats it as a ghost if CloudKit re-syncs it after reinstall (M9.30)
        if let householdID = household.id?.uuidString {
            KeychainHelper.markHouseholdAsLeft(householdID)
            DiagnosticLogger.shared.info(
                "M9.30: Marked household \(householdID) as deleted in Keychain",
                category: .household)
        }

        // Step 4: Clear current household FIRST so UI stops referencing shared objects
        currentHousehold = nil
        knownParticipantRecordIDs = nil

        // Step 5: Delete household entity
        viewContext.delete(household)
        try viewContext.save()

        // Step 6: Purge shared store objects from context
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

            // M10.6.17 FIX: Delete the Household entity itself (lives in private store)
            viewContext.delete(household)
            #if DEBUG
            print("✅ M10.6.17: Deleted ghost Household entity from private store")
            #endif

            // M10.6.17: Delete HouseholdMember entities
            let memberRequest: NSFetchRequest<HouseholdMember> = HouseholdMember.fetchRequest()
            if let members = try? viewContext.fetch(memberRequest) {
                for member in members { viewContext.delete(member) }
                #if DEBUG
                print("✅ M10.6.17: Deleted \(members.count) HouseholdMember entities")
                #endif
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
        // M9.15.3: Fetch by householdKey predicate instead of relationship
        // IngredientTemplateService.findOrCreateTemplate sets householdKey but NOT the
        // household relationship, so relationship-based fetches miss those entities.
        let householdKey = household.id?.uuidString ?? ""

        let recipeSet: Set<Recipe> = {
            let req: NSFetchRequest<Recipe> = Recipe.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            return Set((try? viewContext.fetch(req)) ?? [])
        }()
        let listSet: Set<WeeklyList> = {
            let req: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            return Set((try? viewContext.fetch(req)) ?? [])
        }()
        let mealPlanSet: Set<MealPlan> = {
            let req: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            return Set((try? viewContext.fetch(req)) ?? [])
        }()
        let categorySet: Set<Category> = {
            let req: NSFetchRequest<Category> = Category.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            return Set((try? viewContext.fetch(req)) ?? [])
        }()
        let templateSet: Set<IngredientTemplate> = {
            let req: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            return Set((try? viewContext.fetch(req)) ?? [])
        }()

        // M7.2.2: Fetch existing personal categories and templates to avoid duplicates
        // When a user joins a household, their personal data stays in the private store.
        // Migrating without dedup would create duplicates of everything they already had.
        // M9.15.3 FIX: Build lookup maps so skipped items still get mapped for downstream re-linking
        let existingCategoriesByName: [String: Category] = {
            let req: NSFetchRequest<Category> = Category.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            var map: [String: Category] = [:]
            for cat in results {
                let key = cat.normalizedName ?? cat.name?.lowercased() ?? ""
                if !key.isEmpty { map[key] = cat }
            }
            return map
        }()

        let existingTemplatesByName: [String: IngredientTemplate] = {
            let req: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            var map: [String: IngredientTemplate] = [:]
            for tmpl in results {
                let key = tmpl.canonicalName ?? tmpl.name?.lowercased() ?? ""
                if !key.isEmpty { map[key] = tmpl }
            }
            return map
        }()

        // Migrate categories first (needed for ingredient templates)
        // Skip categories that already exist in personal store by normalized name
        // M9.15.3: Map skipped categories to existing personal copies so templates keep their links
        var categoryMapping: [UUID: Category] = [:]
        var skippedCategories = 0
        for oldCategory in categorySet {
            let normalizedName = oldCategory.normalizedName ?? oldCategory.name?.lowercased() ?? ""
            if let existingPersonal = existingCategoriesByName[normalizedName] {
                // Category exists — map old household ID → existing personal entity
                if let oldId = oldCategory.id {
                    categoryMapping[oldId] = existingPersonal
                }
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

        let diag = DiagnosticLogger.shared
        diag.debug("Migration: \(categorySet.count) categories — \(categorySet.count - skippedCategories) new, \(skippedCategories) mapped to existing", category: .household)

        // M10.6.20: Re-link GroceryItem.categoryEntity to new personal Categories
        let groceryItemRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let groceryItems = try viewContext.fetch(groceryItemRequest)
        for item in groceryItems {
            if let catName = item.category, !catName.isEmpty {
                let catReq: NSFetchRequest<Category> = Category.fetchRequest()
                catReq.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == nil", catName)
                catReq.fetchLimit = 1
                item.categoryEntity = try? viewContext.fetch(catReq).first
            }
        }

        // Migrate ingredient templates, skipping those that already exist by canonical name
        // M9.15.3: Map skipped templates to existing personal copies so ingredients keep their links
        var templateMapping: [UUID: IngredientTemplate] = [:]
        var skippedTemplates = 0
        for oldTemplate in templateSet {
            let canonicalName = oldTemplate.canonicalName ?? oldTemplate.name?.lowercased() ?? ""
            if let existingPersonal = existingTemplatesByName[canonicalName] {
                // Template exists — map old household ID → existing personal entity
                if let oldId = oldTemplate.id {
                    templateMapping[oldId] = existingPersonal
                }
                // M9.15.3: If existing personal template lacks a category but the household
                // one has one, adopt the household's category (mapped to personal)
                if existingPersonal.categoryEntity == nil,
                   let oldCat = oldTemplate.categoryEntity, let oldCatId = oldCat.id,
                   let newCat = categoryMapping[oldCatId] {
                    existingPersonal.categoryEntity = newCat
                }
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

            // M9.12: Link categoryEntity using categoryMapping instead of copying string
            if let oldCat = oldTemplate.categoryEntity, let oldCatId = oldCat.id,
               let newCat = categoryMapping[oldCatId] {
                newTemplate.categoryEntity = newCat
            }

            if let oldId = oldTemplate.id {
                templateMapping[oldId] = newTemplate
            }
        }

        diag.debug("Migration: \(templateSet.count) templates — \(templateSet.count - skippedTemplates) new, \(skippedTemplates) mapped to existing", category: .household)

        // Migrate stores (M18.1.5) — skip duplicates by name
        let storeSet: Set<Store> = {
            let req: NSFetchRequest<Store> = Store.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            return Set((try? viewContext.fetch(req)) ?? [])
        }()
        let existingStoreNames: Set<String> = {
            let req: NSFetchRequest<Store> = Store.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.name?.lowercased() })
        }()
        var storeMapping: [UUID: Store] = [:]
        for oldStore in storeSet {
            let name = oldStore.name?.lowercased() ?? ""
            if existingStoreNames.contains(name) { continue }
            let newStore = Store(context: viewContext)
            newStore.id = UUID()
            newStore.name = oldStore.name
            newStore.color = oldStore.color
            newStore.sortOrder = oldStore.sortOrder
            newStore.dateCreated = oldStore.dateCreated
            newStore.updatedAt = oldStore.updatedAt
            newStore.household = nil
            newStore.householdKey = nil
            if let oldId = oldStore.id { storeMapping[oldId] = newStore }
        }
        // Re-link migrated templates' preferredStore
        for oldTemplate in templateSet {
            if let oldStoreId = oldTemplate.preferredStore?.id,
               let newStore = storeMapping[oldStoreId],
               let oldTemplateId = oldTemplate.id,
               let newTemplate = templateMapping[oldTemplateId] {
                newTemplate.preferredStore = newStore
            }
        }
        if !storeSet.isEmpty {
            diag.debug("Migration: \(storeSet.count) stores — \(storeMapping.count) new", category: .household)
        }

        // Fetch existing personal recipe titles to avoid duplicates
        let existingRecipeTitles: Set<String> = {
            let req: NSFetchRequest<Recipe> = Recipe.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.title?.lowercased() })
        }()

        // Migrate recipes with ingredients, skipping duplicates by title
        var recipeMapping: [UUID: Recipe] = [:]
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
            // M10.4.0: Recipe attribution fields
            newRecipe.imageURL = oldRecipe.imageURL
            newRecipe.author = oldRecipe.author
            newRecipe.household = nil
            newRecipe.householdKey = nil

            if let oldId = oldRecipe.id { recipeMapping[oldId] = newRecipe }
            diag.debug("Migrated recipe '\(oldRecipe.title ?? "?")': imageURL=\(oldRecipe.imageURL != nil ? "yes" : "nil"), author=\(oldRecipe.author ?? "nil")", category: .household)

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
                // M9.15: Ingredient is now HouseholdScoped — inherit from parent Recipe
                newIngredient.household = newRecipe.household
                newIngredient.householdKey = newRecipe.householdKey

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
                // M9.12: Link categoryEntity using categoryMapping instead of copying string
                if let oldCat = oldItem.categoryEntity, let oldCatId = oldCat.id {
                    if let newCat = categoryMapping[oldCatId] {
                        newItem.categoryEntity = newCat
                    } else {
                        diag.debug("  ⚠️ Migrate GroceryListItem '\(oldItem.name ?? "?")' category '\(oldCat.name ?? "?")' (id=\(oldCatId)) NOT in categoryMapping — \(categoryMapping.count) entries", category: .household)
                    }
                }
                newItem.sortOrder = oldItem.sortOrder
                newItem.isCompleted = oldItem.isCompleted
                newItem.isParseable = oldItem.isParseable
                newItem.parseConfidence = oldItem.parseConfidence
                newItem.weeklyList = newList
                // M9.15: GroceryListItem is now HouseholdScoped — inherit from parent WeeklyList
                newItem.household = newList.household
                newItem.householdKey = newList.householdKey
            }
        }

        // Fetch existing personal meal plan names to avoid duplicates
        let existingPlanNames: Set<String> = {
            let req: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
            req.predicate = NSPredicate(format: "householdKey == nil")
            let results = (try? viewContext.fetch(req)) ?? []
            return Set(results.compactMap { $0.name?.lowercased() })
        }()

        // Migrate meal plans with planned meals, skipping duplicates by name
        var mealPlanMapping: [UUID: MealPlan] = [:]
        var skippedPlans = 0
        var migratedPlannedMeals = 0
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

            if let oldId = oldPlan.id { mealPlanMapping[oldId] = newPlan }
        }

        // M10.6.20: Copy PlannedMeals from household MealPlans to personal MealPlans
        for oldPlan in mealPlanSet {
            guard let oldPlanId = oldPlan.id,
                  let newPlan = mealPlanMapping[oldPlanId] else { continue }
            let oldMeals = oldPlan.plannedMeals as? Set<PlannedMeal> ?? []
            for oldMeal in oldMeals {
                let newMeal = PlannedMeal(context: viewContext)
                newMeal.id = UUID()
                newMeal.date = oldMeal.date
                newMeal.mealType = oldMeal.mealType
                newMeal.notes = oldMeal.notes
                newMeal.isCompleted = oldMeal.isCompleted
                newMeal.scaleFactor = oldMeal.scaleFactor
                newMeal.servings = oldMeal.servings
                newMeal.quickOption = oldMeal.quickOption
                newMeal.slotKey = oldMeal.slotKey
                newMeal.household = nil
                newMeal.householdKey = nil
                newMeal.mealPlan = newPlan
                // Remap recipe relationship to new personal copy
                if let oldRecipeId = oldMeal.recipe?.id,
                   let newRecipe = recipeMapping[oldRecipeId] {
                    newMeal.recipe = newRecipe
                }
                migratedPlannedMeals += 1
            }
        }

        #if DEBUG
        print("📊 M7.2.2: Migrated household data to personal:")
        print("   \(categorySet.count - skippedCategories) categories (\(skippedCategories) skipped — already exist)")
        print("   \(templateSet.count - skippedTemplates) ingredient templates (\(skippedTemplates) skipped — already exist)")
        print("   \(recipeSet.count - skippedRecipes) recipes (\(skippedRecipes) skipped — already exist)")
        print("   \(listSet.count - skippedLists) weekly lists (\(skippedLists) skipped — already exist)")
        print("   \(mealPlanSet.count - skippedPlans) meal plans (\(skippedPlans) skipped — already exist)")
        print("   \(migratedPlannedMeals) planned meals")
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
    
    /// M9.15: Creates household using create-empty-then-copy pattern.
    /// Replaces the broken attach-then-share pattern (ADR 008) that caused
    /// CloudKit error 134060 when objects had existing CKRecords in the private zone.
    ///
    /// New flow:
    /// 1. Create empty Household + HouseholdMember (no data relationships)
    /// 2. Share via CloudKit (single object = no zone conflicts)
    /// 3. Wait for shared store to be ready
    /// 4. Copy personal data to shared store as new objects via ManagedObjectFactory
    /// 5. Delete old private-store originals
    ///
    /// The `moveExistingData` parameter is preserved for API compatibility but is
    /// effectively always true — there's no reason to leave data orphaned in private store.
    func createHouseholdAndShare(name: String, ownerName: String, moveExistingData: Bool) async throws -> Household {
        // M9.15.3: Stop background discovery — user explicitly chose to create
        cancelDiscovery()

        let diag = DiagnosticLogger.shared
        diag.info("=== CREATE HOUSEHOLD START ===", category: .household)
        diag.info("Name: \(name), Owner: \(ownerName), MoveData: \(moveExistingData)", category: .household)

        isLoading = true
        creationStatus = "Checking iCloud account…"
        defer {
            isLoading = false
            creationStatus = nil
        }

        // M7.3.3: Prevent creating a household when already in one
        if currentHousehold != nil {
            CloudKitLogger.warning("Cannot create household - already in one")
            throw HouseholdError.alreadyInHousehold
        }

        // Also check for any existing households in the database
        let existingRequest: NSFetchRequest<Household> = Household.fetchRequest()
        existingRequest.fetchLimit = 1
        if let existingHouseholds = try? viewContext.fetch(existingRequest),
           !existingHouseholds.isEmpty {
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
            case .available: statusName = "iCloud available"
            case .noAccount: statusName = "No iCloud account signed in"
            case .restricted: statusName = "iCloud access is restricted"
            case .couldNotDetermine: statusName = "Could not determine iCloud status"
            case .temporarilyUnavailable: statusName = "iCloud is temporarily unavailable"
            @unknown default: statusName = "iCloud unavailable (status: \(accountStatus.rawValue))"
            }
            throw HouseholdError.creationFailed(statusName)
        }

        // M10.6: Pre-creation cleanup — remove orphaned objects from previous households
        cleanOrphanedHouseholdData()

        do {
            #if DEBUG
            print("\n🏗️ M9.15: Creating household (create-empty-then-copy pattern)")
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

            // 2. Create EMPTY Household + owner member (no data relationships!)
            // M9.15: Critical difference from old pattern — DO NOT attach any data here.
            // Sharing an empty object means no CKRecords need to move between zones.
            diag.info("Step 2: Creating empty Household entity", category: .household)
            creationStatus = "Creating household…"
            let household = Household(context: viewContext)
            household.id = UUID()
            household.name = name
            household.ownerRecordName = ownerIdentifier
            household.ownerDisplayName = ownerName
            household.createdDate = Date()

            let ownerMember = HouseholdMember(context: viewContext)
            ownerMember.id = UUID()
            ownerMember.email = ownerIdentifier
            ownerMember.displayName = ownerName
            UserDefaults.standard.set(ownerName, forKey: "cachedOwnerDisplayName")
            ownerMember.role = "owner"
            ownerMember.status = "active"
            ownerMember.joinedDate = Date()
            ownerMember.household = household

            // 3. Save empty household to Core Data (private store initially)
            diag.info("Step 3: Saving empty Household to private store", category: .household)
            creationStatus = "Saving to device…"
            do {
                try viewContext.save()
                diag.info("Step 3: Save succeeded", category: .household)
            } catch {
                diag.error("Step 3 FAILED: \(Self.extractDetailedError(error))", category: .household)
                throw HouseholdError.creationFailed("Failed to save household locally: \(Self.extractDetailedError(error))")
            }

            #if DEBUG
            household.logStoreIdentity()  // Should show "Private Store"
            #endif

            // 4. Share the EMPTY household via CloudKit
            // M9.15: Only Household + HouseholdMember are shared — no data graph = no zone conflicts
            diag.info("Step 4: Sharing empty Household via CloudKit", category: .household)
            let persistenceController = PersistenceController.shared
            creationStatus = "Setting up CloudKit sharing…"
            let share: CKShare
            do {
                share = try await shareWithRetry(household: household, persistence: persistenceController) { status in
                    self.creationStatus = status
                }
                diag.info("Step 4: CKShare created: \(share.recordID.recordName)", category: .household)
            } catch {
                diag.error("Step 4 FAILED — CloudKit sharing: \(Self.extractDetailedError(error))", category: .household)
                CloudKitLogger.householdError("CloudKit sharing failed after retries", householdID: household.id?.uuidString, error: error)
                viewContext.delete(ownerMember)
                viewContext.delete(household)
                try? viewContext.save()
                throw HouseholdError.creationFailed("CloudKit sharing failed: \(Self.extractDetailedError(error))")
            }

            #if DEBUG
            print("✅ CKShare created: \(share.recordID.recordName)")
            #endif

            // 5. Persist the CKShare
            diag.info("Step 5: Persisting CKShare to context", category: .household)
            creationStatus = "Finalizing CloudKit share…"
            try viewContext.save()

            #if DEBUG
            print("✅ Context saved - CKShare should sync to CloudKit now")
            household.logStoreIdentity()  // Should show "Shared Store" after share
            #endif

            // 6. Store share record reference
            diag.info("Step 6: Archiving CKShare reference", category: .household)
            household.shareRecord = try NSKeyedArchiver.archivedData(
                withRootObject: share,
                requiringSecureCoding: true
            )
            viewContext.refreshAllObjects()
            try viewContext.save()

            // 7. Copy personal data with household relationship (if requested)
            // M9.21: Copies stay in the private store (default). On the owner's phone,
            // the shared store is for OTHER users' data, not the owner's. The mirroring
            // delegate uses Core Data relationships to determine CloudKit zone assignment.
            // Setting new.household = household places copies in the same shared zone.
            if moveExistingData {
                diag.info("Step 7: Copying personal data to household", category: .household)
                creationStatus = "Linking your data to household…"
                try copyPersonalDataToHousehold(household: household)
                diag.info("Step 7: Data copy complete", category: .household)
            } else {
                diag.info("Step 7: Skipped (moveExistingData=false)", category: .household)
            }

            // 8. Break GroceryItem→Category cross-store relationships
            diag.info("Step 8: Breaking cross-store GroceryItem→Category links", category: .household)
            breakGroceryItemCategoryLinks()

            // 9. Update state
            currentHousehold = household
            creationStatus = "Done!"
            diag.info("=== CREATE HOUSEHOLD COMPLETE ===", category: .household)

            // M9.30: Push existing Keychain API key to new Household (encrypted)
            // so the user doesn't have to re-enter it after creating a household
            if let existingKey = KeychainHelper.getLLMAPIKey(), !existingKey.isEmpty,
               let householdID = household.id {
                household.llmAPIKey = try? HouseholdKeyEncryption.encrypt(existingKey, householdID: householdID)
                try? viewContext.save()
                diag.info("M9.30: Pushed existing API key to new household (encrypted)", category: .household)
            }

            CloudKitLogger.householdCreated(name)
            CloudKitLogger.shareCreated(recordID: share.recordID.recordName)
            if moveExistingData {
                CloudKitLogger.debug("Personal data copied to household — CloudKit will migrate to shared zone")
            }

            return household

        } catch let householdError as HouseholdError {
            diag.error("=== CREATE HOUSEHOLD FAILED: \(householdError.localizedDescription) ===", category: .household)
            throw householdError
        } catch {
            diag.error("=== CREATE HOUSEHOLD FAILED: \(Self.extractDetailedError(error)) ===", category: .household)
            CloudKitLogger.householdError("Household creation failed", householdID: nil, error: error)
            throw HouseholdError.creationFailed(Self.extractDetailedError(error))
        }
    }

    // MARK: - M9.15.3: Copy-and-Delete Household Data Helpers

    /// M9.15.3: Copy personal data into the household by creating NEW objects with
    /// householdKey set, then deleting the originals.
    ///
    /// Why copy-and-delete instead of stamp-in-place:
    /// Stamping modifies existing objects that may have stale CKRecord zone metadata
    /// from a previous household. CloudKit's mirroring delegate tracks zone assignments
    /// by persistent ID. When SQLite reuses row IDs for deleted+recreated objects,
    /// the delegate finds the new object in BOTH the old shared zone and the private
    /// zone → error 134060. Creating fresh objects guarantees persistent IDs the
    /// delegate has never seen → no zone conflicts.
    ///
    /// Copy order respects the entity dependency graph (parents before children):
    /// Categories → IngredientTemplates → Recipes → Ingredients
    /// → WeeklyLists → GroceryListItems → MealPlans → PlannedMeals
    private func copyPersonalDataToHousehold(household: Household) throws {
        let diag = DiagnosticLogger.shared
        guard let householdKey = household.id?.uuidString else {
            throw HouseholdError.copyFailed("Household missing ID")
        }

        let persistence = PersistenceController.shared
        var copiedCount = 0

        // M9.21: Log store identity for diagnostics
        let householdStore = household.objectID.persistentStore?.url?.lastPathComponent ?? "unknown"
        diag.info("copyPersonalData: household store=\(householdStore), householdKey=\(householdKey)", category: .household)

        // M9.21: Copies stay in the PRIVATE store (default for Entity(context:)).
        // On the owner's phone, the shared store mirrors OTHER users' shares — not the owner's.
        // The owner's shared zone lives in the private CloudKit database.
        // The mirroring delegate uses Core Data RELATIONSHIPS (not string attributes) to
        // determine zone assignment. Setting new.household = household tells the mirroring
        // delegate to place each copy's CKRecord in the same shared zone as the household.
        // This is safe because both household and copies are in the private store at copy time.

        // --- Categories ---
        var categoryMapping: [UUID: Category] = [:]
        let categoryReq: NSFetchRequest<Category> = Category.fetchRequest()
        categoryReq.predicate = NSPredicate(format: "householdKey == nil")
        categoryReq.affectedStores = [persistence.privateStore]
        let oldCategories = (try? viewContext.fetch(categoryReq)) ?? []
        for old in oldCategories {
            let new = Category(context: viewContext)
            new.id = UUID()
            new.name = old.name
            new.sortOrder = old.sortOrder
            new.color = old.color
            new.isDefault = old.isDefault
            new.dateCreated = old.dateCreated
            new.normalizedName = old.normalizedName
            new.updatedAt = old.updatedAt
            // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
            new.household = household
            new.householdKey = householdKey
            if let oldId = old.id { categoryMapping[oldId] = new }
            copiedCount += 1
        }
        if !oldCategories.isEmpty {
            diag.debug("Copied \(oldCategories.count) Category(s) to household", category: .household)
        }

        // --- IngredientTemplates ---
        var templateMapping: [UUID: IngredientTemplate] = [:]
        let templateReq: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateReq.predicate = NSPredicate(format: "householdKey == nil")
        templateReq.affectedStores = [persistence.privateStore]
        let oldTemplates = (try? viewContext.fetch(templateReq)) ?? []
        for old in oldTemplates {
            let new = IngredientTemplate(context: viewContext)
            new.id = UUID()
            new.name = old.name
            new.canonicalName = old.canonicalName
            new.usageCount = old.usageCount
            new.dateCreated = old.dateCreated
            new.updatedAt = old.updatedAt
            new.isStaple = old.isStaple
            // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
            new.household = household
            new.householdKey = householdKey
            // Re-link category to new copy
            if let oldCat = old.categoryEntity, let oldCatId = oldCat.id,
               let newCat = categoryMapping[oldCatId] {
                new.categoryEntity = newCat
            }
            if let oldId = old.id { templateMapping[oldId] = new }
            copiedCount += 1
        }
        if !oldTemplates.isEmpty {
            diag.debug("Copied \(oldTemplates.count) IngredientTemplate(s) to household", category: .household)
        }

        // --- Recipes + Ingredients ---
        var recipeMapping: [UUID: Recipe] = [:]
        let recipeReq: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeReq.predicate = NSPredicate(format: "householdKey == nil")
        recipeReq.affectedStores = [persistence.privateStore]
        let oldRecipes = (try? viewContext.fetch(recipeReq)) ?? []
        for old in oldRecipes {
            let new = Recipe(context: viewContext)
            new.id = UUID()
            new.title = old.title
            new.instructions = old.instructions
            new.servings = old.servings
            new.cookTime = old.cookTime
            new.prepTime = old.prepTime
            new.sourceURL = old.sourceURL
            new.tags = old.tags
            new.dateCreated = old.dateCreated
            new.isFavorite = old.isFavorite
            new.usageCount = old.usageCount
            // M10.4.0: Recipe attribution fields
            new.imageURL = old.imageURL
            new.author = old.author
            new.lastUsed = old.lastUsed
            // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
            new.household = household
            new.householdKey = householdKey
            if let oldId = old.id { recipeMapping[oldId] = new }
            copiedCount += 1
            diag.debug("Copied recipe '\(old.title ?? "?")': imageURL=\(old.imageURL != nil ? "yes" : "nil"), author=\(old.author ?? "nil")", category: .household)

            // Copy child Ingredients
            let ingredientSet = old.ingredients as? Set<Ingredient> ?? []
            for oldIng in ingredientSet {
                let newIng = Ingredient(context: viewContext)
                newIng.id = UUID()
                newIng.name = oldIng.name
                newIng.displayText = oldIng.displayText
                newIng.numericValue = oldIng.numericValue
                newIng.standardUnit = oldIng.standardUnit
                newIng.notes = oldIng.notes
                newIng.sortOrder = oldIng.sortOrder
                newIng.isParseable = oldIng.isParseable
                newIng.parseConfidence = oldIng.parseConfidence
                newIng.recipe = new
                // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
                newIng.household = household
                newIng.householdKey = householdKey
                // Re-link template to new copy
                if let oldTemplateId = oldIng.ingredientTemplate?.id,
                   let newTemplate = templateMapping[oldTemplateId] {
                    newIng.ingredientTemplate = newTemplate
                }
                copiedCount += 1
            }
        }
        if !oldRecipes.isEmpty {
            diag.debug("Copied \(oldRecipes.count) Recipe(s) to household", category: .household)
        }

        // --- Stores (M18.1.5) ---
        var storeMapping: [UUID: Store] = [:]
        let storeReq: NSFetchRequest<Store> = Store.fetchRequest()
        storeReq.predicate = NSPredicate(format: "householdKey == nil")
        storeReq.affectedStores = [persistence.privateStore]
        let oldStores = (try? viewContext.fetch(storeReq)) ?? []
        for old in oldStores {
            let new = Store(context: viewContext)
            new.id = UUID()
            new.name = old.name
            new.color = old.color
            new.sortOrder = old.sortOrder
            new.dateCreated = old.dateCreated
            new.updatedAt = old.updatedAt
            new.household = household
            new.householdKey = householdKey
            if let oldId = old.id { storeMapping[oldId] = new }
            copiedCount += 1
        }
        // Re-link template preferredStore to new household copies
        for oldTemplate in oldTemplates {
            if let oldStoreId = oldTemplate.preferredStore?.id,
               let newStore = storeMapping[oldStoreId],
               let oldTemplateId = oldTemplate.id,
               let newTemplate = templateMapping[oldTemplateId] {
                newTemplate.preferredStore = newStore
            }
        }
        if !oldStores.isEmpty {
            diag.debug("Copied \(oldStores.count) Store(s) to household", category: .household)
        }

        // --- WeeklyLists + GroceryListItems ---
        let listReq: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        listReq.predicate = NSPredicate(format: "householdKey == nil")
        listReq.affectedStores = [persistence.privateStore]
        let oldLists = (try? viewContext.fetch(listReq)) ?? []
        for old in oldLists {
            let new = WeeklyList(context: viewContext)
            new.id = UUID()
            new.name = old.name
            new.notes = old.notes
            new.dateCreated = old.dateCreated
            new.isCompleted = old.isCompleted
            // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
            new.household = household
            new.householdKey = householdKey
            copiedCount += 1

            // Copy child GroceryListItems
            let itemSet = old.items as? Set<GroceryListItem> ?? []
            for oldItem in itemSet {
                let newItem = GroceryListItem(context: viewContext)
                newItem.id = UUID()
                newItem.name = oldItem.name
                newItem.displayText = oldItem.displayText
                newItem.numericValue = oldItem.numericValue
                newItem.standardUnit = oldItem.standardUnit
                newItem.sortOrder = oldItem.sortOrder
                newItem.isCompleted = oldItem.isCompleted
                newItem.isParseable = oldItem.isParseable
                newItem.parseConfidence = oldItem.parseConfidence
                newItem.weeklyList = new
                // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
                newItem.household = household
                newItem.householdKey = householdKey
                // Re-link category to new copy
                if let oldCat = oldItem.categoryEntity, let oldCatId = oldCat.id {
                    if let newCat = categoryMapping[oldCatId] {
                        newItem.categoryEntity = newCat
                    } else {
                        diag.debug("  ⚠️ GroceryListItem '\(oldItem.name ?? "?")' category '\(oldCat.name ?? "?")' (id=\(oldCatId)) NOT in categoryMapping — \(categoryMapping.count) entries", category: .household)
                    }
                } else {
                    diag.debug("  GroceryListItem '\(oldItem.name ?? "?")' has no category", category: .household)
                }
                copiedCount += 1
            }
        }
        if !oldLists.isEmpty {
            diag.debug("Copied \(oldLists.count) WeeklyList(s) to household", category: .household)
        }

        // --- MealPlans + PlannedMeals ---
        let planReq: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        planReq.predicate = NSPredicate(format: "householdKey == nil")
        planReq.affectedStores = [persistence.privateStore]
        let oldPlans = (try? viewContext.fetch(planReq)) ?? []
        var mealPlanMapping: [UUID: MealPlan] = [:]
        for old in oldPlans {
            let new = MealPlan(context: viewContext)
            new.id = UUID()
            new.name = old.name
            new.startDate = old.startDate
            new.createdDate = old.createdDate
            new.duration = old.duration
            new.isActive = old.isActive
            new.isCompleted = old.isCompleted
            // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
            new.household = household
            new.householdKey = householdKey
            if let oldId = old.id { mealPlanMapping[oldId] = new }
            copiedCount += 1
        }
        // Copy PlannedMeals (second pass to use mealPlanMapping + recipeMapping)
        for old in oldPlans {
            guard let oldId = old.id, let newPlan = mealPlanMapping[oldId] else { continue }
            let oldMeals = old.plannedMeals as? Set<PlannedMeal> ?? []
            for oldMeal in oldMeals {
                let newMeal = PlannedMeal(context: viewContext)
                newMeal.id = UUID()
                newMeal.date = oldMeal.date
                newMeal.mealType = oldMeal.mealType
                newMeal.notes = oldMeal.notes
                newMeal.isCompleted = oldMeal.isCompleted
                newMeal.scaleFactor = oldMeal.scaleFactor
                newMeal.servings = oldMeal.servings
                newMeal.quickOption = oldMeal.quickOption
                newMeal.slotKey = oldMeal.slotKey
                newMeal.mealPlan = newPlan
                // M9.21: Relationship for CloudKit zone assignment + string for fetch predicates
                newMeal.household = household
                newMeal.householdKey = householdKey
                // Re-link recipe to new copy
                if let oldRecipeId = oldMeal.recipe?.id,
                   let newRecipe = recipeMapping[oldRecipeId] {
                    newMeal.recipe = newRecipe
                }
                copiedCount += 1
            }
        }
        if !oldPlans.isEmpty {
            diag.debug("Copied \(oldPlans.count) MealPlan(s) to household", category: .household)
        }

        // --- Delete originals (children first via cascade, but explicit for safety) ---
        for old in oldCategories { viewContext.delete(old) }
        for old in oldTemplates { viewContext.delete(old) }
        for old in oldStores { viewContext.delete(old) }
        for old in oldRecipes { viewContext.delete(old) }
        for old in oldLists { viewContext.delete(old) }
        for old in oldPlans { viewContext.delete(old) }

        try viewContext.save()
        diag.info("Copied \(copiedCount) total objects to household \(householdKey) (originals deleted)", category: .household)
    }

    // MARK: - M9.15: Create-Empty-Then-Copy Helpers (Legacy)

    /// M9.15: Copy all personal data from private store to shared store as new objects.
    /// Uses ManagedObjectFactory for correct store assignment. Copy order respects
    /// the entity relationship graph — parents before children.
    ///
    /// Pattern: fetch from private store → create new in shared store → reconstruct relationships → delete originals
    private func copyPersonalDataToSharedStore(household: Household) throws {
        let persistence = PersistenceController.shared
        let factory = ManagedObjectFactory(context: viewContext, persistence: persistence)
        let scope = DataScope.household(id: household.objectID, storeID: .shared)

        guard let householdKey = household.id?.uuidString else {
            throw HouseholdError.copyFailed("Household missing ID")
        }

        #if DEBUG
        print("\n📦 M9.15: Copying personal data to shared store...")
        #endif

        // Old→new ID maps for relationship reconstruction
        var categoryMap: [NSManagedObjectID: Category] = [:]
        var templateMap: [NSManagedObjectID: IngredientTemplate] = [:]
        var recipeMap: [NSManagedObjectID: Recipe] = [:]
        var weeklyListMap: [NSManagedObjectID: WeeklyList] = [:]
        var mealPlanMap: [NSManagedObjectID: MealPlan] = [:]

        // 1. Categories (no dependencies)
        let oldCategories = try fetchPersonalEntities(Category.self, persistence: persistence)
        for old in oldCategories {
            let new = try factory.make(Category.self, in: scope) { cat in
                self.copyAllAttributes(from: old, to: cat)
                cat.id = UUID()  // Fresh ID for shared store
            }
            categoryMap[old.objectID] = new
        }

        // 2. IngredientTemplates (→ Category)
        let oldTemplates = try fetchPersonalEntities(IngredientTemplate.self, persistence: persistence)
        for old in oldTemplates {
            let new = try factory.make(IngredientTemplate.self, in: scope) { tmpl in
                self.copyAllAttributes(from: old, to: tmpl)
                tmpl.id = UUID()
                if let oldCat = old.categoryEntity {
                    tmpl.categoryEntity = categoryMap[oldCat.objectID]
                }
            }
            templateMap[old.objectID] = new
        }

        // 3. Recipes (no entity dependencies)
        let oldRecipes = try fetchPersonalEntities(Recipe.self, persistence: persistence)
        for old in oldRecipes {
            let new = try factory.make(Recipe.self, in: scope) { recipe in
                self.copyAllAttributes(from: old, to: recipe)
                recipe.id = UUID()
            }
            recipeMap[old.objectID] = new
        }

        // 4. Ingredients (→ Recipe, → IngredientTemplate)
        // M9.15: Ingredient is now HouseholdScoped — inherits from parent Recipe
        let oldIngredients = try fetchPersonalEntities(Ingredient.self, persistence: persistence)
        for old in oldIngredients {
            let newIngredient = Ingredient(context: viewContext)
            copyAllAttributes(from: old, to: newIngredient)
            newIngredient.id = UUID()
            // Reconstruct relationships
            if let oldRecipe = old.recipe, let newRecipe = recipeMap[oldRecipe.objectID] {
                newIngredient.recipe = newRecipe
            }
            if let oldTemplate = old.ingredientTemplate, let newTemplate = templateMap[oldTemplate.objectID] {
                newIngredient.ingredientTemplate = newTemplate
            }
            // M9.15: Inherit household/householdKey from parent Recipe
            if let parentRecipe = newIngredient.recipe {
                newIngredient.household = parentRecipe.household
                newIngredient.householdKey = parentRecipe.householdKey
            } else {
                newIngredient.household = household
                newIngredient.householdKey = householdKey
            }
            // Assign to shared store
            viewContext.assign(newIngredient, to: persistence.sharedStore)
        }

        // 5. WeeklyLists (no entity dependencies)
        let oldLists = try fetchPersonalEntities(WeeklyList.self, persistence: persistence)
        for old in oldLists {
            let new = try factory.make(WeeklyList.self, in: scope) { list in
                self.copyAllAttributes(from: old, to: list)
                list.id = UUID()
            }
            weeklyListMap[old.objectID] = new
        }

        // 6. GroceryListItems (→ WeeklyList, → Category, → Recipe)
        // M9.15: GroceryListItem is now HouseholdScoped — inherits from parent WeeklyList
        let oldItems = try fetchPersonalEntities(GroceryListItem.self, persistence: persistence)
        for old in oldItems {
            let newItem = GroceryListItem(context: viewContext)
            copyAllAttributes(from: old, to: newItem)
            newItem.id = UUID()
            // Reconstruct relationships
            if let oldList = old.weeklyList, let newList = weeklyListMap[oldList.objectID] {
                newItem.weeklyList = newList
            }
            if let oldCat = old.categoryEntity, let newCat = categoryMap[oldCat.objectID] {
                newItem.categoryEntity = newCat
            }
            // Reconstruct sourceRecipes (to-many)
            if let oldSourceRecipes = old.sourceRecipes as? Set<Recipe> {
                for oldRecipe in oldSourceRecipes {
                    if let newRecipe = recipeMap[oldRecipe.objectID] {
                        newItem.addToSourceRecipes(newRecipe)
                    }
                }
            }
            // M9.15: Inherit household/householdKey from parent WeeklyList
            if let parentList = newItem.weeklyList {
                newItem.household = parentList.household
                newItem.householdKey = parentList.householdKey
            } else {
                newItem.household = household
                newItem.householdKey = householdKey
            }
            viewContext.assign(newItem, to: persistence.sharedStore)
        }

        // 7. MealPlans (no entity dependencies)
        let oldPlans = try fetchPersonalEntities(MealPlan.self, persistence: persistence)
        for old in oldPlans {
            let new = try factory.make(MealPlan.self, in: scope) { plan in
                self.copyAllAttributes(from: old, to: plan)
                plan.id = UUID()
            }
            mealPlanMap[old.objectID] = new
        }

        // 8. PlannedMeals (→ MealPlan, → Recipe)
        let oldMeals = try fetchPersonalEntities(PlannedMeal.self, persistence: persistence)
        for old in oldMeals {
            let _ = try factory.make(PlannedMeal.self, in: scope) { meal in
                self.copyAllAttributes(from: old, to: meal)
                meal.id = UUID()
                if let oldPlan = old.mealPlan, let newPlan = mealPlanMap[oldPlan.objectID] {
                    meal.mealPlan = newPlan
                }
                if let oldRecipe = old.recipe, let newRecipe = recipeMap[oldRecipe.objectID] {
                    meal.recipe = newRecipe
                }
            }
        }

        #if DEBUG
        print("📦 M9.15: Copy complete:")
        print("   Categories: \(oldCategories.count)")
        print("   IngredientTemplates: \(oldTemplates.count)")
        print("   Recipes: \(oldRecipes.count)")
        print("   Ingredients: \(oldIngredients.count)")
        print("   WeeklyLists: \(oldLists.count)")
        print("   GroceryListItems: \(oldItems.count)")
        print("   MealPlans: \(oldPlans.count)")
        print("   PlannedMeals: \(oldMeals.count)")
        #endif

        // Delete originals from private store (copy succeeded)
        // Delete in reverse dependency order: children first, parents last
        creationStatus = "Cleaning up old data…"
        for old in oldMeals { viewContext.delete(old) }
        for old in oldPlans { viewContext.delete(old) }
        for old in oldItems { viewContext.delete(old) }
        for old in oldLists { viewContext.delete(old) }
        for old in oldIngredients { viewContext.delete(old) }
        for old in oldRecipes { viewContext.delete(old) }
        for old in oldTemplates { viewContext.delete(old) }
        for old in oldCategories { viewContext.delete(old) }

        try viewContext.save()

        #if DEBUG
        print("✅ M9.15: Private store originals deleted, save complete")
        #endif
    }

    /// M9.15: Fetch entities from the private store only (excludes shared store objects).
    private func fetchPersonalEntities<T: NSManagedObject>(_ type: T.Type, persistence: PersistenceController) throws -> [T] {
        let request = type.fetchRequest() as! NSFetchRequest<T>
        request.affectedStores = [persistence.privateStore]
        return try viewContext.fetch(request)
    }

    /// M9.15: Copy all non-relationship attributes from one managed object to another.
    /// Uses Core Data entity description to dynamically enumerate attributes,
    /// ensuring full fidelity without manually listing every property.
    private func copyAllAttributes(from source: NSManagedObject, to destination: NSManagedObject) {
        for (name, _) in source.entity.attributesByName {
            // Skip id — caller assigns fresh UUIDs
            if name == "id" { continue }
            destination.setValue(source.value(forKey: name), forKey: name)
        }
    }

    /// M9.15: Break GroceryItem→Category cross-store relationships.
    /// GroceryItem stays in private store; Category moves to shared store.
    /// Preserves category string for display fallback via effectiveCategory.
    /// M9.15: One-time backfill for existing household users.
    /// Populates householdKey on Ingredient/GroceryListItem records that were created
    /// before v9 schema (when these entities weren't HouseholdScoped).
    private func backfillChildEntityHouseholdKeys() {
        let hasRun = UserDefaults.standard.bool(forKey: "m9.15.backfillComplete")
        guard !hasRun else { return }
        guard currentHousehold != nil else { return }

        var backfilled = 0

        // Ingredients: copy from parent Recipe
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        ingredientRequest.predicate = NSPredicate(format: "householdKey == nil AND recipe.householdKey != nil")
        if let ingredients = try? viewContext.fetch(ingredientRequest) {
            for ingredient in ingredients {
                ingredient.householdKey = ingredient.recipe?.householdKey
                ingredient.household = ingredient.recipe?.household
                backfilled += 1
            }
        }

        // GroceryListItems: copy from parent WeeklyList
        let itemRequest: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "householdKey == nil AND weeklyList.householdKey != nil")
        if let items = try? viewContext.fetch(itemRequest) {
            for item in items {
                item.householdKey = item.weeklyList?.householdKey
                item.household = item.weeklyList?.household
                backfilled += 1
            }
        }

        if backfilled > 0 {
            try? viewContext.save()
            #if DEBUG
            print("📦 M9.15: Backfilled householdKey on \(backfilled) child entities")
            #endif
        }

        UserDefaults.standard.set(true, forKey: "m9.15.backfillComplete")
    }

    private func breakGroceryItemCategoryLinks() {
        let groceryItemRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        if let groceryItems = try? viewContext.fetch(groceryItemRequest) {
            for item in groceryItems where item.categoryEntity != nil {
                if item.category == nil || item.category?.isEmpty == true {
                    item.category = item.categoryEntity?.name
                }
                item.categoryEntity = nil
            }
        }
    }

    // M7.6.8: Drill into NSError chain to find the actual underlying error message.
    // CloudKit errors from NSPersistentCloudKitContainer are often wrapped in
    // multiple NSError layers where localizedDescription just shows "Cocoa error XXXXX".
    private static func extractDetailedError(_ error: Error) -> String {
        let nsError = error as NSError

        // Check for underlying CloudKit error
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            let underlyingNS = underlying as NSError
            if underlyingNS.domain == CKErrorDomain {
                return underlyingNS.localizedDescription
            }
            return extractDetailedError(underlying)
        }

        // Check for multiple underlying errors
        if let underlyingErrors = nsError.userInfo["NSDetailedErrors"] as? [Error], let first = underlyingErrors.first {
            return extractDetailedError(first)
        }

        let description = nsError.localizedDescription
        if description.contains("Cocoa error") {
            return "\(description) [domain: \(nsError.domain), code: \(nsError.code)]"
        }
        return description
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

        throw lastError ?? HouseholdError.creationFailed("CloudKit share failed with unknown error")
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

        // M9.30: Member cap — check accepted + pending < 10
        let acceptedCount = share.participants.count
        let pendingCount = household.memberArray.filter { $0.isPending && !$0.isExpired }.count
        let maxMembers = 10
        guard acceptedCount + pendingCount < maxMembers else {
            throw HouseholdError.memberCapReached(maxMembers)
        }

        // M9.30: Clean expired invitations before generating new URL
        cleanExpiredInvitations(household: household)

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

        // M9.30: Track when invite was created for 24-hour expiration
        household.lastInviteDate = Date()
        try viewContext.save()

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

    // MARK: - M9.30: Invitation Security

    /// Revert publicPermission to .none after a member accepts or after 24h expiry.
    /// OWNER-ONLY — only the CKShare owner can modify share permissions.
    func revertPublicPermissionIfNeeded(household: Household) async {
        guard await isOwner(household: household) else { return }

        // Check if invite has expired (>24 hours since last invite URL was generated)
        if let lastInvite = household.lastInviteDate,
           Date().timeIntervalSince(lastInvite) > 86400 {
            do {
                let share = try await getShare(for: household)
                if share.publicPermission == .readWrite {
                    // ADR 009 constraint: public-link participants depend on
                    // publicPermission = .readWrite. Reverting to .none kicks
                    // ALL non-owner members who joined via the public link.
                    let nonOwner = share.participants.filter { $0.role != .owner }
                    if !nonOwner.isEmpty {
                        DiagnosticLogger.shared.info(
                            "M9.30: Skipping publicPermission revert — \(nonOwner.count) member(s) would lose access",
                            category: .household)
                        // Clear lastInviteDate so we stop re-checking every launch
                        household.lastInviteDate = nil
                        try? viewContext.save()
                        return
                    }

                    share.publicPermission = .none
                    let persistenceController = PersistenceController.shared
                    try await persistenceController.container.persistUpdatedShare(
                        share, in: persistenceController.privateStore)
                    DiagnosticLogger.shared.info(
                        "M9.30: Reverted publicPermission to .none (24h expired, no members)",
                        category: .household)
                }
            } catch {
                DiagnosticLogger.shared.error(
                    "M9.30: Failed to revert permission: \(error.localizedDescription)",
                    category: .household)
            }
        }
    }

    /// Cancel a single pending invitation. Owner-only.
    /// Deletes the pending HouseholdMember record and reverts share permission if no more pending.
    func cancelInvitation(member: HouseholdMember, household: Household) async throws {
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }
        guard member.isPending else { return }

        viewContext.delete(member)
        try viewContext.save()

        // If no more pending members, close the public link — but only if
        // no accepted non-owner participants exist (ADR 009: reverting publicPermission
        // kicks public-link participants).
        let remainingPending = household.memberArray.filter { $0.isPending && !$0.isExpired }
        if remainingPending.isEmpty {
            do {
                let share = try await getShare(for: household)
                if share.publicPermission == .readWrite {
                    let nonOwner = share.participants.filter { $0.role != .owner }
                    guard nonOwner.isEmpty else {
                        DiagnosticLogger.shared.info(
                            "M9.30: Skipping permission revert after cancel — \(nonOwner.count) member(s) would lose access",
                            category: .household)
                        return
                    }
                    share.publicPermission = .none
                    let persistenceController = PersistenceController.shared
                    try await persistenceController.container.persistUpdatedShare(
                        share, in: persistenceController.privateStore)
                }
            } catch {
                // Non-fatal — member was already removed
                DiagnosticLogger.shared.error(
                    "M9.30: Failed to revert permission after cancel: \(error.localizedDescription)",
                    category: .household)
            }
        }
    }

    /// Revoke all pending invitations and close public link. Owner-only.
    func revokeAllPendingInvitations(household: Household) async throws {
        guard await isOwner(household: household) else {
            throw HouseholdError.notOwner
        }

        // Delete all pending members
        let pending = household.memberArray.filter { $0.isPending }
        for member in pending {
            viewContext.delete(member)
        }
        try viewContext.save()

        // Close public link — but only if no accepted non-owner participants exist
        // (ADR 009: reverting publicPermission kicks public-link participants).
        do {
            let share = try await getShare(for: household)
            if share.publicPermission == .readWrite {
                let nonOwner = share.participants.filter { $0.role != .owner }
                guard nonOwner.isEmpty else {
                    DiagnosticLogger.shared.info(
                        "M9.30: Skipping permission revert after revoke-all — \(nonOwner.count) member(s) would lose access",
                        category: .household)
                    return
                }
                share.publicPermission = .none
                let persistenceController = PersistenceController.shared
                try await persistenceController.container.persistUpdatedShare(
                    share, in: persistenceController.privateStore)
                DiagnosticLogger.shared.info(
                    "M9.30: Revoked all invitations, publicPermission = .none",
                    category: .household)
            }
        } catch {
            DiagnosticLogger.shared.error(
                "M9.30: Failed to revert permission after revoke: \(error.localizedDescription)",
                category: .household)
        }
    }

    /// Clean up expired pending invitations on app launch. Owner-only.
    func cleanExpiredInvitations(household: Household) {
        let expired = household.memberArray.filter { $0.isExpired }
        guard !expired.isEmpty else { return }

        for member in expired {
            viewContext.delete(member)
        }
        do {
            try viewContext.save()
            DiagnosticLogger.shared.info(
                "M9.30: Cleaned \(expired.count) expired invitation(s)",
                category: .household)
        } catch {
            DiagnosticLogger.shared.error(
                "M9.30: Failed to clean expired invitations: \(error.localizedDescription)",
                category: .household)
        }
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
            // noShareRecord can mean two things:
            // 1. User was removed from the share (genuine ghost)
            // 2. Household was just created and CloudKit hasn't migrated it
            //    to the shared zone yet (false negative — still in private store)
            // 3. M9.30: Deleted household re-synced from CloudKit (ghost)
            //
            // Check which store the household is in AND whether it was
            // previously deleted/left to distinguish the cases.
            let privateStore = PersistenceController.shared.privateStore
            if household.objectID.persistentStore == privateStore {
                // M9.30: Check if this household was deleted or left — if so, it's a ghost
                if let householdID = household.id?.uuidString, hasLeftHousehold(householdID) {
                    #if DEBUG
                    print("⚠️ noShareRecord + private store + marked as left/deleted → ghost")
                    #endif
                    return false
                }
                #if DEBUG
                print("⚠️ noShareRecord but household is in private store — assuming owner (CloudKit migration pending)")
                #endif
                return true
            }
            // M9.31: Shared-store household with no share — could be transient
            // (mirroring delegate mid-import during sync) or genuine removal.
            // Retry once after 2 seconds before concluding non-participant.
            #if DEBUG
            print("⚠️ noShareRecord for shared-store household — retrying in 2s")
            #endif
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            do {
                let retryShare = try await getShare(for: household)
                let isParticipant = retryShare.currentUserParticipant != nil
                #if DEBUG
                print("   Retry result: \(isParticipant ? "IS participant" : "NOT participant")")
                #endif
                return isParticipant
            } catch {
                #if DEBUG
                print("   Retry failed: \(error) — concluding not a participant")
                #endif
                return false
            }
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
                // Pattern 2: "Rich iPhone" / "Rich MacBook Pro" -> "Rich"
                else {
                    let knownDeviceTypes = ["iPhone", "iPad", "iPod", "Mac", "MacBook", "iMac"]
                    let components = deviceName.components(separatedBy: " ")
                    if components.count >= 2 && knownDeviceTypes.contains(components[1]) {
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
    
    /// M10.6.19: Run at app launch when no household is active.
    /// Clears zone corruption from ghost awakeFromInsert assignments so the
    /// CloudKit mirroring delegate can initialize and sync personal data.
    /// Safe to call every launch — no-ops if stores are already clean.
    func repairZoneCorruptionIfNeeded() {
        // M10.6.20: Fix cross-store GroceryItem→Category relationships for users IN a household
        if currentHousehold != nil {
            repairCrossStoreGroceryItemRelationships()
        }
        guard currentHousehold == nil else { return }
        cleanOrphanedHouseholdData()
    }

    /// M10.6.20: GroceryItem (private store) may reference Category (shared store) via categoryEntity.
    /// This cross-store relationship causes CloudKit zone corruption. NULL out the relationship
    /// and preserve the category name as a fallback string for effectiveCategory.
    private func repairCrossStoreGroceryItemRelationships() {
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        guard let items = try? viewContext.fetch(request) else { return }
        var fixedCount = 0
        for item in items where item.categoryEntity != nil {
            // Only fix items whose categoryEntity is in a different store (cross-store)
            if let catStore = item.categoryEntity?.objectID.persistentStore,
               let itemStore = item.objectID.persistentStore,
               catStore != itemStore {
                if item.category == nil || item.category?.isEmpty == true {
                    item.category = item.categoryEntity?.name
                }
                item.categoryEntity = nil
                fixedCount += 1
            }
        }
        if fixedCount > 0, viewContext.hasChanges {
            try? viewContext.save()
            #if DEBUG
            print("🔧 M10.6.20: Fixed \(fixedCount) cross-store GroceryItem→Category relationships")
            #endif
        }
    }

    /// M10.6: Pre-creation cleanup — removes ALL objects with non-nil householdKey
    /// that don't belong to any currently active household. Prevents zone corruption
    /// when creating a new household after leaving a previous one.
    /// Also purges shared store remnants and orphaned Ingredients not linked to any Recipe.
    private func cleanOrphanedHouseholdData() {
        let diag = DiagnosticLogger.shared
        diag.info("Pre-creation orphan cleanup starting", category: .household)
        var cleanedCount = 0

        // 0. Delete ALL ghost Household and HouseholdMember entities
        // Since currentHousehold is nil (checked by caller), any Household is a ghost.
        // Household lives in the PRIVATE store (attach-then-share pattern) and survives
        // shared store cleanup — must be explicitly deleted.
        for entityName in ["Household", "HouseholdMember"] {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            if let objects = try? viewContext.fetch(request), !objects.isEmpty {
                for obj in objects {
                    viewContext.delete(obj)
                    cleanedCount += 1
                }
                #if DEBUG
                print("   Deleted \(objects.count) ghost \(entityName)(s)")
                #endif
            }
        }

        // 1. Delete all objects with a stale householdKey (no active household exists)
        // Since currentHousehold is nil (checked by caller), ANY householdKey is stale
        // M9.15: Include Ingredient and GroceryListItem (now HouseholdScoped)
        let entityKeys: [(NSFetchRequest<NSManagedObject>, String)] = [
            (NSFetchRequest<NSManagedObject>(entityName: "PlannedMeal"), "PlannedMeal"),
            (NSFetchRequest<NSManagedObject>(entityName: "MealPlan"), "MealPlan"),
            (NSFetchRequest<NSManagedObject>(entityName: "GroceryListItem"), "GroceryListItem"),
            (NSFetchRequest<NSManagedObject>(entityName: "WeeklyList"), "WeeklyList"),
            (NSFetchRequest<NSManagedObject>(entityName: "Ingredient"), "Ingredient"),
            (NSFetchRequest<NSManagedObject>(entityName: "Recipe"), "Recipe"),
            (NSFetchRequest<NSManagedObject>(entityName: "IngredientTemplate"), "IngredientTemplate"),
            (NSFetchRequest<NSManagedObject>(entityName: "Category"), "Category"),
        ]

        for (request, name) in entityKeys {
            request.predicate = NSPredicate(format: "householdKey != nil")
            if let objects = try? viewContext.fetch(request), !objects.isEmpty {
                for obj in objects {
                    viewContext.delete(obj)
                    cleanedCount += 1
                }
                #if DEBUG
                print("   Deleted \(objects.count) orphaned \(name)(s)")
                #endif
            }
        }

        // 2. Delete orphaned Ingredients not linked to any Recipe
        // These can survive if a Recipe was deleted but Ingredients weren't cascade-cleaned
        let ingredientRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Ingredient")
        ingredientRequest.predicate = NSPredicate(format: "recipe == nil")
        if let orphanedIngredients = try? viewContext.fetch(ingredientRequest), !orphanedIngredients.isEmpty {
            for ingredient in orphanedIngredients {
                viewContext.delete(ingredient)
                cleanedCount += 1
            }
            #if DEBUG
            print("   Deleted \(orphanedIngredients.count) orphaned Ingredient(s) with no Recipe")
            #endif
        }

        // 3. Purge shared store objects (without destroying the store file).
        // M9.15.3: destroyAndRecreateSharedStore() kills the NSCloudKitMirroringDelegate
        // permanently (error 134060: "store was removed from the coordinator"), making
        // the shared store unable to sync for the rest of the app session. Use the safer
        // purgeAllSharedStoreObjects() which deletes rows but keeps the store intact.
        // The old zone metadata concern is moot with create-empty-then-copy (M9.15):
        // we share an empty Household with no pre-existing CKRecords.
        let purgedCount = PersistenceController.shared.purgeAllSharedStoreObjects(from: viewContext)
        if purgedCount > 0 {
            #if DEBUG
            print("   ✅ Purged \(purgedCount) shared store objects")
            #endif
        }

        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                diag.error("Orphan cleanup save error: \(error.localizedDescription)", category: .household)
            }
        }

        diag.info("Pre-creation orphan cleanup complete — removed \(cleanedCount) objects", category: .household)
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

        // M9.15: Delete child HouseholdScoped entities first (before parents)
        for childEntity in ["Ingredient", "GroceryListItem"] {
            let request = NSFetchRequest<NSManagedObject>(entityName: childEntity)
            request.predicate = NSPredicate(format: "householdKey == %@", householdKey)
            if let objects = try? viewContext.fetch(request) {
                #if DEBUG
                if !objects.isEmpty { print("   Found \(objects.count) \(childEntity)(s) to delete") }
                #endif
                for obj in objects {
                    viewContext.delete(obj)
                    deletedCount += 1
                }
            }
        }

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

        // Delete planned meals with this householdKey (before meal plans to avoid orphans)
        let plannedMealRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        plannedMealRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)
        do {
            let plannedMeals = try viewContext.fetch(plannedMealRequest)
            #if DEBUG
            print("   Found \(plannedMeals.count) planned meals to delete")
            #endif
            for plannedMeal in plannedMeals {
                viewContext.delete(plannedMeal)
                deletedCount += 1
            }
        } catch {
            #if DEBUG
            print("   ❌ PlannedMeal fetch error: \(error)")
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
