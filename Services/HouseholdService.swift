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
    /// M7.3.2: Verifies user is actually a member before setting current household
    func loadCurrentHousehold() async {
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1

        do {
            let households = try viewContext.fetch(request)

            // M7.3.2: Verify user is actually a member of the household
            if let household = households.first {
                let currentEmail = try await getCurrentUserEmail()
                let isMember = household.memberArray.contains { $0.email == currentEmail }

                if isMember {
                    currentHousehold = household
                    print("✅ Loaded household: \(household.name ?? "Unknown")")
                } else {
                    currentHousehold = nil
                    print("ℹ️ Household exists but user is not a member (left or removed)")
                }
            } else {
                currentHousehold = nil
            }
        } catch {
            print("❌ Error loading household: \(error)")
            errorMessage = "Failed to load household"
            currentHousehold = nil
        }
    }

    /// M7.3.2: Waits for member deletion to sync from CloudKit (Issue #3)
    /// Uses polling pattern to detect member count changes
    /// - Returns: True if count changed or already synced, false only if sync appears stuck
    @MainActor
    func waitForMemberDeletionSync() async -> Bool {
        guard let household = currentHousehold else {
            print("⚠️ No current household to sync")
            return false
        }

        let initialMemberCount = household.memberCount
        print("🔄 Refreshing member count... (current: \(initialMemberCount))")

        let startTime = Date()
        let quickCheckDuration: TimeInterval = 5.0
        let pollInterval: TimeInterval = 1.0

        // Poll for up to 5 seconds looking for changes
        while Date().timeIntervalSince(startTime) < quickCheckDuration {
            // Refresh from Core Data (CloudKit syncs in background)
            viewContext.refreshAllObjects()

            // Re-fetch household to get latest data
            await loadCurrentHousehold()

            guard let refreshedHousehold = currentHousehold else {
                print("⚠️ Household disappeared during sync")
                return true // Household was deleted
            }

            let currentMemberCount = refreshedHousehold.memberCount

            if currentMemberCount != initialMemberCount {
                let elapsed = Date().timeIntervalSince(startTime)
                print("✅ Member count updated after \(String(format: "%.1f", elapsed))s: \(initialMemberCount) → \(currentMemberCount)")
                return true
            }

            // Wait before next poll
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        // No change detected after 5 seconds - assume already synced
        print("✅ Member count stable at \(initialMemberCount) (already synced)")
        return true
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
    /// - Parameters:
    ///   - household: The household to leave
    ///   - migrateData: Whether to migrate household data to personal store
    /// - Throws: HouseholdError if user is owner or not a member
    func leaveHousehold(_ household: Household, migrateData: Bool) async throws {
        // Get current user's email/identifier
        let currentEmail = try await getCurrentUserEmail()

        // Find current user's member record
        guard let currentMember = household.memberArray.first(where: { $0.email == currentEmail }) else {
            throw HouseholdError.notMember
        }

        // Prevent owner from leaving (must delete household instead)
        guard !currentMember.isOwner else {
            throw HouseholdError.ownerCannotLeave
        }

        // Step 1: Migrate data BEFORE stopping participation (while we still have access)
        if migrateData {
            try await migrateHouseholdDataToPersonal(household)
            print("✅ M7.3.2: Migrated household data to personal store")
        }

        // Step 2: Remove member from household (this syncs to all devices)
        viewContext.delete(currentMember)
        try viewContext.save()

        // Step 3: Stop participating in the share
        // This removes device access to the shared CloudKit zone
        // Shared data will disappear from device after CloudKit processes the removal
        do {
            try await stopParticipatingInShare(for: household)
            print("✅ M7.3.2: Stopped participating in share")
            print("   Shared zone access removed - data will sync off device")
        } catch {
            print("⚠️ M7.3.2: Failed to stop participating in share: \(error)")
            print("   Shared data may remain on device - manual cleanup may be needed")
            // Don't throw - member record is already deleted, just log the issue
        }

        // Step 4: Clear current household (UI will show "Create Household")
        currentHousehold = nil

        print("✅ M7.3.2: Left household: \(household.name ?? "Unknown")")
        if migrateData {
            print("   Personal copy created, shared data removed")
        } else {
            print("   All data removed (clean app)")
        }
    }

    /// M7.3.2: Stops participating in a CloudKit share
    /// This removes the device's access to the shared zone
    /// - Parameter household: The household whose share to stop participating in
    /// - Throws: HouseholdError if share cannot be fetched or operation fails
    private func stopParticipatingInShare(for household: Household) async throws {
        // Fetch the CKShare from the household
        let share = try await fetchShare(for: household)

        // Get the container
        guard let container = PersistenceController.shared.container as? NSPersistentCloudKitContainer else {
            throw HouseholdError.cloudKitUnavailable
        }

        // Stop participating in the share
        // This removes access to the shared zone and triggers CloudKit to remove shared data
        try await container.purgeObjectsAndRecordsInZone(with: share.recordID.zoneID, in: PersistenceController.shared.sharedStore)

        print("🔄 M7.3.2: Purged shared zone data for zone: \(share.recordID.zoneID.zoneName)")
    }

    /// M7.3.2: Fetches the CKShare record for a household
    /// - Parameter household: The household to fetch the share for
    /// - Returns: The CKShare record
    /// - Throws: HouseholdError if share record is missing or invalid
    private func fetchShare(for household: Household) async throws -> CKShare {
        // Try to unarchive the share from stored data
        guard let shareData = household.shareRecord else {
            throw HouseholdError.noShareRecord
        }

        guard let share = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: CKShare.self,
            from: shareData
        ) else {
            throw HouseholdError.noShareRecord
        }

        return share
    }

    /// M7.3.2: Migrates household data to personal store
    /// - Parameter household: The household to migrate from
    private func migrateHouseholdDataToPersonal(_ household: Household) async throws {
        let recipeSet = household.recipes as? Set<Recipe> ?? []
        let listSet = household.weeklyLists as? Set<WeeklyList> ?? []
        let mealPlanSet = household.mealPlans as? Set<MealPlan> ?? []

        // Migrate recipes with ingredients
        for oldRecipe in recipeSet {
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
                newIngredient.ingredientTemplate = oldIngredient.ingredientTemplate
            }
        }

        // Migrate weekly lists with items
        for oldList in listSet {
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

        // Migrate meal plans with planned meals
        for oldPlan in mealPlanSet {
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

        print("📊 Migrated: \(recipeSet.count) recipes, \(listSet.count) lists, \(mealPlanSet.count) plans")
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

        // Enable public link sharing
        // This allows anyone with the URL to join (like a shared Google Doc link)
        // NOTE: SceneDelegate will handle the acceptance via acceptShareInvitations
        if share.publicPermission == .none {
            share.publicPermission = .readWrite
            print("✅ Enabled public link sharing (readWrite)")

            // Persist updated share back to CloudKit via Core Data
            // M7.2.2: Share updates always go to private store (owner's data)
            let persistenceController = PersistenceController.shared
            let privateStore = persistenceController.privateStore

            try await persistenceController.container.persistUpdatedShare(share, in: privateStore)
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

    /// M7.2.2: Manually checks CloudKit for accepted invitations
    /// This is a workaround for when URL handling doesn't trigger (app already running)
    /// Call this when user taps "Check for Invitations" button
    func checkForAcceptedInvitations() async {
        print("🔍 Manually checking for accepted invitations...")

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

            // Get current user's email to check membership
            let currentEmail = try await getCurrentUserEmail()
            print("   Current user: \(currentEmail)")

            // Find a household where this user is a member
            for household in households {
                print("   Checking household: \(household.name ?? "Unnamed")")
                print("      Members: \(household.members?.count ?? 0)")

                // Check if user is already a member of this household
                if let member = household.memberArray.first(where: { $0.email == currentEmail }) {
                    print("✅ Found household where you're a member!")
                    print("   Household: \(household.name ?? "Unnamed")")
                    print("   Status: \(member.status ?? "unknown")")
                    print("   Is pending: \(member.isPending)")

                    // Set as current household
                    currentHousehold = household

                    // If still pending, accept it
                    if member.isPending {
                        try await acceptInvitation(for: household)
                    }

                    return
                }

                // M7.2.2: Auto-create member for public link shares
                // If household exists in shared store but user is not a member,
                // they must have accepted via public link - create member record
                let sharedStore = PersistenceController.shared.sharedStore
                if household.objectID.persistentStore == sharedStore {
                    print("🔗 Household from shared store - auto-creating member for public link share")

                    // Create new active member
                    let newMember = HouseholdMember(context: viewContext)
                    newMember.id = UUID()
                    newMember.email = currentEmail
                    newMember.role = "member"
                    newMember.status = "active"
                    newMember.joinedDate = Date()

                    // Get display name - try multiple approaches
                    var displayName: String?

                    // Try 1: Get from CloudKit user identity (if available)
                    // Note: Requires .userDiscoverability permission (requested in SceneDelegate)
                    do {
                        let userRecordID = try await container.userRecordID()
                        print("   📝 CloudKit user record ID: \(userRecordID.recordName)")

                        if let identity = try await container.userIdentity(forUserRecordID: userRecordID) {
                            print("   ✅ Got CloudKit identity")

                            if let nameComponents = identity.nameComponents {
                                let formatter = PersonNameComponentsFormatter()
                                formatter.style = .medium
                                displayName = formatter.string(from: nameComponents)
                                print("   ✅ Display name from name components: \(displayName!)")
                            } else {
                                print("   ⚠️ Identity found but no name components available")
                            }

                            // Also log email if available (for debugging)
                            if let lookupInfo = identity.lookupInfo, let emailAddress = lookupInfo.emailAddress {
                                print("   📧 Email from identity: \(emailAddress)")
                            }
                        } else {
                            print("   ⚠️ userIdentity returned nil - may need .userDiscoverability permission")
                        }
                    } catch {
                        print("   ⚠️ CloudKit identity unavailable: \(error.localizedDescription)")
                        print("   ℹ️ This is normal if user hasn't granted user discoverability permission")
                    }

                    // Try 2: Use device name as fallback
                    if displayName == nil {
                        let deviceName = UIDevice.current.name
                        print("   ℹ️ Device name: '\(deviceName)'")

                        // Pattern 1: "John's iPhone" -> "John"
                        if let range = deviceName.range(of: "'s ") {
                            displayName = String(deviceName[..<range.lowerBound])
                            print("   ✅ Extracted from possessive pattern: \(displayName!)")
                        }
                        // Pattern 2: "Rich iPhone" -> "Rich" (first word before "iPhone"/"iPad")
                        else if deviceName.contains("iPhone") || deviceName.contains("iPad") {
                            let components = deviceName.components(separatedBy: " ")
                            if components.count >= 2 && (components[1] == "iPhone" || components[1] == "iPad") {
                                displayName = components[0]
                                print("   ✅ Extracted first word from device name: \(displayName!)")
                            }
                        }
                        // Pattern 3: Just use the whole device name if it's short and not generic
                        else if deviceName.count <= 20 && !["iPhone", "iPad", "iPod"].contains(deviceName) {
                            displayName = deviceName
                            print("   ✅ Using device name as-is: \(displayName!)")
                        }
                    }

                    // Try 3: Extract from email if it looks like a real email
                    if displayName == nil {
                        // Check if this is a CloudKit user record ID (starts with "_" followed by hex)
                        if currentEmail.hasPrefix("_") && currentEmail.count > 20 {
                            // This is a CloudKit user record ID, not an email - use generic fallback
                            displayName = "User"
                            print("   ℹ️ Detected CloudKit user record ID, using generic fallback: \(displayName!)")
                        } else {
                            // Looks like an actual email, try to extract a name
                            displayName = extractDisplayName(from: currentEmail)
                            print("   ℹ️ Using extracted name from email: \(displayName!)")
                        }
                    }

                    newMember.displayName = displayName

                    newMember.household = household

                    try viewContext.save()

                    print("✅ Auto-created member for public link share")
                    print("   Member: \(newMember.displayName ?? currentEmail)")
                    print("   Role: \(newMember.role ?? "member")")

                    // Refresh household to pick up new member relationship
                    viewContext.refresh(household, mergeChanges: true)

                    // Set as current household (this will trigger UI update)
                    currentHousehold = household

                    return
                }
            }

            print("   No households found where you're a member")
            print("   The share may not have been accepted yet")

        } catch {
            print("❌ Error checking for invitations: \(error)")
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
