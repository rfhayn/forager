//
//  RecipeImportPreviewView.swift
//  forager
//
//  Created for M10.1.4: Import preview UI
//  Shows extracted recipe fields with confidence dots (green/amber/red).
//  Inline editing for all fields. Shared across all import phases (URL/Text/Photo).
//

import SwiftUI

// MARK: - Recipe Import Preview View

/// Preview of an extracted recipe with per-field confidence indicators.
/// Users can inline-edit any field before saving. Warning banner shows
/// for partial extractions where core fields are missing.
struct RecipeImportPreviewView: View {
    @State var draft: ImportDraftRecipe
    @ObservedObject var importService: RecipeImportService
    let onSave: (ImportDraftRecipe) -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                // Warning banner for partial extractions
                if draft.successLevel == .partial {
                    partialExtractionBanner
                }

                // Image preview
                if let imageURL = draft.imageURL.value,
                   let url = URL(string: imageURL) {
                    imagePreview(url: url)
                }

                // Source attribution
                if let sourceURL = draft.sourceURL,
                   let host = URL(string: sourceURL)?.host {
                    sourceAttribution(host: host)
                }

                // Fields
                titleSection
                ingredientsSection
                instructionsSection
                timesSection
                servingsSection
                metadataSection
            }
            .padding(ForagerTheme.Spacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
    }

    // MARK: - Partial Extraction Banner

    private var partialExtractionBanner: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ForagerTheme.statusWarningFG)
            VStack(alignment: .leading, spacing: 2) {
                Text("Partial extraction")
                    .font(ForagerTheme.footnoteFont)
                    .foregroundStyle(ForagerTheme.statusWarningFG)
                Text("Missing: \(draft.fieldsMissing.joined(separator: ", ")). Fill in before saving.")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            Spacer()
        }
        .padding(ForagerTheme.Spacing.md)
        .background(ForagerTheme.statusWarningBG.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.md))
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

    // MARK: - Source Attribution

    private func sourceAttribution(host: String) -> some View {
        HStack(spacing: ForagerTheme.Spacing.xs) {
            Image(systemName: "link")
                .font(.caption)
            Text("From \(host)")
                .font(ForagerTheme.captionFont)
        }
        .foregroundStyle(ForagerTheme.textTertiary)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        fieldSection(label: "Title", confidence: draft.title.confidence) {
            TextField("Recipe title", text: $draft.title.value)
                .font(ForagerTheme.cardTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: draft.title.value) { _, _ in
                    draft.title.wasEdited = true
                }
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        fieldSection(label: "Ingredients (\(draft.ingredients.value.count))", confidence: draft.ingredients.confidence) {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                ForEach(draft.ingredients.value.indices, id: \.self) { index in
                    HStack {
                        Text("\(index + 1).")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                            .frame(width: 24, alignment: .trailing)
                        Text(draft.ingredients.value[index])
                            .font(ForagerTheme.bodyFont)
                            .foregroundStyle(ForagerTheme.textPrimary)
                    }
                }
            }
            .padding(ForagerTheme.Spacing.md)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        fieldSection(label: "Instructions", confidence: draft.instructions.confidence) {
            Text(draft.instructions.value.isEmpty ? "No instructions extracted" : draft.instructions.value)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(draft.instructions.value.isEmpty ? ForagerTheme.textTertiary : ForagerTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ForagerTheme.Spacing.md)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        }
    }

    // MARK: - Times Section

    private var timesSection: some View {
        HStack(spacing: ForagerTheme.Spacing.lg) {
            timeField(label: "Prep", value: draft.prepTimeMinutes.value, confidence: draft.prepTimeMinutes.confidence)
            timeField(label: "Cook", value: draft.cookTimeMinutes.value, confidence: draft.cookTimeMinutes.confidence)
        }
    }

    private func timeField(label: String, value: Int?, confidence: ImportConfidence) -> some View {
        fieldSection(label: label, confidence: confidence) {
            Text(value.map { "\($0) min" } ?? "—")
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(value != nil ? ForagerTheme.textPrimary : ForagerTheme.textTertiary)
        }
    }

    // MARK: - Servings Section

    private var servingsSection: some View {
        fieldSection(label: "Servings", confidence: draft.servings.confidence) {
            Text("\(draft.servings.value)")
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textPrimary)
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
                .background(Color(.systemGray6))
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

    // MARK: - Save Bar

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: ForagerTheme.Spacing.md) {
                Button("Cancel", role: .cancel) { onCancel() }
                    .buttonStyle(.bordered)

                Button(action: { onSave(draft) }) {
                    Text("Save Recipe")
                        .font(ForagerTheme.bodyFont.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
                .disabled(draft.successLevel == .failure)
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Field Section Helper

    private func fieldSection<Content: View>(
        label: String,
        confidence: ImportConfidence,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                Text(label)
                    .font(ForagerTheme.footnoteFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                confidenceDot(confidence)
            }
            content()
        }
    }

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
