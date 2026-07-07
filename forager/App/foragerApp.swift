// foragerApp.swift
// FUI-1.1: 4-tab navigation (Home, Lists, Recipes, Meals)
// M7.2.2 Task 3: CloudKit share invitation handling
// M7.2.3 Phase 2.4: ManagedObjectFactory environment injection

import SwiftUI
import CloudKit
import Combine

// MARK: - FUI-1.1: Navigation Tab Enum (4 tabs — Home replaces Search+Settings)

enum NavigationTab: String, CaseIterable {
    case home
    case lists
    case recipes
    case mealPlans

    var title: String {
        switch self {
        case .home: return "Home"
        case .lists: return "Lists"
        case .recipes: return "Recipes"
        case .mealPlans: return "Meals"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .lists: return "checklist"
        case .recipes: return "book"
        case .mealPlans: return "fork.knife"
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

    // M9.16: Unified grocery list item creation service
    @StateObject private var groceryListItemService: GroceryListItemService

    // M10.6.8: Shared ingredient matching service
    @StateObject private var ingredientMatchService: IngredientMatchService

    // M18.1.3: Store service for store-aware shopping
    @StateObject private var storeService: StoreService

    // architecture-compliance-sweep: Category service for user-facing custom-category creation
    @StateObject private var categoryService: CategoryService

    // M10.1: Import service at app level for browser and URL import
    @StateObject private var importService: RecipeImportService

    // M9.13: Factory + scope provider stored at app level for service injection (ADR 014)
    private let scopeProvider: HouseholdScopeProvider
    private let objectFactory: ManagedObjectFactory

    // M9.27: Onboarding — welcome carousel for first launch, coach marks for replay
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showWelcome = false
    @State private var showCoachMarks = false
    @State private var selectedTab: NavigationTab = .home
    @State private var showSearch = false

    // First-launch loading screen
    @State private var isReady = false

    // TODO (M7.5): Remove — native TabView handles pop-to-root
    @State private var listsPopToRoot = false
    @State private var recipesPopToRoot = false
    @State private var mealPlansPopToRoot = false

    /// reskin-provisions-press: apply the Provisions Press display voice to
    /// UIKit-managed navigation titles (SwiftUI's .navigationTitle renders
    /// through UINavigationBar, which ForagerTheme fonts can't reach).
    /// Only typography is set — backgrounds/tints stay untouched so the
    /// Liquid Glass chrome keeps its adaptive material.
    private static func configureNavigationBarTypography() {
        func condensedHeavy(size: CGFloat) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: .heavy)
            let descriptor = base.fontDescriptor.withDesign(.default)?
                .addingAttributes([.traits: [
                    UIFontDescriptor.TraitKey.width: NSNumber(value: 0.2)
                ]]) ?? base.fontDescriptor
            return UIFont(descriptor: descriptor.withSymbolicTraits(.traitCondensed) ?? descriptor, size: size)
        }

        let navBar = UINavigationBar.appearance()
        navBar.largeTitleTextAttributes = [.font: condensedHeavy(size: 34)]
        navBar.titleTextAttributes = [.font: condensedHeavy(size: 17)]

        // iOS 26 glass bars ignore the legacy proxy for INLINE titles (large
        // titles still honor it) — route the same fonts through
        // UINavigationBarAppearance. configureWithTransparentBackground()
        // sets no background of its own, so the Liquid Glass material stays.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        // 20pt: inline titles read as a proper crate-label stamp next to
        // the back capsule (17 felt undersized once pushed screens went inline)
        appearance.titleTextAttributes = [.font: condensedHeavy(size: 20)]
        appearance.largeTitleTextAttributes = [.font: condensedHeavy(size: 34)]
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
    }

    init() {
        // reskin-provisions-press: crate-label navigation titles — heavy
        // condensed system font for large titles and inline bar titles.
        // Colors stay dynamic (nav bars remain Liquid Glass; only type changes).
        Self.configureNavigationBarTypography()

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
        let groceryItemSvc = GroceryListItemService(context: context, templateService: templateService, parsingService: parsingService)
        _groceryListItemService = StateObject(wrappedValue: groceryItemSvc)
        _recipeService = StateObject(wrappedValue: recipe)
        _weeklyListService = StateObject(wrappedValue: weeklyList)

        // M18.1.3: Store service for store-aware shopping
        let storeSvc = StoreService(context: context)
        _storeService = StateObject(wrappedValue: storeSvc)

        // architecture-compliance-sweep: Category service for user-facing custom-category creation
        let categorySvc = CategoryService(context: context, householdService: household)
        _categoryService = StateObject(wrappedValue: categorySvc)

        // M10.1: Import service for browser and URL import
        let importSvc = RecipeImportService(context: context, parsingService: parsingService)
        _importService = StateObject(wrappedValue: importSvc)

        // M10.6.11: Wire household key into template and import services so new
        // templates are scoped to the current household (fixes invisible templates bug)
        templateService.householdKeyProvider = { [weak household] in
            household?.currentHouseholdKey
        }
        importSvc.householdKeyProvider = { [weak household] in
            household?.currentHouseholdKey
        }

        // M10.6.18: Wire household key into MealPlanService singleton (ADR 013)
        MealPlanService.shared.householdKeyProvider = { [weak household] in
            household?.currentHouseholdKey
        }

        // fix-meal-plan-household-observer (2026-04-30): supersedes the prior eager
        // `loadActiveMealPlan()` call (fix-dashboard-meal-plan-cold-start, 2026-04-19),
        // which still raced HouseholdService's async load. Subscribing to
        // `$currentHousehold` fires immediately with the current value AND again when
        // the async load resolves, so Dashboard meal-plan cards populate as soon as
        // the household is known instead of staying blank until the Meals tab is opened.
        MealPlanService.shared.observeHousehold(household)

        // M9.13: Create scope provider + factory, inject into services (ADR 014)
        let sp = HouseholdScopeProvider(
            householdService: household,
            persistence: PersistenceController.shared
        )
        let factory = ManagedObjectFactory(
            context: context,
            scopeProvider: sp,
            persistence: PersistenceController.shared
        )
        self.scopeProvider = sp
        self.objectFactory = factory

        // Inject factory into all services that create HouseholdScoped entities
        recipe.configure(factory: factory)
        weeklyList.configure(factory: factory)
        templateService.configure(factory: factory)
        storeSvc.configure(factory: factory)
        categorySvc.configure(factory: factory)
        storeSvc.householdKeyProvider = { [weak household] in
            household?.currentHouseholdKey
        }
        MealPlanService.shared.configure(factory: factory)
        MealPlanService.shared.configure(groceryListItemService: groceryItemSvc)

        // M9.24: Wire scope provider so import assigns to correct store
        // (shared store on member devices, private store on owner/personal)
        importSvc.scopeProvider = sp

        // M8.4: CoreML warmup — triggers lazy model loading off main thread
        // Prevents first-prediction latency spike (100-500ms JIT compilation)
        DispatchQueue.global(qos: .utility).async {
            _ = IngredientParsingService.extractCleanIngredientName(from: "warmup")
        }
    }

    var body: some Scene {
        WindowGroup {
            // reskin-provisions-press: global tomato tint — SwiftUI Toggles
            // (and other controls) don't follow the AccentColor asset on
            // their own; root-level .tint makes switches/controls tomato.
            Group {
                if isReady {
                    // M15.1: Liquid Glass TabView replaces CustomBottomNavigationView
                    ZStack {
                        TabView(selection: $selectedTab) {
                            Tab("Home", systemImage: "house", value: .home) {
                                NavigationStack {
                                    DashboardView(selectedTab: $selectedTab)
                                        .searchButton(showSearch: $showSearch)
                                }
                            }
                            Tab("Lists", systemImage: "checklist", value: .lists) {
                                NavigationStack {
                                    WeeklyListsView(popToRoot: $listsPopToRoot)
                                        .searchButton(showSearch: $showSearch)
                                }
                            }
                            Tab("Meals", systemImage: "fork.knife", value: .mealPlans) {
                                NavigationStack {
                                    MealPlansListView(popToRoot: $mealPlansPopToRoot)
                                        .searchButton(showSearch: $showSearch)
                                }
                            }
                            Tab("Recipes", systemImage: "book", value: .recipes) {
                                NavigationStack {
                                    RecipeListView(popToRoot: $recipesPopToRoot)
                                        .searchButton(showSearch: $showSearch)
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
                    .environmentObject(groceryListItemService)
                    .environmentObject(importService)
                    .environmentObject(storeService)
                    .environmentObject(categoryService)
                    .task {
                        // Fire household loading off the main actor so the TabView
                        // renders immediately with empty state. CKShare network calls
                        // inside loadCurrentHousehold() are @MainActor but can block
                        // for 10-20s on fresh install — detaching lets the UI appear
                        // while those calls resolve in the background.
                        Task.detached {
                            // Reload household now that stores are loaded (isReady gate
                            // ensures stores are ready before TabView renders).
                            // The init-time loadCurrentHousehold() fires before stores
                            // load, so it finds nothing — this is the real load.
                            await householdService.loadCurrentHousehold()
                            // M10.6.19: Clear zone corruption from ghost awakeFromInsert so
                            // CloudKit mirroring delegate can initialize and sync personal data.
                            await householdService.repairZoneCorruptionIfNeeded()
                            await householdService.refreshCurrentMemberDisplayName()

                            // M9.15.3: If no household found, start background discovery.
                            // Handles reinstall scenario where CloudKit hasn't synced yet.
                            // Non-blocking — app is fully usable while this runs.
                            let hasHousehold = await MainActor.run { householdService.currentHousehold != nil }
                            if !hasHousehold {
                                await householdService.discoverExistingHousehold()
                            }
                        }
                    }
                    .onAppear {
                        // M9.27: Show welcome carousel on first launch
                        if !hasCompletedOnboarding {
                            showWelcome = true
                        }
                    }
                    .fullScreenCover(isPresented: $showWelcome) {
                        WelcomeWalkthroughView()
                    }
                    .fullScreenCover(isPresented: $showSearch) {
                        NavigationStack {
                            UnifiedSearchView()
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Done") { showSearch = false }
                                            .keyboardShortcut(.cancelAction)
                                    }
                                }
                        }
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(householdService)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .replayOnboarding)) { _ in
                        // M9.27: Replay shows the welcome carousel
                        showWelcome = true
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
            .tint(ForagerTheme.accentPrimary)
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
