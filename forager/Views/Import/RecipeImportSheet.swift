//
//  RecipeImportSheet.swift
//  forager
//
//  Created for M10.1.4: Import preview UI
//  Entry point sheet for recipe import. URL input → loading → preview → save.
//  M10.2: Added text paste import mode alongside URL.
//

import SwiftUI
import CoreData

// MARK: - Import Mode

/// Determines which initial input view the import sheet shows
enum ImportMode {
    case url
    case text
    case photo
}

// MARK: - Recipe Import Sheet

/// Entry point sheet for importing recipes from URLs or pasted text.
/// State-driven content switches between input, loading, preview, and error states.
struct RecipeImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var importService: RecipeImportService

    let mode: ImportMode
    // M10.6.13: Callback invoked when save completes — used by RecipeBrowserView
    // to track save success before the sheet dismisses
    var onSaveComplete: (() -> Void)?

    @State private var urlText = ""
    @State private var showingDuplicateSheet = false
    @State private var duplicateResult: DuplicateResult?
    @State private var showingCategoryAssignment = false
    @State private var uncategorizedTemplates: [IngredientTemplate] = []
    /// Category assignments from inline preview pickers (ingredient index → category)
    @State private var pendingCategoryAssignments: [Int: String] = [:]
    @FocusState private var urlFieldFocused: Bool

    init(importService: RecipeImportService, mode: ImportMode = .url, onSaveComplete: (() -> Void)? = nil) {
        self.importService = importService
        self.mode = mode
        self.onSaveComplete = onSaveComplete
    }

    var body: some View {
        NavigationStack {
            Group {
                switch importService.state {
                case .idle, .received:
                    switch mode {
                    case .url:
                        urlInputView
                    case .text:
                        TextPasteImportView(importService: importService)
                    case .photo:
                        PhotoImportView(importService: importService)
                    }

                case .fetching, .extracting:
                    loadingView

                case .needsReview(let draft):
                    RecipeImportPreviewView(
                        draft: draft,
                        importService: importService,
                        onSave: { handleSave(draft: $0, categoryAssignments: $1) },
                        onCancel: { handleCancel() }
                    )

                case .saving:
                    savingView

                case .saved:
                    // Save completed — handleSave controls dismiss/category flow
                    // Show nothing while post-save logic (category assignment or dismiss) runs
                    Color.clear

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
            .sheet(isPresented: $showingCategoryAssignment) {
                if !uncategorizedTemplates.isEmpty {
                    CategoryAssignmentModal(
                        uncategorizedTemplates: uncategorizedTemplates,
                        onAssignmentsComplete: {
                            showingCategoryAssignment = false
                            uncategorizedTemplates = []
                            dismissAfterSave()
                        }
                    )
                    .interactiveDismissDisabled(!ProcessInfo.processInfo.isiOSAppOnMac)
                    .environment(\.managedObjectContext, viewContext)
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

    // MARK: - Error View (Wireframe Screen 5)

    @ViewBuilder
    private func errorView(_ error: ImportError) -> some View {
        switch error {
        case .paywallDetected:
            paywallErrorView(error)
        case .noRecipeFound:
            noRecipeErrorView(error)
        case .networkError, .timeout:
            networkErrorView(error)
        default:
            genericErrorView(error)
        }
    }

    private func paywallErrorView(_ error: ImportError) -> some View {
        errorLayout(
            icon: error.errorIcon,
            iconColor: ForagerTheme.statusWarningFG,
            circleBG: ForagerTheme.surfaceWarning,
            title: error.errorTitle,
            body: "We extracted what we could from this page."
        ) {
            Button(action: {
                if let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    openURL(url)
                }
            }) {
                Label("Open in Safari", systemImage: "safari")
            }
            .buttonStyle(.borderedProminent)
            .tint(ForagerTheme.accentPrimary)

            tryAgainButton
        }
    }

    private func noRecipeErrorView(_ error: ImportError) -> some View {
        errorLayout(
            icon: error.errorIcon,
            iconColor: ForagerTheme.statusInfoFG,
            circleBG: ForagerTheme.surfaceAccent,
            title: error.errorTitle,
            body: mode == .text
                ? "We couldn't identify a recipe in this text. Try including clear ingredient lines."
                : "We couldn't find a recipe on this page."
        ) {
            if mode == .url {
                Button("Try Pasting Recipe Text") {
                    importService.cancelImport()
                    dismiss()
                    // User should use the "Paste Recipe Text" menu option
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
            }

            tryAgainButton
        }
    }

    private func networkErrorView(_ error: ImportError) -> some View {
        errorLayout(
            icon: error.errorIcon,
            iconColor: ForagerTheme.statusDangerFG,
            circleBG: ForagerTheme.surfaceDanger,
            title: error.errorTitle,
            body: "Check your connection and try again."
        ) {
            Button("Try Again") { startImport() }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)

            tryAgainButton
        }
    }

    private func genericErrorView(_ error: ImportError) -> some View {
        errorLayout(
            icon: error.errorIcon,
            iconColor: ForagerTheme.statusWarningFG,
            circleBG: ForagerTheme.surfaceWarning,
            title: error.errorTitle,
            body: error.userMessage
        ) {
            if error.isRetryable {
                Button("Retry") { startImport() }
                    .buttonStyle(.borderedProminent)
                    .tint(ForagerTheme.accentPrimary)
            }

            tryAgainButton
        }
    }

    // MARK: - Error Layout Template

    /// Shared layout for all error presentations (wireframe screen 5 pattern):
    /// Icon in colored circle → Title → Body → Action buttons
    private func errorLayout<Actions: View>(
        icon: String,
        iconColor: Color,
        circleBG: Color,
        title: String,
        body: String,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(circleBG)
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)

            Text(body)
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ForagerTheme.Spacing.lg)

            VStack(spacing: ForagerTheme.Spacing.sm) {
                actions()
            }

            Spacer()
        }
    }

    /// Context-aware "try again" button — resets to input view
    private var tryAgainButton: some View {
        Button(tryAgainLabel) {
            importService.cancelImport()
            urlText = ""
        }
        .buttonStyle(.bordered)
    }

    private var tryAgainLabel: String {
        switch mode {
        case .url: return "Try Different URL"
        case .text: return "Try Different Text"
        case .photo: return "Try Different Photo"
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

    private func handleSave(draft: ImportDraftRecipe, categoryAssignments: [Int: String]) {
        pendingCategoryAssignments = categoryAssignments
        // Check for duplicates first
        if let duplicate = importService.checkDuplicate(for: draft) {
            duplicateResult = duplicate
            showingDuplicateSheet = true
        } else {
            Task {
                if let result = await importService.saveImport(from: draft, categoryAssignments: pendingCategoryAssignments) {
                    applyCategoryAssignmentsAndFinish(result)
                }
            }
        }
    }

    private func saveWithoutDuplicateCheck() {
        showingDuplicateSheet = false
        if case .needsReview(let draft) = importService.state {
            Task {
                if let result = await importService.saveImport(from: draft, categoryAssignments: pendingCategoryAssignments) {
                    applyCategoryAssignmentsAndFinish(result)
                }
            }
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

        Task {
            if let result = await importService.replaceExistingRecipe(objectID: existingID, with: draft, categoryAssignments: pendingCategoryAssignments) {
                applyCategoryAssignmentsAndFinish(result)
            }
        }
    }

    /// Reset import state and dismiss the sheet
    private func dismissAfterSave() {
        // M10.6.13: Notify caller (e.g. RecipeBrowserView) before state reset
        onSaveComplete?()
        importService.cancelImport()
        dismiss()
    }

    /// M10.6.9: Categories are now applied during save via index-based assignments.
    /// This method handles any remaining uncategorized templates by showing the modal.
    private func applyCategoryAssignmentsAndFinish(_ result: ImportSaveResult) {
        guard !result.uncategorizedTemplateIDs.isEmpty else {
            dismissAfterSave()
            return
        }

        // Resolve templates that still have no category after save
        let stillUncategorized = result.uncategorizedTemplateIDs.compactMap { objectID in
            try? viewContext.existingObject(with: objectID) as? IngredientTemplate
        }

        // If some templates still need categories, show the modal; otherwise dismiss
        if !stillUncategorized.isEmpty {
            uncategorizedTemplates = stillUncategorized
            showingCategoryAssignment = true
        } else {
            dismissAfterSave()
        }
    }

    private func handleCancel() {
        importService.cancelImport()
        dismiss()
    }
}
