// StoreChangeModal.swift
// M18.1.5: Bulk store assignment for ingredient templates.
// Mirrors CategoryChangeModal pattern — walkthrough-style assignment.

import SwiftUI
import CoreData

struct StoreChangeModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    let ingredientTemplates: [IngredientTemplate]
    let storeService: StoreService
    let onAssignmentsComplete: () -> Void

    @State private var storeAssignments: [NSManagedObjectID: NSManagedObjectID?] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?

    @FetchRequest private var stores: FetchedResults<Store>

    init(ingredientTemplates: [IngredientTemplate],
         storeService: StoreService,
         householdKey: String?,
         onAssignmentsComplete: @escaping () -> Void) {
        self.ingredientTemplates = ingredientTemplates
        self.storeService = storeService
        self.onAssignmentsComplete = onAssignmentsComplete

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
            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(ingredientTemplates, id: \.objectID) { template in
                            IngredientStoreRow(
                                template: template,
                                stores: Array(stores),
                                selectedStoreID: storeAssignments[template.objectID] ?? nil,
                                onStoreSelected: { storeID in
                                    storeAssignments[template.objectID] = storeID
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                actionButtons
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            initializeAssignments()
        }
        .alert("Assignment Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage { Text(error) }
        }
    }

    private func initializeAssignments() {
        guard storeAssignments.isEmpty else { return }
        for template in ingredientTemplates {
            storeAssignments[template.objectID] = template.preferredStore?.objectID
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Stores")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("\(ingredientTemplates.count) ingredient\(ingredientTemplates.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                Spacer()
            }

            Text("Set where you usually buy each ingredient.")
                .font(.callout)
                .foregroundStyle(ForagerTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: assignStores) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isLoading ? "Assigning..." : "Assign Stores")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(assignedCount > 0 ? ForagerTheme.accentPrimary : ForagerTheme.accentPrimary.opacity(0.6))
                .foregroundStyle(.white)
                .cornerRadius(ForagerTheme.Radius.md)
            }
            .disabled(isLoading)

            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Cancel")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .cornerRadius(ForagerTheme.Radius.md)
            }
            .disabled(isLoading)

            if ingredientTemplates.count > 1 {
                VStack(spacing: 4) {
                    HStack {
                        Text("\(assignedCount) of \(ingredientTemplates.count) assigned")
                            .font(.footnote)
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Spacer()
                    }
                    if assignedCount < ingredientTemplates.count {
                        HStack {
                            Text("\(ingredientTemplates.count - assignedCount) without a store")
                                .font(.footnote)
                                .foregroundStyle(ForagerTheme.textSecondary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }

    private var assignedCount: Int {
        storeAssignments.values.compactMap { $0 }.count
    }

    // MARK: - Actions

    private func assignStores() {
        isLoading = true
        errorMessage = nil

        var hasChanges = false

        for template in ingredientTemplates {
            let currentStoreID = template.preferredStore?.objectID
            let selectedStoreID = storeAssignments[template.objectID] ?? nil

            if currentStoreID != selectedStoreID {
                hasChanges = true
                if let storeID = selectedStoreID,
                   let store = try? viewContext.existingObject(with: storeID) as? Store {
                    storeService.assignStore(store, toTemplate: template)
                } else {
                    storeService.assignStore(nil, toTemplate: template)
                }
            }
        }

        if !hasChanges {
            isLoading = false
            onAssignmentsComplete()
            dismiss()
            return
        }

        isLoading = false
        onAssignmentsComplete()
        dismiss()
    }
}

// MARK: - Ingredient Store Row

struct IngredientStoreRow: View {
    let template: IngredientTemplate
    let stores: [Store]
    let selectedStoreID: NSManagedObjectID?
    let onStoreSelected: (NSManagedObjectID?) -> Void

    private var selectedStore: Store? {
        guard let id = selectedStoreID else { return nil }
        return stores.first { $0.objectID == id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name ?? "Unknown ingredient")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let category = template.categoryEntity?.name {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }

                Spacer()
                storeStatusView
            }

            NavigationLink(destination: StorePickerView(
                stores: stores,
                selectedStoreID: selectedStoreID,
                onStoreSelected: onStoreSelected
            )) {
                HStack {
                    if let store = selectedStore {
                        HStack(spacing: 8) {
                            StoreColorDot(hex: store.color, size: 16)
                            Text(store.name ?? "Unnamed")
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("Choose Store")
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(ForagerTheme.Radius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(ForagerTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                .stroke(selectedStore != nil ? ForagerTheme.statusSuccessFG.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
        )
    }

    private var storeStatusView: some View {
        Group {
            if let store = selectedStore {
                HStack(spacing: 6) {
                    StoreColorDot(hex: store.color, size: 16)
                    Text(store.name ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 16, height: 16)
                    Text("No store")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Store Selection View

struct StorePickerView: View {
    let stores: [Store]
    let selectedStoreID: NSManagedObjectID?
    let onStoreSelected: (NSManagedObjectID?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(stores, id: \.objectID) { store in
                Button {
                    onStoreSelected(store.objectID)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        StoreColorDot(hex: store.color, size: 24)
                        Text(store.name ?? "Unknown")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedStoreID == store.objectID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ForagerTheme.accentPrimary)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button("No Store") {
                onStoreSelected(nil)
                dismiss()
            }
            .foregroundStyle(ForagerTheme.textSecondary)
        }
        .navigationTitle("Select Store")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
