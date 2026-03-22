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
    
    // M10.6: LLM settings for AI import
    @StateObject private var llmSettings = LLMSettingsService.shared

    // M10.6.3: API key entry state
    @State private var apiKeyInput = ""


    // M7.0.2: Privacy policy URL presentation state
    @State private var showingPrivacyPolicy = false

    var body: some View {
        // M15.1: NavigationView removed — SettingsView is inside NavigationStack from TabView
        List {
            // M7.2.1: Household Management
            householdSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M15.1: Data Management (Ingredients & Categories relocated from tabs)
            dataManagementSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M4.1: Meal Planning Preferences
            mealPlanningSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M4.3.1: Display Options
            displayOptionsSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M10.6: AI Integration (optional LLM API)
            aiImportSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M9.15.3: Diagnostic Log (available in Release + Debug)
            diagnosticLogSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M10.6.18: Developer tools hidden in Release builds for launch
            #if DEBUG
            developerToolsSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            #endif

            // M7.0.2: About & Privacy
            aboutSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(ForagerTheme.backgroundCanvas.ignoresSafeArea())
        .sheet(isPresented: $showingPrivacyPolicy) {
            SafariView(url: URL(string: "https://rfhayn.github.io/forager/privacy.html")!)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - M15.5b: Household Section (simplified — detail in HouseholdView)

    private var householdSection: some View {
        Section {
            NavigationLink {
                HouseholdView()
            } label: {
                if let household = householdService.currentHousehold {
                    HStack {
                        Image(systemName: "person.3")
                            .foregroundStyle(ForagerTheme.accentSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(household.name ?? "My Household")
                                .font(ForagerTheme.bodyFont)
                            Text("Manage members, invitations, and sharing")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "person.3")
                            .foregroundStyle(ForagerTheme.accentPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Household")
                                .font(ForagerTheme.bodyFont)
                                .foregroundStyle(ForagerTheme.accentPrimary)
                            Text("Share lists, recipes, and meal plans with family")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                    }
                }
            }
            .foragerGlassCard()
        } header: {
            Text("Household")
        }
    }
    
    // MARK: - M15.1: Data Management Section (relocated from tabs — ADR 011)

    @State private var showingRestoreConfirmation = false
    @State private var restoreResultMessage: String?

    private var dataManagementSection: some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                NavigationLink {
                    IngredientsView(popToRoot: .constant(false))
                } label: {
                    Label("Ingredients", systemImage: "leaf.circle")
                }
                .buttonStyle(.borderless)
                Divider()
                NavigationLink {
                    ManageCategoriesView(popToRoot: .constant(false))
                } label: {
                    Label("Categories", systemImage: "folder.badge.gearshape")
                }
                .buttonStyle(.borderless)
                Divider()
                Button {
                    showingRestoreConfirmation = true
                } label: {
                    Label("Restore Default Categories", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
            }
            .foragerGlassCard()
            .confirmationDialog("Restore Default Categories?",
                                isPresented: $showingRestoreConfirmation,
                                titleVisibility: .visible) {
                Button("Restore") {
                    do {
                        let created = try DefaultSeeder.restoreDefaultCategories(in: viewContext)
                        restoreResultMessage = created > 0
                            ? "Restored \(created) missing categories."
                            : "All default categories already exist."
                    } catch {
                        restoreResultMessage = "Failed to restore: \(error.localizedDescription)"
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will re-create any missing default categories (Produce, Pantry, Dairy & Fridge, etc.). Existing categories won't be affected.")
            }
            .alert("Categories", isPresented: Binding(
                get: { restoreResultMessage != nil },
                set: { if !$0 { restoreResultMessage = nil } }
            )) {
                Button("OK") { restoreResultMessage = nil }
            } message: {
                Text(restoreResultMessage ?? "")
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
            VStack(spacing: ForagerTheme.Spacing.sm) {
                // Duration stepper (3-14 days)
                // Controls how many days appear in meal plan calendar
                Stepper(
                    "Plan Duration: \(preferencesService.mealPlanDuration) days",
                    value: $preferencesService.mealPlanDuration,
                    in: 3...14
                )

                Divider()

                // Start day picker (Sunday-Saturday)
                // Determines which day meal plan calendar begins on
                Picker("Start Day", selection: $preferencesService.mealPlanStartDay) {
                    ForEach(0..<7) { day in
                        Text(dayName(for: day)).tag(day)
                    }
                }

                Divider()

                // Auto-name toggle
                // When enabled, generates names like "Week of Oct 23"
                HStack {
                    Toggle("Auto-name Meal Plans", isOn: $preferencesService.autoNameMealPlans)
                    Button {
                        showingAutoNameInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
                .alert("Auto-name Meal Plans", isPresented: $showingAutoNameInfo) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Automatically names new meal plans based on their start date — for example, \"Week of Mar 3\" for a 7-day plan. When off, you'll name each plan yourself.")
                }
            }
            .foragerGlassCard()
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
            VStack {
                // Show recipe sources toggle
                // When enabled, shows recipe tags like "[Tacos] [Spaghetti]"
                HStack {
                    Toggle("Show Recipe Sources", isOn: $preferencesService.showRecipeSources)
                    Button {
                        showingRecipeSourcesInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
                .alert("Show Recipe Sources", isPresented: $showingRecipeSourcesInfo) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Shows which recipes each grocery item came from — for example, \"Ground beef\" will display [Tacos] [Spaghetti] tags. Helpful when your grocery list is generated from a meal plan.")
                }
            }
            .foragerGlassCard()
        } header: {
            Text("Display Options")
        }
    }
    
    // MARK: - M10.6: AI Integration Section

    @State private var showingAutoNameInfo = false
    @State private var showingRecipeSourcesInfo = false
    @State private var showingAIInfo = false

    private var aiImportSection: some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                HStack {
                    Toggle("Enable AI for Ingredients", isOn: $llmSettings.isEnabled)
                    Button {
                        showingAIInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
                .alert("AI for Ingredients", isPresented: $showingAIInfo) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Uses AI to parse complex ingredient text that the built-in parser can't handle — things like \"juice of 2 lemons\" or \"salt and pepper to taste.\"\n\nRequires an API key from your AI provider. Your ingredient text is sent to the API for parsing. Estimated cost is ~$0.0005 per recipe. Your key is stored securely in iOS Keychain on your device.\n\nThe app works fully without this — it's an optional enhancement.")
                }

                if llmSettings.isEnabled {
                    Divider()

                    // Provider
                    HStack {
                        Text("Provider")
                        Spacer()
                        Text("Claude (API Key)")
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }

                    Divider()

                    // M10.6.16: API Key row — per-user, stored in Keychain
                    if llmSettings.hasAPIKey {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text(llmSettings.maskedAPIKey ?? "")
                                .foregroundStyle(ForagerTheme.textSecondary)
                            Button("Clear") {
                                clearAPIKey()
                                apiKeyInput = ""
                            }
                            .foregroundStyle(.red)
                            .font(.caption)
                        }
                    } else {
                        SecureField("Paste API key", text: $apiKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .onSubmit {
                                saveAPIKey(apiKeyInput)
                                apiKeyInput = ""
                            }
                            .onChange(of: apiKeyInput) { _, newValue in
                                // Auto-save when a valid API key is pasted (starts with sk-)
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.hasPrefix("sk-") && trimmed.count > 20 {
                                    saveAPIKey(trimmed)
                                    apiKeyInput = ""
                                }
                            }
                    }

                    Divider()

                    HStack {
                        Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                            Label("Get API Key", systemImage: "arrow.up.right.square")
                                .font(.caption)
                        }
                        Spacer()
                        Button {
                            Task { await llmSettings.testConnection() }
                        } label: {
                            if llmSettings.isTestingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                                    .font(.caption)
                            }
                        }
                        .disabled(!llmSettings.hasAPIKey || llmSettings.isTestingConnection)
                    }

                    // Connection status
                    connectionStatusRow
                }
            }
            .foragerGlassCard()
        } header: {
            Text("AI Integration")
        } footer: {
            if llmSettings.isEnabled {
                Text("Only ingredient text is sent to the API. Estimated cost: ~$0.0005/recipe. Your key is stored securely in iOS Keychain on this device.")
                    .font(.caption)
            }
        }
    }

    // MARK: - M10.6.16: API Key Helpers (per-user, Keychain only)

    private func saveAPIKey(_ key: String) {
        llmSettings.saveAPIKey(key)
    }

    private func clearAPIKey() {
        llmSettings.deleteAPIKey()
    }

    @ViewBuilder
    private var connectionStatusRow: some View {
        if let result = llmSettings.connectionTestResult {
            HStack {
                Text("Status")
                Spacer()
                switch result {
                case .success:
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                case .failure(let message):
                    Label(message, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        } else if !llmSettings.hasAPIKey {
            HStack {
                Text("Status")
                Spacer()
                Label("Not configured", systemImage: "circle")
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - M9.15.3: Diagnostic Log Section (Release-safe)

    @ObservedObject private var diagnosticLogger = DiagnosticLogger.shared

    private var diagnosticLogSection: some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                NavigationLink {
                    DiagnosticLogView()
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundStyle(ForagerTheme.accentSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diagnostic Log")
                                .font(ForagerTheme.bodyFont)
                            Text("\(diagnosticLogger.lineCount) lines • \(diagnosticLogger.formattedFileSize)")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                    }
                }
                .buttonStyle(.borderless)

                Divider()

                Toggle("Logging Enabled", isOn: $diagnosticLogger.isEnabled)
                    .font(ForagerTheme.bodyFont)
            }
            .foragerGlassCard()
        } header: {
            Text("Diagnostics")
        } footer: {
            Text("Persistent log of CloudKit and household operations. Export from the log viewer to share with support.")
                .font(.caption)
        }
    }

    // M7.1.2: Developer Tools Section
    // M7.2.3 Phase 3.5: Added CloudKit Test Harness

    // Developer tools for CloudKit sync testing and debugging
    // Provides access to sync status monitoring and validation
    private var developerToolsSection: some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                // M10.6.5: Debug log toggle + viewer
                // M10.6.13: Ungated for Release builds
                Toggle("Debug Mode", isOn: Binding(
                    get: { DebugLogService.shared.isEnabled },
                    set: { DebugLogService.shared.isEnabled = $0 }
                ))

                if DebugLogService.shared.isEnabled {
                    Divider()
                    NavigationLink {
                        DebugLogView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(ForagerTheme.accentSecondary)
                            VStack(alignment: .leading) {
                                Text("Debug Log")
                                    .font(.headline)
                                Text("\(DebugLogService.shared.entries.count) entries")
                                    .font(.caption)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                        }
                    }
                }

                Divider()

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
                Divider()

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
                Divider()

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

                Divider()

                // M8.4 Phase 7: Correction corpus gate status
                let correctionCount = ParsingTelemetryService.shared.getTotalCorrectionCount()
                let retrainingThreshold = 50
                HStack {
                    Image(systemName: "brain")
                        .foregroundStyle(correctionCount >= retrainingThreshold ? ForagerTheme.statusSuccessFG : ForagerTheme.textTertiary)
                    VStack(alignment: .leading) {
                        Text("Correction Corpus")
                            .font(.headline)
                        Text(correctionCount >= retrainingThreshold
                            ? "Ready for retraining (\(correctionCount) corrections)"
                            : "Need \(retrainingThreshold - correctionCount) more corrections (\(correctionCount)/\(retrainingThreshold))")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    Spacer()
                    Text("\(correctionCount)")
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(correctionCount >= retrainingThreshold ? ForagerTheme.statusSuccessFG : ForagerTheme.textTertiary)
                }
                #endif
            }
            .foragerGlassCard()
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
            VStack(spacing: ForagerTheme.Spacing.sm) {
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
                .buttonStyle(.borderless)

                Divider()

                // Privacy Policy link
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
                .buttonStyle(.borderless)
            }
            .foragerGlassCard()
        } header: {
            Text("About")
        } footer: {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                Text("Your data is stored on your device and synced privately through your iCloud account. Household data is shared only with household members. We never collect or share your information with third parties.")
                    .font(ForagerTheme.captionFont)
                Text("Forager v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textDisabled)
            }
            .frame(maxWidth: .infinity, alignment: .center)
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

    // M4.1: Converts day number (0-6) to weekday name
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
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg, style: .continuous))
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.lg, style: .continuous))
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
    // M9.15: Uses create-empty-then-copy pattern (replaces broken attach-then-share)
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
