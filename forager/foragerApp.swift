// foragerApp.swift
// Updated with Settings Tab - M3 Phase 3
// Updated with Meal Planning Tab - M4.2
// CORRECTED: Tap-to-Pop-to-Root with NavigationStack and path arrays
// M7.2.2 Task 3: CloudKit share invitation handling
// M7.2.3 Phase 2.4: ManagedObjectFactory environment injection

import SwiftUI
import CloudKit

// MARK: - M7.2.3 Phase 2.4: Environment Key for ManagedObjectFactory

private struct ManagedObjectFactoryKey: EnvironmentKey {
    static let defaultValue: ManagedObjectFactory? = nil
}

extension EnvironmentValues {
    var managedObjectFactory: ManagedObjectFactory? {
        get { self[ManagedObjectFactoryKey.self] }
        set { self[ManagedObjectFactoryKey.self] = newValue }
    }
}

@main
struct foragerApp: App {
    // M7.2.2: Register AppDelegate to configure SceneDelegate for CloudKit share handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared
    
    // M7.1.2: CloudKit sync monitoring - observing shared instance from PersistenceController
    // Using @ObservedObject since PersistenceController owns the instance
    @StateObject private var syncMonitor = CloudKitSyncMonitor()
    
    // M7.2.2 Task 3: CloudKit share invitation handling via SceneDelegate
    @StateObject private var householdService: HouseholdService
    
    // Tab selection tracking
    @State private var selectedTab: Tab = .lists
    
    // Navigation paths for each tab (for pop-to-root functionality)
    @State private var listsPath = NavigationPath()
    @State private var ingredientsPath = NavigationPath()
    @State private var recipesPath = NavigationPath()
    @State private var mealPlansPath = NavigationPath()
    @State private var categoriesPath = NavigationPath()
    
    // Pop-to-root triggers for sheet dismissal
    @State private var listsPopToRoot = false
    @State private var ingredientsPopToRoot = false
    @State private var recipesPopToRoot = false
    @State private var mealPlansPopToRoot = false
    @State private var categoriesPopToRoot = false

    // M7.2.2: CloudKit permission pre-prompt
    @State private var showPermissionPrePrompt = false

    // M7.2.2 Task 3: Initialize HouseholdService
    init() {
        let service = HouseholdService(context: PersistenceController.shared.container.viewContext)
        _householdService = StateObject(wrappedValue: service)
    }

    var body: some Scene {
        WindowGroup {
            // M7.2.3 Phase 2.4 & 2.6: Create ManagedObjectFactory for environment injection
            let scopeProvider = HouseholdScopeProvider(
                householdService: householdService,
                persistence: persistenceController  // ✅ Phase 2.6: Changed from 'context:' to 'persistence:'
            )
            let objectFactory = ManagedObjectFactory(
                context: persistenceController.container.viewContext,
                scopeProvider: scopeProvider,
                persistence: persistenceController  // ✅ Phase 2.6: Added persistence parameter
            )
            
            TabView(selection: $selectedTab) {
                NavigationStack(path: $listsPath) {
                    WeeklyListsView(popToRoot: $listsPopToRoot)
                }
                .tabItem {
                    Label("Lists", systemImage: "list.clipboard")
                }
                .tag(Tab.lists)
                
                NavigationStack(path: $ingredientsPath) {
                    IngredientsView(popToRoot: $ingredientsPopToRoot)
                }
                .tabItem {
                    Label("Ingredients", systemImage: "leaf.circle")
                }
                .tag(Tab.ingredients)
                
                NavigationStack(path: $recipesPath) {
                    RecipeListView(popToRoot: $recipesPopToRoot)
                }
                .tabItem {
                    Label("Recipes", systemImage: "book.pages")
                }
                .tag(Tab.recipes)
                
                NavigationStack(path: $mealPlansPath) {
                    MealPlansListView(popToRoot: $mealPlansPopToRoot)
                }
                .tabItem {
                    Label("Meal Plans", systemImage: "calendar")
                }
                .tag(Tab.mealPlans)
                
                NavigationStack(path: $categoriesPath) {
                    ManageCategoriesView(popToRoot: $categoriesPopToRoot)
                }
                .tabItem {
                    Label("Categories", systemImage: "folder.badge.gearshape")
                }
                .tag(Tab.categories)
                
                // M3 Phase 3: Settings Tab (replaces DEBUG-only Migration tab)
                // M7.2.2 FIX: No longer needs context - uses environmentObject
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(Tab.settings)
            }
            .onChange(of: selectedTab) { oldTab, newTab in
                // Pop to root when tapping the already-selected tab
                // This is standard iOS tab bar behavior
                if oldTab == newTab {
                    handlePopToRoot(for: newTab)
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environment(\.managedObjectFactory, objectFactory) // M7.2.3 Phase 2.4: Inject factory
            .environmentObject(householdService) // M7.2.3 Phase 2.4: Make household service available
            .environmentObject(syncMonitor) // M7.1.2: Make sync monitor available to all views
            // M7.2.2: Pre-permission prompt for iCloud name access
            .alert("See Who's in Your Household", isPresented: $showPermissionPrePrompt) {
                Button("Continue") {
                    Task {
                        await requestSystemPermission()
                    }
                }
                Button("Not Now", role: .cancel) {
                    print("ℹ️ User declined permission pre-prompt")
                }
            } message: {
                Text("To display member names like \"Mary\" instead of \"User\", Forager needs permission to access iCloud display names.\n\nThis helps you know who you're sharing lists with!")
            }
            // M7.2.2: CloudKit share invitations now handled by SceneDelegate
            // M7.2.2: Check for existing households on app launch (new device scenario)
            .task {
                // Give CloudKit a moment to sync on first launch
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

                // Request user discoverability permission if needed
                // This allows fetching iCloud display names for household members
                await requestUserDiscoverabilityPermission()

                // Check if user already has a household (e.g., new device, reinstall)
                if householdService.currentHousehold == nil {
                    print("🔍 App launch: Checking for existing households...")
                    await householdService.checkForAcceptedInvitations()
                }

                // Refresh display name on every launch
                // Handles: permission grants, iCloud name changes, device name changes
                await householdService.refreshCurrentMemberDisplayName()
            }
            // M7.2.2 FIX: Listen for CloudKit share acceptance from SceneDelegate
            // This ensures the SAME HouseholdService instance is used (not a new one)
            .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
                print("📬 Received cloudKitShareAccepted notification")
                Task {
                    await householdService.checkForAcceptedInvitations()
                }
            }
        }
    }

    // MARK: - M7.2.2: CloudKit Permission Management

    /// Checks permission status and shows pre-prompt if needed
    /// Called on app launch to ensure names can be fetched for household members
    private func requestUserDiscoverabilityPermission() async {
        let container = CKContainer(identifier: "iCloud.com.richhayn.forager")

        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                print("ℹ️ iCloud account not available, skipping permission request")
                return
            }

            let permission = try await container.applicationPermissionStatus(for: .userDiscoverability)

            if permission == .granted {
                print("✅ User discoverability permission already granted")
            } else if permission == .initialState {
                // Show pre-permission prompt first
                print("📋 Showing permission pre-prompt...")
                await MainActor.run {
                    showPermissionPrePrompt = true
                }
            } else {
                print("⚠️ User discoverability permission status: \(permission.rawValue)")
            }
        } catch {
            print("⚠️ Could not check user discoverability permission: \(error)")
        }
    }

    /// Requests the actual system permission (called after pre-prompt acceptance)
    private func requestSystemPermission() async {
        let container = CKContainer(identifier: "iCloud.com.richhayn.forager")

        do {
            print("📋 Requesting system permission...")
            let permission = try await container.requestApplicationPermission(.userDiscoverability)

            if permission == .granted {
                print("✅ User discoverability permission granted")

                // Refresh display name after permission grant
                await householdService.refreshCurrentMemberDisplayName()
            } else {
                print("⚠️ User discoverability permission denied - will use fallback names")
            }
        } catch {
            print("⚠️ Could not request user discoverability permission: \(error)")
        }
    }

    // MARK: - Tab Pop-to-Root Handler

    // Clears navigation path and triggers sheet dismissal for the specified tab
    private func handlePopToRoot(for tab: Tab) {
        switch tab {
        case .lists:
            listsPath = NavigationPath()
            listsPopToRoot.toggle()
        case .ingredients:
            ingredientsPath = NavigationPath()
            ingredientsPopToRoot.toggle()
        case .recipes:
            recipesPath = NavigationPath()
            recipesPopToRoot.toggle()
        case .mealPlans:
            mealPlansPath = NavigationPath()
            mealPlansPopToRoot.toggle()
        case .categories:
            categoriesPath = NavigationPath()
            categoriesPopToRoot.toggle()
        case .settings:
            break // Settings has no navigation stack
        }
    }
}

// MARK: - Tab Enumeration

// Defines all tabs in the app for type-safe selection tracking
enum Tab {
    case lists
    case ingredients
    case recipes
    case mealPlans
    case categories
    case settings
}

// MARK: - Custom Button Styles
// Note: These are now also defined in SettingsView.swift with "Migration" prefix
// Keeping these here for backward compatibility with any other views that might use them

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.red.opacity(0.8) : Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - M7.2.2: AppDelegate for SceneDelegate Configuration

/// AppDelegate that configures SceneDelegate for CloudKit share invitation handling
/// Required because SwiftUI apps need UIKit lifecycle integration for CloudKit shares
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
