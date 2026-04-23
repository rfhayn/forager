//
//  StoreDeduplicator.swift
//  forager
//
//  fix-no-store-default-duplicates (2026-04-23): cross-device duplicate-store removal.
//  Mirrors CategoryDeduplicator with two divergences required by Store's semantics:
//    1. Grouping key includes isDefault (protected default vs user-created row).
//    2. Explicit re-parenting of IngredientTemplate.preferredStore and
//       GroceryListItem.store BEFORE deleting a duplicate. CategoryDeduplicator
//       can lean on nullify + Uncategorized as a safety net; Store has no
//       equivalent safety net, so nullify would silently drop user-assigned
//       preferences — a user-visible regression.
//

import CoreData
import Foundation

/// Detects and removes duplicate Store rows after CloudKit sync.
///
/// Why this exists:
/// - `DefaultSeeder.ensureNoStoreExists` has a CloudKit-import race. Its
///   single-shot `fetchLimit = 1` check returns nil before prior-device rows
///   import, so a new row is created locally; the prior row then imports
///   moments later and nothing reconciles them.
/// - `HouseholdService.copyPersonalDataToHousehold` previously cloned all
///   personal-scope Store rows into a new household without dedup. That path
///   now has its own guard (see the same change), but duplicates accumulated
///   before that fix land here for cleanup.
///
/// Strategy:
/// 1. Fetch all Store rows.
/// 2. Group by (name, scope, isDefault) — compound semantic uniqueness.
/// 3. For each group with more than one row, keep the oldest by dateCreated.
/// 4. For each duplicate: re-parent inverse relationships to the keeper
///    BEFORE deleting, so IngredientTemplate.preferredStore and
///    GroceryListItem.store never get silently nulled.
/// 5. Save — CloudKit syncs deletions to other devices.
///
/// Safe to call repeatedly. A second run finds nothing and is a no-op.
/// Wired to run on NSPersistentStoreRemoteChange via CloudKitSyncMonitor.
final class StoreDeduplicator {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public Deduplication Methods

    /// Detect and remove duplicate Stores, re-parenting inverse relationships.
    /// - Returns: Number of duplicate rows deleted.
    /// - Throws: Core Data errors during fetch or save.
    @discardableResult
    func removeDuplicates() throws -> Int {
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Store.name, ascending: true),
            NSSortDescriptor(keyPath: \Store.dateCreated, ascending: true)
        ]

        let allStores = try context.fetch(request)

        // Group by compound semantic key: name + scope + isDefault.
        // The isDefault dimension keeps a hypothetical user-created "No Store"
        // (unlikely given the M18.2 UI lock but technically possible) separate
        // from the protected default. CategoryDeduplicator's key doesn't need
        // this dimension because Category has no isDefault flag.
        let grouped = Dictionary(grouping: allStores) { store -> String in
            let name = store.name?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
            let scope = store.householdKey ?? "personal"
            let defaultFlag = store.isDefault ? "default" : "user"
            return "\(name)|\(scope)|\(defaultFlag)"
        }

        var deletedCount = 0

        for (compoundKey, stores) in grouped where stores.count > 1 {
            #if DEBUG
            print("⚠️ StoreDeduplicator: Found \(stores.count) duplicates for key '\(compoundKey)'")
            #endif

            // Keep oldest (earliest dateCreated). Nil dates sort last.
            let sorted = stores.sorted { a, b in
                guard let dateA = a.dateCreated, let dateB = b.dateCreated else {
                    return false
                }
                return dateA < dateB
            }

            guard let keeper = sorted.first else { continue }
            let duplicates = Array(sorted.dropFirst())

            #if DEBUG
            print("  ✅ Keeping: '\(keeper.name ?? "<nil>")' (created: \(keeper.dateCreated ?? Date()))")
            #endif

            // Re-parent inverse relationships BEFORE delete.
            // This is the architectural divergence from CategoryDeduplicator:
            // Store has no Uncategorized-style safety net, so nullify semantics
            // would drop IngredientTemplate.preferredStore and
            // GroceryListItem.store assignments user-visibly.
            for duplicate in duplicates {
                reparentInverseRelationships(from: duplicate, to: keeper)

                #if DEBUG
                print("  🗑️ Deleting: '\(duplicate.name ?? "<nil>")' (created: \(duplicate.dateCreated ?? Date()))")
                #endif
                context.delete(duplicate)
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            try context.save()
            #if DEBUG
            print("✅ StoreDeduplicator: Removed \(deletedCount) duplicate Store(s); CloudKit will sync deletions")
            #endif
        }

        return deletedCount
    }

    /// Count duplicates without removing them. Useful for diagnostics.
    /// - Returns: Number of duplicate rows that would be removed by `removeDuplicates()`.
    /// - Throws: Core Data errors during fetch.
    func countDuplicates() throws -> Int {
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let allStores = try context.fetch(request)

        let grouped = Dictionary(grouping: allStores) { store -> String in
            let name = store.name?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
            let scope = store.householdKey ?? "personal"
            let defaultFlag = store.isDefault ? "default" : "user"
            return "\(name)|\(scope)|\(defaultFlag)"
        }

        var duplicateCount = 0
        for stores in grouped.values where stores.count > 1 {
            duplicateCount += (stores.count - 1)
        }
        return duplicateCount
    }

    // MARK: - Private

    /// Re-point every `IngredientTemplate.preferredStore` and
    /// `GroceryListItem.store` reference from `duplicate` to `keeper` so the
    /// impending delete of `duplicate` does not null these fields.
    ///
    /// Iterates a snapshot copy of each inverse collection to avoid mutating
    /// an NSSet mid-iteration.
    private func reparentInverseRelationships(from duplicate: Store, to keeper: Store) {
        let templates = (duplicate.ingredientTemplates as? Set<IngredientTemplate>) ?? []
        for template in templates {
            template.preferredStore = keeper
        }

        let items = (duplicate.groceryListItems as? Set<GroceryListItem>) ?? []
        for item in items {
            item.store = keeper
        }

        #if DEBUG
        if !templates.isEmpty || !items.isEmpty {
            print("  🔁 Re-parented \(templates.count) template(s) + \(items.count) item(s) to keeper")
        }
        #endif
    }
}
