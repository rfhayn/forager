//
//  StoreService.swift
//  forager
//
//  M18.1.1: Store CRUD, assignment, query, and cross-store resolution.
//  Follows established service layer pattern (ADR 013 scope-aware fetches,
//  ADR 014 factory enforcement for HouseholdScoped entities).
//

import Foundation
import CoreData

@MainActor
class StoreService: ObservableObject {

    // MARK: - Properties

    @Published var errorMessage: String?

    private let viewContext: NSManagedObjectContext

    // M18.1.1: Factory for creating Store in correct persistent store (ADR 014)
    private(set) var factory: ManagedObjectFactory?

    // Household key for scoping fetches (ADR 013)
    var householdKey: String?
    var householdKeyProvider: (() -> String?)?

    private var resolvedHouseholdKey: String? {
        householdKey ?? householdKeyProvider?()
    }

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    /// One-time factory injection at app startup (ADR 014)
    func configure(factory: ManagedObjectFactory) {
        self.factory = factory
    }

    // MARK: - CRUD

    /// Creates a new store with the given name and color.
    /// Uses ManagedObjectFactory for correct store assignment (ADR 014).
    @discardableResult
    func createStore(name: String, color: String, in context: NSManagedObjectContext? = nil) -> Store? {
        clearError()

        let ctx = context ?? viewContext

        if let factory = factory {
            do {
                let store = try factory.make(Store.self, configure: { s in
                    s.id = UUID()
                    s.name = name
                    s.color = color
                    s.sortOrder = self.nextSortOrder()
                    s.dateCreated = Date()
                    s.updatedAt = Date()
                })
                save("create store")
                return store
            } catch {
                #if DEBUG
                print("❌ StoreService: Factory error creating Store: \(error)")
                #endif
            }
        }

        // Fallback: no factory available
        let store = Store(context: ctx)
        store.id = UUID()
        store.name = name
        store.color = color
        store.sortOrder = nextSortOrder()
        store.householdKey = resolvedHouseholdKey
        store.dateCreated = Date()
        store.updatedAt = Date()
        save("create store")
        return store
    }

    /// Deletes a store. If `reassignTo` is provided, templates currently assigned
    /// to the deleted store are reassigned to it. Otherwise, templates are unassigned.
    func deleteStore(_ store: Store, reassignTo replacement: Store? = nil, in context: NSManagedObjectContext? = nil) {
        clearError()

        // Reassign templates before deletion
        if let templates = store.ingredientTemplates as? Set<IngredientTemplate> {
            for template in templates {
                template.preferredStore = replacement
                template.updatedAt = Date()
            }
        }

        // Nullify grocery item snapshots (Core Data nullify rule handles this,
        // but explicit clear ensures consistency for in-memory objects)
        if let items = store.groceryListItems as? Set<GroceryListItem> {
            for item in items {
                item.store = nil
            }
        }

        viewContext.delete(store)
        save("delete store")
    }

    /// Reorders stores by updating sortOrder to match array index.
    func reorderStores(_ stores: [Store], in context: NSManagedObjectContext? = nil) {
        clearError()

        for (index, store) in stores.enumerated() {
            let newOrder = Int16(index)
            if store.sortOrder != newOrder {
                store.sortOrder = newOrder
                store.updatedAt = Date()
            }
        }

        save("reorder stores")
    }

    // MARK: - Query

    /// Fetches all stores for the current household scope, ordered by sortOrder.
    /// All fetches include householdKey predicate (ADR 013).
    func fetchStores(in context: NSManagedObjectContext? = nil) -> [Store] {
        let ctx = context ?? viewContext
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        request.predicate = householdKeyPredicate()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Store.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Store.name, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            #if DEBUG
            print("❌ StoreService: Error fetching stores: \(error)")
            #endif
            return []
        }
    }

    // MARK: - Assignment

    /// Assigns a preferred store to an ingredient template.
    /// This is a "learning" operation — future grocery items from this template
    /// will snapshot this store preference.
    func assignStore(_ store: Store?, toTemplate template: IngredientTemplate, in context: NSManagedObjectContext? = nil) {
        clearError()
        template.preferredStore = store
        template.updatedAt = Date()
        save("assign store to template")
    }

    /// Assigns a store to a grocery list item (direct override of snapshot).
    func assignStore(_ store: Store?, toGroceryItem item: GroceryListItem, in context: NSManagedObjectContext? = nil) {
        clearError()
        item.store = store
        save("assign store to grocery item")
    }

    // MARK: - Cross-Store Resolution

    /// Resolves a store for use in the context of a target weekly list.
    /// Handles dual-store CloudKit safety: if the template's preferredStore lives
    /// in a different persistent store than the target list, looks up by name
    /// in the target list's household scope instead.
    ///
    /// Mirrors `GroceryListItemService.resolveCategory()` pattern.
    func resolveStore(
        for template: IngredientTemplate?,
        targetList: WeeklyList
    ) -> Store? {
        guard let store = template?.preferredStore else { return nil }

        let targetPersistentStore = targetList.objectID.persistentStore
        let storePersistentStore = store.objectID.persistentStore

        // Same store or store info unavailable — direct assignment is safe
        if targetPersistentStore == storePersistentStore
            || targetPersistentStore == nil
            || storePersistentStore == nil {
            return store
        }

        // Cross-store — lookup by name in target list's household scope
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let storeName = store.name ?? ""
        if let hk = targetList.householdKey {
            request.predicate = NSPredicate(
                format: "name ==[c] %@ AND householdKey == %@", storeName, hk
            )
        } else {
            request.predicate = NSPredicate(
                format: "name ==[c] %@ AND householdKey == nil", storeName
            )
        }
        request.fetchLimit = 1
        return (try? viewContext.fetch(request))?.first
    }

    // MARK: - Helpers

    private func householdKeyPredicate() -> NSPredicate {
        if let key = resolvedHouseholdKey {
            return NSPredicate(format: "householdKey == %@", key)
        } else {
            return NSPredicate(format: "householdKey == nil")
        }
    }

    private func nextSortOrder() -> Int16 {
        let stores = fetchStores()
        let maxOrder = stores.map(\.sortOrder).max() ?? -1
        return maxOrder + 1
    }

    private func clearError() {
        errorMessage = nil
    }

    @discardableResult
    private func save(_ operation: String) -> Bool {
        guard viewContext.hasChanges else { return true }

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "Failed to \(operation)"
            #if DEBUG
            print("❌ StoreService: Failed to \(operation): \(error)")
            #endif
            viewContext.rollback()
            return false
        }
    }
}
