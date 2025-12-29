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
    @StateObject private var householdService: HouseholdService
    
    // Access to Core Data context for migration service
    @Environment(\.managedObjectContext) private var viewContext
    
    // M7.0.2: Privacy policy URL presentation state
    @State private var showingPrivacyPolicy = false
    
    // M7.2.1: Household creation sheet state
    @State private var showCreateHouseholdSheet = false
    
    // M7.2.2: Invitation sheet state
    @State private var showInviteMemberSheet = false
    
    // M7.2.1: Initializer to inject HouseholdService
    init(context: NSManagedObjectContext) {
        _householdService = StateObject(wrappedValue: HouseholdService(context: context))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // M7.2.1: Household Management
                householdSection
                
                // M4.1: Meal Planning Preferences
                mealPlanningSection
                
                // M4.3.1: Display Options
                displayOptionsSection
                
                // M7.1.2: Developer Tools
                developerToolsSection
                
                // M7.0.2: About & Privacy
                aboutSection
                
                // M3: Data Management with Migration - Hidden after migration complete
                // migrationSection
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
        }
    }
    
    // MARK: - M7.2.1: Household Section
    
    // Household management section for creating and viewing household details
    // Enables users to share grocery lists, recipes, and meal plans with family
    private var householdSection: some View {
        Section {
            if let household = householdService.currentHousehold {
                // User is in a household - show details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Household Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(household.name ?? "Unnamed Household")
                            .fontWeight(.medium)
                    }
                    
                    // M7.2.2 Task 4: Link to members list
                    NavigationLink {
                        HouseholdMembersView(household: household, service: householdService)
                    } label: {
                        HStack {
                            Text("Members")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(household.members?.count ?? 0)")
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    HStack {
                        Text("Owner")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(household.memberArray.first(where: { $0.isOwner })?.displayName ?? "Unknown")
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 4)
                
                // M7.2.2: Invite Member button
                Button(action: {
                    showInviteMemberSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Member")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
                
            } else {
                // No household - show create button
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create or join a household to share grocery lists, recipes, and meal plans with family or roommates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
            }
        } header: {
            Text("Household")
        } footer: {
            if householdService.currentHousehold == nil {
                Text("All household members will automatically see and share all grocery lists, recipes, and meal plans.")
                    .font(.caption)
            }
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
    
    // MARK: - M7.1.2: Developer Tools Section
    
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
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("CloudKit Sync Status")
                            .font(.headline)
                        Text("Monitor sync events and test CloudKit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // M7.2.2: Household Debug link - TEMPORARILY DISABLED
            // Shows all households in database for debugging sync issues
            // TODO: Add HouseholdDebugView.swift to Xcode project
            /*
            NavigationLink {
                HouseholdDebugView()
            } label: {
                HStack {
                    Image(systemName: "house.circle")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Household Debug")
                            .font(.headline)
                        Text("View all households in database")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Reset Migration")
                            .font(.headline)
                        Text("Re-run Stage A migration for testing")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            // Privacy Policy link
            // Opens privacy policy in in-app Safari browser
            Button {
                showingPrivacyPolicy = true
            } label: {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundColor(.green)
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Quantity Migration")
                            .font(.headline)
                        Text("Convert ingredients to structured format")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Data Management")
        }
    }
    */
    
    // MARK: - Helper Methods
    
    // M4.1: Converts day number (0-6) to weekday name
    // Used by Picker to display "Sunday", "Monday", etc.
    private func dayName(for day: Int) -> String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[day]
    }
}

// MARK: - M7.2.1: Create Household Sheet

// Sheet view for creating a new household
// Allows user to enter household name and creates CloudKit shared zone
struct CreateHouseholdSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var householdService: HouseholdService
    
    @State private var householdName: String = ""
    @State private var ownerDisplayName: String = "" // NEW: User's display name
    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Household Details")) {
                    TextField("Household Name", text: $householdName)
                        .autocapitalization(.words)
                    
                    TextField("Your Name", text: $ownerDisplayName)
                        .autocapitalization(.words)
                }
                
                Section {
                    Text("A household allows you to share all your grocery lists, recipes, and meal plans with family members or roommates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
                        createHousehold()
                    }
                    .disabled(householdName.isEmpty || ownerDisplayName.isEmpty || isCreating)
                }
            }
            .overlay {
                if isCreating {
                    ProgressView("Creating household...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .alert("Error Creating Household", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // Creates household using HouseholdService
    // Displays loading indicator and handles errors
    private func createHousehold() {
        isCreating = true
        
        Task {
            do {
                _ = try await householdService.createHousehold(
                    name: householdName,
                    ownerName: ownerDisplayName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                print("❌ Failed to create household: \(error)")
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
        SettingsView(context: PersistenceController.preview.container.viewContext)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
