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
import CloudKit

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

    // M18.1.3: Store service for store management
    @EnvironmentObject private var storeService: StoreService

    // M9.26: Navigation state for Settings destinations
    @State private var showingIngredients = false
    @State private var showingCategories = false
    @State private var showingStores = false

    // M9.34: Import guide replay
    @State private var importGuideReset = false

    // Debug: Share URL acceptance
    @State private var shareURLInput = ""
    @State private var isAcceptingShare = false
    @State private var shareAcceptResult: String?

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

            // M10.6: AI Integration (optional LLM API)
            aiImportSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // M9.15.3: Diagnostic Log
            // M9.28 gated behind #if DEBUG for production hide.
            // architecture-compliance-sweep (2026-04-19): un-gated for TestFlight
            // beta builds so testers can enable logging + share log entries with
            // the developer. **TODO: re-gate with `#if DEBUG || BETA` or a
            // Settings.bundle toggle before App Store submission.** Tracked at
            // /Users/rich/Development/forager/docs/next-prompt.md backlog and
            // the current-story "Known Issues & Limitations" section.
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
    
    // MARK: - Print Row Grammar (reskin-provisions-press)

    /// Hairline rule between broadsheet rows (matches list-detail dividers).
    private var hairline: some View {
        Rectangle()
            .fill(ForagerTheme.borderSubtle)
            .frame(height: 1.5)
            .padding(.vertical, ForagerTheme.Spacing.sm)
    }

    /// Right-aligned mono value — the price-tag position.
    private func rowValue(_ text: String) -> some View {
        Text(text)
            .font(ForagerTheme.quantityFont)
            .foregroundStyle(ForagerTheme.textSecondary)
    }

    /// Uppercase condensed tomato action (dashboard "PICK ONE" grammar).
    private func rowAction(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold).width(.condensed))
            .tracking(0.5)
            .foregroundStyle(ForagerTheme.accentPrimary)
    }

    /// Printed status tag (white condensed label on solid fill).
    private func statusTag(_ text: String, fill: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold).width(.condensed))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
    }

    /// Small tertiary chevron for navigation rows.
    private var rowChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(ForagerTheme.textTertiary)
    }

    // MARK: - M15.5b: Household Section (simplified — detail in HouseholdView)

    private var householdSection: some View {
        Section {
            ZStack {
                NavigationLink { HouseholdView() } label: { EmptyView() }
                    .opacity(0)
                if let household = householdService.currentHousehold {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(household.name ?? "My Household")
                                .font(ForagerTheme.bodyFont)
                                .fontWeight(.medium)
                            Text("Manage members, invitations, and sharing")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                        Spacer()
                        rowChevron
                    }
                } else {
                    // Empty-state row — dashboard grammar: message + tomato action
                    HStack {
                        Text("Share lists, recipes, and meal plans with family.")
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                        Spacer()
                        rowAction("Create")
                    }
                }
            }
            .padding(.vertical, ForagerTheme.Spacing.xs)
        } header: {
            ForagerBand("Household")
                .textCase(nil)
        }
    }
    
    // MARK: - M15.1: Data Management Section (relocated from tabs — ADR 011)


    private var dataManagementSection: some View {
        Section {
            VStack(spacing: 0) {
                // Ingredients row
                Button { showingIngredients = true } label: {
                    HStack {
                        Text("Ingredients")
                            .font(ForagerTheme.bodyFont)
                        Spacer()
                        rowChevron
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                hairline

                // Categories row
                Button { showingCategories = true } label: {
                    HStack {
                        Text("Categories")
                            .font(ForagerTheme.bodyFont)
                        Spacer()
                        rowChevron
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                hairline

                // M18.1.3: Stores row
                Button { showingStores = true } label: {
                    HStack {
                        Text("Stores")
                            .font(ForagerTheme.bodyFont)
                        Spacer()
                        rowChevron
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

            }
            .padding(.vertical, ForagerTheme.Spacing.xs)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .navigationDestination(isPresented: $showingIngredients) {
                IngredientsView(popToRoot: .constant(false))
            }
            .navigationDestination(isPresented: $showingCategories) {
                ManageCategoriesView(popToRoot: .constant(false))
            }
            .navigationDestination(isPresented: $showingStores) {
                ManageStoresView(popToRoot: .constant(false), storeService: storeService)
            }
        } header: {
            ForagerBand("Data")
                .textCase(nil)
        }
    }

    // MARK: - M4.1: Meal Planning Section
    
    // Meal planning preferences for user configuration
    // Controls meal plan duration, start day, and display options
    private var mealPlanningSection: some View {
        Section {
            VStack(spacing: 0) {
                // Duration stepper (3-14 days)
                // Controls how many days appear in meal plan calendar
                Stepper(value: $preferencesService.mealPlanDuration, in: 3...14) {
                    HStack {
                        Text("Plan Duration")
                            .font(ForagerTheme.bodyFont)
                        Spacer()
                        rowValue("\(preferencesService.mealPlanDuration) DAYS")
                    }
                }

                hairline

                // Start day picker (Sunday-Saturday)
                // Determines which day meal plan calendar begins on
                Picker("Start Day", selection: $preferencesService.mealPlanStartDay) {
                    ForEach(0..<7) { day in
                        Text(dayName(for: day)).tag(day)
                    }
                }

                hairline

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
            .padding(.vertical, ForagerTheme.Spacing.xs)
        } header: {
            ForagerBand("Meal Planning")
                .textCase(nil)
        } footer: {
            Text("Configure how meal plans are created and displayed. Meal plans will default to \(preferencesService.mealPlanDuration) days starting on \(preferencesService.startDayName).")
                .font(.caption)
        }
    }
    
    // MARK: - M10.6: AI Integration Section

    @State private var showingAutoNameInfo = false
    @State private var showingAIInfo = false

    private var aiImportSection: some View {
        Section {
            VStack(spacing: 0) {
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
                    hairline

                    // Provider
                    HStack {
                        Text("Provider")
                            .font(ForagerTheme.bodyFont)
                        Spacer()
                        rowValue("Claude (API Key)")
                    }

                    hairline

                    // M10.6.16: API Key row — per-user, stored in Keychain
                    if llmSettings.hasAPIKey {
                        HStack {
                            Text("API Key")
                                .font(ForagerTheme.bodyFont)
                            Spacer()
                            rowValue(llmSettings.maskedAPIKey ?? "")
                            Button {
                                clearAPIKey()
                                apiKeyInput = ""
                            } label: {
                                Text("CLEAR")
                                    .font(.system(size: 12, weight: .bold).width(.condensed))
                                    .tracking(0.5)
                                    .foregroundStyle(ForagerTheme.statusDangerFG)
                            }
                            .buttonStyle(.borderless)
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

                    hairline

                    HStack {
                        Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                            rowAction("Get API Key")
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        Button {
                            Task { await llmSettings.testConnection() }
                        } label: {
                            if llmSettings.isTestingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                rowAction("Test Connection")
                            }
                        }
                        .buttonStyle(.borderless)
                        .disabled(!llmSettings.hasAPIKey || llmSettings.isTestingConnection)
                    }

                    // Connection status
                    connectionStatusRow
                }
            }
            .padding(.vertical, ForagerTheme.Spacing.xs)
        } header: {
            ForagerBand("AI Integration")
                .textCase(nil)
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

    // Debug: Accept a CloudKit share invitation from a pasted URL
    private func acceptShareFromURL() async {
        let trimmed = shareURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            shareAcceptResult = "❌ Invalid URL"
            return
        }

        isAcceptingShare = true
        shareAcceptResult = nil

        let container = CKContainer(identifier: "iCloud.com.richhayn.forager")

        do {
            let metadata = try await container.shareMetadata(for: url)

            let persistence = PersistenceController.shared
            let sharedStore = persistence.sharedStore

            persistence.container.acceptShareInvitations(
                from: [metadata],
                into: sharedStore
            ) { _, error in
                DispatchQueue.main.async {
                    isAcceptingShare = false
                    if let error = error {
                        shareAcceptResult = "❌ \(error.localizedDescription)"
                    } else {
                        shareAcceptResult = "✅ Share accepted — restart app to load household"
                        shareURLInput = ""
                    }
                }
            }
        } catch {
            isAcceptingShare = false
            shareAcceptResult = "❌ \(error.localizedDescription)"
        }
    }

    @ViewBuilder
    private var connectionStatusRow: some View {
        if let result = llmSettings.connectionTestResult {
            HStack {
                Text("Status")
                    .font(ForagerTheme.bodyFont)
                Spacer()
                switch result {
                case .success:
                    statusTag("Connected", fill: ForagerTheme.statusSuccessFG)
                case .failure(let message):
                    VStack(alignment: .trailing, spacing: 2) {
                        statusTag("Failed", fill: ForagerTheme.statusDangerFG)
                        Text(message)
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.statusDangerFG)
                            .lineLimit(1)
                    }
                }
            }
        } else if !llmSettings.hasAPIKey {
            HStack {
                Text("Status")
                    .font(ForagerTheme.bodyFont)
                Spacer()
                statusTag("Not Set", fill: ForagerTheme.textDisabled)
            }
        }
    }

    // MARK: - M9.15.3: Diagnostic Log Section (Release-safe)

    @ObservedObject private var diagnosticLogger = DiagnosticLogger.shared

    @State private var showingDiagnosticLog = false

    private var diagnosticLogSection: some View {
        Section {
            VStack(spacing: 0) {
                Button { showingDiagnosticLog = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diagnostic Log")
                                .font(ForagerTheme.bodyFont)
                            Text("\(diagnosticLogger.lineCount) lines • \(diagnosticLogger.formattedFileSize)")
                                .font(ForagerTheme.footnoteFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                        Spacer()
                        rowChevron
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                hairline

                Toggle("Logging Enabled", isOn: $diagnosticLogger.isEnabled)
                    .font(ForagerTheme.bodyFont)
            }
            .padding(.vertical, ForagerTheme.Spacing.xs)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .navigationDestination(isPresented: $showingDiagnosticLog) {
                DiagnosticLogView()
            }
        } header: {
            ForagerBand("Diagnostics")
                .textCase(nil)
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
            VStack(spacing: 0) {
                // M10.6.5: Debug log toggle + viewer
                // M10.6.13: Ungated for Release builds
                Toggle("Debug Mode", isOn: Binding(
                    get: { DebugLogService.shared.isEnabled },
                    set: { DebugLogService.shared.isEnabled = $0 }
                ))

                if DebugLogService.shared.isEnabled {
                    hairline
                    ZStack {
                        NavigationLink { DebugLogView() } label: { EmptyView() }
                            .opacity(0)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Debug Log")
                                    .font(ForagerTheme.bodyFont)
                                Text("\(DebugLogService.shared.entries.count) entries")
                                    .font(ForagerTheme.footnoteFont)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                            Spacer()
                            rowChevron
                        }
                    }
                }

                hairline

                // CloudKit Sync Status link
                // Opens test interface for monitoring CloudKit sync events
                ZStack {
                    NavigationLink { CloudKitSyncTestView() } label: { EmptyView() }
                        .opacity(0)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CloudKit Sync Status")
                                .font(ForagerTheme.bodyFont)
                            Text("Monitor sync events and test CloudKit")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                        Spacer()
                        rowChevron
                    }
                }

                #if DEBUG
                hairline

                // M7.2.3 Phase 3.5: CloudKit Test Harness
                // Comprehensive testing UI for duplicate prevention validation
                ZStack {
                    NavigationLink { CloudKitTestHarnessView() } label: { EmptyView() }
                        .opacity(0)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CloudKit Test Harness")
                                .font(ForagerTheme.bodyFont)
                            Text("Test duplicate prevention and repository patterns")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                        Spacer()
                        rowChevron
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
                hairline

                // M7.3.3: Category Sync Diagnostic
                // Dumps all categories with their store location and householdKey
                // Use to troubleshoot why categories aren't syncing to members
                Button {
                    householdService.dumpCategorySyncDiagnostics()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Category Sync Diagnostic")
                                .font(ForagerTheme.bodyFont)
                            Text("Dump category store & householdKey info")
                                .font(ForagerTheme.captionFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                        Spacer()
                    }
                }

                hairline

                // M8.4 Phase 7: Correction corpus gate status
                let correctionCount = ParsingTelemetryService.shared.getTotalCorrectionCount()
                let retrainingThreshold = 50
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Correction Corpus")
                            .font(ForagerTheme.bodyFont)
                        Text(correctionCount >= retrainingThreshold
                            ? "Ready for retraining (\(correctionCount) corrections)"
                            : "Need \(retrainingThreshold - correctionCount) more corrections (\(correctionCount)/\(retrainingThreshold))")
                            .font(ForagerTheme.footnoteFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    Spacer()
                    Text("\(correctionCount)")
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(correctionCount >= retrainingThreshold ? ForagerTheme.statusSuccessFG : ForagerTheme.textTertiary)
                }

                hairline

                // Debug: Accept share invitation by pasting URL
                VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                    Text("Accept Share URL")
                        .font(ForagerTheme.bodyFont)
                        .fontWeight(.medium)
                    TextField("Paste iCloud share URL", text: $shareURLInput)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.caption)
                    if isAcceptingShare {
                        ProgressView("Accepting...")
                            .font(.caption)
                    } else if let result = shareAcceptResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("✅") ? ForagerTheme.statusSuccessFG : ForagerTheme.statusDangerFG)
                    }
                    Button {
                        Task { await acceptShareFromURL() }
                    } label: {
                        Text("Accept Invitation")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ForagerPrimaryButtonStyle())
                    .disabled(shareURLInput.isEmpty || isAcceptingShare)
                }
                #endif
            }
            .padding(.vertical, ForagerTheme.Spacing.xs)
        } header: {
            ForagerBand("Developer Tools")
                .textCase(nil)
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
            // Replay Onboarding
            Button {
                NotificationCenter.default.post(name: .replayOnboarding, object: nil)
            } label: {
                HStack {
                    Text("Replay Onboarding")
                        .font(ForagerTheme.bodyFont)
                    Spacer()
                    rowChevron
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.visible)
            .listRowSeparatorTint(ForagerTheme.borderSubtle)

            // M9.34: Replay Import Guide — resets the flag so next import shows guide
            Button {
                UserDefaults.standard.set(false, forKey: "hasSeenImportGuide")
                importGuideReset = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Replay Import Guide")
                            .font(ForagerTheme.bodyFont)
                        Spacer()
                        rowChevron
                    }
                    if importGuideReset {
                        Text("Guide will show next time you import a recipe")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.statusSuccessFG)
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.visible)
            .listRowSeparatorTint(ForagerTheme.borderSubtle)

            // Privacy Policy link
            Button {
                showingPrivacyPolicy = true
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .font(ForagerTheme.bodyFont)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .font(.caption)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.visible)
            .listRowSeparatorTint(ForagerTheme.borderSubtle)
        } header: {
            ForagerBand("About")
                .textCase(nil)
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
            ForagerBand("Data Management")
                .textCase(nil)
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
                .scrollContentBackground(.hidden)
                .background(ForagerTheme.backgroundCanvas)
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
                    .keyboardShortcut(.cancelAction)
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
