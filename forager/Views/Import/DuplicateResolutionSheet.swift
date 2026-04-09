//
//  DuplicateResolutionSheet.swift
//  forager
//
//  Created for M10.1.4: Import preview UI
//  Modal dialog when a duplicate recipe is detected during import.
//  Options: Import as New, Replace Existing, Cancel.
//  Wireframe screen 4 alignment (M10.1).
//

import SwiftUI

// MARK: - Duplicate Resolution Sheet

/// Modal dialog shown when the import orchestrator detects a potential duplicate.
/// Presents the match type (exact URL or fuzzy title) and offers three resolution options:
/// Import as New, Replace Existing (in-place update preserving relationships), or Cancel.
struct DuplicateResolutionSheet: View {
    let duplicateResult: DuplicateResult
    let onImportAsNew: () -> Void
    let onReplaceExisting: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.xl) {
                Spacer()

                // Duplicate icon — warning circle with document-copy symbol
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ForagerTheme.statusWarningFG)

                Text("Similar Recipe Found")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)

                Text(duplicateDescription)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ForagerTheme.Spacing.lg)

                // Three stacked buttons (wireframe screen 4: all outlined style)
                VStack(spacing: ForagerTheme.Spacing.sm) {
                    Button(action: {
                        dismiss()
                        onImportAsNew()
                    }) {
                        Text("Import as New Recipe")
                            .font(ForagerTheme.bodyFont.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                    }
                    .buttonStyle(.bordered)
                    .tint(ForagerTheme.accentPrimary)

                    Button(action: {
                        dismiss()
                        onReplaceExisting()
                    }) {
                        Text("Replace Existing")
                            .font(ForagerTheme.bodyFont.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                    }
                    .buttonStyle(.bordered)
                    .tint(ForagerTheme.accentPrimary)

                    Button(action: {
                        dismiss()
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(ForagerTheme.bodyFont)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ForagerTheme.textSecondary)
                }
                .padding(.horizontal, ForagerTheme.Spacing.lg)

                Spacer()
            }
            .padding(ForagerTheme.Spacing.lg)
            .navigationTitle("Similar Recipe Found")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents(ProcessInfo.processInfo.isiOSAppOnMac ? [.large] : [.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Description

    private var duplicateDescription: String {
        switch duplicateResult {
        case .exactURL:
            return "A recipe from this exact URL already exists in your collection."
        case .fuzzyTitle(_, let title, _):
            return "You already have \"\(title)\" in your collection."
        }
    }
}
