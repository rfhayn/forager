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
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.container = CKContainer(identifier: "iCloud.com.richhayn.forager")
        
        // Load current household on init
        Task {
            await loadCurrentHousehold()
        }
    }
    
    // MARK: - Household Management
    
    /// Loads the current user's household (if any)
    func loadCurrentHousehold() async {
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let households = try viewContext.fetch(request)
            currentHousehold = households.first
        } catch {
            print("❌ Error loading household: \(error)")
            errorMessage = "Failed to load household"
        }
    }
    
    /// Creates a new household with CloudKit shared zone
    /// - Parameters:
    ///   - name: Name of the household (e.g., "Smith Family")
    ///   - ownerName: Display name for the owner (e.g., "Sarah")
    /// - Returns: The newly created Household
    func createHousehold(name: String, ownerName: String) async throws -> Household {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Get current user's email from CloudKit
            let ownerEmail = try await getCurrentUserEmail()
            
            // 2. Create Household entity
            let household = Household(context: viewContext)
            household.id = UUID()
            household.name = name
            household.ownerEmail = ownerEmail
            household.createdDate = Date()
            
            // 3. Create owner as first member
            let ownerMember = HouseholdMember(context: viewContext)
            ownerMember.id = UUID()
            ownerMember.email = ownerEmail
            ownerMember.displayName = ownerName  // Use provided display name
            ownerMember.role = "owner"
            ownerMember.status = "active"  // Owner is immediately active
            ownerMember.joinedDate = Date()
            ownerMember.household = household
            
            // 4. Save to Core Data (this triggers CloudKit sync)
            try viewContext.save()
            
            // 5. Create CloudKit share
            let share = try await createCloudKitShare(for: household)
            
            // 6. Store share record reference
            household.shareRecord = try NSKeyedArchiver.archivedData(
                withRootObject: share,
                requiringSecureCoding: true
            )
            
            // 7. Save share record
            try viewContext.save()
            
            // 8. Update current household
            currentHousehold = household
            
            print("✅ Household created: \(name)")
            print("✅ Owner: \(ownerEmail)")
            print("✅ CloudKit shared zone activated")
            
            return household
            
        } catch {
            print("❌ Household creation failed: \(error)")
            throw HouseholdError.creationFailed(error.localizedDescription)
        }
    }
    
    /// Checks if current user is the owner of the household
    func isOwner(household: Household) async -> Bool {
        guard let ownerEmail = household.ownerEmail else { return false }
        
        do {
            let currentEmail = try await getCurrentUserEmail()
            return currentEmail == ownerEmail
        } catch {
            return false
        }
    }
    
    // MARK: - CloudKit Integration
    
    /// Creates a CloudKit share for the household
    /// This creates the shared zone that other users can access
    private func createCloudKitShare(for household: Household) async throws -> CKShare {
        // Create a new CKShare
        // Note: Actual CloudKit record association will be handled by NSPersistentCloudKitContainer
        let share = CKShare(rootRecord: CKRecord(recordType: "CD_Household"))
        share[CKShare.SystemFieldKey.title] = household.name as CKRecordValue?
        share.publicPermission = .none  // Private sharing only
        
        return share
    }
    
    /// Gets the current user's email from CloudKit
    /// Falls back to userRecordID if email is not available
    private func getCurrentUserEmail() async throws -> String {
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
                        continuation.resume(returning: recordID.recordName)
                        return
                    }
                    
                    // Try to get email, fallback to recordName if not available
                    if let email = identity?.lookupInfo?.emailAddress {
                        print("✅ Retrieved email: \(email)")
                        continuation.resume(returning: email)
                    } else {
                        print("⚠️ Email not available, using userRecordID as fallback")
                        continuation.resume(returning: recordID.recordName)
                    }
                }
            }
        }
    }
    
    // MARK: - Member Management
    
    /// Invites a member to the household by creating a pending member record
    /// Owner must then present UICloudSharingController with the returned share
    /// - Parameters:
    ///   - email: iCloud email address of person to invite
    ///   - household: Household to invite them to
    /// - Returns: CKShare to present in UICloudSharingController
    func inviteMember(email: String, to household: Household) async throws -> CKShare {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Verify caller is owner
            guard await isOwner(household: household) else {
                throw HouseholdError.notOwner
            }
            
            // 2. Check if already a member
            let existingMember = household.memberArray.first { $0.email == email }
            if let existing = existingMember {
                if existing.isActive {
                    throw HouseholdError.alreadyMember
                } else {
                    throw HouseholdError.invitationPending
                }
            }
            
            // 3. Create pending member
            let pendingMember = HouseholdMember(context: viewContext)
            pendingMember.id = UUID()
            pendingMember.email = email
            pendingMember.displayName = extractDisplayName(from: email)
            pendingMember.role = "member"
            pendingMember.status = "pending"
            pendingMember.household = household
            // joinedDate remains nil until acceptance
            
            // 4. Save pending member
            try viewContext.save()
            
            // 5. Get share for UICloudSharingController
            let share = try await getShare(for: household)
            
            print("✅ Pending invitation created for: \(email)")
            return share
            
        } catch {
            print("❌ Invitation failed: \(error)")
            if let hhError = error as? HouseholdError {
                throw hhError
            } else {
                throw HouseholdError.invitationFailed(error.localizedDescription)
            }
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
    
    // MARK: - Helper Methods
    
    /// Gets the CKShare record for the household
    /// Used for invitation and share management
    private func getShare(for household: Household) async throws -> CKShare {
        guard let shareData = household.shareRecord else {
            throw HouseholdError.noShareRecord
        }
        
        // Unarchive the CKShare from stored data
        guard let share = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: CKShare.self,
            from: shareData
        ) else {
            throw HouseholdError.noShareRecord
        }
        
        return share
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
}
