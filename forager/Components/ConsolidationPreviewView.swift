//
//  ConsolidationPreviewView.swift
//  forager
//
//  M3 Phase 5: Consolidation Preview with Unit Conversion Support
//

import SwiftUI

struct ConsolidationPreviewView: View {
    @Environment(\.dismiss) var dismiss
    
    let analysis: MergeAnalysis
    let mergeService: QuantityMergeService
    let onComplete: () -> Void
    
    @State private var isExecuting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Summary section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.triangle.merge")
                                .foregroundStyle(ForagerTheme.accentSecondary)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(analysis.summary)
                                    .font(.headline)
                                
                                Text("Review changes below before applying")
                                    .font(.caption)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Merge groups
                ForEach(analysis.groups) { group in
                    Section(header: groupHeader(group)) {
                        ForEach(group.mergedItems) { item in
                            mergedItemRow(item)
                        }
                    }
                }
            }
            .navigationTitle("Consolidate Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        executeConsolidation()
                    } label: {
                        if isExecuting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Apply")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isExecuting)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Builders
    
    private func groupHeader(_ group: MergeGroup) -> some View {
        HStack {
            Text(group.ingredientName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(group.originalCount) → \(group.resultCount) items")
                .font(.caption)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
    }
    
    private func mergedItemRow(_ item: MergedItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: item.isMerged ? "arrow.triangle.merge" : "minus.circle")
                .foregroundStyle(item.isMerged ? ForagerTheme.statusSuccessFG : ForagerTheme.textTertiary)
                .font(.title3)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Display text — quantities render in the mono price-tag role
                Text(item.displayText.displayingKitchenFractions)
                    .font(ForagerTheme.quantityFontLarge)
                    .fontWeight(item.isMerged ? .semibold : .regular)
                
                // Merge info
                if item.isMerged && item.sourceCount > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ForagerTheme.statusSuccessFG)
                            .font(.caption)
                        
                        if item.isConverted {
                            Text("Merged from \(item.sourceCount) items (with unit conversion)")
                                .font(.caption)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        } else {
                            Text("Merged from \(item.sourceCount) items")
                                .font(.caption)
                                .foregroundStyle(ForagerTheme.textSecondary)
                        }
                    }
                }
                
                // Conversion indicator
                if item.isMerged && item.isConverted {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(ForagerTheme.statusInfoFG)
                            .font(.caption)
                        Text("Units converted for combination")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.statusInfoFG)
                    }
                }
                
                // Sources
                if !item.sources.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(ForagerTheme.accentSecondary)
                            .font(.caption2)
                        Text("Sources: \(formatSources(item.sources))")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private func formatSources(_ sources: [String]) -> String {
        let uniqueSources = Array(Set(sources)).sorted()
        
        if uniqueSources.count <= 3 {
            return uniqueSources.joined(separator: ", ")
        } else {
            let first = uniqueSources.prefix(2).joined(separator: ", ")
            return "\(first), +\(uniqueSources.count - 2) more"
        }
    }
    
    // MARK: - Actions
    
    private func executeConsolidation() {
        isExecuting = true
        
        do {
            try mergeService.executeMerge(analysis: analysis)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
                onComplete()
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isExecuting = false
        }
    }
}
