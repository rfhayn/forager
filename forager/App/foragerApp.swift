// foragerApp.swift
// M15.1: Liquid Glass TabView with 5-tab navigation
// M7.2.2 Task 3: CloudKit share invitation handling
// M7.2.3 Phase 2.4: ManagedObjectFactory environment injection

import SwiftUI
import CloudKit
import Combine

// MARK: - M15.1: Navigation Tab Enum (5 tabs — ADR 011)

enum NavigationTab: String, CaseIterable {
    case lists
    case recipes
    case mealPlans
    case settings
    case search

    var title: String {
        switch self {
        case .lists: return "Lists"
        case .recipes: return "Recipes"
        case .mealPlans: return "Meals"
        case .settings: return "Settings"
        case .search: return "Search"
        }
    }

    var icon: String {
        switch self {
        case .lists: return "list.bullet"
        case .recipes: return "book"
        case .mealPlans: return "calendar"
        case .settings: return "gearshape"
        case .search: return "magnifyingglass"
        }
    }
}

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

// MARK: - App Entry Point

@main
struct foragerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared
    @StateObject private var syncMonitor = CloudKitSyncMonitor()
    @StateObject private var householdService: HouseholdService

    // M7.5: Service layer — all Core Data writes go through services
    @StateObject private var recipeService: RecipeService
    @StateObject private var weeklyListService: WeeklyListService
    @StateObject private var ingredientTemplateService: IngredientTemplateService
    @StateObject private var ingredientParsingService: IngredientParsingService

    // M10.6.8: Shared ingredient matching service
    @StateObject private var ingredientMatchService: IngredientMatchService

    // M10.1: Import service at app level for browser and URL import
    @StateObject private var importService: RecipeImportService

    // Coach mark onboarding
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showCoachMarks = false
    @State private var selectedTab: NavigationTab = .lists

    // First-launch loading screen
    @State private var isReady = false

    // TODO (M7.5): Remove — native TabView handles pop-to-root
    @State private var listsPopToRoot = false
    @State private var recipesPopToRoot = false
    @State private var mealPlansPopToRoot = false

    init() {
        let context = PersistenceController.shared.container.viewContext

        let household = HouseholdService(context: context)
        _householdService = StateObject(wrappedValue: household)

        // M7.5: Build service dependency chain
        let templateService = IngredientTemplateService(context: context)
        let parsingService = IngredientParsingService(context: context, templateService: templateService)
        let recipe = RecipeService(context: context, parsingService: parsingService)
        let weeklyList = WeeklyListService(context: context, parsingService: parsingService)

        _ingredientTemplateService = StateObject(wrappedValue: templateService)
        _ingredientParsingService = StateObject(wrappedValue: parsingService)
        _ingredientMatchService = StateObject(wrappedValue: IngredientMatchService(parsingService: parsingService, templateService: templateService))
        _recipeService = StateObject(wrappedValue: recipe)
        _weeklyListService = StateObject(wrappedValue: weeklyList)

        // M10.1: Import service for browser and URL import
        let importSvc = RecipeImportService(context: context, parsingService: parsingService)
        _importService = StateObject(wrappedValue: importSvc)

        // M10.6.7: Wire household API key into LLM settings
        // Reads currentHousehold.llmAPIKey live — CloudKit keeps it in sync
        LLMSettingsService.shared.householdAPIKeyProvider = { [weak household] in
            household?.currentHousehold?.llmAPIKey
        }

        // M10.6.11: Wire household key into template and import services so new
        // templates are scoped to the current household (fixes invisible templates bug)
        templateService.householdKeyProvider = { [weak household] in
            household?.currentHouseholdKey
        }
        importSvc.householdKeyProvider = { [weak household] in
            household?.currentHouseholdKey
        }

        // M8.4: CoreML warmup — triggers lazy model loading off main thread
        // Prevents first-prediction latency spike (100-500ms JIT compilation)
        DispatchQueue.global(qos: .utility).async {
            _ = IngredientParsingService.extractCleanIngredientName(from: "warmup")
        }
    }

    var body: some Scene {
        WindowGroup {
            let scopeProvider = HouseholdScopeProvider(
                householdService: householdService,
                persistence: persistenceController
            )
            let objectFactory = ManagedObjectFactory(
                context: persistenceController.container.viewContext,
                scopeProvider: scopeProvider,
                persistence: persistenceController
            )

            Group {
                if isReady {
                    // M15.1: Liquid Glass TabView replaces CustomBottomNavigationView
                    ZStack {
                        TabView(selection: $selectedTab) {
                            Tab("Lists", systemImage: "list.bullet", value: .lists) {
                                NavigationStack {
                                    WeeklyListsView(popToRoot: $listsPopToRoot)
                                }
                            }
                            Tab("Recipes", systemImage: "book", value: .recipes) {
                                NavigationStack {
                                    RecipeListView(popToRoot: $recipesPopToRoot)
                                }
                            }
                            Tab("Meals", systemImage: "calendar", value: .mealPlans) {
                                NavigationStack {
                                    MealPlansListView(popToRoot: $mealPlansPopToRoot)
                                }
                            }
                            Tab("Settings", systemImage: "gearshape", value: .settings) {
                                NavigationStack {
                                    SettingsView()
                                }
                            }
                            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                                NavigationStack {
                                    UnifiedSearchView()
                                }
                            }
                        }
                        .tabBarMinimizeBehavior(.onScrollDown)

                        if showCoachMarks {
                            CoachMarkOverlay(
                                isActive: $showCoachMarks,
                                selectedTab: $selectedTab
                            )
                        }
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.managedObjectFactory, objectFactory)
                    .environmentObject(householdService)
                    .environmentObject(syncMonitor)
                    // M7.5: Service layer environment objects
                    .environmentObject(recipeService)
                    .environmentObject(weeklyListService)
                    .environmentObject(ingredientTemplateService)
                    .environmentObject(ingredientParsingService)
                    .environmentObject(ingredientMatchService)
                    .environmentObject(importService)
                    .task {
                        // Reload household now that stores are loaded (isReady gate
                        // ensures stores are ready before TabView renders).
                        // The init-time loadCurrentHousehold() fires before stores
                        // load, so it finds nothing — this is the real load.
                        await householdService.loadCurrentHousehold()
                        await householdService.refreshCurrentMemberDisplayName()

                        // Check for new invitations after a delay (not urgent)
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if householdService.currentHousehold == nil {
                            #if DEBUG
                            print("🔍 App launch: Checking for existing households...")
                            #endif
                            await householdService.checkForAcceptedInvitations()
                            // Refresh display name if invitation check loaded a household
                            await householdService.refreshCurrentMemberDisplayName()
                        }
                    }
                    .onAppear {
                        if !hasCompletedOnboarding {
                            showCoachMarks = true
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .replayOnboarding)) { _ in
                        hasCompletedOnboarding = false
                        showCoachMarks = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
                        #if DEBUG
                        print("📬 Received cloudKitShareAccepted notification")
                        #endif
                        Task {
                            await householdService.checkForAcceptedInvitations()
                        }
                    }
                } else {
                    AppLoadingView()
                        .onAppear {
                            persistenceController.prepare()
                        }
                }
            }
            .onReceive(persistenceController.$isReady) { ready in
                if ready {
                    withAnimation(.easeIn(duration: 0.3)) {
                        isReady = true
                    }
                }
            }
        }
    }
}

// MARK: - First-Launch Loading Screen

private struct AppLoadingView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                ProgressView()
                    .tint(.secondary)
            }
        }
    }
}

// MARK: - Button Styles (M15.1: Updated with ForagerTheme colors)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? ForagerTheme.buttonPrimaryPressed : ForagerTheme.buttonPrimaryDefault)
            .foregroundStyle(ForagerTheme.buttonPrimaryText)
            .cornerRadius(ForagerTheme.Radius.sm)
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
            .background(configuration.isPressed ? ForagerTheme.backgroundTertiary : ForagerTheme.backgroundSecondary)
            .foregroundStyle(ForagerTheme.textPrimary)
            .cornerRadius(ForagerTheme.Radius.sm)
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
            .background(configuration.isPressed ? ForagerTheme.statusDangerFG.opacity(0.8) : ForagerTheme.statusDangerFG)
            .foregroundStyle(.white)
            .cornerRadius(ForagerTheme.Radius.sm)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - AppDelegate for SceneDelegate Configuration

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
