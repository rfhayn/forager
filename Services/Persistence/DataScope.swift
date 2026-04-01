//
//  DataScope.swift
//  forager
//
//  M7.2.3 Phase 2.1 & 2.6: Scope-Based Store Assignment Foundation
//  Created on January 2, 2026
//  Updated Phase 2.6: Added StoreID abstraction (Gemini feedback)
//
//  Defines the ownership scope for data in the app and protocol for
//  household-scoped entities. Implementation from Gemini external validation.
//

import Foundation
import CoreData

// MARK: - Store Identifier

/// M7.2.3 Phase 2.6: Store identity abstraction
///
/// ## Purpose
/// Identifies which persistent store to use WITHOUT passing NSPersistentStore
/// instances through call chains (which is a leaky abstraction).
///
/// ## Benefits (Gemini feedback)
/// - Store resolution encapsulated in PersistenceController
/// - Easier to test (simple enum vs Core Data objects)
/// - Prevents wrong-coordinator issues
/// - Cleaner API surface
///
/// Source: Gemini - "don't pass NSPersistentStore through call chains"
enum StoreID {
    /// Private CloudKit zone (user's personal data)
    case `private`
    
    /// Shared CloudKit zone (household collaborative data)
    case shared
}

// MARK: - Data Scope Enum

/// Represents the ownership scope for data in the app
///
/// ## Design Principles
/// - **One Active Scope**: App operates in one scope at a time (personal OR household)
/// - **ObjectID-based**: Uses NSManagedObjectID to prevent stale household references
/// - **Store-aware**: Tracks which persistent store the household lives in via StoreID
///
/// ## M7.2.3 Phase 2.6 Changes
/// - **v1**: `case household(id: NSManagedObjectID, store: NSPersistentStore)`
/// - **v2**: `case household(id: NSManagedObjectID, storeID: StoreID)` ← Cleaner!
///
/// ## Usage
/// ```swift
/// let scope = scopeProvider.activeScope
/// switch scope {
/// case .personal:
///     // Create in private store, household = nil
/// case .household(let id, let storeID):
///     // Create in shared store, auto-set household relationship
///     let targetStore = persistence.store(for: storeID)
/// }
/// ```
enum DataScope {
    /// Data belongs to the current user only (Private Store)
    ///
    /// Objects created in this scope:
    /// - Live in Private CloudKit zone
    /// - Are NOT visible to household members
    /// - Have `household = nil`
    case personal
    
    /// Data belongs to a household (Shared Store)
    ///
    /// - Parameters:
    ///   - id: NSManagedObjectID of the Household (prevents stale references)
    ///   - storeID: Which store the household lives in (.private or .shared)
    ///
    /// ## Critical: ObjectID Stability
    /// Using ObjectID instead of Household object prevents stale references after
    /// the household moves from Private → Shared during share creation.
    ///
    /// ## M7.2.3 Phase 2.6: StoreID Abstraction
    /// Store is now identified by enum, not NSPersistentStore instance.
    /// PersistenceController resolves StoreID → NSPersistentStore internally.
    ///
    /// Objects created in this scope:
    /// - Live in Shared CloudKit zone (typically)
    /// - ARE visible to household members
    /// - Have `household = <household>` automatically set
    case household(id: NSManagedObjectID, storeID: StoreID)
}

// MARK: - HouseholdScoped Protocol

/// Protocol for entities that can be scoped to a household
///
/// ## HouseholdScoped Invariant (Core Principle 5)
/// Any entity conforming to HouseholdScoped MUST:
/// - Be created exclusively via `ManagedObjectFactory`
/// - Have `household != nil` when in household scope
/// - Have `household == nil` when in personal scope
/// - Never transition between scopes after creation (except via attach-then-share)
///
/// ## Why This Matters
/// - Prevents cross-store relationship violations
/// - Makes ownership clear and deterministic
/// - Simplifies debugging (object's store never changes post-creation)
///
/// ## Enforcement
/// - ManagedObjectFactory is the ONLY creation path
/// - Cross-store validator catches violations in DEBUG
/// - Protocol conformance makes it compiler-enforced
///
/// Source: Gemini feedback - "Make household-scoped a first-class invariant"
protocol HouseholdScoped: NSManagedObject {
    /// The household this entity belongs to (nil for personal scope)
    var household: Household? { get set }
    
    /// String representation of household.id for:
    /// - Semantic deduplication without relationship traversal
    /// - CloudKit predicate queries (require string attributes)
    /// - Efficient lookups without fetching full object graph
    ///
    /// Auto-set by ManagedObjectFactory when creating in household scope
    var householdKey: String? { get set }
}

// MARK: - ScopeProvider Protocol

/// M7.2.3 Phase 2.6: Protocol for providing active data scope
///
/// ## Purpose
/// Abstracts how scope is determined (allows different implementations)
///
/// ## MainActor Isolation
/// Marked @MainActor because implementations typically access SwiftUI state
/// (HouseholdService.currentHousehold, etc.)
///
/// ## Scope Snapshot Pattern (Gemini best practice)
/// The `scopeSnapshot()` method captures immutable scope for background work.
/// This ensures deterministic behavior - scope at "enqueue time" not "execution time".
///
/// Source: ChatGPT + Gemini feedback
@MainActor
protocol ScopeProvider {
    /// Current active scope (may change as user switches households)
    var activeScope: DataScope { get }
    
    /// M7.2.3 Phase 2.6: Capture immutable scope snapshot
    ///
    /// ## Use Case: Background Operations
    /// When enqueuing background work, capture scope on main thread:
    /// ```swift
    /// let snapshot = scopeProvider.scopeSnapshot()  // ✅ Main thread
    ///
    /// persistence.performScopedWrite(scope: snapshot) { context, factory in
    ///     // ✅ Uses scope from enqueue time, not execution time
    /// }
    /// ```
    ///
    /// ## Benefits (Gemini)
    /// - No cross-actor calls from background → main
    /// - Deterministic behavior (scope at enqueue time)
    /// - Fewer parameters through call chains
    ///
    /// Source: Gemini - "snapshot scope on main before hopping"
    func scopeSnapshot() -> DataScope
}

// MARK: - HouseholdScoped Conformance

extension WeeklyList: HouseholdScoped {}
extension Recipe: HouseholdScoped {}
extension PlannedMeal: HouseholdScoped {}
extension MealPlan: HouseholdScoped {}
extension Category: HouseholdScoped {}
extension IngredientTemplate: HouseholdScoped {}
// M9.15: Promoted from non-HouseholdScoped — eliminates cross-store relationships
extension Ingredient: HouseholdScoped {}
extension GroceryListItem: HouseholdScoped {}
// M18.1: Store-aware shopping
extension Store: HouseholdScoped {}

// MARK: - Debug Utilities

#if DEBUG
extension DataScope: CustomStringConvertible {
    var description: String {
        switch self {
        case .personal:
            return "Personal (Private Store)"
        case .household(let id, let storeID):
            return "Household(\(id.uriRepresentation().lastPathComponent)) in \(storeID)"
        }
    }
}

extension StoreID: CustomStringConvertible {
    var description: String {
        switch self {
        case .private: return "Private"
        case .shared: return "Shared"
        }
    }
}
#endif
