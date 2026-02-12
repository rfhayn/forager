//
//  MigrationDebugView.swift
//  forager
//
//  Created for M3 Phase 3: Migration UI
//  Debug view to trigger and monitor quantity migration
//

import SwiftUI
import CoreData

struct MigrationDebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var migrationService: QuantityMigrationService
    
    @State private var showingPreview = false
    @State private var migrationPreview: MigrationPreview?
    @State private var migrationSummary: MigrationSummary?
    @State private var isMigrating = false
    
    init(context: NSManagedObjectContext) {
        _migrationService = StateObject(wrappedValue: QuantityMigrationService(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Preview Section
                    if let preview = migrationPreview {
                        previewSection(preview)
                    }
                    
                    // Migration Controls
                    migrationControls
                    
                    // Results Section
                    if let summary = migrationSummary {
                        resultsSection(summary)
                    }
                    
                    // Progress Section
                    if isMigrating {
                        progressSection
                    }
                }
                .padding()
            }
            .navigationTitle("Quantity Migration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("M3: Structured Quantities")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This migration will parse existing quantity data and populate structured fields for recipe scaling and smart consolidation.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func previewSection(_ preview: MigrationPreview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Migration Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Summary Stats
            VStack(spacing: 8) {
                HStack {
                    Text("Total Items:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(preview.totalToMigrate)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Estimated Success Rate:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(preview.estimatedSuccessRate * 100))%")
                        .fontWeight(.medium)
                        .foregroundColor(preview.estimatedSuccessRate > 0.8 ? .green : .orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Sample Previews
            if !preview.sampleIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample Ingredients:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(preview.sampleIngredients.prefix(3), id: \.0) { sample in
                        sampleRow(original: sample.0, structured: sample.1)
                    }
                }
            }
            
            if !preview.sampleGroceryItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample Grocery Items:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(preview.sampleGroceryItems.prefix(3), id: \.0) { sample in
                        sampleRow(original: sample.0, structured: sample.1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func sampleRow(original: String, structured: StructuredQuantity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(original)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if structured.isParseable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            if let numericValue = structured.numericValue {
                Text("→ \(numericValue, specifier: "%.2f") \(structured.standardUnit ?? "")")
                    .font(.caption2)
                    .foregroundColor(.blue)
            } else {
                Text("→ Text-only (no numeric value)")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var migrationControls: some View {
        VStack(spacing: 12) {
            // Preview Button
            Button(action: {
                migrationPreview = migrationService.getMigrationPreview()
                showingPreview = true
            }) {
                HStack {
                    Image(systemName: "eye")
                    Text("Preview Migration")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isMigrating)
            
            // Migrate Button
            Button(action: {
                executeMigration()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Execute Migration")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isMigrating ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isMigrating || migrationService.isComplete)
            
            // Validate Button (shows after migration)
            if migrationService.isComplete {
                Button(action: {
                    validateMigration()
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Text("Validate Results")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func resultsSection(_ summary: MigrationSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Migration Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                resultRow(
                    icon: "list.bullet",
                    label: "Total Items",
                    value: "\(summary.totalItems)",
                    color: .blue
                )
                
                resultRow(
                    icon: "checkmark.circle.fill",
                    label: "Successful",
                    value: "\(summary.totalSuccessful) (\(Int(summary.successRate * 100))%)",
                    color: .green
                )
                
                resultRow(
                    icon: "exclamationmark.triangle.fill",
                    label: "Failed",
                    value: "\(summary.totalFailed)",
                    color: summary.totalFailed > 0 ? .orange : .secondary
                )
                
                Divider()
                
                resultRow(
                    icon: "leaf",
                    label: "Ingredients",
                    value: "\(summary.ingredientsSuccessful)/\(summary.totalIngredients)",
                    color: .purple
                )
                
                resultRow(
                    icon: "cart",
                    label: "Grocery Items",
                    value: "\(summary.groceryItemsSuccessful)/\(summary.totalGroceryItems)",
                    color: .indigo
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Success message
            if summary.successRate >= 0.8 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Migration successful! Ready for recipe scaling and smart consolidation.")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func resultRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: migrationService.migrationProgress) {
                Text(migrationService.currentStatus)
                    .font(.subheadline)
            }
            .progressViewStyle(.linear)
            
            Text("\(Int(migrationService.migrationProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func executeMigration() {
        isMigrating = true
        
        Task {
            let summary = await migrationService.migrateAllQuantities()
            
            await MainActor.run {
                self.migrationSummary = summary
                self.isMigrating = false
            }
        }
    }
    
    private func validateMigration() {
        let validation = migrationService.validateMigration()
        
        if validation.isValid {
            #if DEBUG
            print("✅ Validation passed!")
            #endif
        } else {
            #if DEBUG
            print("⚠️ Validation issues found:")
            #endif
            for issue in validation.issues {
                #if DEBUG
                print("  - \(issue)")
                #endif
            }
        }
    }
}

#Preview {
    MigrationDebugView(context: PersistenceController.preview.container.viewContext)
}
