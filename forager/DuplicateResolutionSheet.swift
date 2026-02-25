//
//  DuplicateResolutionSheet.swift
//  forager
//
//  Created for M10.1.4: Import preview UI
//  Modal dialog when a duplicate recipe is detected during import.
//  Options: Import as New, Cancel.
//

import SwiftUI

// MARK: - Duplicate Resolution Sheet

/// Modal dialog shown when the import orchestrator detects a potential duplicate.
/// Presents the match type (exact URL or fuzzy title) and offers resolution options.
struct DuplicateResolutionSheet: View {
    let duplicateResult: DuplicateResult
    let onImportAsNew: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.xl) {
                Spacer()

                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ForagerTheme.statusWarningFG)

                Text("Possible Duplicate")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)

                Text(duplicateDescription)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ForagerTheme.Spacing.lg)

                VStack(spacing: ForagerTheme.Spacing.md) {
                    Button(action: {
                        dismiss()
                        onImportAsNew()
                    }) {
                        Text("Import as New Recipe")
                            .font(ForagerTheme.bodyFont.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ForagerTheme.accentPrimary)

                    Button(action: {
                        dismiss()
                        onCancel()
                    }) {
                        Text("Cancel Import")
                            .font(ForagerTheme.bodyFont)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForagerTheme.Spacing.md)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, ForagerTheme.Spacing.lg)

                Spacer()
            }
            .padding(ForagerTheme.Spacing.lg)
            .navigationTitle("Duplicate Found")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var duplicateDescription: String {
        switch duplicateResult {
        case .exactURL:
            return "A recipe from this exact URL already exists in your collection."
        case .fuzzyTitle(_, let title, _):
            return "A recipe with a similar title already exists: \"\(title)\""
        }
    }
}
