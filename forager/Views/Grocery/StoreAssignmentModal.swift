//
//  StoreAssignmentModal.swift
//  forager
//
//  M18.1.4: Store picker for "Buy at..." action on grocery list items.
//  Assigns store to both the current GroceryListItem (snapshot) and
//  the item's IngredientTemplate (learning for future items).
//

import SwiftUI
import CoreData

struct StoreAssignmentModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    let item: GroceryListItem
    let storeService: StoreService

    @FetchRequest private var stores: FetchedResults<Store>

    init(item: GroceryListItem, storeService: StoreService, householdKey: String?) {
        self.item = item
        self.storeService = storeService

        let predicate: NSPredicate
        if let key = householdKey {
            predicate = NSPredicate(format: "householdKey == %@", key)
        } else {
            predicate = NSPredicate(format: "householdKey == nil")
        }

        _stores = FetchRequest<Store>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Store.sortOrder, ascending: true),
                NSSortDescriptor(keyPath: \Store.name, ascending: true)
            ],
            predicate: predicate
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // "No Store" option
                Button {
                    assignStore(nil)
                } label: {
                    HStack(spacing: ForagerTheme.Spacing.sm) {
                        Circle()
                            .strokeBorder(ForagerTheme.borderDefault, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                        Text("No Store")
                            .font(ForagerTheme.bodyFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Spacer()
                        if item.store == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(ForagerTheme.accentPrimary)
                                .font(.caption)
                        }
                    }
                }
                .listRowBackground(Color.clear)

                // Store options
                ForEach(stores) { store in
                    Button {
                        assignStore(store)
                    } label: {
                        HStack(spacing: ForagerTheme.Spacing.sm) {
                            StoreColorDot(hex: store.color, size: 12)
                            Text(store.name ?? "Unnamed")
                                .font(ForagerTheme.bodyFont)
                                .foregroundStyle(ForagerTheme.textPrimary)
                            Spacer()
                            if item.store == store {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(ForagerTheme.accentPrimary)
                                    .font(.caption)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("Buy at...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }

    private func assignStore(_ store: Store?) {
        // Set on current grocery list item (snapshot)
        item.store = store

        // Also update the template's preferredStore (learning)
        if let templateName = item.name {
            let cleanName = IngredientParsingService.extractCleanIngredientName(from: templateName)
            let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            if let key = householdService.currentHouseholdKey {
                request.predicate = NSPredicate(
                    format: "name ==[c] %@ AND householdKey == %@", cleanName, key
                )
            } else {
                request.predicate = NSPredicate(
                    format: "name ==[c] %@ AND householdKey == nil", cleanName
                )
            }
            request.fetchLimit = 1

            if let template = try? item.managedObjectContext?.fetch(request).first {
                template.preferredStore = store
                template.updatedAt = Date()
            }
        }

        // Single save for both mutations
        storeService.assignStore(store, toGroceryItem: item)
        dismiss()
    }
}
