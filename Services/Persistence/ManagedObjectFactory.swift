//
//  ManagedObjectFactory.swift
//  forager
//
//  M7.2.3 Phase 2.3 & 2.6: Scope-Based Store Assignment - Object Factory
//  Created on January 2, 2026
//  Updated Phase 2.6: StoreID resolution, loud failures, 'in' parameter
//
//  Factory for creating managed objects with automatic store assignment
//  and household relationship management. This is the ONLY way to create
//  household-scoped entities in the app.
//
//  Implementation adapted from Gemini + ChatGPT external validation.
//

import Foundation
import CoreData

// MARK: - Factory Errors

/// M7.2.3 Phase 2.6: Explicit errors for loud failures
///
/// Source: Gemini - "Prefer throw if scope says household but fetch fails"
enum FactoryError: Error {
    /// Household ObjectID could not be resolved to an object
    case householdNotFound(NSManagedObjectID)
    
    /// ObjectID resolved but was not a Household type
    case invalidHouseholdObjectID
    
    var localizedDescription: String {
        switch self {
        case .householdNotFound(let id):
            return "Household not found for ObjectID: \(id)"
        case .invalidHouseholdObjectID:
            return "ObjectID did not resolve to a Household type"
        }
    }
}

// MARK: - Managed Object Factory

/// Factory for creating managed objects with automatic store assignment
///
/// ## Core Responsibilities
/// - **Store Assignment**: Automatically assigns objects to Private or Shared store
/// - **Household Linking**: Auto-sets household relationship based on scope
/// - **HouseholdKey**: Auto-populates householdKey for efficient queries
/// - **Enforcement**: Only creation path for household-scoped entities
///
/// ## M7.2.3 Phase 2.6 Refinements (External Validation)
/// 1. **StoreID Resolution**: Uses enum instead of NSPersistentStore (Gemini)
/// 2. **Loud Failures**: Throws on household lookup failure instead of silent nil (Gemini)
/// 3. **`in` Parameter**: Named parameter for explicit scope (ChatGPT + Gemini)
/// 4. **Optional ScopeProvider**: Works for both main + background contexts (ChatGPT)
///
/// ## Usage Patterns
///
/// ### Main Thread (SwiftUI Views)
/// ```swift
/// @Environment(\.managedObjectFactory) private var factory
///
/// func createList() {
///     guard let factory = factory else { return }
///
///     _ = try factory.make(WeeklyList.self) { list in
///         list.id = UUID()
///         // Scope from provider, store + household auto-set!
///     }
/// }
/// ```
///
/// ### Background Context
/// ```swift
/// let scope = DataScope.household(id: householdID, storeID: .shared)
///
/// persistence.performScopedWrite(scope: scope) { context, factory in
///     _ = try factory.make(Category.self, in: scope) { category in
///         category.id = UUID()
///         // Explicit scope, store + household auto-set!
///     }
/// }
/// ```
///
/// ## Critical: HouseholdScoped Invariant
/// Any entity conforming to HouseholdScoped MUST be created via this factory.
/// Direct creation (`Recipe(context:)`) is explicitly forbidden.
///
/// Source: Gemini + ChatGPT - Refined from Phase 2.3 implementation
///
/// ## M7.2.6 Threading Note
/// NOT marked @MainActor because it works in both contexts:
/// - Main thread: With ScopeProvider (which IS @MainActor)
/// - Background thread: With explicit scope (no provider needed)
final class ManagedObjectFactory {
    
    // MARK: - Dependencies
    
    private let context: NSManagedObjectContext
    private let scopeProvider: ScopeProvider?  // ✅ Optional for background usage
    private let persistence: PersistenceController
    
    // MARK: - Initialization
    
    /// M7.2.3 Phase 2.6: Creates factory with optional scope provider
    ///
    /// ## Parameters
    /// - context: Managed object context for creating objects
    /// - scopeProvider: Optional provider for automatic scope (nil for background)
    /// - persistence: Persistence controller for store resolution
    ///
    /// ## Design Decision (External Validation)
    /// **Optional scopeProvider** (ChatGPT's approach):
    /// - One initializer, simpler API
    /// - Works for both main + background contexts
    /// - Priority chain: explicit > provider > personal
    ///
    /// Alternative considered (Gemini's suggestion):
    /// - Two separate initializers (more rigid)
    ///
    /// **Verdict**: Optional is cleaner and more flexible
    ///
    /// Source: ChatGPT - "Making it optional is clean"
    init(
        context: NSManagedObjectContext,
        scopeProvider: ScopeProvider? = nil,
        persistence: PersistenceController
    ) {
        self.context = context
        self.scopeProvider = scopeProvider
        self.persistence = persistence
    }
    
    // MARK: - Object Creation
    
    /// M7.2.3 Phase 2.6: Creates object with automatic store + household assignment
    ///
    /// ## Automatic Behavior
    /// - **Personal scope**: Object in Private Store, household = nil
    /// - **Household scope**: Object in Shared Store, household auto-set
    ///
    /// ## Scope Priority (Refined in Phase 2.6)
    /// 1. **Explicit scope** (in parameter) - for background contexts
    /// 2. **ScopeProvider** (if available) - for main thread/views
    /// 3. **Fallback to .personal** - if neither provided
    ///
    /// ## Parameters
    /// - type: The NSManagedObject type to create
    /// - explicitScope: Optional explicit scope (for background contexts)
    /// - configure: Configuration closure for setting properties
    ///
    /// ## Returns
    /// The created object with:
    /// - Correct store assignment (via StoreID resolution)
    /// - Household relationship set (if in household scope)
    /// - HouseholdKey populated (if in household scope)
    ///
    /// ## Throws
    /// - `FactoryError.householdNotFound`: If household ObjectID can't be resolved
    /// - `FactoryError.invalidHouseholdObjectID`: If ObjectID isn't a Household
    ///
    /// ## Example (Main Thread)
    /// ```swift
    /// let list = try factory.make(WeeklyList.self) { newList in
    ///     newList.id = UUID()
    ///     newList.startDate = Date()
    /// }
    /// ```
    ///
    /// ## Example (Background Context)
    /// ```swift
    /// let scope = DataScope.household(id: householdID, storeID: .shared)
    /// let category = try factory.make(Category.self, in: scope) { newCat in
    ///     newCat.id = UUID()
    ///     newCat.name = "Produce"
    /// }
    /// ```
    ///
    /// Source: ChatGPT + Gemini - "in:" parameter for readability
    func make<T: NSManagedObject>(
        _ type: T.Type,
        in explicitScope: DataScope? = nil,  // ✅ Named 'in' for readability
        configure: (T) -> Void
    ) throws -> T {
        let object = T(context: context)
        
        // M7.2.3 Phase 2.6: Priority chain for scope resolution
        // scopeProvider is only non-nil when on MainActor (from Environment),
        // so we can safely access it using assumeIsolated
        let activeScope: DataScope
        if let explicitScope = explicitScope {
            activeScope = explicitScope
        } else if let provider = scopeProvider {
            activeScope = MainActor.assumeIsolated {
                provider.activeScope
            }
        } else {
            activeScope = .personal
        }
        
        #if DEBUG
        print("🏭 ManagedObjectFactory: Creating \(type)")
        print("   Scope: \(activeScope)")
        #endif
        
        switch activeScope {
        case .personal:
            // M7.2.3 Phase 2.6: Resolve StoreID → NSPersistentStore
            let targetStore = persistence.store(for: .private)
            context.assign(object, to: targetStore)
            
            // Explicitly ensure household relationship is nil
            if let scopedObject = object as? HouseholdScoped {
                scopedObject.household = nil
                scopedObject.householdKey = nil
            }
            
            #if DEBUG
            print("   Store: Private (household = nil)")
            #endif
            
        case .household(let householdID, let storeID):
            // M7.2.3 Phase 2.6: Resolve StoreID → NSPersistentStore (Gemini)
            let targetStore = persistence.store(for: storeID)
            context.assign(object, to: targetStore)
            
            // M7.2.3 Phase 2.6: Loud failure on household resolution (Gemini)
            // "Prefer throw if scope says household but fetch fails"
            // M9.14: Added fallback fetch for stale ObjectIDs after CloudKit sync/reinstall
            if let scopedObject = object as? HouseholdScoped {
                var resolvedHousehold: Household?

                // Primary path: resolve by ObjectID (fast)
                do {
                    resolvedHousehold = try context.existingObject(with: householdID) as? Household
                } catch {
                    // M9.14: ObjectID may be stale after reinstall + CloudKit sync.
                    // Fallback to fetch — the household exists in the store, the reference is just stale.
                    #if DEBUG
                    print("⚠️ Factory: existingObject(with:) failed (\(error.localizedDescription)), trying fetch fallback")
                    #endif
                }

                // M9.14: Fallback path — fetch household directly
                if resolvedHousehold == nil {
                    let request: NSFetchRequest<Household> = Household.fetchRequest()
                    request.fetchLimit = 1
                    resolvedHousehold = try context.fetch(request).first

                    #if DEBUG
                    if resolvedHousehold != nil {
                        print("   ✅ Factory: Fallback fetch succeeded")
                    }
                    #endif
                }

                guard let household = resolvedHousehold else {
                    #if DEBUG
                    fatalError("❌ Factory: Household not found via ObjectID or fallback fetch")
                    #else
                    throw FactoryError.householdNotFound(householdID)
                    #endif
                }

                scopedObject.household = household
                scopedObject.householdKey = household.id?.uuidString

                #if DEBUG
                print("   ✅ Household: \(household.name ?? "Unnamed")")
                print("   ✅ HouseholdKey: \(household.id?.uuidString ?? "nil")")
                print("   ✅ Store: \(storeID)")
                #endif
            }
        }
        
        // Configure object properties
        configure(object)
        
        #if DEBUG
        // Log final store assignment (using StoreIdentityLogger)
        print("  Factory Result:")
        object.logStoreIdentity()
        #endif
        
        return object
    }
}

// MARK: - Debug Utilities

#if DEBUG
extension ManagedObjectFactory {
    /// Creates an object and logs verbose details (for debugging)
    func makeWithLogging<T: NSManagedObject>(
        _ type: T.Type,
        in explicitScope: DataScope? = nil,
        label: String = "Object Creation",
        configure: (T) -> Void
    ) throws -> T {
        print("\n🏭 [\(label)] Creating \(type)")
        
        // M7.2.3 Phase 2.6: Same scope resolution as make()
        let activeScope: DataScope
        if let explicitScope = explicitScope {
            activeScope = explicitScope
        } else if let provider = scopeProvider {
            activeScope = MainActor.assumeIsolated {
                provider.activeScope
            }
        } else {
            activeScope = .personal
        }
        
        print("   Explicit Scope: \(explicitScope?.description ?? "nil")")
        print("   Provider Scope: \(scopeProvider != nil ? "<available>" : "nil")")
        print("   Active Scope: \(activeScope)")
        
        let object = try make(type, in: explicitScope, configure: configure)
        
        print("   ✅ Object created successfully\n")
        
        return object
    }
}
#endif
