//
//  SettingsView.swift
//  forager
//
//  Enhanced for M4.1: Added Meal Planning Preferences Section
//  Enhanced for M4.3.1: Added Display Options Section
//  Enhanced for M7.0.2: Added Privacy Policy Link with SafariServices
//  Enhanced for M7.2.1: Added Household Management Section
//

import SwiftUI
import SafariServices
import CoreData

struct SettingsView: View {
    // M4.1: User preferences service for meal planning settings
    @StateObject private var preferencesService = UserPreferencesService.shared
    
    // M7.2.1: Household service for household management
    // M7.2.2 FIX: Use @EnvironmentObject instead of creating a separate instance
    // This ensures all views share the same HouseholdService state
    @EnvironmentObject private var householdService: HouseholdService

    // Access to Core Data context for migration service
    @Environment(\.managedObjectContext) private var viewContext
    
    // M7.0.2: Privacy policy URL presentation state
    @State private var showingPrivacyPolicy = false

    // M7.6.3: Onboarding replay (signals parent via NotificationCenter)
    
    // M7.2.1: Household creation sheet state
    @State private var showCreateHouseholdSheet = false
    
    // M7.2.2: Invitation sheet state
    @State private var showInviteMemberSheet = false

    // M7.3.1: Rename household state
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var renameError: String?
    @State private var isCurrentUserOwner = false

    // M7.3.2: Leave household state
    @State private var showLeaveConfirmation = false
    @State private var shouldMigrateData = false

    // M7.3.3: Delete household state (owner-only)
    @State private var showDeleteConfirmation = false

    // M7.3.2: Member sync state (Issue #3)
    @State private var isSyncingMembers = false

    // M7.2.2 Refactor: CKShare-based participant info
    @State private var participantCount: Int = 0
    @State private var ownerDisplayName: String = "Unknown"

    var body: some View {
        // M15.1: NavigationView removed — SettingsView is inside NavigationStack from TabView
        Form {
            // M7.2.1: Household Management
            householdSection

            // M15.1: Data Management (Ingredients & Categories relocated from tabs)
            dataManagementSection

            // M4.1: Meal Planning Preferences
            mealPlanningSection

            // M4.3.1: Display Options
            displayOptionsSection

            // M7.1.2: Developer Tools (hidden in production)
            #if DEBUG
            developerToolsSection
            #endif

            // M7.0.2: About & Privacy
            aboutSection
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPrivacyPolicy) {
            SafariView(url: URL(string: "https://rfhayn.github.io/forager/privacy.html")!)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showCreateHouseholdSheet) {
            CreateHouseholdSheet(householdService: householdService)
        }
        .sheet(isPresented: $showInviteMemberSheet) {
            if let household = householdService.currentHousehold {
                InviteMemberSheet(service: householdService, household: household)
            }
        }
        .alert("Leave Household?", isPresented: $showLeaveConfirmation) {
            Button("Migrate & Leave", role: .destructive) {
                shouldMigrateData = true
                if let household = householdService.currentHousehold {
                    leaveHousehold(household)
                }
            }
            Button("Clean App & Leave", role: .destructive) {
                shouldMigrateData = false
                if let household = householdService.currentHousehold {
                    leaveHousehold(household)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose 'Migrate & Leave' to keep a personal copy of all data, or 'Clean App & Leave' to start fresh with a clean app.")
        }
        .alert("Delete Household?", isPresented: $showDeleteConfirmation) {
            Button("Migrate & Delete", role: .destructive) {
                if let household = householdService.currentHousehold {
                    deleteHousehold(household, migrateData: true)
                }
            }
            Button("Clean Delete", role: .destructive) {
                if let household = householdService.currentHousehold {
                    deleteHousehold(household, migrateData: false)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes the household and removes all members' access. Choose 'Migrate & Delete' to keep a personal copy, or 'Clean Delete' to remove everything.")
        }
    }
    
    // MARK: - M7.2.1: Household Section
    // M7.4: Restructured for better visual hierarchy and cleaner UX

    // Household management section for creating and viewing household details
    // Enables users to share grocery lists, recipes, and meal plans with family
    private var householdSection: some View {
        Group {
            if let household = householdService.currentHousehold {
                // M7.4: HOUSEHOLD INFORMATION section
                Section {
                    // M7.3.1: Editable household name (owner only)
                    HStack {
                        if isEditingName {
                            // Edit mode - text field
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Household Name", text: $editedName)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        saveHouseholdName(household)
                                    }

                                HStack {
                                    Button("Cancel") {
                                        isEditingName = false
                                        renameError = nil
                                    }
                                    .foregroundStyle(ForagerTheme.textTertiary)
                                    .font(.caption)

                                    Spacer()

                                    Button("Save") {
                                        saveHouseholdName(household)
                                    }
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                }

                                if let error = renameError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.statusDangerFG)
                                }
                            }
                        } else {
                            // M7.4: Removed "Tap to rename" instruction - pencil icon is sufficient
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Household Name")
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                    Spacer()
                                    if isCurrentUserOwner {
                                        Image(systemName: "pencil")
                                            .foregroundStyle(ForagerTheme.accentSecondary)
                                            .font(.caption)
                                    }
                                }
                                Text(household.name ?? "Unnamed Household")
                                    .fontWeight(.medium)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isCurrentUserOwner {
                                    editedName = household.name ?? ""
                                    isEditingName = true
                                }
                            }
                        }
                    }

                    // Owner information
                    HStack {
                        Text("Owner")
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Spacer()
                        Text(ownerDisplayName)
                            .fontWeight(.medium)
                    }
                } header: {
                    Text("Household Information")
                }
                .task {
                    // M7.3.1: Check if current user is owner
                    isCurrentUserOwner = await householdService.isOwner(household: household)

                    // M7.2.2 Refactor: Load participant info from CKShare
                    participantCount = await householdService.getParticipantCount(for: household)
                    if let owner = await householdService.getOwnerParticipant(for: household) {
                        ownerDisplayName = owner.displayName
                    }
                }

                // M7.4: MEMBERS section
                Section {
                    // M7.2.2 Task 4: Link to members list
                    NavigationLink {
                        HouseholdMembersView(household: household, service: householdService)
                    } label: {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundStyle(ForagerTheme.accentSecondary)
                            Text("Members")
                            Spacer()
                            if isSyncingMembers {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                                Text("Syncing...")
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            } else {
                                Text("\(participantCount)")
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                        }
                    }

                    #if DEBUG
                    // M7.4: Moved Refresh Members to DEBUG-only
                    // M7.3.2: Refresh members button (Issue #3)
                    if isCurrentUserOwner && !isSyncingMembers {
                        Button(action: {
                            refreshMembers()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Members")
                            }
                            .foregroundStyle(ForagerTheme.accentSecondary)
                        }
                    }
                    #endif
                } header: {
                    Text("Members")
                }

                // M7.4: ACTIONS section
                Section {
                    // M7.2.2: Invite Member button
                    Button(action: {
                        showInviteMemberSheet = true
                    }) {
                        HStack {
                            Image(systemName: "paperplane")
                            Text("Invite Member")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ForagerTheme.accentPrimary)
                        .foregroundStyle(.white)
                        .cornerRadius(ForagerTheme.Radius.md)
                    }

                    // M7.3.2: Leave Household button (non-owners only)
                    if !isCurrentUserOwner {
                        Button(action: {
                            showLeaveConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Leave Household")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ForagerTheme.statusDangerFG.opacity(0.1))
                            .foregroundStyle(ForagerTheme.statusDangerFG)
                            .cornerRadius(ForagerTheme.Radius.md)
                        }
                    }

                    // M7.4: Moved Delete to bottom of actions section (iOS convention)
                    // M7.3.3: Delete Household button (owner-only)
                    if isCurrentUserOwner {
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Household")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ForagerTheme.statusDangerFG.opacity(0.1))
                            .foregroundStyle(ForagerTheme.statusDangerFG)
                            .cornerRadius(ForagerTheme.Radius.md)
                        }
                    }
                } header: {
                    Text("Actions")
                }

            } else {
                // No household - show create button
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create or join a household to share grocery lists, recipes, and meal plans with family or roommates.")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: {
                            showCreateHouseholdSheet = true
                        }) {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("Create Household")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ForagerTheme.accentPrimary)
                            .foregroundStyle(.white)
                            .cornerRadius(ForagerTheme.Radius.md)
                        }
                    }
                } header: {
                    Text("Household")
                } footer: {
                    Text("All household members will automatically see and share all grocery lists, recipes, and meal plans.")
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - M15.1: Data Management Section (relocated from tabs — ADR 011)

    private var dataManagementSection: some View {
        Section {
            NavigationLink {
                IngredientsView(popToRoot: .constant(false))
            } label: {
                Label("Ingredients", systemImage: "leaf.circle")
            }
            NavigationLink {
                ManageCategoriesView(popToRoot: .constant(false))
            } label: {
                Label("Categories", systemImage: "folder.badge.gearshape")
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - M4.1: Meal Planning Section
    
    // Meal planning preferences for user configuration
    // Controls meal plan duration, start day, and display options
    private var mealPlanningSection: some View {
        Section {
            // Duration stepper (3-14 days)
            // Controls how many days appear in meal plan calendar
            Stepper(
                "Plan Duration: \(preferencesService.mealPlanDuration) days",
                value: $preferencesService.mealPlanDuration,
                in: 3...14
            )
            
            // Start day picker (Sunday-Saturday)
            // Determines which day meal plan calendar begins on
            Picker("Start Day", selection: $preferencesService.mealPlanStartDay) {
                ForEach(0..<7) { day in
                    Text(dayName(for: day)).tag(day)
                }
            }
            
            // Auto-name toggle
            // When enabled, generates names like "Week of Oct 23"
            Toggle("Auto-name Meal Plans", isOn: $preferencesService.autoNameMealPlans)
            
        } header: {
            Text("Meal Planning")
        } footer: {
            Text("Configure how meal plans are created and displayed. Meal plans will default to \(preferencesService.mealPlanDuration) days starting on \(preferencesService.startDayName).")
                .font(.caption)
        }
    }
    
    // MARK: - M4.3.1: Display Options Section
    
    // Display preferences for recipe source visibility
    // Controls whether recipe sources appear throughout the app
    private var displayOptionsSection: some View {
        Section {
            // Show recipe sources toggle
            // When enabled, shows recipe tags like "[Tacos] [Spaghetti]"
            Toggle("Show Recipe Sources", isOn: $preferencesService.showRecipeSources)
            
        } header: {
            Text("Display Options")
        } footer: {
            Text("When enabled, grocery list items will show which recipes they came from (e.g., \"Ground beef [Tacos]\").")
                .font(.caption)
        }
    }
    
    // M7.1.2: Developer Tools Section
    // M7.2.3 Phase 3.5: Added CloudKit Test Harness
    
    // Developer tools for CloudKit sync testing and debugging
    // Provides access to sync status monitoring and validation
    private var developerToolsSection: some View {
        Section {
            // CloudKit Sync Status link
            // Opens test interface for monitoring CloudKit sync events
            NavigationLink {
                CloudKitSyncTestView()
            } label: {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundStyle(ForagerTheme.accentSecondary)
                    VStack(alignment: .leading) {
                        Text("CloudKit Sync Status")
                            .font(.headline)
                        Text("Monitor sync events and test CloudKit")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
            
            #if DEBUG
            // M7.2.3 Phase 3.5: CloudKit Test Harness
            // Comprehensive testing UI for duplicate prevention validation
            NavigationLink {
                CloudKitTestHarnessView()
            } label: {
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundStyle(ForagerTheme.accentSecondary)
                    VStack(alignment: .leading) {
                        Text("CloudKit Test Harness")
                            .font(.headline)
                        Text("Test duplicate prevention and repository patterns")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
            #endif
            
            // M7.2.2: Household Debug link - TEMPORARILY DISABLED
            // Shows all households in database for debugging sync issues
            // TODO: Add HouseholdDebugView.swift to Xcode project
            /*
            NavigationLink {
                HouseholdDebugView()
            } label: {
                HStack {
                    Image(systemName: "house.circle")
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                    VStack(alignment: .leading) {
                        Text("Household Debug")
                            .font(.headline)
                        Text("View all households in database")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
            */
            
            #if DEBUG
            // M7.1.3 Part 4: Migration reset button (TEMPORARY - testing only)
            // Resets Stage A migration flag to re-run migration with current data
            Button {
                MigrationTestHelper.resetStageAMigration()
                print(MigrationTestHelper.getMigrationStatus())
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                    VStack(alignment: .leading) {
                        Text("Reset Migration")
                            .font(.headline)
                        Text("Re-run Stage A migration for testing")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }

            // M7.3.3: Category Sync Diagnostic
            // Dumps all categories with their store location and householdKey
            // Use to troubleshoot why categories aren't syncing to members
            Button {
                householdService.dumpCategorySyncDiagnostics()
            } label: {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundStyle(ForagerTheme.accentSecondary)
                    VStack(alignment: .leading) {
                        Text("Category Sync Diagnostic")
                            .font(.headline)
                        Text("Dump category store & householdKey info")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
            #endif
            
        } header: {
            Text("Developer Tools")
        } footer: {
            Text("Tools for testing and debugging CloudKit synchronization.")
                .font(.caption)
        }
    }
    
    // MARK: - M7.0.2: About Section
    
    // About section with app information and legal links
    // Provides access to privacy policy and app version
    private var aboutSection: some View {
        Section {
            // M7.6.3: Replay Onboarding (signals foragerApp via notification)
            Button {
                NotificationCenter.default.post(name: .replayOnboarding, object: nil)
            } label: {
                HStack {
                    Image(systemName: "hand.wave")
                        .foregroundStyle(ForagerTheme.accentSecondary)
                    Text("Replay Onboarding")
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }

            // Privacy Policy link
            // Opens privacy policy in in-app Safari browser
            Button {
                showingPrivacyPolicy = true
            } label: {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                    Text("Privacy Policy")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .font(.caption)
                }
            }
            
        } header: {
            Text("About")
        } footer: {
            Text("forager stores all data locally on your device. We do not collect, transmit, or share any personal information.")
                .font(.caption)
        }
    }
    
    // MARK: - M3: Legacy Sections (Hidden)
    
    // Migration section for quantity data management
    // Hidden after M3 migration complete - preserved for reference
    /*
    private var migrationSection: some View {
        Section {
            NavigationLink(destination: MigrationDebugView(context: viewContext)) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(ForagerTheme.accentSecondary)
                    VStack(alignment: .leading) {
                        Text("Quantity Migration")
                            .font(.headline)
                        Text("Convert ingredients to structured format")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
            }
        } header: {
            Text("Data Management")
        }
    }
    */
    
    // MARK: - Helper Methods

    // M7.3.1: Saves household name after validation
    // Owner-only operation with automatic CloudKit sync
    private func saveHouseholdName(_ household: Household) {
        Task {
            do {
                try await householdService.renameHousehold(household, to: editedName)
                isEditingName = false
                renameError = nil

                // Trigger view refresh
                await householdService.loadCurrentHousehold()
            } catch {
                renameError = error.localizedDescription
            }
        }
    }

    // M7.3.2: Leaves household with optional data migration
    private func leaveHousehold(_ household: Household) {
        Task {
            do {
                try await householdService.leaveHousehold(
                    household,
                    migrateData: shouldMigrateData
                )

                // Refresh household to trigger UI update
                await householdService.loadCurrentHousehold()

            } catch {
                // Show error in console (could add alert UI here)
                #if DEBUG
                print("❌ Error leaving household: \(error)")
                #endif
            }
        }
    }

    // M7.3.3: Deletes household with optional data migration (owner-only)
    private func deleteHousehold(_ household: Household, migrateData: Bool) {
        Task {
            do {
                try await householdService.deleteHousehold(
                    household,
                    migrateData: migrateData
                )
                await householdService.loadCurrentHousehold()
            } catch {
                #if DEBUG
                print("❌ Error deleting household: \(error)")
                #endif
            }
        }
    }

    // M7.3.2: Refreshes member list with sync polling (Issue #3)
    private func refreshMembers() {
        guard let household = householdService.currentHousehold else { return }
        Task {
            isSyncingMembers = true
            // M7.2.2 Refactor: Refresh participant count from CKShare
            participantCount = await householdService.getParticipantCount(for: household)
            if let owner = await householdService.getOwnerParticipant(for: household) {
                ownerDisplayName = owner.displayName
            }
            isSyncingMembers = false
        }
    }

    // M4.1: Converts day number (0-6) to weekday name
    // Used by Picker to display "Sunday", "Monday", etc.
    private func dayName(for day: Int) -> String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[day]
    }
}

// MARK: - M7.2.1: Create Household Sheet (Updated M7.2.3 Phase 4.1)

// Sheet view for creating a new household
// M7.2.3: Now includes migration flow to move existing personal data to household
struct CreateHouseholdSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var householdService: HouseholdService
    
    @State private var householdName: String = ""
    @State private var ownerDisplayName: String = ""
    @State private var isLoadingName: Bool = true
    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // M7.2.3 Phase 4.1: Migration flow state
    @State private var showMigrationSheet: Bool = false
    @State private var personalDataCounts: (recipes: Int, lists: Int, mealPlans: Int, categories: Int, templates: Int) = (0, 0, 0, 0, 0)
    @State private var shouldMigrateData: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Household Details")) {
                    TextField("Household Name", text: $householdName)
                        .autocapitalization(.words)

                    HStack {
                        TextField("Your Name", text: $ownerDisplayName)
                            .autocapitalization(.words)
                        if isLoadingName {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }

                Section {
                    Text("A household allows you to share all your grocery lists, recipes, and meal plans with family members or roommates.")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
            .task {
                // M7.6.8: Auto-populate name from iCloud if available
                do {
                    let info = try await householdService.resolveCurrentUserName()
                    if ownerDisplayName.isEmpty && info != "Me" {
                        ownerDisplayName = info
                    }
                } catch {}
                isLoadingName = false
            }
            .navigationTitle("Create Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        checkPersonalDataAndCreate()
                    }
                    .disabled(householdName.isEmpty || ownerDisplayName.isEmpty || isCreating)
                }
            }
            .overlay {
                if isCreating {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(householdService.creationStatus ?? "Creating household…")
                            .font(.subheadline)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut(duration: 0.2), value: householdService.creationStatus)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .cornerRadius(ForagerTheme.Radius.lg)
                    .shadow(radius: 10)
                }
            }
            .alert("Error Creating Household", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showMigrationSheet) {
                // M7.2.3 Phase 4.1: Show migration prompt if user has personal data
                PreHouseholdDataMigrationSheet(
                    recipeCount: personalDataCounts.recipes,
                    listCount: personalDataCounts.lists,
                    mealPlanCount: personalDataCounts.mealPlans,
                    categoryCount: personalDataCounts.categories,
                    templateCount: personalDataCounts.templates,
                    onMoveAll: {
                        shouldMigrateData = true
                        createHouseholdWithMigration()
                    },
                    onKeepPersonal: {
                        shouldMigrateData = false
                        createHouseholdWithMigration()
                    }
                )
            }
        }
    }
    
    // M7.2.3 Phase 4.1: Checks for existing personal data before creating household
    // Shows migration sheet if data exists, otherwise creates household directly
    private func checkPersonalDataAndCreate() {
        // Count existing personal data
        personalDataCounts = householdService.countPersonalData()
        
        let totalCount = personalDataCounts.recipes + personalDataCounts.lists + personalDataCounts.mealPlans + personalDataCounts.categories + personalDataCounts.templates
        
        if totalCount > 0 {
            // User has personal data - show migration prompt
            showMigrationSheet = true
        } else {
            // No personal data - create household directly
            shouldMigrateData = false
            createHouseholdWithMigration()
        }
    }
    
    // M7.2.3 Phase 4.1: Creates household with optional data migration
    // Uses createHouseholdAndShare which implements attach-then-share pattern
    private func createHouseholdWithMigration() {
        isCreating = true
        
        Task {
            do {
                _ = try await householdService.createHouseholdAndShare(
                    name: householdName,
                    ownerName: ownerDisplayName,
                    moveExistingData: shouldMigrateData
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                #if DEBUG
                print("❌ Failed to create household: \(error)")
                #endif
            }
            isCreating = false
        }
    }
}

// MARK: - M7.0.2: SafariView Wrapper

// UIViewControllerRepresentable wrapper for SFSafariViewController
// Enables in-app Safari browser for displaying web content
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HouseholdService(context: PersistenceController.preview.container.viewContext))
    }
}
