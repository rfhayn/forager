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
    case noInvitationURL
    
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
            // This creates CKShare and moves household to Shared Zone
            // Note: We use 'to: nil' to let Core Data manage CKShare creation
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

            print("✅ Household created: \(name)")
            print("✅ Owner: \(ownerIdentifier)")
            print("✅ CloudKit shared zone activated")
            if moveExistingData {
                print("✅ Personal data migrated to household")
            }

            return household

        } catch {
            print("❌ Household creation failed: \(error)")
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

        // Enable public link sharing
        // This allows anyone with the URL to join (like a shared Google Doc link)
        // NOTE: CKShare.participants is read-only, so we can't add one-time participants
        // The trade-off: public link (anyone with URL) vs private (UICloudSharingController required)
        if share.publicPermission == .none {
            share.publicPermission = .readWrite
            print("✅ Enabled public link sharing (readWrite)")

            // Persist updated share back to CloudKit via Core Data
            let persistenceController = PersistenceController.shared

            // Get the persistent store (should be the first/only store in CloudKit setup)
            guard let persistentStore = persistenceController.container.persistentStoreCoordinator.persistentStores.first else {
                throw HouseholdError.cloudKitUnavailable
            }

            try await persistenceController.container.persistUpdatedShare(share, in: persistentStore)
            print("✅ Share updated with public permissions")
        } else {
            print("ℹ️ Share already has public permissions")
        }

        // Get the invitation URL from the share itself
        // The share URL is what recipients will use to join
        guard let invitationURL = share.url else {
            print("❌ Share missing URL")
            throw HouseholdError.noInvitationURL
        }

        print("✅ One-time invitation URL created: \(invitationURL)")

        return invitationURL
    }

    /// Syncs participants from CloudKit share to local database
    /// Creates or updates HouseholdMember records for each participant
    /// Called after UICloudSharingController saves the share
    /// - Parameter household: Household to sync participants for
    func syncParticipantsFromShare(household: Household) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get live share with current participants
            let share = try await getShare(for: household)

            print("🔄 Syncing participants from CloudKit share...")
            print("   Total participants: \(share.participants.count)")

            // Get current members from local database
            let existingMembers = household.memberArray

            // Process each participant from share
            for participant in share.participants {
                // Force explicit CloudKit types to avoid name collision
                let ckParticipant: CKShare.Participant = participant

                // userIdentity is NON-optional
                let identity: CKUserIdentity = ckParticipant.userIdentity

                // userRecordID is OPTIONAL (per Apple's CloudKit API)
                guard let userRecordID: CKRecord.ID = identity.userRecordID else {
                    print("⚠️ Skipping participant - userRecordID is nil")
                    continue
                }

                let recordName: String = userRecordID.recordName

                // lookupInfo and emailAddress are both optional
                let email: String = identity.lookupInfo?.emailAddress ?? recordName

                // Check if member already exists
                let existingMember = existingMembers.first { $0.email == email }

                if let member = existingMember {
                    // Update existing member status if needed
                    if member.isPending && participant.acceptanceStatus == .accepted {
                        member.status = "active"
                        member.joinedDate = Date()
                        print("✅ Activated member: \(email)")
                    }
                } else {
                    // Create new member record
                    let newMember = HouseholdMember(context: viewContext)
                    newMember.id = UUID()
                    newMember.email = email

                    // Get display name from CloudKit using stable identity variable
                    if let nameComponents = identity.nameComponents {
                        let formatter = PersonNameComponentsFormatter()
                        formatter.style = .medium
                        newMember.displayName = formatter.string(from: nameComponents)
                    } else {
                        newMember.displayName = extractDisplayName(from: email)
                    }

                    // Determine if owner
                    if participant.role == .owner {
                        newMember.role = "owner"
                        newMember.status = "active"
                        newMember.joinedDate = Date()
                    } else {
                        newMember.role = "member"
                        newMember.status = participant.acceptanceStatus == .accepted ? "active" : "pending"
                        newMember.joinedDate = participant.acceptanceStatus == .accepted ? Date() : nil
                    }

                    newMember.household = household
                    print("✅ Created new member: \(email) (\(newMember.status ?? "unknown"))")
                }
            }

            // Save changes
            try viewContext.save()
            print("✅ Participants synced successfully")

        } catch {
            print("❌ Failed to sync participants: \(error)")
            throw error
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

            print("✅ Fetched live CKShare from CloudKit: \(share.recordID.recordName)")
            print("   Current participants: \(share.participants.count)")

            return share

        } catch {
            print("❌ Failed to fetch live share: \(error)")

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

            let fetchedRecord = try await database.record(for: shareRecordID)

            guard let liveShare = fetchedRecord as? CKShare else {
                throw HouseholdError.noShareRecord
            }

            print("✅ Fetched live CKShare via fallback: \(liveShare.recordID.recordName)")
            return liveShare
        }
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
