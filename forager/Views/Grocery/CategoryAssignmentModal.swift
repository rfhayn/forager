// M10.3.9: Category Assignment — Card-by-Card Review Pattern
// Mirrors IngredientReviewSheet: step through uncategorized templates one at a time,
// edit name, pick category, save & advance. Name edits trigger re-parsing + template matching.

import SwiftUI
import CoreData

struct CategoryAssignmentModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var ingredientTemplateService: IngredientTemplateService
    @EnvironmentObject private var parsingService: IngredientParsingService

    // Data
    let uncategorizedTemplates: [IngredientTemplate]
    let onAssignmentsComplete: () -> Void

    // Card-by-card state (mirrors IngredientReviewSheet)
    @State private var currentIndex = 0
    @State private var editedName = ""
    @State private var selectedCategory: String = ""
    @State private var errorMessage: String?

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var allCategories: FetchedResults<Category>

    // Filter by household scope, exclude "Uncategorized"
    private var realCategories: [Category] {
        let key = householdService.currentHouseholdKey
        let scoped = allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
        return scoped.filter { $0.displayName.lowercased() != "uncategorized" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.lg) {
                // Progress bar
                ProgressView(value: Double(currentIndex), total: Double(uncategorizedTemplates.count))
                    .tint(ForagerTheme.accentPrimary)

                // Progress text
                HStack {
                    Text("Assign Categories")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Spacer()
                    Text("\(currentIndex + 1) of \(uncategorizedTemplates.count)")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }

                // Current ingredient card
                if currentIndex < uncategorizedTemplates.count {
                    ingredientCard(uncategorizedTemplates[currentIndex])
                }

                Spacer()

                // Action buttons
                HStack(spacing: ForagerTheme.Spacing.md) {
                    Button {
                        skipCurrent()
                    } label: {
                        Text("Skip")
                            .font(ForagerTheme.bodyFont)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                                    .strokeBorder(ForagerTheme.borderDefault)
                            )
                    }

                    Button {
                        saveAndAdvance()
                    } label: {
                        Text(currentIndex < uncategorizedTemplates.count - 1 ? "Save & Next" : "Save & Done")
                            .font(ForagerTheme.bodyFont.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                            .foregroundStyle(.white)
                            .background(ForagerTheme.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                    }
                }
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("New Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip All") { skipAll() }
                        .font(ForagerTheme.captionFont)
                }
            }
            .onAppear { loadCurrentIngredient() }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Ingredient Card

    private func ingredientCard(_ template: IngredientTemplate) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
            // Info badge
            HStack(spacing: ForagerTheme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.accentPrimary)
                Text("New ingredient — assign a category")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            .padding(.horizontal, ForagerTheme.Spacing.sm)
            .padding(.vertical, ForagerTheme.Spacing.xs)
            .background(ForagerTheme.surfaceAccent)
            .clipShape(Capsule())

            // Editable name
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                Text("Name")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                TextField("Ingredient name", text: $editedName)
                    .font(ForagerTheme.bodyFont)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }

            // Category picker (Menu — not NavigationLink)
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                Text("Category")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)

                Menu {
                    Button("Uncategorized") {
                        selectedCategory = ""
                    }
                    ForEach(realCategories, id: \.objectID) { category in
                        Button(category.displayName) {
                            selectedCategory = category.displayName
                        }
                    }
                } label: {
                    HStack {
                        if selectedCategory.isEmpty {
                            Text("Choose Category")
                                .foregroundStyle(ForagerTheme.textTertiary)
                        } else {
                            HStack(spacing: ForagerTheme.Spacing.sm) {
                                Circle()
                                    .fill(ForagerTheme.categoryColor(for: selectedCategory))
                                    .frame(width: 12, height: 12)
                                Text(selectedCategory)
                                    .foregroundStyle(ForagerTheme.textPrimary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                    .font(ForagerTheme.bodyFont)
                    .padding(ForagerTheme.Spacing.md)
                    .background(ForagerTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                            .strokeBorder(ForagerTheme.borderDefault)
                    )
                }
            }
        }
        .padding(ForagerTheme.Spacing.lg)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
    }

    // MARK: - Actions

    private func loadCurrentIngredient() {
        guard currentIndex < uncategorizedTemplates.count else { return }
        let template = uncategorizedTemplates[currentIndex]
        editedName = template.name ?? ""
        selectedCategory = template.category ?? ""
    }

    private func advance() {
        if currentIndex < uncategorizedTemplates.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                currentIndex += 1
            }
            loadCurrentIngredient()
        } else {
            onAssignmentsComplete()
        }
    }

    private func skipCurrent() {
        // Assign "Uncategorized" to the current template and advance
        guard currentIndex < uncategorizedTemplates.count else { return }
        let template = uncategorizedTemplates[currentIndex]
        template.category = "Uncategorized"
        ingredientTemplateService.saveContext()
        advance()
    }

    private func skipAll() {
        // Assign "Uncategorized" to all remaining templates
        for i in currentIndex..<uncategorizedTemplates.count {
            uncategorizedTemplates[i].category = "Uncategorized"
        }
        ingredientTemplateService.saveContext()
        onAssignmentsComplete()
    }

    private func saveAndAdvance() {
        guard currentIndex < uncategorizedTemplates.count else { return }
        let template = uncategorizedTemplates[currentIndex]
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Ingredient name cannot be empty"
            return
        }

        let nameChanged = trimmedName.lowercased() != (template.name ?? "").lowercased()

        if nameChanged {
            // Re-parse the edited name to get a clean display name
            let parsed = parsingService.parseIngredient(text: trimmedName)
            let cleanName = parsed.displayName

            // Check if the new name matches an existing template (merge-on-rename)
            if let existingTemplate = findExistingTemplate(named: cleanName, excluding: template) {
                mergeTemplate(template, into: existingTemplate)

                // If the existing template already has a category, auto-fill it
                if let existingCategory = existingTemplate.category,
                   !existingCategory.isEmpty,
                   existingCategory.lowercased() != "uncategorized" {
                    // Template merged + already categorized — advance
                    advance()
                    return
                } else {
                    // Template merged but still needs category — apply selected
                    let categoryToUse = selectedCategory.isEmpty ? "Uncategorized" : selectedCategory
                    existingTemplate.category = categoryToUse
                    ingredientTemplateService.saveContext()
                    advance()
                    return
                }
            } else {
                // No match — rename the template and search for category hint
                let categoryToUse = selectedCategory.isEmpty ? "Uncategorized" : selectedCategory
                ingredientTemplateService.updateTemplate(template, name: cleanName,
                    category: categoryToUse, isStaple: template.isStaple)
            }
        } else {
            // Name unchanged — just assign the category
            let categoryToUse = selectedCategory.isEmpty ? "Uncategorized" : selectedCategory
            ingredientTemplateService.updateTemplate(template, name: trimmedName,
                category: categoryToUse, isStaple: template.isStaple)
        }

        if let error = ingredientTemplateService.errorMessage {
            errorMessage = error
        } else {
            advance()
        }
    }

    // MARK: - Template Matching

    /// Find an existing template with the same name (case-insensitive), excluding the current one.
    /// Mirrors the merge-on-rename logic from IngredientRowView.saveNameEdit()
    private func findExistingTemplate(named name: String, excluding template: IngredientTemplate) -> IngredientTemplate? {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        if let householdKey = householdService.currentHouseholdKey {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@ AND householdKey == %@",
                                            name, template, householdKey)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@ AND householdKey == nil",
                                            name, template)
        }
        return try? viewContext.fetch(request).first
    }

    /// Merge the source template into the target: move ingredient relationships, sum usage, delete source.
    /// Same logic as IngredientRowView.saveNameEdit() merge path.
    private func mergeTemplate(_ source: IngredientTemplate, into target: IngredientTemplate) {
        #if DEBUG
        print("📝 M10.3.9: Merging '\(source.name ?? "nil")' into '\(target.name ?? "nil")'")
        #endif

        // Move all ingredient relationships to the target template
        if let ingredientsToMove = source.ingredients as? Set<Ingredient> {
            for ing in ingredientsToMove {
                ing.ingredientTemplate = target
            }
        }

        // Sum usage counts and preserve staple status
        target.usageCount += source.usageCount
        if source.isStaple { target.isStaple = true }
        target.updatedAt = Date()

        // Log correction for ML training
        let originalName = source.name ?? ""
        let correctedName = target.name ?? ""
        if originalName.lowercased() != correctedName.lowercased() {
            ParsingTelemetryService.shared.logCorrection(
                originalName: originalName,
                originalQuantity: nil,
                originalUnit: nil,
                originalConfidence: 0,
                correctedName: correctedName,
                correctedQuantity: nil,
                correctedUnit: nil,
                source: .templateRename
            )
        }

        // Delete the old (now-empty) template
        ingredientTemplateService.deleteTemplate(source)
    }
}
