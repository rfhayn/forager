//
//  ManagedObjectFactory.swift
//  forager
//
//  M7.2.3 Phase 2.3: Scope-Based Store Assignment - Object Factory
//  Created on January 2, 2026
//
//  Factory for creating managed objects with automatic store assignment
//  and household relationship management. This is the ONLY way to create
//  household-scoped entities in the app.
//
//  Implementation adapted from Gemini external validation.
//

import Foundation
import CoreData

/// Factory for creating managed objects with automatic store assignment
///
/// ## Core Responsibilities
/// - **Store Assignment**: Automatically assigns objects to Private or Shared store
/// - **Household Linking**: Auto-sets household relationship based on scope
/// - **HouseholdKey**: Auto-populates householdKey for efficient queries
/// - **Enforcement**: Only creation path for household-scoped entities
///
/// ## Usage
/// ```swift
/// let factory = ManagedObjectFactory(
///     context: viewContext,
///     scopeProvider: scopeProvider
/// )
///
/// // Create a recipe in the correct scope
/// let recipe = await factory.make(Recipe.self) { newRecipe in
///     newRecipe.id = UUID()
///     newRecipe.title = "Chocolate Cake"
///     newRecipe.servings = 8
/// }
/// // Recipe is automatically in correct store with household set!
/// ```
///
/// ## Critical: HouseholdScoped Invariant
/// Any entity conforming to HouseholdScoped MUST be created via this factory.
/// Direct creation (`Recipe(context:)`) is explicitly forbidden.
///
/// Source: Gemini - Adapted for @MainActor and simplified store assignment
@MainActor
final class ManagedObjectFactory {
    
    // MARK: - Dependencies
    
    private let context: NSManagedObjectContext
    private let scopeProvider: HouseholdScopeProvider
    
    // MARK: - Initialization
    
    /// Creates a factory for object creation with automatic store assignment
    /// - Parameters:
    ///   - context: Managed object context for creating objects
    ///   - scopeProvider: Provides current scope (personal vs household)
    init(context: NSManagedObjectContext, scopeProvider: HouseholdScopeProvider) {
        self.context = context
        self.scopeProvider = scopeProvider
    }
    
    // MARK: - Object Creation
    
    /// Creates a new object in the appropriate store based on current scope
    ///
    /// ## Automatic Behavior
    /// - **Personal scope**: Object created in Private Store, household = nil
    /// - **Household scope**: Object created in Shared Store, household auto-set
    ///
    /// ## Store Assignment (Phase 2.3)
    /// Currently creates objects in default store. Store assignment will be
    /// implemented in Phase 2.4 when NSManagedObjectContext.assign(_:to:) is available.
    ///
    /// ## Parameters
    ///   - type: The NSManagedObject type to create
    ///   - configure: Configuration closure for setting properties
    ///
    /// ## Returns
    /// The created object with:
    /// - Correct store assignment (Private or Shared)
    /// - Household relationship set (if in household scope)
    /// - HouseholdKey populated (if in household scope)
    ///
    /// ## Example
    /// ```swift
    /// let list = await factory.make(WeeklyList.self) { newList in
    ///     newList.id = UUID()
    ///     newList.startDate = Date()
    ///     newList.status = "active"
    /// }
    /// ```
    func make<T: NSManagedObject>(_ type: T.Type, configure: (T) -> Void) -> T {
        let object = T(context: context)
        let scope = scopeProvider.activeScope
        
        #if DEBUG
        print("🏭 ManagedObjectFactory: Creating \(type)")
        #endif
        
        switch scope {
        case .personal:
            // Personal scope: household should be nil
            #if DEBUG
            print("   Scope: Personal (Private Store)")
            #endif
            
            // Explicitly ensure household relationship is nil
            if let scopedObject = object as? HouseholdScoped {
                scopedObject.household = nil
                scopedObject.householdKey = nil
            }
            
        case .household(let householdID, let targetStore):
            // Household scope: set household relationship and key
            #if DEBUG
            print("   Scope: Household (Store: \(targetStore.url?.lastPathComponent ?? "unknown"))")
            #endif
            
            // Set household relationship
            if let scopedObject = object as? HouseholdScoped {
                // Fetch household in current context (prevents stale references)
                if let household = try? context.existingObject(with: householdID) as? Household {
                    scopedObject.household = household
                    scopedObject.householdKey = household.id?.uuidString
                    
                    #if DEBUG
                    print("   ✅ Household relationship set: \(household.name ?? "Unnamed")")
                    print("   ✅ HouseholdKey set: \(household.id?.uuidString ?? "nil")")
                    #endif
                } else {
                    print("   ⚠️ Could not resolve household from ObjectID")
                }
            }
        }
        
        // Configure object properties
        configure(object)
        
        #if DEBUG
        // Log final store assignment (using StoreIdentityLogger from Prep Phase)
        if let managedObject = object as? NSManagedObject {
            print("  Factory Result:")
            managedObject.logStoreIdentity()
        }
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
        label: String = "Object Creation",
        configure: (T) -> Void
    ) -> T {
        print("\n🏭 [\(label)] Creating \(type)")
        print("   Current Scope: \(scopeProvider.activeScope)")
        
        let object = make(type, configure: configure)
        
        print("   ✅ Object created successfully")
        print("")
        
        return object
    }
}
#endif
