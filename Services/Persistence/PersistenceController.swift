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
    
    // MARK: - M7.2.3 Phase 2.6: Store Properties
    
    /// Private CloudKit store (user's personal data)
    /// Lazily computed from loaded persistent stores
    var privateStore: NSPersistentStore {
        // For NSPersistentCloudKitContainer with single configuration,
        // the default store is the private store
        guard let store = container.persistentStoreCoordinator.persistentStores.first else {
            fatalError("❌ M7.2.3: No persistent stores loaded")
        }
        return store
    }
    
    /// Shared CloudKit store (household collaborative data)
    /// Note: Will be properly implemented in Phase 4 (Attach-Then-Share)
    /// For now, returns the same store as private (single store configuration)
    var sharedStore: NSPersistentStore {
        // TODO M7.2.3 Phase 4: Implement proper shared store lookup
        // For now, same as private store until we implement multi-store config
        return privateStore
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
        
        if let description = container.persistentStoreDescriptions.first {
            configureStoreDescription(description, inMemory: inMemory)
        }
        loadPersistentStores()
        configureViewContext()
        
        // M7.2.3 Phase 3.6: Perform setup immediately
        // DefaultSeeder now queries CloudKit directly, no observer needed!
        if !inMemory {
            performOneTimeSetup()
        }
    }
    
    // MARK: - Private Configuration
    
    /// Configure CloudKit sync, migration, history tracking, and remote notifications
    private func configureStoreDescription(_ description: NSPersistentStoreDescription, inMemory: Bool) {
        // M7.1.1: CloudKit container configuration
        let containerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.richhayn.forager"
        )
        description.cloudKitContainerOptions = containerOptions
        
        #if DEBUG
        // Force Development environment in Debug builds for testing
        description.setOption("Development" as NSObject,
                            forKey: "NSPersistentStoreCloudKitEnvironment")
        print("☁️ M7.2.3 Phase 4.4: CloudKit sync ENABLED")
        print("   Container: iCloud.com.richhayn.forager")
        print("   Environment: Development")
        print("   Device: \(UIDevice.current.name)")
        print("   iCloud Account: \(FileManager.default.ubiquityIdentityToken != nil ? "✅ Signed In" : "❌ NOT SIGNED IN")")
        #else
        print("☁️ M7.2.3: CloudKit sync enabled (Production)")
        #endif
        
        // M7.1.3: Enable automatic lightweight migration
        description.setOption(true as NSNumber,
                            forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber,
                            forKey: NSInferMappingModelAutomaticallyOption)
        
        // Enable history tracking and remote change notifications (required for CloudKit)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, 
                            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
            print("🧪 M7.2.3: In-memory store for testing")
        }
    }
    
    /// Load persistent stores with error handling
    private func loadPersistentStores() {
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ M7.2.3 Phase 4.4: Store loading FAILED")
                print("   Error: \(error.localizedDescription)")
                print("   Details: \(error.userInfo)")
                fatalError("❌ M7.2.3: Core Data store loading failed: \(error), \(error.userInfo)")
            }
            print("✅ M7.2.3 Phase 4.4: Core Data stack loaded successfully")
            print("   Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
            print("   CloudKit: \(storeDescription.cloudKitContainerOptions != nil ? "Enabled" : "Disabled")")
        }
    }
    
    /// M7.2.3: Configure view context with object-trump merge policy
    /// In-memory changes win over persistent store (appropriate for user edits)
    private func configureViewContext() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        print("✅ M7.2.3: View context configured with object-trump merge policy")
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
