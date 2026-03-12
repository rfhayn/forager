//
//  HouseholdScopeProvider.swift
//  forager
//
//  M7.2.3 Phase 2.2 & 2.6: Scope-Based Store Assignment - ScopeProvider
//  Created on January 2, 2026
//  Updated Phase 2.6: ScopeProvider protocol conformance + scopeSnapshot
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
/// ## M7.2.3 Phase 2.6 Changes
/// - Now conforms to `ScopeProvider` protocol
/// - Implements `scopeSnapshot()` for background work (Gemini feedback)
/// - Uses `StoreID` instead of `NSPersistentStore` (Gemini feedback)
///
/// ## Usage
/// ```swift
/// let scopeProvider = HouseholdScopeProvider(
///     householdService: householdService,
///     persistence: persistence
/// )
///
/// // Main thread: use activeScope directly
/// let scope = scopeProvider.activeScope
///
/// // Background: capture snapshot first
/// let snapshot = scopeProvider.scopeSnapshot()
/// persistence.performScopedWrite(scope: snapshot) { ... }
/// ```
///
/// Source: Gemini + ChatGPT - Adapted for @MainActor isolation
@MainActor
final class HouseholdScopeProvider: ScopeProvider {
    
    // MARK: - Dependencies
    
    private let householdService: HouseholdService
    private let persistence: PersistenceController
    
    // MARK: - Initialization
    
    /// Creates a scope provider with required dependencies
    ///
    /// ## M7.2.3 Phase 2.6 Changes
    /// - Now takes `persistence` instead of `context`
    /// - Needed for StoreID → NSPersistentStore resolution
    ///
    /// Parameters:
    /// - householdService: Service that tracks current household
    /// - persistence: Persistence controller for store access
    init(householdService: HouseholdService, persistence: PersistenceController) {
        self.householdService = householdService
        self.persistence = persistence
    }
    
    // MARK: - ScopeProvider Protocol
    
    /// M7.2.3 Phase 2.6: Returns the active data scope
    ///
    /// ## Decision Logic
    /// 1. **No household** → Personal scope
    /// 2. **Household exists** → Resolve which store it's in
    ///
    /// ## Key Behavior
    /// - **Before share creation**: Returns .personal (household in Private)
    /// - **After share creation**: Returns .household (household in Shared)
    /// - **Dynamic resolution**: Checks store on every access
    ///
    /// ## M7.2.3 Phase 2.6 Changes
    /// - Returns `.household(id, storeID: .shared)` instead of passing NSPersistentStore
    /// - Store resolution now handled by PersistenceController.store(for:)
    var activeScope: DataScope {
        // 1. Check if a household is currently active
        guard let household = householdService.currentHousehold else {
            #if DEBUG
            print("🏠 HouseholdScopeProvider: No household → Personal scope")
            #endif
            return .personal
        }
        
        // M9.14: Verify household object is still valid in current context
        // After reinstall + CloudKit sync, the object may be faulted or invalidated
        guard household.managedObjectContext != nil, !household.isDeleted else {
            #if DEBUG
            print("⚠️ HouseholdScopeProvider: Household object invalid (deleted or no context) → Personal scope (fallback)")
            #endif
            return .personal
        }

        // 2. Get the store directly from the ObjectID
        guard let householdStore = household.objectID.persistentStore else {
            #if DEBUG
            print("⚠️ HouseholdScopeProvider: Could not resolve store → Personal scope (fallback)")
            #endif
            return .personal
        }
        
        // 3. Determine which StoreID based on URL heuristic
        // TODO M7.2.3 Phase 4: Improve store detection when multi-store config is implemented
        let storeURL = householdStore.url?.absoluteString.lowercased() ?? ""
        let isSharedStore = storeURL.contains("shared")
        
        if isSharedStore {
            // Household is in a CloudKit shared store
            #if DEBUG
            print("👥 HouseholdScopeProvider: Household in shared store → Household scope")
            print("   Household: \(household.name ?? "Unnamed")")
            print("   StoreID: .shared")
            #endif
            
            return .household(id: household.objectID, storeID: .shared)
        } else {
            // Household is in local/private store or not yet shared
            // Still return personal scope until share is created
            #if DEBUG
            print("🏠 HouseholdScopeProvider: Household in private store → Personal scope")
            print("   Household: \(household.name ?? "Unnamed")")
            print("   StoreID: .private")
            #endif
            return .personal
        }
    }
    
    /// M7.2.3 Phase 2.6: Capture immutable scope snapshot for background work
    ///
    /// ## Purpose (Gemini Best Practice)
    /// When enqueuing background work, capture scope on main thread:
    /// ```swift
    /// // ✅ Main thread
    /// let snapshot = scopeProvider.scopeSnapshot()
    ///
    /// // ✅ Background thread - uses scope from enqueue time
    /// persistence.performScopedWrite(scope: snapshot) { context, factory in
    ///     // ...
    /// }
    /// ```
    ///
    /// ## Benefits
    /// - No cross-actor calls from background → main
    /// - Deterministic behavior (scope at enqueue time, not execution time)
    /// - Fewer parameters through call chains
    /// - Immutable snapshot safe to pass anywhere
    ///
    /// ## Returns
    /// Immutable DataScope value captured at call time
    ///
    /// Source: Gemini - "snapshot scope on main before hopping"
    func scopeSnapshot() -> DataScope {
        return activeScope  // DataScope is a value type, safe to return
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
        
        if case .household(let id, _) = scope {
            if let household = try? persistence.container.viewContext.existingObject(with: id) as? Household {
                print("   Household Name: \(household.name ?? "Unnamed")")
                print("   Household ID: \(household.id?.uuidString ?? "nil")")
            }
        }
        
        print("")
    }
}
#endif
