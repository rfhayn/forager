//
//  DataScope.swift
//  forager
//
//  M7.2.3 Phase 2.1: Scope-Based Store Assignment Foundation
//  Created on January 2, 2026
//
//  Defines the ownership scope for data in the app and protocol for
//  household-scoped entities. Implementation from Gemini external validation.
//

import Foundation
import CoreData

// MARK: - Data Scope Enum

/// Represents the ownership scope for data in the app
///
/// ## Design Principles
/// - **One Active Scope**: App operates in one scope at a time (personal OR household)
/// - **ObjectID-based**: Uses NSManagedObjectID to prevent stale household references
/// - **Store-aware**: Tracks which persistent store the household lives in
///
/// ## Usage
/// ```swift
/// let scope = scopeProvider.activeScope
/// switch scope {
/// case .personal:
///     // Create in private store, household = nil
/// case .household(let id, let store):
///     // Create in shared store, auto-set household relationship
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
    ///   - store: The persistent store where household currently resides
    ///
    /// ## Critical: ObjectID Stability
    /// Using ObjectID instead of Household object prevents stale references after
    /// the household moves from Private → Shared during share creation.
    ///
    /// Objects created in this scope:
    /// - Live in Shared CloudKit zone
    /// - ARE visible to household members
    /// - Have `household = <household>` automatically set
    case household(id: NSManagedObjectID, store: NSPersistentStore)
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

// MARK: - HouseholdScoped Conformance

// ⚠️ TODO M7.2.3 Phase 2: UNCOMMENT AFTER PHASE 2 COMPLETION
// These conformance declarations are commented out until Core Data model
// fully generates the required properties (household, householdKey).
//
// ✅ WHEN TO UNCOMMENT:
// - After Phase 2.5 (all creation points updated)
// - After verifying build succeeds with factory pattern
// - Before Phase 2 completion commit
//
// Without these uncommented, ManagedObjectFactory won't be able to use
// the HouseholdScoped protocol, which is critical for Phase 2.

// extension WeeklyList: HouseholdScoped {}
// extension Recipe: HouseholdScoped {}
// extension PlannedMeal: HouseholdScoped {}
// extension Category: HouseholdScoped {}
// extension IngredientTemplate: HouseholdScoped {}

// MARK: - Debug Utilities

#if DEBUG
extension DataScope: CustomStringConvertible {
    var description: String {
        switch self {
        case .personal:
            return "Personal (Private Store)"
        case .household(let id, let store):
            let storeURL = store.url?.lastPathComponent ?? "unknown"
            return "Household(\(id.uriRepresentation().lastPathComponent)) in \(storeURL)"
        }
    }
}
#endif
