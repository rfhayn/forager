//
//  RecipeImportPreviewView.swift
//  forager
//
//  Created for M10.1.4: Import preview UI
//  Shows extracted recipe fields with confidence dots (green/amber/red).
//  Inline editing for all fields. Shared across all import phases (URL/Text/Photo).
//  Layout aligned to wireframe screens 1 (happy path) and 3 (partial extraction).
//

import SwiftUI

// MARK: - Recipe Import Preview View

/// Preview of an extracted recipe with per-field confidence indicators.
/// Layout follows wireframes: source → title → metadata row → ingredients → instructions → image → metadata.
/// Save moves to nav bar trailing; Cancel is nav bar leading.
struct RecipeImportPreviewView: View {
    @State var draft: ImportDraftRecipe
    @ObservedObject var importService: RecipeImportService
    /// Callback passes the draft + a dictionary of (parsed ingredient name → selected category)
    let onSave: (ImportDraftRecipe, [String: String]) -> Void
    let onCancel: () -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var parsingService: IngredientParsingService
    @EnvironmentObject private var templateService: IngredientTemplateService
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var matchService: IngredientMatchService

    @State private var showAllSteps = false
    @State private var ingredientMatches: [Int: IngredientMatchResult] = [:]
    /// User's category selections per ingredient index (inline assignment)
    @State private var categoryAssignments: [Int: String] = [:]
    /// User's ingredient name edits per index (nil = not edited, use original)
    @State private var editedIngredientNames: [Int: String] = [:]
    /// Which ingredient row is currently being edited (nil = none)
    @State private var editingIndex: Int?
    // M10.8: Inline instruction editing state
    @State private var editingStepIndex: Int?
    @State private var editedSteps: [Int: String] = [:]
    @FocusState private var focusedStep: Int?
    /// Which ingredient row has its category picker open (nil = none)
    @State private var categoryPickerIndex: Int?

    // M10.6.6: LLM parsing state
    @State private var isLLMBatchParsing = false
    @State private var llmParsingIngredients: Set<Int> = []
    @State private var llmToastMessage: String?

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var allCategories: FetchedResults<Category>

    /// Categories filtered by household, excluding "Uncategorized"
    private var realCategories: [Category] {
        let key = householdService.currentHouseholdKey
        let scoped = allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
        return scoped.filter { $0.displayName.lowercased() != "uncategorized" }
    }

    // MARK: - Ingredient Match (M10.6.8: Uses shared IngredientMatchResult)

    // MARK: - Instruction Steps (computed)

    /// Split the instructions string into individual steps for numbered display.
    private var instructionSteps: [String] {
        draft.instructions.value
            .components(separatedBy: "\n")
            .map { line in
                // Strip leading "1. ", "2. " etc. — we re-number with circles
                var cleaned = line
                if let range = cleaned.range(of: #"^\d+\.\s*"#, options: .regularExpression) {
                    cleaned.removeSubrange(range)
                }
                return cleaned
            }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// How many steps to show before collapse
    private let collapsedStepCount = 3

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                // Source attribution
                if let sourceURL = draft.sourceURL,
                   let host = URL(string: sourceURL)?.host {
                    sourceAttribution(host: host)
                }

                // Recipe title (editable)
                titleSection

                // Warning banner for partial extractions (wireframe screen 3)
                if draft.successLevel == .partial {
                    partialExtractionBanner
                }

                // Compact metadata row OR partial meta field cards
                if draft.successLevel == .partial {
                    partialMetaFieldCards
                } else {
                    compactMetadataRow
                }

                sectionDivider

                // Ingredients section
                ingredientsSection

                sectionDivider

                // Instructions section
                instructionsSection

                // Image preview (after instructions, per wireframe)
                if let imageURL = draft.imageURL.value,
                   let url = URL(string: imageURL) {
                    imagePreview(url: url)
                }

                // Author/cuisine/category metadata
                metadataSection
            }
            .padding(ForagerTheme.Spacing.lg)
        }
        .task { computeIngredientMatches() }
        .onChange(of: editingIndex) { oldValue, newValue in
            // Re-match when leaving an ingredient row
            if let oldIndex = oldValue, oldIndex != newValue {
                reMatchIngredient(index: oldIndex)
            }
            // M10.8: Mutual exclusion — exit step editing when ingredient editing starts
            if newValue != nil && editingStepIndex != nil {
                commitImportStepEdit(index: editingStepIndex!)
                editingStepIndex = nil
            }
        }
        // M10.8: Sync focus and commit for instruction step editing
        .onChange(of: editingStepIndex) { oldValue, newValue in
            if let oldIdx = oldValue, oldIdx != newValue {
                commitImportStepEdit(index: oldIdx)
            }
            focusedStep = newValue
            // Mutual exclusion — exit ingredient editing when step editing starts
            if newValue != nil && editingIndex != nil {
                if let idx = editingIndex { reMatchIngredient(index: idx) }
                editingIndex = nil
            }
        }
        .onChange(of: focusedStep) { _, newValue in
            if newValue == nil, let idx = editingStepIndex {
                commitImportStepEdit(index: idx)
                editingStepIndex = nil
            }
        }
        // Category picker sheet
        .sheet(isPresented: Binding(
            get: { categoryPickerIndex != nil },
            set: { if !$0 { categoryPickerIndex = nil } }
        )) {
            if let index = categoryPickerIndex {
                categoryPickerSheet(index: index)
                    .presentationDetents([.medium, .large])
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveWithCategories() }
                    .fontWeight(.semibold)
                    .disabled(draft.successLevel == .failure)
            }
        }
        .llmParsingToast(message: $llmToastMessage)
    }

    // MARK: - Source Attribution

    private func sourceAttribution(host: String) -> some View {
        HStack(spacing: ForagerTheme.Spacing.xs) {
            Image(systemName: "link")
                .font(.caption)
            Text("From \(host)")
                .font(ForagerTheme.footnoteFont)
        }
        .foregroundStyle(ForagerTheme.textLink)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        HStack(alignment: .top, spacing: ForagerTheme.Spacing.sm) {
            TextField("Recipe title", text: $draft.title.value)
                .font(ForagerTheme.detailTitle)
                .onChange(of: draft.title.value) { _, _ in
                    draft.title.wasEdited = true
                }
            confidenceDot(draft.title.confidence)
                .padding(.top, ForagerTheme.Spacing.sm)
        }
    }

    // MARK: - Compact Metadata Row (happy path)

    /// Single row: "N servings · N min prep · N min cook" with dot separators.
    private var compactMetadataRow: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            Text("\(draft.servings.value) servings")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)

            if let prep = draft.prepTimeMinutes.value {
                metaDot
                Text("\(prep) min prep")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }

            if let cook = draft.cookTimeMinutes.value {
                metaDot
                Text("\(cook) min cook")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
        }
    }

    private var metaDot: some View {
        Circle()
            .fill(ForagerTheme.textDisabled)
            .frame(width: 3, height: 3)
    }

    // MARK: - Partial Extraction Banner

    private var partialExtractionBanner: some View {
        HStack(alignment: .top, spacing: ForagerTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ForagerTheme.statusWarningFG)
                .font(.body)
            Text("Some fields couldn't be extracted. Please review highlighted items.")
                .font(ForagerTheme.footnoteFont)
                .foregroundStyle(ForagerTheme.statusWarningFG)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfaceWarning)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(ForagerTheme.statusWarningFG, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
    }

    // MARK: - Partial Meta Field Cards (wireframe screen 3)

    /// Side-by-side cards for prep/cook/servings when extraction is partial.
    /// Empty fields get dashed borders and placeholder text.
    private var partialMetaFieldCards: some View {
        VStack(spacing: ForagerTheme.Spacing.sm) {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                metaFieldCard(
                    label: "PREP TIME",
                    value: draft.prepTimeMinutes.value.map { "\($0) min" },
                    confidence: draft.prepTimeMinutes.confidence,
                    placeholder: "Add prep time"
                )
                metaFieldCard(
                    label: "COOK TIME",
                    value: draft.cookTimeMinutes.value.map { "\($0) min" },
                    confidence: draft.cookTimeMinutes.confidence,
                    placeholder: "Add cook time"
                )
            }
            HStack(spacing: ForagerTheme.Spacing.sm) {
                metaFieldCard(
                    label: "SERVINGS",
                    value: draft.servings.confidence == .medium
                        ? "\(draft.servings.value)?"
                        : "\(draft.servings.value)",
                    confidence: draft.servings.confidence,
                    placeholder: "Add servings"
                )
                // Empty spacer card for balanced layout
                Color.clear.frame(maxWidth: .infinity)
            }
        }
    }

    private func metaFieldCard(label: String, value: String?, confidence: ImportConfidence, placeholder: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                if let value = value {
                    Text(value)
                        .font(ForagerTheme.secondaryFont.weight(.semibold))
                        .foregroundStyle(confidence == .medium ? ForagerTheme.statusWarningFG : ForagerTheme.textPrimary)
                } else {
                    Text(placeholder)
                        .font(ForagerTheme.secondaryFont)
                        .foregroundStyle(ForagerTheme.textDisabled)
                        .italic()
                }
            }
            Spacer()
            confidenceDot(confidence)
        }
        .padding(ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(value == nil ? ForagerTheme.surfaceWarning : ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(
                    value == nil ? ForagerTheme.statusWarningFG : ForagerTheme.borderSubtle,
                    style: value == nil ? StrokeStyle(lineWidth: 1, dash: [5, 3]) : StrokeStyle(lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Divider()
            .foregroundStyle(ForagerTheme.borderSubtle)
    }

    // MARK: - M10.6.8: LLM Parsing Methods

    private func batchLLMParse() async {
        let texts = draft.ingredients.value
        guard !texts.isEmpty else { return }

        isLLMBatchParsing = true
        let categoryNames = realCategories.map { $0.displayName }

        if let results = await matchService.aiParseBatch(texts: texts, source: .import_, categories: categoryNames) {
            for (index, result) in results.enumerated() {
                guard index < draft.ingredients.value.count else { break }
                ingredientMatches[index] = result
                if let category = result.categoryName {
                    categoryAssignments[index] = category
                }
            }
            llmToastMessage = "AI parsed \(results.count) ingredients"
        } else {
            llmToastMessage = parsingService.lastLLMError ?? "AI parsing failed"
        }

        isLLMBatchParsing = false
    }

    private func singleLLMParse(index: Int) async {
        guard index < draft.ingredients.value.count else { return }

        llmParsingIngredients.insert(index)
        let categoryNames = realCategories.map { $0.displayName }

        let text = editedIngredientNames[index] ?? draft.ingredients.value[index]
        if let result = await matchService.aiParseSingle(text: text, source: .import_, categories: categoryNames) {
            ingredientMatches[index] = result
            if let category = result.categoryName {
                categoryAssignments[index] = category
            }
        }

        llmParsingIngredients.remove(index)
    }

    /// Parse each ingredient line, look up existing templates, and pre-fill category assignments.
    // M10.6.8: Delegates to shared IngredientMatchService
    private func computeIngredientMatches() {
        let results = matchService.matchBatch(texts: draft.ingredients.value)
        var matches: [Int: IngredientMatchResult] = [:]

        for (index, result) in results.enumerated() {
            guard let result else { continue }
            matches[index] = result
            // Pre-fill category assignments from matched templates (don't overwrite user edits)
            if let category = result.categoryName, categoryAssignments[index] == nil {
                categoryAssignments[index] = category
            }
        }

        ingredientMatches = matches
    }

    /// Build category assignments keyed by parsed ingredient name and pass to save callback.
    /// Applies any user edits to the draft's ingredient list before saving.
    private func saveWithCategories() {
        // Apply full-line edits to draft
        for (index, editedText) in editedIngredientNames {
            guard index < draft.ingredients.value.count else { continue }
            let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                draft.ingredients.value[index] = trimmed
            }
        }

        // Build category map keyed by parsed name (use cached match results when available)
        var nameToCategory: [String: String] = [:]
        for (index, category) in categoryAssignments {
            if let match = ingredientMatches[index] {
                nameToCategory[match.parsedName.lowercased()] = category
            } else {
                let text = editedIngredientNames[index] ?? (index < draft.ingredients.value.count ? draft.ingredients.value[index] : "")
                let parsed = parsingService.parseIngredient(text: text)
                nameToCategory[parsed.displayName.lowercased()] = category
            }
        }
        onSave(draft, nameToCategory)
    }

    // MARK: - Ingredient Editing

    /// Binding for the full ingredient text at a given index.
    private func ingredientTextBinding(index: Int, original: String) -> Binding<String> {
        Binding(
            get: { editedIngredientNames[index] ?? original },
            set: { editedIngredientNames[index] = $0 }
        )
    }

    /// Re-run parsing + template matching after the user edits an ingredient line.
    private func reMatchIngredient(index: Int) {
        let text = editedIngredientNames[index] ?? (index < draft.ingredients.value.count ? draft.ingredients.value[index] : "")
        if let result = matchService.matchIngredient(text: text) {
            ingredientMatches[index] = result
            if let category = result.categoryName {
                categoryAssignments[index] = category
            } else {
                // M10.6.8: Clear stale category when edited ingredient has no matching template
                categoryAssignments.removeValue(forKey: index)
            }
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            // M10.6.6: Section header with batch LLM parse sparkle button
            HStack {
                Text("Ingredients")
                    .font(ForagerTheme.bodyFont.weight(.bold))
                    .foregroundStyle(ForagerTheme.textPrimary)
                Spacer()
                if parsingService.isLLMAvailable {
                    if isLLMBatchParsing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            Task { await batchLLMParse() }
                        } label: {
                            ClaudeParseLabel()
                                .font(ForagerTheme.secondaryFont)
                        }
                        .disabled(draft.ingredients.value.isEmpty)
                    }
                }
            }
            .padding(.top, ForagerTheme.Spacing.sm)

            // Summary of ingredient match status
            if !ingredientMatches.isEmpty {
                ingredientMatchSummary
            }

            ForEach(draft.ingredients.value.indices, id: \.self) { index in
                ingredientRow(
                    index: index,
                    text: draft.ingredients.value[index],
                    confidence: draft.ingredients.confidence,
                    matchInfo: ingredientMatches[index]
                )
            }
        }
    }

    /// M10.6.8: Summary bar uses shared component
    private var ingredientMatchSummary: some View {
        let categorized = categoryAssignments.values.filter { !$0.isEmpty }.count
        let total = draft.ingredients.value.count
        return IngredientMatchSummaryView(categorized: categorized, uncategorized: total - categorized)
    }

    /// M10.6.8: Per-ingredient row using shared IngredientMatchRow component
    private func ingredientRow(index: Int, text: String, confidence: ImportConfidence, matchInfo: IngredientMatchResult?) -> some View {
        let isLowConfidence = confidence == .low || confidence == .medium
        let isEditing = editingIndex == index
        let currentText = editedIngredientNames[index] ?? text
        let effectiveCategory = categoryAssignments[index] ?? matchInfo?.categoryName

        return IngredientMatchRow(
            matchResult: matchInfo,
            rawText: currentText,
            isEditing: isEditing,
            isAIParsing: llmParsingIngredients.contains(index),
            showRawText: true,
            categoryName: effectiveCategory,
            onTapEdit: { editingIndex = index },
            onCategoryTap: { categoryPickerIndex = index },
            editText: ingredientTextBinding(index: index, original: text),
            onSubmitEdit: {
                reMatchIngredient(index: index)
                editingIndex = nil
            }
        )
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(isLowConfidence ? ForagerTheme.surfaceWarning : ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(isEditing ? ForagerTheme.accentPrimary : (isLowConfidence ? ForagerTheme.statusWarningFG : ForagerTheme.borderSubtle), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .contextMenu {
            if parsingService.isLLMAvailable {
                Button {
                    Task { await singleLLMParse(index: index) }
                } label: {
                    ClaudeParseLabel()
                }
            }
        }
    }

    // M10.6.8: categoryLabel moved to shared IngredientMatchRow component

    /// Sheet with colored category options for a given ingredient index
    private func categoryPickerSheet(index: Int) -> some View {
        let currentText = editedIngredientNames[index]
            ?? (index < draft.ingredients.value.count ? draft.ingredients.value[index] : "")

        return NavigationStack {
            List {
                Section {
                    // Show which ingredient we're categorizing
                    Text(currentText)
                        .font(ForagerTheme.bodyFont.weight(.medium))
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(realCategories, id: \.objectID) { category in
                        Button {
                            categoryAssignments[index] = category.displayName
                            categoryPickerIndex = nil
                        } label: {
                            HStack(spacing: ForagerTheme.Spacing.md) {
                                Circle()
                                    .fill(ForagerTheme.categoryColor(for: category.displayName))
                                    .frame(width: 12, height: 12)
                                Text(category.displayName)
                                    .font(ForagerTheme.bodyFont)
                                    .foregroundStyle(ForagerTheme.textPrimary)
                                Spacer()
                                if categoryAssignments[index] == category.displayName {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(ForagerTheme.accentPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { categoryPickerIndex = nil }
                }
            }
        }
    }

    // MARK: - Instructions Section (M10.8: Inline-Editable)

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            sectionHeader(label: "Instructions", showEditIcon: false)

            if instructionSteps.isEmpty {
                Text("No instructions extracted")
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .italic()
            } else {
                // Auto-expand when editing a step
                let stepsToShow = (showAllSteps || editingStepIndex != nil)
                    ? instructionSteps
                    : Array(instructionSteps.prefix(collapsedStepCount))

                ForEach(Array(stepsToShow.enumerated()), id: \.offset) { index, step in
                    importInstructionStepRow(index: index, step: step)
                }

                // "Show all N steps" collapse link
                if instructionSteps.count > collapsedStepCount && editingStepIndex == nil {
                    Button(action: { withAnimation { showAllSteps.toggle() } }) {
                        Text(showAllSteps
                             ? "Show fewer steps"
                             : "Show all \(instructionSteps.count) steps")
                            .font(ForagerTheme.footnoteFont)
                            .foregroundStyle(ForagerTheme.textLink)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, ForagerTheme.Spacing.xs)
                }
            }

            // Add step button
            Button { addImportStep() } label: {
                Label("Add Step", systemImage: "plus.circle")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.accentPrimary)
            }
            .padding(.top, ForagerTheme.Spacing.xs)
        }
    }

    /// Bordered card per instruction step with display/edit toggle (import version)
    private func importInstructionStepRow(index: Int, step: String) -> some View {
        let isEditing = editingStepIndex == index
        let currentText = editedSteps[index] ?? step

        return HStack(alignment: .top, spacing: ForagerTheme.Spacing.md) {
            Text("\(index + 1)")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.accentPrimary)
                .frame(width: 24, height: 24)
                .background(ForagerTheme.accentTint)
                .clipShape(Circle())

            if isEditing {
                TextField("Step \(index + 1)", text: importStepTextBinding(index: index, original: step), axis: .vertical)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .focused($focusedStep, equals: index)
                    .submitLabel(.done)
                    .onSubmit {
                        commitImportStepEdit(index: index)
                        editingStepIndex = nil
                    }
            } else {
                Text(currentText)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingStepIndex = index
                    }
            }
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(isEditing ? ForagerTheme.accentPrimary : ForagerTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .contextMenu {
            Button(role: .destructive) {
                deleteImportStep(at: index)
            } label: {
                Label("Delete Step", systemImage: "trash")
            }
        }
    }

    // MARK: - M10.8: Import Step Editing Helpers

    /// Binding for buffered step text edits (import view)
    private func importStepTextBinding(index: Int, original: String) -> Binding<String> {
        Binding(
            get: { editedSteps[index] ?? original },
            set: { editedSteps[index] = $0 }
        )
    }

    /// Commit a single step edit to the draft's instructions
    private func commitImportStepEdit(index: Int) {
        guard let editedText = editedSteps[index] else { return }
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)

        var steps = instructionSteps
        guard index < steps.count else { return }

        if trimmed.isEmpty {
            steps.remove(at: index)
        } else {
            steps[index] = trimmed
        }

        draft.instructions.value = steps.joined(separator: "\n")
        draft.instructions.wasEdited = true
        editedSteps.removeValue(forKey: index)
    }

    /// Add a new step to the draft instructions
    private func addImportStep() {
        let placeholder = "New step"
        var steps = instructionSteps
        steps.append(placeholder)
        draft.instructions.value = steps.joined(separator: "\n")
        draft.instructions.wasEdited = true

        let newIndex = steps.count - 1
        editedSteps[newIndex] = ""
        showAllSteps = true
        editingStepIndex = newIndex
    }

    /// Delete a step from the draft instructions
    private func deleteImportStep(at index: Int) {
        var steps = instructionSteps
        guard index < steps.count else { return }
        steps.remove(at: index)
        draft.instructions.value = steps.joined(separator: "\n")
        draft.instructions.wasEdited = true
        editedSteps.removeAll()
        editingStepIndex = nil
    }

    // MARK: - Image Preview

    private func imagePreview(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
            case .failure:
                EmptyView()
            default:
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                    .fill(ForagerTheme.backgroundTertiary)
                    .frame(height: 200)
                    .overlay(ProgressView())
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        Group {
            if draft.author.value != nil || draft.cuisine != nil || draft.category != nil {
                VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
                    if let author = draft.author.value {
                        metadataRow(icon: "person", text: author)
                    }
                    if let cuisine = draft.cuisine {
                        metadataRow(icon: "fork.knife", text: cuisine)
                    }
                    if let category = draft.category {
                        metadataRow(icon: "tag", text: category)
                    }
                }
                .padding(ForagerTheme.Spacing.md)
                .background(ForagerTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
            }
        }
    }

    private func metadataRow(icon: String, text: String) -> some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(ForagerTheme.textTertiary)
                .frame(width: 20)
            Text(text)
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
    }

    // MARK: - Section Header

    /// Left-aligned section header with optional trailing pencil edit icon.
    private func sectionHeader(label: String, showEditIcon: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(ForagerTheme.bodyFont.weight(.bold))
                .foregroundStyle(ForagerTheme.textPrimary)
            Spacer()
            if showEditIcon {
                Image(systemName: "pencil")
                    .font(.body)
                    .foregroundStyle(ForagerTheme.accentPrimary)
            }
        }
        .padding(.top, ForagerTheme.Spacing.sm)
    }

    // MARK: - Confidence Indicators

    /// Confidence indicator dot: green (high), amber (medium), red (low), gray (missing)
    private func confidenceDot(_ confidence: ImportConfidence) -> some View {
        Circle()
            .fill(confidenceColor(confidence))
            .frame(width: 8, height: 8)
    }

    private func confidenceColor(_ confidence: ImportConfidence) -> Color {
        switch confidence {
        case .high: return ForagerTheme.statusSuccessFG
        case .medium: return ForagerTheme.statusWarningFG
        case .low: return ForagerTheme.statusDangerFG
        case .missing: return ForagerTheme.borderDefault
        }
    }
}
