//
//  HouseholdScopeProvider.swift
//  forager
//
//  M7.2.3 Phase 2.2: Scope-Based Store Assignment - ScopeProvider
//  Created on January 2, 2026
//
//  Provides the current data scope based on household state.
//  Automatically determines whether objects should be created in
//  Private Store (personal) or Shared Store (household).
//
//  Implementation adapted from Gemini external validation.
//

import Foundation
import CoreData

/// Provides the current data scope based on household state
///
/// ## Architecture
/// - **Input**: HouseholdService.currentHousehold (may be nil)
/// - **Output**: DataScope enum (.personal or .household)
/// - **Key Feature**: Auto-resolves which store household lives in
///
/// ## Usage
/// ```swift
/// let scopeProvider = HouseholdScopeProvider(
///     householdService: householdService,
///     context: viewContext
/// )
///
/// let scope = await scopeProvider.activeScope
/// ```
///
/// Source: Gemini - Adapted for MainActor isolation
@MainActor
final class HouseholdScopeProvider {
    
    // MARK: - Dependencies
    
    private let householdService: HouseholdService
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    /// Creates a scope provider with required dependencies
    /// - Parameters:
    ///   - householdService: Service that tracks current household
    ///   - context: Managed object context for store access
    init(householdService: HouseholdService, context: NSManagedObjectContext) {
        self.householdService = householdService
        self.context = context
    }
    
    // MARK: - Scope Resolution
    
    /// Returns the active data scope
    ///
    /// ## Decision Logic
    /// 1. **No household** → Personal scope
    /// 2. **Household exists** → Resolve which store it's in
    ///
    /// ## Key Behavior
    /// - **Before share creation**: Returns .personal (household in Private)
    /// - **After share creation**: Returns .household (household in Shared)
    /// - **Dynamic resolution**: Checks store on every access
    var activeScope: DataScope {
        // 1. Check if a household is currently active
        guard let household = householdService.currentHousehold else {
            #if DEBUG
            print("🏠 HouseholdScopeProvider: No household → Personal scope")
            #endif
            return .personal
        }
        
        // 2. Get the store directly from the ObjectID
        // NSManagedObjectID has a persistentStore property!
        guard let householdStore = household.objectID.persistentStore else {
            #if DEBUG
            print("⚠️ HouseholdScopeProvider: Could not resolve store → Personal scope (fallback)")
            #endif
            return .personal
        }
        
        // 3. Check if household is in a shared CloudKit store
        // For now, we'll determine this by checking if the store URL contains "shared"
        // This is a simplified heuristic that works for NSPersistentCloudKitContainer
        let storeURL = householdStore.url?.absoluteString.lowercased() ?? ""
        let isSharedStore = storeURL.contains("shared")
        
        if isSharedStore {
            // Household is in a CloudKit shared store
            #if DEBUG
            print("👥 HouseholdScopeProvider: Household in shared store → Household scope")
            print("   Household: \(household.name ?? "Unnamed")")
            print("   Store: \(householdStore.url?.lastPathComponent ?? "unknown")")
            #endif
            
            return .household(id: household.objectID, store: householdStore)
        } else {
            // Household is in local/private store or not yet shared
            #if DEBUG
            print("🏠 HouseholdScopeProvider: Household in private store → Personal scope")
            print("   Store: \(householdStore.url?.lastPathComponent ?? "unknown")")
            #endif
            return .personal
        }
    }
}

// MARK: - Debug Utilities

#if DEBUG
extension HouseholdScopeProvider {
    /// Logs the current scope (useful for debugging)
    func logCurrentScope(_ label: String = "Scope Check") {
        let scope = activeScope
        print("\n📍 [\(label)] Current Scope:")
        print("   \(scope)")
        print("")
    }
}
#endif
