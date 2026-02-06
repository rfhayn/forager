//
//  EditIngredientSheet.swift
//  forager
//
//  M8.1: Parsing Resilience & Telemetry
//  Created: February 6, 2026
//
//  Structured edit form for ingredient corrections
//  Logs corrections to ParsingTelemetryService for data-driven improvement
//

import SwiftUI
import CoreData

// MARK: - Edit Ingredient Data Model

/// Represents editable ingredient data separate from Core Data entity
struct EditableIngredientData {
    var quantity: String
    var unit: String
    var name: String
    var notes: String

    // Original values for telemetry
    let originalQuantity: Double?
    let originalUnit: String?
    let originalName: String
    let originalConfidence: Float

    init(from ingredient: Ingredient) {
        self.quantity = ingredient.numericValue > 0 ? String(ingredient.numericValue) : ""
        self.unit = ingredient.standardUnit ?? ""
        self.name = ingredient.ingredientTemplate?.normalizedName ?? ingredient.name ?? ""
        self.notes = ingredient.notes ?? ""

        // Store originals for telemetry
        self.originalQuantity = ingredient.numericValue > 0 ? ingredient.numericValue : nil
        self.originalUnit = ingredient.standardUnit
        self.originalName = ingredient.name ?? ""
        self.originalConfidence = ingredient.parseConfidence
    }

    init(from item: GroceryListItem) {
        self.quantity = item.numericValue > 0 ? String(item.numericValue) : ""
        self.unit = item.standardUnit ?? ""
        // GroceryListItem uses name directly (no template relationship)
        self.name = item.name ?? ""
        self.notes = "" // GroceryListItem doesn't have notes

        // Store originals for telemetry
        self.originalQuantity = item.numericValue > 0 ? item.numericValue : nil
        self.originalUnit = item.standardUnit
        self.originalName = item.name ?? ""
        self.originalConfidence = item.parseConfidence
    }

    /// Format display text from components
    func formatDisplayText() -> String {
        var parts: [String] = []
        if !quantity.isEmpty {
            parts.append(quantity)
        }
        if !unit.isEmpty {
            parts.append(unit)
        }
        if !name.isEmpty {
            parts.append(name)
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - Edit Ingredient Sheet

struct EditIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // The ingredient being edited (either Recipe Ingredient or GroceryListItem)
    let ingredient: Ingredient?
    let groceryItem: GroceryListItem?

    // Callback for when save completes
    var onSave: (() -> Void)?

    // Edit state
    @State private var data: EditableIngredientData
    @State private var showValidationError = false
    @State private var validationMessage = ""

    // MARK: - Initializers

    init(ingredient: Ingredient, onSave: (() -> Void)? = nil) {
        self.ingredient = ingredient
        self.groceryItem = nil
        self.onSave = onSave
        _data = State(initialValue: EditableIngredientData(from: ingredient))
    }

    init(groceryItem: GroceryListItem, onSave: (() -> Void)? = nil) {
        self.ingredient = nil
        self.groceryItem = groceryItem
        self.onSave = onSave
        _data = State(initialValue: EditableIngredientData(from: groceryItem))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                quantitySection
                ingredientSection
                notesSection

                if data.originalConfidence < 0.5 {
                    originalTextSection
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(data.name.isEmpty)
                }
            }
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - View Sections

    private var quantitySection: some View {
        Section {
            HStack {
                TextField("Amount (e.g., 2, 1.5)", text: $data.quantity)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)

                Divider()

                TextField("Unit (e.g., cups, tbsp)", text: $data.unit)
                    .frame(maxWidth: .infinity)
            }
        } header: {
            Text("Quantity & Unit")
        } footer: {
            Text("Leave empty if not applicable (e.g., \"salt to taste\")")
        }
    }

    private var ingredientSection: some View {
        Section("Ingredient Name") {
            TextField("Name (e.g., flour, chicken breast)", text: $data.name)
                .autocapitalization(.none)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if ingredient != nil { // Only show for Recipe Ingredients
            Section {
                TextField("e.g., minced, diced, room temperature", text: $data.notes)
            } header: {
                Text("Notes (Optional)")
            } footer: {
                Text("Preparation notes or additional details")
            }
        }
    }

    private var originalTextSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Original text:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\"\(data.originalName)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        } header: {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Low Confidence Parse")
            }
        } footer: {
            Text("This ingredient was parsed with low confidence. Please review and correct if needed.")
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        // Validate name is not empty
        guard !data.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Ingredient name cannot be empty"
            showValidationError = true
            return
        }

        // Parse quantity to numeric
        let numericQuantity: Double?
        if data.quantity.isEmpty {
            numericQuantity = nil
        } else if let parsed = Double(data.quantity) {
            numericQuantity = parsed
        } else {
            validationMessage = "Quantity must be a valid number (e.g., 2, 1.5, 0.75)"
            showValidationError = true
            return
        }

        // Log correction to telemetry if values changed
        let hasChanges = hasSignificantChanges(newQuantity: numericQuantity)
        if hasChanges {
            ParsingTelemetryService.shared.logCorrection(
                originalEventId: nil, // We don't track event IDs yet
                originalName: data.originalName,
                originalQuantity: data.originalQuantity,
                originalUnit: data.originalUnit,
                originalConfidence: data.originalConfidence,
                correctedName: data.name,
                correctedQuantity: numericQuantity,
                correctedUnit: data.unit.isEmpty ? nil : data.unit
            )
        }

        // Update the entity
        if let ingredient = ingredient {
            updateIngredient(ingredient, quantity: numericQuantity)
        } else if let groceryItem = groceryItem {
            updateGroceryItem(groceryItem, quantity: numericQuantity)
        }

        // Save context
        do {
            try viewContext.save()
            onSave?()
            dismiss()
        } catch {
            validationMessage = "Failed to save: \(error.localizedDescription)"
            showValidationError = true
        }
    }

    private func updateIngredient(_ ingredient: Ingredient, quantity: Double?) {
        ingredient.numericValue = quantity ?? 0.0
        ingredient.standardUnit = data.unit.isEmpty ? nil : data.unit
        ingredient.displayText = data.formatDisplayText()
        ingredient.isParseable = quantity != nil
        ingredient.parseConfidence = 1.0 // Manual edit = max confidence
        ingredient.notes = data.notes.isEmpty ? nil : data.notes

        // Update name through the template if needed
        if data.name != data.originalName {
            ingredient.name = data.formatDisplayText()
        }
    }

    private func updateGroceryItem(_ item: GroceryListItem, quantity: Double?) {
        item.numericValue = quantity ?? 0.0
        item.standardUnit = data.unit.isEmpty ? nil : data.unit
        item.displayText = data.formatDisplayText()
        item.isParseable = quantity != nil
        item.parseConfidence = 1.0 // Manual edit = max confidence

        // Update name
        if data.name != data.originalName {
            item.name = data.formatDisplayText()
        }
    }

    private func hasSignificantChanges(newQuantity: Double?) -> Bool {
        // Check if any values changed
        let nameChanged = data.name != data.originalName
        let quantityChanged = newQuantity != data.originalQuantity
        let unitChanged = (data.unit.isEmpty ? nil : data.unit) != data.originalUnit

        return nameChanged || quantityChanged || unitChanged
    }
}

// MARK: - Preview

#Preview("Recipe Ingredient") {
    let context = PersistenceController.preview.container.viewContext
    let ingredient = Ingredient(context: context)
    ingredient.id = UUID()
    ingredient.name = "2 cups flour"
    ingredient.numericValue = 2.0
    ingredient.standardUnit = "cup"
    ingredient.displayText = "2 cups"
    ingredient.parseConfidence = 0.95

    return EditIngredientSheet(ingredient: ingredient)
        .environment(\.managedObjectContext, context)
}

#Preview("Low Confidence") {
    let context = PersistenceController.preview.container.viewContext
    let ingredient = Ingredient(context: context)
    ingredient.id = UUID()
    ingredient.name = "2-3 cloves garlic, minced"
    ingredient.numericValue = 0.0
    ingredient.standardUnit = nil
    ingredient.displayText = "2-3 cloves garlic"
    ingredient.parseConfidence = 0.3

    return EditIngredientSheet(ingredient: ingredient)
        .environment(\.managedObjectContext, context)
}
