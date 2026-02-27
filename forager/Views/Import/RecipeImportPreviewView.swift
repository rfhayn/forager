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
    /// Also applies any user name edits to the draft's ingredient list.
    private func saveWithCategories() {
        // Apply name edits to draft ingredient texts
        for (index, editedName) in editedIngredientNames {
            guard index < draft.ingredients.value.count else { continue }
            let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // Reconstruct: keep original qty portion, replace name
                let originalText = draft.ingredients.value[index]
                let parts = splitIngredientText(originalText)
                if let qty = parts.qty {
                    draft.ingredients.value[index] = "\(qty) \(trimmed)"
                } else {
                    draft.ingredients.value[index] = trimmed
                }
            }
        }

        // Build category map keyed by parsed name
        var nameToCategory: [String: String] = [:]
        for (index, category) in categoryAssignments {
            // Use edited name if available, otherwise the original match info
            let parsedName: String
            if let editedName = editedIngredientNames[index] {
                let parsed = parsingService.parseIngredient(text: editedName)
                parsedName = parsed.displayName.lowercased()
            } else if let info = ingredientMatches[index] {
                parsedName = info.parsedName.lowercased()
            } else {
                continue
            }
            nameToCategory[parsedName] = category
        }
        onSave(draft, nameToCategory)
    }

    // MARK: - Ingredient Name Editing

    /// Binding for editable ingredient name at a given index.
    /// Lazily initializes from the original text's name portion.
    private func ingredientNameBinding(index: Int, original: String) -> Binding<String> {
        Binding(
            get: { editedIngredientNames[index] ?? original },
            set: { editedIngredientNames[index] = $0 }
        )
    }

    /// Re-run parsing + template matching for a single edited ingredient.
    private func reMatchIngredient(index: Int) {
        guard let editedName = editedIngredientNames[index] else { return }
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
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
            sectionHeader(label: "Ingredients", showEditIcon: false)

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

    /// Per-ingredient bordered card row with inline category picker
    private func ingredientRow(index: Int, text: String, confidence: ImportConfidence, matchInfo: IngredientMatchInfo?) -> some View {
        let isLowConfidence = confidence == .low || confidence == .medium
        let hasCategory = categoryAssignments[index] != nil && !(categoryAssignments[index]?.isEmpty ?? true)

        return HStack(spacing: ForagerTheme.Spacing.sm) {
            // Status indicator
            if hasCategory {
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

            // Ingredient name (editable) + category picker
            VStack(alignment: .leading, spacing: 2) {
                let parts = splitIngredientText(text)
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    if let qty = parts.qty {
                        Text(qty)
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .monospacedDigit()
                    }

                    TextField("Ingredient name", text: ingredientNameBinding(index: index, original: parts.name))
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(isLowConfidence ? ForagerTheme.statusWarningFG : ForagerTheme.textPrimary)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { reMatchIngredient(index: index) }
                }

                // Inline category picker
                inlineCategoryPicker(index: index)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(isLowConfidence ? ForagerTheme.surfaceWarning : ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(isLowConfidence ? ForagerTheme.statusWarningFG : ForagerTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
    }

    /// Compact inline Menu for category selection per ingredient
    private func inlineCategoryPicker(index: Int) -> some View {
        Menu {
            Button(action: { categoryAssignments[index] = nil }) {
                Label("Uncategorized", systemImage: "circle")
            }
            ForEach(realCategories, id: \.objectID) { category in
                Button(action: { categoryAssignments[index] = category.displayName }) {
                    Label {
                        Text(category.displayName)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(ForagerTheme.categoryColor(for: category.displayName))
                    }
                }
            }
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
    }

    /// Split "2 1/4 cups all-purpose flour" → (qty: "2 1/4 cups", name: "all-purpose flour")
    private func splitIngredientText(_ text: String) -> (qty: String?, name: String) {
        // Match leading quantity: digits, fractions, spaces, and unit words
        let pattern = #"^([\d½⅓⅔¼¾⅛⅜⅝⅞/\s]+(?:cups?|cup|tbsp|tsp|tablespoons?|teaspoons?|oz|ounces?|lbs?|pounds?|g|kg|ml|l|liters?|quarts?|pints?|gallons?|cloves?|cans?|packages?|large|medium|small|whole|pinch(?:es)?)\b)\s*(.+)"#
        if let match = text.range(of: pattern, options: .regularExpression, range: text.startIndex..<text.endIndex) {
            let fullMatch = String(text[match])
            if let nameRange = fullMatch.range(of: pattern, options: .regularExpression) {
                // Use NSRegularExpression for capture groups
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let nsString = text as NSString
                    if let result = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsString.length)),
                       result.numberOfRanges >= 3 {
                        let qty = nsString.substring(with: result.range(at: 1)).trimmingCharacters(in: .whitespaces)
                        let name = nsString.substring(with: result.range(at: 2)).trimmingCharacters(in: .whitespaces)
                        return (qty, name)
                    }
                }
                _ = nameRange // suppress warning
            }
        }
        return (nil, text)
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            sectionHeader(label: "Instructions", showEditIcon: true)

            if instructionSteps.isEmpty {
                Text("No instructions extracted")
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .italic()
            } else {
                let stepsToShow = showAllSteps
                    ? instructionSteps
                    : Array(instructionSteps.prefix(collapsedStepCount))

                ForEach(Array(stepsToShow.enumerated()), id: \.offset) { index, step in
                    instructionStep(number: index + 1, text: step)
                }

                // "Show all N steps" collapse link
                if instructionSteps.count > collapsedStepCount {
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
        }
    }

    /// Numbered step circle (24px accent tint) + step text
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: ForagerTheme.Spacing.md) {
            Text("\(number)")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.accentPrimary)
                .frame(width: 24, height: 24)
                .background(ForagerTheme.accentTint)
                .clipShape(Circle())

            Text(text)
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, ForagerTheme.Spacing.xs)
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
