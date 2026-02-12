// foragerApp.swift
// Updated with Settings Tab - M3 Phase 3
// Updated with Meal Planning Tab - M4.2
// CORRECTED: Tap-to-Pop-to-Root with NavigationStack and path arrays
// M7.2.2 Task 3: CloudKit share invitation handling
// M7.2.3 Phase 2.4: ManagedObjectFactory environment injection

import SwiftUI
import CloudKit
import Combine

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

    // M7.6.3: Coach mark onboarding
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showCoachMarks = false
    @State private var selectedTab: NavigationTab = .lists

    // M7.6.3: First-launch loading screen — bridged from PersistenceController.$isReady
    @State private var isReady = false

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
            
            // M7.6.3: Show loading splash until one-time setup completes,
            // then transition to main content
            Group {
                if isReady {
                    // M7.4: Custom Apple Music-style bottom navigation
                    CustomBottomNavigationView(selectedTab: $selectedTab, showCoachMarks: $showCoachMarks)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.managedObjectFactory, objectFactory) // M7.2.3 Phase 2.4: Inject factory
                    .environmentObject(householdService) // M7.2.3 Phase 2.4: Make household service available
                    .environmentObject(syncMonitor) // M7.1.2: Make sync monitor available to all views
                    // M7.2.2: Check for existing households on app launch (new device scenario)
                    .task {
                        // Give CloudKit a moment to sync on first launch
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

                        // Check if user already has a household (e.g., new device, reinstall)
                        if householdService.currentHousehold == nil {
                            #if DEBUG
                            print("🔍 App launch: Checking for existing households...")
                            #endif
                            await householdService.checkForAcceptedInvitations()
                        }

                        // Refresh display name on every launch
                        // Handles: iCloud name changes, device name changes
                        await householdService.refreshCurrentMemberDisplayName()
                    }
                    // M7.6.3: Show coach mark onboarding after splash dismisses
                    .onAppear {
                        if !hasCompletedOnboarding {
                            showCoachMarks = true
                        }
                    }
                    // M7.6.3: Listen for replay onboarding from Settings
                    .onReceive(NotificationCenter.default.publisher(for: .replayOnboarding)) { _ in
                        hasCompletedOnboarding = false
                        showCoachMarks = true
                    }
                    // M7.2.2 FIX: Listen for CloudKit share acceptance from SceneDelegate
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
            // M7.6.3: Bridge PersistenceController's @Published isReady to local @State
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

// MARK: - M7.6.3: First-Launch Loading Screen

/// Branded splash shown while one-time setup (seeding, migrations) completes.
/// Matches the storyboard launch screen aesthetic using the same named color and icon assets.
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
