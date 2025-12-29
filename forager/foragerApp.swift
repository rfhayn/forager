// foragerApp.swift
// Updated with Settings Tab - M3 Phase 3
// Updated with Meal Planning Tab - M4.2
// CORRECTED: Tap-to-Pop-to-Root with NavigationStack and path arrays
// M7.2.2 Task 3: CloudKit share invitation handling

import SwiftUI
import CloudKit

// CloudKit share metadata key for user activity
private let CKShareMetadataKey = "CKShareMetadataKey"

@main
struct foragerApp: App {
    let persistenceController = PersistenceController.shared
    
    // M7.1.2: CloudKit sync monitoring - observing shared instance from PersistenceController
    // Using @ObservedObject since PersistenceController owns the instance
    @StateObject private var syncMonitor = CloudKitSyncMonitor()
    
    // M7.2.2 Task 3: CloudKit share invitation handling
    @State private var pendingShareMetadata: CKShare.Metadata?
    @State private var showAcceptInvitationSheet = false
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
    
    // M7.2.2 Task 3: Initialize HouseholdService
    init() {
        let service = HouseholdService(context: PersistenceController.shared.container.viewContext)
        _householdService = StateObject(wrappedValue: service)
    }

    var body: some Scene {
        WindowGroup {
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
                // M7.2.1: Pass context for HouseholdService
                SettingsView(context: persistenceController.container.viewContext)
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
            .environmentObject(syncMonitor) // M7.1.2: Make sync monitor available to all views
            // M7.2.2 Task 3: Handle CloudKit share invitations
            .onContinueUserActivity("com.apple.CloudKit.ShareInvitation") { userActivity in
                handleCloudKitShare(userActivity)
            }
            .sheet(isPresented: $showAcceptInvitationSheet) {
                if let metadata = pendingShareMetadata {
                    AcceptInvitationSheet(service: householdService, share: metadata)
                }
            }
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
    
    // MARK: - M7.2.2 Task 3: CloudKit Share Handling
    
    /// Handles incoming CloudKit share invitation
    /// Called when user taps invitation link from Messages, Mail, etc.
    private func handleCloudKitShare(_ userActivity: NSUserActivity) {
        // Extract CKShareMetadata from userInfo
        guard let metadataData = userActivity.userInfo?[CKShareMetadataKey] as? Data else {
            print("❌ No share metadata found in user activity")
            return
        }
        
        // Unarchive the metadata
        guard let shareMetadata = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: CKShare.Metadata.self,
            from: metadataData
        ) else {
            print("❌ Failed to unarchive share metadata")
            return
        }
        
        print("✅ Received CloudKit share invitation")
        print("   Root record: \(shareMetadata.rootRecordID.recordName)")
        
        // Store metadata and present acceptance sheet
        pendingShareMetadata = shareMetadata
        showAcceptInvitationSheet = true
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
