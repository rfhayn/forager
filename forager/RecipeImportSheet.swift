//
//  RecipeImportSheet.swift
//  forager
//
//  Created for M10.1.4: Import preview UI
//  Entry point sheet for recipe import. URL input → loading → preview → save.
//  Expanded in M10.2/M10.3 for "Text" and "Photo" import modes.
//

import SwiftUI
import CoreData

// MARK: - Recipe Import Sheet

/// Entry point sheet for importing recipes from URLs.
/// State-driven content switches between URL input, loading, preview, and error states.
struct RecipeImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var importService: RecipeImportService

    @State private var urlText = ""
    @State private var showingDuplicateSheet = false
    @State private var duplicateResult: DuplicateResult?
    @FocusState private var urlFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                switch importService.state {
                case .idle, .received:
                    urlInputView

                case .fetching, .extracting:
                    loadingView

                case .needsReview(let draft):
                    RecipeImportPreviewView(
                        draft: draft,
                        importService: importService,
                        onSave: { handleSave(draft: $0) },
                        onCancel: { handleCancel() }
                    )

                case .saving:
                    savingView

                case .saved:
                    successView

                case .failed(let error):
                    errorView(error)
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !importService.state.isLoading && !importService.state.isReviewing {
                        Button("Cancel") { handleCancel() }
                    }
                }
            }
            .sheet(isPresented: $showingDuplicateSheet) {
                if let duplicate = duplicateResult {
                    DuplicateResolutionSheet(
                        duplicateResult: duplicate,
                        onImportAsNew: { saveWithoutDuplicateCheck() },
                        onReplaceExisting: { replaceExistingWithDraft() },
                        onCancel: { showingDuplicateSheet = false }
                    )
                }
            }
        }
    }

    // MARK: - URL Input View

    private var urlInputView: some View {
        VStack(spacing: ForagerTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "link.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(ForagerTheme.accentSecondary)

            Text("Paste a recipe URL")
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)

            Text("We'll extract the recipe details automatically")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: ForagerTheme.Spacing.sm) {
                TextField("https://example.com/recipe...", text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($urlFieldFocused)
                    .submitLabel(.go)
                    .onSubmit { startImport() }

                Button(action: startImport) {
                    Text("Import Recipe")
                        .font(ForagerTheme.bodyFont.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ForagerTheme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
                .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)

            Spacer()
            Spacer()
        }
        .padding(ForagerTheme.Spacing.lg)
        .onAppear { urlFieldFocused = true }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, ForagerTheme.Spacing.md)

            Text(importService.state.statusMessage)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textSecondary)

            Spacer()
        }
    }

    // MARK: - Saving View

    private var savingView: some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Saving recipe...")
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ForagerTheme.statusSuccessFG)

            Text("Recipe Saved!")
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(_ error: ImportError) -> some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ForagerTheme.statusWarningFG)

            Text(error.userMessage)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ForagerTheme.Spacing.lg)

            HStack(spacing: ForagerTheme.Spacing.md) {
                if error.isRetryable {
                    Button("Retry") { startImport() }
                        .buttonStyle(.borderedProminent)
                        .tint(ForagerTheme.accentPrimary)
                }

                Button("Try Different URL") {
                    importService.cancelImport()
                    urlText = ""
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func startImport() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else {
            // Try adding https:// if no scheme
            if let url = URL(string: "https://\(trimmed)") {
                Task { await importService.importFromURL(url) }
            }
            return
        }
        Task { await importService.importFromURL(url) }
    }

    private func handleSave(draft: ImportDraftRecipe) {
        // Check for duplicates first
        if let duplicate = importService.checkDuplicate(for: draft) {
            duplicateResult = duplicate
            showingDuplicateSheet = true
        } else {
            let _ = importService.saveImport(from: draft)
        }
    }

    private func saveWithoutDuplicateCheck() {
        showingDuplicateSheet = false
        if case .needsReview(let draft) = importService.state {
            let _ = importService.saveImport(from: draft)
        }
    }

    private func replaceExistingWithDraft() {
        showingDuplicateSheet = false
        guard case .needsReview(let draft) = importService.state,
              let duplicate = duplicateResult else { return }

        let existingID: NSManagedObjectID
        switch duplicate {
        case .exactURL(let objectID):
            existingID = objectID
        case .fuzzyTitle(let objectID, _, _):
            existingID = objectID
        }

        let _ = importService.replaceExistingRecipe(objectID: existingID, with: draft)
    }

    private func handleCancel() {
        importService.cancelImport()
        dismiss()
    }
}
