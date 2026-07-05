//
//  AddStoreView.swift
//  forager
//
//  M18.1.3: Add store sheet — name + color picker + suggested store chips.
//

import SwiftUI
import CoreData

struct AddStoreView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    /// Injected StoreService for CRUD (ADR 014 factory enforcement)
    var storeService: StoreService

    @State private var name = ""
    @State private var selectedColor = ForagerTheme.storeColorPalette[0]
    @State private var showingError = false
    @State private var errorMessage = ""

    /// Suggested store chips shown when no stores exist yet.
    private let suggestedStores = [
        "Costco", "Walmart", "Target", "Kroger",
        "Whole Foods", "Aldi", "Trader Joe's"
    ]

    /// Whether to show suggested chips (only when the household has no stores).
    var showSuggestions: Bool = true

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if showSuggestions {
                    suggestedChipsSection
                }

                Section(header: Text("Store Details")) {
                    TextField("Store Name", text: $name)
                        .textInputAutocapitalization(.words)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(ForagerTheme.secondaryFont)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
                            ForEach(ForagerTheme.storeColorPalette, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? ForagerTheme.textPrimary : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button("Add Store") {
                        saveStore()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("New Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Suggested Store Chips

    private var suggestedChipsSection: some View {
        Section(header: Text("Quick Add")) {
            FlowLayout(spacing: 8) {
                ForEach(suggestedStores, id: \.self) { storeName in
                    Button {
                        name = storeName
                    } label: {
                        Text(storeName)
                            .font(ForagerTheme.secondaryFont)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                name == storeName
                                    ? ForagerTheme.accentPrimary.opacity(0.15)
                                    : ForagerTheme.backgroundSecondary
                            )
                            .foregroundStyle(
                                name == storeName
                                    ? ForagerTheme.accentPrimary
                                    : ForagerTheme.textPrimary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                                    .stroke(
                                        name == storeName
                                            ? ForagerTheme.accentPrimary
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Save

    private func saveStore() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for duplicate store names within current household scope
        let existing = storeService.fetchStores()
        if existing.contains(where: { $0.name?.lowercased() == trimmedName.lowercased() }) {
            errorMessage = "A store with this name already exists."
            showingError = true
            return
        }

        storeService.createStore(name: trimmedName, color: selectedColor)
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let householdService = HouseholdService(context: context)
    let storeService = StoreService(context: context)

    AddStoreView(storeService: storeService)
        .environment(\.managedObjectContext, context)
        .environmentObject(householdService)
}
