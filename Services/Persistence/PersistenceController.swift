//
//  PersistenceController.swift
//  forager
//
//  M7.2.3 Phase 1.1: Extracted from Persistence.swift
//  M7.2.3 Phase 2.6: Added store properties and StoreID resolution
//  Single responsibility: Core Data container and store management
//
//  Created on December 30, 2025.
//

import CoreData
import CloudKit  // M7.2.2: Required for CKDatabase.Scope
import Foundation
import UIKit  // M7.2.3 Phase 4.4: Required for UIDevice

/// M7.2.3 Phase 3.6: Core Data stack initialization and configuration
/// Responsibilities: Container setup, CloudKit sync, store loading, merge policies
/// Does NOT handle: Seeding (DefaultSeeder), Migrations (old Persistence.swift), Diagnostics (CloudKitDiagnostics)
/// 
/// This is the NEW clean PersistenceController extracted from bloated Persistence.swift
final class PersistenceController {
    
    // MARK: - Singleton
    
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Sample data creation handled by DefaultSeeder (Phase 1.2)
        return controller
    }()
    
    // MARK: - Properties
    
    /// M7.1.1: CloudKit-enabled container (was NSPersistentContainer)
    let container: NSPersistentCloudKitContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - M7.2.2: Store Properties (Dual-Store Architecture)

    /// Private CloudKit store (user's personal data)
    /// M7.2.2: Identifies store by filename (forager.sqlite)
    var privateStore: NSPersistentStore {
        guard let store = container.persistentStoreCoordinator.persistentStores.first(where: {
            $0.url?.lastPathComponent == "forager.sqlite"
        }) else {
            fatalError("❌ M7.2.2: Private store not found. Expected forager.sqlite")
        }
        return store
    }

    /// Shared CloudKit store (accepted shares from other users)
    /// M7.2.2: Identifies store by filename (forager_shared.sqlite)
    /// CRITICAL: This store is what enables Device B to receive shared household data
    var sharedStore: NSPersistentStore {
        guard let store = container.persistentStoreCoordinator.persistentStores.first(where: {
            $0.url?.lastPathComponent == "forager_shared.sqlite"
        }) else {
            fatalError("❌ M7.2.2: Shared store not found. Expected forager_shared.sqlite")
        }
        return store
    }
    
    /// M7.2.3 Phase 2.6: Resolve StoreID to NSPersistentStore
    ///
    /// ## Purpose
    /// Encapsulates store resolution logic inside PersistenceController.
    /// Callers use StoreID enum instead of passing NSPersistentStore instances.
    ///
    /// ## Benefits (Gemini feedback)
    /// - Store plumbing localized to persistence layer
    /// - No NSPersistentStore instances passed through call chains
    /// - Easier to test and maintain
    ///
    /// Source: Gemini - "Better: make DataScope carry stable store identity"
    func store(for storeID: StoreID) -> NSPersistentStore {
        switch storeID {
        case .private:
            return privateStore
        case .shared:
            return sharedStore
        }
    }
    
    // MARK: - Initialization
    
    init(inMemory: Bool = false) {
        // M7.2.3 Phase 4.4: Conditional CloudKit based on build configuration
        // - Release builds: Always use CloudKit
        // - Debug builds: Use CloudKit ONLY if ENABLE_CLOUDKIT_DEBUG flag is set
        // - Benefit: Fast iteration during development, CloudKit testing when needed
        #if !DEBUG || ENABLE_CLOUDKIT_DEBUG
        container = NSPersistentCloudKitContainer(name: "forager")
        print("☁️ M7.2.3: Using NSPersistentCloudKitContainer (CloudKit ENABLED)")
        #else
        container = NSPersistentCloudKitContainer(name: "forager") as! NSPersistentCloudKitContainer
        // Note: In pure Debug mode without flag, consider using:
        // let regularContainer = NSPersistentContainer(name: "forager")
        // For now, keeping CloudKit enabled to maintain type compatibility
        print("⚡ M7.2.3: Using NSPersistentCloudKitContainer (Debug mode - consider disabling CloudKit for faster iteration)")
        #endif

        // M7.2.2: Configure dual-store architecture for CloudKit sharing
        // Research from ChatGPT & Gemini confirms this is REQUIRED for shared database sync
        configureDualStoreArchitecture(inMemory: inMemory)

        loadPersistentStores()
        configureViewContext()

        // M7.2.3 Phase 3.6: Perform setup immediately
        // DefaultSeeder now queries CloudKit directly, no observer needed!
        if !inMemory {
            performOneTimeSetup()
        }
    }
    
    // MARK: - Private Configuration

    /// M7.2.2: Configure dual-store architecture for CloudKit sharing
    /// CRITICAL FIX: NSPersistentCloudKitContainer requires separate stores for Private and Shared databases
    /// Research sources: ChatGPT & Gemini deep research (temp-chatgpt-research.md, temp-gemini-research.md)
    ///
    /// Key insight: Each store maps 1:1 to a CloudKit database scope
    /// - Private Store (.private) → owner's personal data
    /// - Shared Store (.shared) → accepted shares from others
    ///
    /// Without this, shared zones exist in CloudKit but never sync to local Core Data
    private func configureDualStoreArchitecture(inMemory: Bool) {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("❌ M7.2.2: Unable to locate Application Support directory")
        }

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        if inMemory {
            // In-memory testing: use /dev/null for both stores
            let privateDesc = createStoreDescription(url: URL(fileURLWithPath: "/dev/null"), scope: .private, inMemory: true)
            let sharedDesc = createStoreDescription(url: URL(fileURLWithPath: "/dev/null"), scope: .shared, inMemory: true)
            container.persistentStoreDescriptions = [privateDesc, sharedDesc]
            print("🧪 M7.2.2: Dual in-memory stores configured")
        } else {
            // Production: separate SQLite files for private and shared data
            let privateStoreURL = appSupportURL.appendingPathComponent("forager.sqlite")
            let sharedStoreURL = appSupportURL.appendingPathComponent("forager_shared.sqlite")

            let privateDesc = createStoreDescription(url: privateStoreURL, scope: .private, inMemory: false)
            let sharedDesc = createStoreDescription(url: sharedStoreURL, scope: .shared, inMemory: false)

            container.persistentStoreDescriptions = [privateDesc, sharedDesc]

            print("✅ M7.2.2: Dual-store architecture configured")
            print("   Private Store: \(privateStoreURL.lastPathComponent)")
            print("   Shared Store:  \(sharedStoreURL.lastPathComponent)")
        }
    }

    /// Create a persistent store description with CloudKit configuration
    func createStoreDescription(url: URL, scope: CKDatabase.Scope, inMemory: Bool) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: url)
        // Both stores use the same data model automatically

        // CloudKit container options with explicit database scope
        let containerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.richhayn.forager"
        )
        containerOptions.databaseScope = scope // CRITICAL: Explicit scope assignment
        description.cloudKitContainerOptions = containerOptions

        #if DEBUG
        // Force Development environment in Debug builds
        description.setOption("Development" as NSObject,
                            forKey: "NSPersistentStoreCloudKitEnvironment")
        if scope == .private {
            print("☁️ M7.2.2: CloudKit sync ENABLED")
            print("   Container: iCloud.com.richhayn.forager")
            print("   Environment: Development")
            print("   Device: \(UIDevice.current.name)")
            print("   iCloud Account: \(FileManager.default.ubiquityIdentityToken != nil ? "✅ Signed In" : "❌ NOT SIGNED IN")")
        }
        #else
        if scope == .private {
            print("☁️ M7.2.2: CloudKit sync enabled (Production)")
        }
        #endif

        // M7.1.3: Enable automatic lightweight migration
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        // Required for CloudKit sync
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        return description
    }
    
    /// M7.2.2: Load persistent stores with error handling
    /// Now loads BOTH private and shared stores
    private func loadPersistentStores() {
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ M7.2.2: Store loading FAILED")
                print("   Error: \(error.localizedDescription)")
                print("   Details: \(error.userInfo)")
                fatalError("❌ M7.2.2: Core Data store loading failed: \(error), \(error.userInfo)")
            }

            // Log each store as it loads
            let scope = storeDescription.cloudKitContainerOptions?.databaseScope
            let scopeName = scope == .private ? "Private" : (scope == .shared ? "Shared" : "Unknown")
            print("✅ M7.2.2: \(scopeName) store loaded")
            print("   URL: \(storeDescription.url?.lastPathComponent ?? "unknown")")
            print("   CloudKit Scope: .\(scopeName.lowercased())")
        }
    }
    
    /// M7.2.3: Configure view context with object-trump merge policy
    /// In-memory changes win over persistent store (appropriate for user edits)
    private func configureViewContext() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        print("✅ M7.2.3: View context configured with object-trump merge policy")
    }
    
    // MARK: - M7.2.2: Shared Store Lifecycle

    /// M7.2.2: Deletes all objects in the shared store from the given context.
    /// Notifies @FetchRequest observers so SwiftUI drops references before store destruction.
    /// Returns the number of objects deleted.
    @discardableResult
    func purgeAllSharedStoreObjects(from context: NSManagedObjectContext) -> Int {
        let coordinator = container.persistentStoreCoordinator
        guard let sharedStore = coordinator.persistentStores.first(where: {
            $0.url?.lastPathComponent == "forager_shared.sqlite"
        }) else { return 0 }

        var deletedCount = 0
        for entity in container.managedObjectModel.entities {
            guard let entityName = entity.name else { continue }
            let fetchReq = NSFetchRequest<NSManagedObject>(entityName: entityName)
            fetchReq.affectedStores = [sharedStore]
            if let objects = try? context.fetch(fetchReq) {
                for obj in objects {
                    context.delete(obj)
                    deletedCount += 1
                }
            }
        }

        if context.hasChanges {
            try? context.save()
        }

        return deletedCount
    }

    /// Destroys and recreates the shared SQLite store.
    /// Used during leave-household flow to deterministically remove all ghost data.
    /// More reliable than entity-by-entity purge which can miss objects.
    func destroyAndRecreateSharedStore() throws {
        let coordinator = container.persistentStoreCoordinator
        guard let store = coordinator.persistentStores.first(where: {
            $0.url?.lastPathComponent == "forager_shared.sqlite"
        }) else {
            print("ℹ️ M7.2.2: No shared store to destroy")
            return
        }

        let storeURL = store.url!
        print("🔄 M7.2.2: Destroying shared store at \(storeURL.lastPathComponent)")

        // Remove from coordinator
        try coordinator.remove(store)

        // Delete SQLite files (main + WAL + SHM)
        try coordinator.destroyPersistentStore(at: storeURL, type: .sqlite)

        // Recreate with same CloudKit configuration
        // Must use loadPersistentStores (not coordinator.addPersistentStore) so that
        // NSPersistentCloudKitContainer registers the CloudKit mirroring for this store.
        let desc = createStoreDescription(url: storeURL, scope: .shared, inMemory: false)

        // Temporarily set descriptions to only the shared store to avoid re-loading private store
        let savedDescriptions = container.persistentStoreDescriptions
        container.persistentStoreDescriptions = [desc]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            if let error = error {
                loadError = error
            }
        }

        // Restore full description list
        container.persistentStoreDescriptions = savedDescriptions
            .filter { $0.url?.lastPathComponent != "forager_shared.sqlite" } + [desc]

        if let error = loadError {
            throw error
        }

        print("✅ M7.2.2: Shared store recreated")
    }

    // MARK: - Background Context Management
    
    /// Create background context with consistent merge policy
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// Perform write operation on background context with error handling
    func performWrite(
        _ block: @escaping (NSManagedObjectContext) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                    print("✅ M7.2.3: Background context saved successfully")
                } catch {
                    print("❌ M7.2.3: Background save failed: \(error)")
                    DispatchQueue.main.async {
                        onError?(error)
                    }
                }
            }
        }
    }
    
    // MARK: - M7.2.3 Phase 3.6: One-Time Setup
    
    /// Performs one-time setup operations (seeding, migrations)
    /// M7.2.3 Phase 3.6: DefaultSeeder queries CloudKit directly for true idempotence
    /// Called immediately during initialization (no observer/timeout needed!)
    private func performOneTimeSetup() {
        container.performBackgroundTask { context in
            do {
                // M7.2.3 Phase 3.6: Use DefaultSeeder for truly idempotent category creation
                try DefaultSeeder.seedDefaultsIfNeeded(in: context)
                
                // Save if any changes were made
                if context.hasChanges {
                    try context.save()
                    print("✅ M7.2.3 Phase 3.6: One-time setup completed")
                }
            } catch {
                print("❌ M7.2.3 Phase 3.6: One-time setup failed: \(error)")
            }
        }
    }
}
