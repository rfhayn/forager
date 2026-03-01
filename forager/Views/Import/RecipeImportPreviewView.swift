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

    @State private var showAllSteps = false
    @State private var ingredientMatches: [Int: IngredientMatchInfo] = [:]
    /// User's category selections per ingredient index (inline assignment)
    @State private var categoryAssignments: [Int: String] = [:]
    /// User's ingredient name edits per index (nil = not edited, use original)
    @State private var editedIngredientNames: [Int: String] = [:]
    /// Which ingredient row is currently being edited (nil = none)
    @State private var editingIndex: Int?
    @FocusState private var focusedIngredient: Int?

    // M10.8 Phase 2: Inline instruction editing state
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

    // MARK: - Ingredient Match Model

    /// Per-ingredient match result computed at preview time (read-only lookup)
    private struct IngredientMatchInfo {
        let parsedName: String
        let status: IngredientStatus
        let categoryName: String?
    }

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
            // Sync focus to editing state
            focusedIngredient = newValue
            // M10.8 Phase 2: Mutual exclusion — exit step editing when ingredient editing starts
            if newValue != nil && editingStepIndex != nil {
                commitImportStepEdit(index: editingStepIndex!)
                editingStepIndex = nil
            }
        }
        .onChange(of: focusedIngredient) { _, newValue in
            // When keyboard focus is lost (tapped away), exit edit mode
            if newValue == nil && editingIndex != nil {
                if let idx = editingIndex { reMatchIngredient(index: idx) }
                editingIndex = nil
            }
        }
        // M10.8 Phase 2: Sync focus and commit for instruction step editing
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

    // MARK: - Ingredient Matching (M10.3.8)

    // MARK: - M10.6.6: LLM Parsing Methods

    private func batchLLMParse() async {
        let texts = draft.ingredients.value
        guard !texts.isEmpty else { return }

        isLLMBatchParsing = true

        if let results = await parsingService.parseBatchWithLLM(texts: texts, source: .import_) {
            for (index, (parsed, _)) in results.enumerated() {
                guard index < draft.ingredients.value.count else { break }

                let cleanName = parsed.displayName
                let existingTemplate = templateService.searchTemplates(query: cleanName, limit: 1)
                    .first(where: { $0.name?.lowercased() == cleanName.lowercased() })

                let status: IngredientStatus
                let categoryName: String?
                if let template = existingTemplate {
                    if let category = template.category, !category.isEmpty,
                       category.lowercased() != "uncategorized" {
                        status = .ready
                        categoryName = category
                        categoryAssignments[index] = category
                    } else {
                        status = .needsCategory
                        categoryName = nil
                    }
                } else {
                    status = .needsTemplate
                    categoryName = nil
                }
                ingredientMatches[index] = IngredientMatchInfo(
                    parsedName: cleanName, status: status, categoryName: categoryName
                )
            }
            llmToastMessage = "AI parsed \(results.count) ingredients"
        } else {
            llmToastMessage = "AI parsing unavailable"
        }

        isLLMBatchParsing = false
    }

    private func singleLLMParse(index: Int) async {
        guard index < draft.ingredients.value.count else { return }

        llmParsingIngredients.insert(index)

        let text = editedIngredientNames[index] ?? draft.ingredients.value[index]
        if let (parsed, _) = await parsingService.parseSingleWithLLM(text: text, source: .import_) {
            let cleanName = parsed.displayName
            let existingTemplate = templateService.searchTemplates(query: cleanName, limit: 1)
                .first(where: { $0.name?.lowercased() == cleanName.lowercased() })

            let status: IngredientStatus
            let categoryName: String?
            if let template = existingTemplate {
                if let category = template.category, !category.isEmpty,
                   category.lowercased() != "uncategorized" {
                    status = .ready
                    categoryName = category
                    categoryAssignments[index] = category
                } else {
                    status = .needsCategory
                    categoryName = nil
                }
            } else {
                status = .needsTemplate
                categoryName = nil
            }
            ingredientMatches[index] = IngredientMatchInfo(
                parsedName: cleanName, status: status, categoryName: categoryName
            )
        }

        llmParsingIngredients.remove(index)
    }

    /// Parse each ingredient line, look up existing templates, and pre-fill category assignments.
    private func computeIngredientMatches() {
        var matches: [Int: IngredientMatchInfo] = [:]
        var prefilledCategories: [Int: String] = [:]

        for (index, text) in draft.ingredients.value.enumerated() {
            let parsed = parsingService.parseIngredient(text: text)
            let cleanName = parsed.displayName

            // Look for exact match against existing templates
            let candidates = templateService.searchTemplates(query: cleanName, limit: 5)
            let exactMatch = candidates.first(where: {
                $0.name?.lowercased() == cleanName.lowercased()
            })

            let status: IngredientStatus
            let categoryName: String?

            if let template = exactMatch {
                if let category = template.category, !category.isEmpty,
                   category.lowercased() != "uncategorized" {
                    status = .ready
                    categoryName = category
                    prefilledCategories[index] = category
                } else {
                    status = .needsCategory
                    categoryName = nil
                }
            } else {
                status = .needsTemplate
                categoryName = nil
            }

            matches[index] = IngredientMatchInfo(
                parsedName: cleanName,
                status: status,
                categoryName: categoryName
            )
        }

        ingredientMatches = matches
        // Pre-fill category assignments from matched templates (don't overwrite user edits)
        for (index, category) in prefilledCategories {
            if categoryAssignments[index] == nil {
                categoryAssignments[index] = category
            }
        }
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

        // Build category map keyed by parsed name
        var nameToCategory: [String: String] = [:]
        for (index, category) in categoryAssignments {
            // Parse the current text to get the clean ingredient name
            let text = editedIngredientNames[index] ?? (index < draft.ingredients.value.count ? draft.ingredients.value[index] : "")
            let parsed = parsingService.parseIngredient(text: text)
            nameToCategory[parsed.displayName.lowercased()] = category
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let parsed = parsingService.parseIngredient(text: trimmed)
        let cleanName = parsed.displayName

        let candidates = templateService.searchTemplates(query: cleanName, limit: 5)
        let exactMatch = candidates.first(where: {
            $0.name?.lowercased() == cleanName.lowercased()
        })

        let status: IngredientStatus
        let categoryName: String?

        if let template = exactMatch {
            if let category = template.category, !category.isEmpty,
               category.lowercased() != "uncategorized" {
                status = .ready
                categoryName = category
                // Auto-fill category from match
                categoryAssignments[index] = category
            } else {
                status = .needsCategory
                categoryName = nil
            }
        } else {
            status = .needsTemplate
            categoryName = nil
        }

        ingredientMatches[index] = IngredientMatchInfo(
            parsedName: cleanName,
            status: status,
            categoryName: categoryName
        )
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
                            ClaudeLogo(size: 20)
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

    /// Summary bar: "N matched · N need category · N new"
    private var ingredientMatchSummary: some View {
        // Count based on actual user assignments, not just initial match status
        let categorized = categoryAssignments.values.filter { !$0.isEmpty }.count
        let total = draft.ingredients.value.count
        let uncategorized = total - categorized

        return HStack(spacing: ForagerTheme.Spacing.md) {
            if categorized > 0 {
                Label("\(categorized) categorized", systemImage: "checkmark.circle.fill")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.statusSuccessFG)
            }
            if uncategorized > 0 {
                Label("\(uncategorized) need category", systemImage: "circle")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .padding(.bottom, ForagerTheme.Spacing.xs)
    }

    /// Per-ingredient bordered card row with display/edit toggle.
    /// Display mode: qty + unit in regular text, parsed name bold/accent.
    /// Edit mode (tap): full-line TextField.
    /// Category picker always on its own line below the ingredient.
    private func ingredientRow(index: Int, text: String, confidence: ImportConfidence, matchInfo: IngredientMatchInfo?) -> some View {
        let isLowConfidence = confidence == .low || confidence == .medium
        let hasCategory = categoryAssignments[index] != nil && !(categoryAssignments[index]?.isEmpty ?? true)
        let isEditing = editingIndex == index
        let currentText = editedIngredientNames[index] ?? text

        return VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
            // Top line: status icon + ingredient text
            HStack(spacing: ForagerTheme.Spacing.sm) {
                // Status indicator (M10.6.6: spinner during LLM parse)
                if llmParsingIngredients.contains(index) {
                    ProgressView()
                        .controlSize(.mini)
                } else if hasCategory {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                        .font(.system(size: 14))
                } else if matchInfo != nil {
                    Image(systemName: "circle")
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .font(.system(size: 14))
                } else {
                    confidenceDot(confidence)
                }

                if isEditing {
                    // Edit mode: full-line TextField
                    TextField("Ingredient", text: ingredientTextBinding(index: index, original: text))
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focusedIngredient, equals: index)
                        .onSubmit {
                            reMatchIngredient(index: index)
                            editingIndex = nil
                        }
                } else {
                    // Display mode: formatted text with parsed name highlighted
                    formattedIngredientText(text: currentText, matchInfo: matchInfo)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingIndex = index
                        }
                }
            }

            // Bottom line: category picker button
            categoryLabel(index: index)
                .padding(.leading, 22) // Align under text, past the status icon
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(isLowConfidence ? ForagerTheme.surfaceWarning : ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(isEditing ? ForagerTheme.accentPrimary : (isLowConfidence ? ForagerTheme.statusWarningFG : ForagerTheme.borderSubtle), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .contextMenu {
            // M10.6.6: Per-ingredient LLM parse
            if parsingService.isLLMAvailable {
                Button {
                    Task { await singleLLMParse(index: index) }
                } label: {
                    ClaudeParseLabel()
                }
            }
        }
    }

    /// Format ingredient text with the parsed name highlighted in bold accent color.
    /// Splits the text around the parsed ingredient name: prefix (qty+unit) in secondary, name in bold accent.
    /// If parsed name can't be found as substring, show full text in primary with bold.
    private func formattedIngredientText(text: String, matchInfo: IngredientMatchInfo?) -> Text {
        guard let info = matchInfo else {
            return Text(text)
                .font(ForagerTheme.bodyFont)
                .foregroundColor(ForagerTheme.textPrimary)
        }

        // Try to find parsed name in the text (case-insensitive)
        if let range = text.range(of: info.parsedName, options: .caseInsensitive) {
            let prefix = String(text[text.startIndex..<range.lowerBound])
            let name = String(text[range])
            let suffix = String(text[range.upperBound...])
            return Text(prefix).font(ForagerTheme.bodyFont).foregroundColor(ForagerTheme.textSecondary)
                + Text(name).font(ForagerTheme.bodyFont).bold().foregroundColor(ForagerTheme.accentPrimary)
                + Text(suffix).font(ForagerTheme.bodyFont).foregroundColor(ForagerTheme.textSecondary)
        }

        // Fallback: parsed name doesn't substring-match (OCR artifacts, normalization differences)
        // Show the full text with the parsed name appended in accent for visibility
        return Text(text).font(ForagerTheme.bodyFont).foregroundColor(ForagerTheme.textPrimary)
            + Text(" → ").font(ForagerTheme.captionFont).foregroundColor(ForagerTheme.textDisabled)
            + Text(info.parsedName).font(ForagerTheme.captionFont).bold().foregroundColor(ForagerTheme.accentPrimary)
    }

    /// Category label button that opens the category picker sheet.
    /// Shows colored dot + category name when selected, "Choose Category" when empty.
    private func categoryLabel(index: Int) -> some View {
        Button {
            categoryPickerIndex = index
        } label: {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                if let selected = categoryAssignments[index], !selected.isEmpty {
                    Circle()
                        .fill(ForagerTheme.categoryColor(for: selected))
                        .frame(width: 8, height: 8)
                    Text(selected)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                } else {
                    Text("Choose Category")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

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

    // MARK: - Instructions Section (M10.8 Phase 2: Inline-Editable)

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

    // MARK: - M10.8 Phase 2: Import Step Editing Helpers

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
                    .fill(Color(.systemGray5))
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
        case .missing: return Color(.systemGray4)
        }
    }
}
