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
    let onSave: (ImportDraftRecipe) -> Void
    let onCancel: () -> Void

    @State private var showAllSteps = false

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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { onSave(draft) }
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

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            sectionHeader(label: "Ingredients", showEditIcon: true)

            ForEach(draft.ingredients.value.indices, id: \.self) { index in
                ingredientRow(text: draft.ingredients.value[index], confidence: draft.ingredients.confidence)
            }
        }
    }

    /// Per-ingredient bordered card row: [confidence dot] [qty] [name]
    private func ingredientRow(text: String, confidence: ImportConfidence) -> some View {
        let isLowConfidence = confidence == .low || confidence == .medium

        return HStack(spacing: ForagerTheme.Spacing.sm) {
            confidenceDot(confidence)

            // Split ingredient text into qty and name portions
            let parts = splitIngredientText(text)
            if let qty = parts.qty {
                Text(qty)
                    .font(ForagerTheme.footnoteFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 48, alignment: .leading)
            }

            Text(parts.name)
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(isLowConfidence ? ForagerTheme.statusWarningFG : ForagerTheme.textPrimary)
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
