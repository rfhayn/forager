//
//  ManageStoresView.swift
//  forager
//
//  M18.1.3: Store management UI — Settings > Stores.
//  Replicates ManageCategoriesView pattern: list, reorder, delete with
//  reassignment dialog, add sheet, empty state.
//

import SwiftUI
import CoreData

struct ManageStoresView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    /// Injected StoreService (ADR 014 factory enforcement)
    @ObservedObject var storeService: StoreService

    // Fetch stores sorted by sortOrder
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Store.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Store.name, ascending: true)
        ],
        animation: .default
    ) private var allStores: FetchedResults<Store>

    // ADR 013: Filter by current household scope
    private var stores: [Store] {
        let currentHouseholdKey = householdService.currentHouseholdKey
        return allStores.filter { store in
            if let householdKey = currentHouseholdKey {
                return store.householdKey == householdKey
            } else {
                return store.householdKey == nil
            }
        }
    }

    // State management
    @State private var isReordering = false
    @State private var showingAddStore = false
    @State private var showingDeleteAlert = false
    @State private var storeToDelete: Store?

    // Reassignment state
    @State private var showingReassignmentDialog = false
    @State private var assignedTemplateCount = 0
    @State private var reassignmentStores: [Store] = []
    @State private var selectedReassignmentStore: Store? = nil

    // Error / success
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            BroadsheetMasthead(title: "Stores")
                .padding(.horizontal, ForagerTheme.Spacing.lg)
            if stores.isEmpty {
                emptyStateView
            } else {
                headerSection
                storesListSection
            }
        }
        .background(ForagerTheme.backgroundCanvas.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddStore) {
            AddStoreView(
                storeService: storeService,
                showSuggestions: stores.isEmpty
            )
        }
        .alert("Delete Store", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let store = storeToDelete {
                    storeService.deleteStore(store)
                    storeToDelete = nil
                }
            }
        } message: {
            if let store = storeToDelete {
                Text("Delete '\(store.displayName)'?\n\nThis store will no longer be available for new items.")
            }
        }
        .sheet(isPresented: $showingReassignmentDialog) {
            NavigationStack {
                reassignmentDialog
                    .navigationTitle("Reassign Templates")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingReassignmentDialog = false
                                storeToDelete = nil
                            }
                        }
                    }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: popToRoot) { _, _ in
            if showingAddStore { showingAddStore = false }
            if showingDeleteAlert { showingDeleteAlert = false }
            if showingReassignmentDialog { showingReassignmentDialog = false }
            if showingError { showingError = false }
            if isReordering { isReordering = false }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Stores", systemImage: "storefront")
        } description: {
            Text("Add stores to track where you buy your groceries. Items will remember your store preferences.")
        } actions: {
            Button("Add Store") {
                showingAddStore = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerSection: some View {
        // reskin-provisions-press: ink band header + caption (uniform grammar)
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            ForagerSectionHeader(title: "Shopping Order", count: stores.count)
            Text("Arrange stores in your preferred shopping order. Drag to reorder.")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textTertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .background(ForagerTheme.backgroundCanvas)
    }

    // MARK: - Store List

    private var storesListSection: some View {
        List {
            ForEach(Array(stores.enumerated()), id: \.element) { index, store in
                StoreRowView(
                    store: store,
                    position: index + 1,
                    storeService: storeService,
                    onDelete: {
                        prepareForStoreDeletion(store)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove(perform: moveStores)
            .onDelete(perform: deleteStores)

            Section { } footer: {
                Text("Drag stores to reorder. Swipe left to delete — its ingredient preferences will be reassigned or cleared.")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .listRowBackground(Color.clear)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ForagerTheme.backgroundCanvas)
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: ForagerTheme.Spacing.md) {
                Button { showingAddStore = true } label: {
                    Image(systemName: "plus")
                }

                if !stores.isEmpty {
                    Button(isReordering ? "Done" : "Reorder") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isReordering.toggle()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Deletion

    private func prepareForStoreDeletion(_ store: Store) {
        storeToDelete = store

        let templateCount = countAssignedTemplates(for: store)

        if templateCount > 0 {
            assignedTemplateCount = templateCount
            reassignmentStores = stores.filter { $0 != store }
            selectedReassignmentStore = reassignmentStores.first
            showingReassignmentDialog = true
        } else {
            showingDeleteAlert = true
        }
    }

    /// ADR 013: Count templates assigned to this store within current household scope.
    private func countAssignedTemplates(for store: Store) -> Int {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()

        if let householdKey = householdService.currentHouseholdKey {
            request.predicate = NSPredicate(format: "preferredStore == %@ AND householdKey == %@", store, householdKey)
        } else {
            request.predicate = NSPredicate(format: "preferredStore == %@ AND householdKey == nil", store)
        }

        do {
            return try viewContext.count(for: request)
        } catch {
            #if DEBUG
            print("❌ ManageStoresView: Error counting template assignments: \(error)")
            #endif
            return 0
        }
    }

    // MARK: - Reassignment Dialog

    private var reassignmentDialog: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Store Has Assigned Ingredients")
                    .font(ForagerTheme.detailTitle)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                if let store = storeToDelete {
                    Text("\(assignedTemplateCount) ingredient\(assignedTemplateCount == 1 ? "" : "s") prefer\(assignedTemplateCount == 1 ? "s" : "") '\(store.displayName)'.")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 16) {
                // Option 1: Reassign to another store
                if !reassignmentStores.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(ForagerTheme.accentPrimary)
                            Text("Reassign to Another Store")
                                .font(ForagerTheme.secondaryFont)
                                .fontWeight(.medium)
                        }

                        NavigationLink(destination: StoreSelectionView(
                            stores: reassignmentStores,
                            selectedStore: $selectedReassignmentStore
                        )) {
                            HStack {
                                if let selected = selectedReassignmentStore {
                                    RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                                        .fill(ForagerTheme.storeColor(hex: selected.color))
                                        .frame(width: 16, height: 16)
                                    Text(selected.displayName)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Select Store")
                                        .foregroundStyle(ForagerTheme.accentPrimary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(ForagerTheme.textSecondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(16)
                    .background(ForagerTheme.backgroundSecondary)
                    .cornerRadius(ForagerTheme.Radius.md)
                }

                // Option 2: Clear store preference
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(ForagerTheme.textTertiary)
                        Text("Clear Store Preference")
                            .font(ForagerTheme.secondaryFont)
                            .fontWeight(.medium)
                    }
                    Text("Ingredients will have no store assigned")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                .padding(16)
                .background(ForagerTheme.backgroundSecondary)
                .cornerRadius(ForagerTheme.Radius.md)
            }

            // Action buttons
            VStack(spacing: 12) {
                if !reassignmentStores.isEmpty {
                    Button("Reassign to Selected Store") {
                        if let store = storeToDelete,
                           let replacement = selectedReassignmentStore {
                            performDeletion(store: store, reassignTo: replacement)
                        }
                    }
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(selectedReassignmentStore == nil ? ForagerTheme.buttonPrimaryDisabledText : ForagerTheme.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedReassignmentStore == nil ? ForagerTheme.buttonPrimaryDisabled : ForagerTheme.buttonPrimaryDefault)
                    .cornerRadius(ForagerTheme.Radius.md)
                    .disabled(selectedReassignmentStore == nil)
                }

                Button("Clear Preferences & Delete") {
                    if let store = storeToDelete {
                        performDeletion(store: store, reassignTo: nil)
                    }
                }
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.buttonPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ForagerTheme.textTertiary)
                .cornerRadius(ForagerTheme.Radius.md)

                Button("Cancel") {
                    showingReassignmentDialog = false
                    storeToDelete = nil
                    selectedReassignmentStore = nil
                }
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.accentPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ForagerTheme.backgroundSecondary)
                .cornerRadius(ForagerTheme.Radius.md)
            }
        }
        .padding(20)
    }

    // MARK: - Deletion Implementation

    private func performDeletion(store: Store, reassignTo replacement: Store?) {
        storeService.deleteStore(store, reassignTo: replacement)
        showingReassignmentDialog = false
        storeToDelete = nil
        selectedReassignmentStore = nil
    }

    // MARK: - Reorder

    private func moveStores(from source: IndexSet, to destination: Int) {
        var storeArray = Array(stores)
        storeArray.move(fromOffsets: source, toOffset: destination)
        storeService.reorderStores(storeArray)
    }

    private func deleteStores(offsets: IndexSet) {
        for index in offsets {
            let store = stores[index]
            prepareForStoreDeletion(store)
            break
        }
    }
}

// MARK: - Store Row View

struct StoreRowView: View {
    let store: Store
    let position: Int
    let storeService: StoreService
    let onDelete: () -> Void

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingColorPicker = false

    var body: some View {
        HStack(spacing: 16) {
            // Position indicator — mono price-tag numeral
            Text("\(position)")
                .font(ForagerTheme.quantityFontLarge)
                .foregroundStyle(ForagerTheme.textSecondary)
                .frame(width: 30)

            // Store color swatch — printed square, tap to change color
            Button {
                showingColorPicker = true
            } label: {
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .fill(ForagerTheme.storeColor(hex: store.color))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                            .strokeBorder(ForagerTheme.borderDefault, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())

            // Store name — tap to edit
            if isEditingName {
                TextField("Store name", text: $editedName)
                    .font(ForagerTheme.secondaryFont)
                    .fontWeight(.medium)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit { saveNameEdit() }
                    .onAppear { editedName = store.name ?? "" }
            } else {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    Text(store.displayName)
                        .font(ForagerTheme.secondaryFont)
                        .fontWeight(.medium)

                    if store.isDefault {
                        Image(systemName: "lock.fill")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                }
                .onTapGesture {
                    guard !store.isDefault else { return }
                    editedName = store.name ?? ""
                    isEditingName = true
                }
            }

            Spacer()

            if isEditingName {
                HStack(spacing: 8) {
                    Button("Cancel") {
                        isEditingName = false
                    }
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .buttonStyle(.borderless)

                    Button("Save") {
                        saveNameEdit()
                    }
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.accentPrimary)
                    .buttonStyle(.borderless)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else if !store.isDefault {
                // Delete button — hidden for protected stores
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(ForagerTheme.statusDangerFG)
                        .font(.title3)
                }
                .buttonStyle(BorderlessButtonStyle())

                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .overlay(alignment: .bottom) {
            // reskin-provisions-press: broadsheet row — hairline rule, no box
            Rectangle()
                .fill(ForagerTheme.borderSubtle)
                .frame(height: 1.5)
        }
        .sheet(isPresented: $showingColorPicker) {
            StoreColorPickerSheet(store: store, storeService: storeService)
        }
    }

    private func saveNameEdit() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != store.name else {
            isEditingName = false
            return
        }
        store.name = trimmed
        store.updatedAt = Date()
        storeService.saveContext()
        isEditingName = false
    }
}

// MARK: - Store Color Picker Sheet

struct StoreColorPickerSheet: View {
    let store: Store
    let storeService: StoreService
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 52))]

    var body: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.lg) {
                // Current color preview — printed square
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.md, style: .continuous)
                    .fill(ForagerTheme.storeColor(hex: store.color))
                    .frame(width: 64, height: 64)
                    .padding(.top, ForagerTheme.Spacing.lg)

                Text(store.displayName)
                    .font(ForagerTheme.detailTitle)

                // Color grid
                LazyVGrid(columns: columns, spacing: ForagerTheme.Spacing.md) {
                    ForEach(ForagerTheme.storeColorPalette, id: \.self) { hex in
                        Button {
                            store.color = hex
                            store.updatedAt = Date()
                            storeService.saveContext()
                            dismiss()
                        } label: {
                            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                .fill(ForagerTheme.storeColor(hex: hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                        .strokeBorder(store.color == hex ? ForagerTheme.textPrimary : Color.clear, lineWidth: 3)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, ForagerTheme.Spacing.lg)

                Spacer()
            }
            .navigationTitle("Store Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }
}

// MARK: - Store Selection View (for reassignment)

struct StoreSelectionView: View {
    let stores: [Store]
    @Binding var selectedStore: Store?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(stores, id: \.self) { store in
                Button {
                    selectedStore = store
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                            .fill(ForagerTheme.storeColor(hex: store.color))
                            .frame(width: 32, height: 32)

                        Text(store.displayName)
                            .font(ForagerTheme.bodyFont)
                            .foregroundStyle(ForagerTheme.textPrimary)

                        Spacer()

                        if selectedStore == store {
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
        }
        .navigationTitle("Select Store")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageStoresView(
            popToRoot: .constant(false),
            storeService: StoreService(context: PersistenceController.preview.container.viewContext)
        )
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
