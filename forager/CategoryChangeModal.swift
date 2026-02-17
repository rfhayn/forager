// CategoryChangeModal.swift
// UPDATED: Match CategoryAssignmentModal UI design exactly while preserving NSManagedObjectID keys

import SwiftUI
import CoreData

struct CategoryChangeModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    // Data
    let ingredientTemplates: [IngredientTemplate]
    let onAssignmentsComplete: () -> Void

    // FIXED: Use NSManagedObjectID as stable keys but match CategoryAssignmentModal state pattern
    @State private var categoryAssignments: [NSManagedObjectID: String?] = [:]
    @State private var showingAddCategory = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Fetch existing categories
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var allCategories: FetchedResults<Category>

    // M7.6.8: Filter by household scope, then exclude "Uncategorized"
    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }

    private var realCategories: [Category] {
        categories.filter { $0.displayName.lowercased() != "uncategorized" }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section - EXACT MATCH to CategoryAssignmentModal
                headerSection
                
                // Ingredient Assignment List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(ingredientTemplates, id: \.objectID) { template in
                            IngredientChangeRow(
                                template: template,
                                categories: realCategories,
                                selectedCategoryName: categoryAssignments[template.objectID] ?? nil,
                                onCategorySelected: { categoryName in
                                    categoryAssignments[template.objectID] = categoryName
                                }
                            )
                        }
                        
                        // Add New Category Option - EXACT MATCH
                        addNewCategoryButton
                    }
                    .padding(.horizontal, 16) // Consistent padding
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                // Action Buttons - EXACT MATCH
                actionButtons
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            initializeAssignments()
        }
        .alert("Assignment Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Initialize with current categories (for changes, not new assignments)
    private func initializeAssignments() {
        guard categoryAssignments.isEmpty else { return }
        
        for template in ingredientTemplates {
            // Initialize with current category for existing ingredients
            categoryAssignments[template.objectID] = template.category
        }
    }
    
    // MARK: - View Components - EXACT MATCH to CategoryAssignmentModal
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Categories")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("\(ingredientTemplates.count) ingredients need categories")
                        .font(.subheadline)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                Spacer()
            }
            
            Text("Assign categories to organize ingredients.")
                .font(.callout)
                .foregroundStyle(ForagerTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var addNewCategoryButton: some View {
        Button(action: {
            showingAddCategory = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ForagerTheme.accentPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Category")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                    Text("Create a custom category for these ingredients")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(ForagerTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                    .stroke(ForagerTheme.accentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Assign Categories Button - EXACT MATCH
            Button(action: assignCategories) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isLoading ? "Assigning..." : "Assign Categories")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(properlyAssignedCount > 0 ? ForagerTheme.accentPrimary : ForagerTheme.accentPrimary.opacity(0.6))
                .foregroundStyle(.white)
                .cornerRadius(ForagerTheme.Radius.md)
            }
            .disabled(isLoading)
            
            // Cancel Button - More appropriate for changing existing categories
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Cancel")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .cornerRadius(ForagerTheme.Radius.md)
            }
            .disabled(isLoading)
            
            // Assignment summary - EXACT MATCH
            if ingredientTemplates.count > 1 {
                VStack(spacing: 4) {
                    HStack {
                        Text("\(properlyAssignedCount) of \(ingredientTemplates.count) assigned")
                            .font(.footnote)
                            .foregroundStyle(ForagerTheme.textSecondary)
                        Spacer()
                    }
                    
                    if properlyAssignedCount < ingredientTemplates.count {
                        HStack {
                            Text("\(ingredientTemplates.count - properlyAssignedCount) will remain uncategorized")
                                .font(.footnote)
                                .foregroundStyle(ForagerTheme.textSecondary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var properlyAssignedCount: Int {
        categoryAssignments.values.compactMap { $0 }.filter { categoryName in
            return categoryName.lowercased() != "uncategorized" && !categoryName.isEmpty
        }.count
    }
    
    // MARK: - Actions
    
    private func assignCategories() {
        isLoading = true
        errorMessage = nil
        
        var hasChanges = false
        
        // Apply only changed categories
        for template in ingredientTemplates {
            let currentCategory = template.category
            let selectedCategory = categoryAssignments[template.objectID] ?? nil
            
            if currentCategory != selectedCategory {
                hasChanges = true
                // Apply new category, handling "Uncategorized" as nil
                if let categoryName = selectedCategory,
                   !categoryName.isEmpty,
                   categoryName.lowercased() != "uncategorized" {
                    template.category = categoryName
                } else {
                    template.category = nil
                }
            }
        }
        
        // Only save if there are changes
        guard hasChanges else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.onAssignmentsComplete()
                self.dismiss()
            }
            return
        }
        
        // Save changes
        do {
            try viewContext.save()
            DispatchQueue.main.async {
                self.isLoading = false
                self.onAssignmentsComplete()
                self.dismiss()
            }
        } catch {
            // Roll back changes on error
            viewContext.rollback()
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to assign categories: \(error.localizedDescription)"
            }
        }
    }
    
    private func skipAssignment() {
        // This function is no longer needed since we use Cancel instead
        dismiss()
    }
}

// MARK: - Ingredient Change Row - EXACT MATCH to IngredientAssignmentRow
struct IngredientChangeRow: View {
    let template: IngredientTemplate
    let categories: [Category]
    let selectedCategoryName: String?
    let onCategorySelected: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ingredient Info - EXACT MATCH
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name ?? "Unknown ingredient")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Category Assignment Status - EXACT MATCH
                categoryStatusView
            }
            
            // Category Selection Button - EXACT MATCH
            NavigationLink(destination: CategorySelectionViewForChange(
                categories: categories,
                selectedCategoryName: selectedCategoryName,
                onCategorySelected: onCategorySelected
            )) {
                HStack {
                    if let categoryName = selectedCategoryName,
                       !categoryName.isEmpty,
                       categoryName.lowercased() != "uncategorized" {
                        HStack(spacing: 8) {
                            // Find the category to get its color
                            let category = categories.first { $0.name == categoryName }
                            Circle()
                                .fill(colorFromHex(category?.color ?? "#4CAF50"))
                                .frame(width: 16, height: 16)
                            Text(categoryName)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("Choose Category")
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(ForagerTheme.Radius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(ForagerTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.md)
                .stroke(isProperlyAssigned ? ForagerTheme.statusSuccessFG.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var isProperlyAssigned: Bool {
        guard let categoryName = selectedCategoryName else { return false }
        return categoryName.lowercased() != "uncategorized" && !categoryName.isEmpty
    }
    
    private var categoryStatusView: some View {
        Group {
            if isProperlyAssigned, let categoryName = selectedCategoryName {
                // Find the category to get its color
                let category = categories.first { $0.name == categoryName }
                HStack(spacing: 6) {
                    Circle()
                        .fill(colorFromHex(category?.color ?? "#4CAF50"))
                        .frame(width: 16, height: 16)
                    Text(categoryName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 16, height: 16)
                    Text("Needs category")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                }
            }
        }
    }
}

// MARK: - Category Selection View for Change - EXACT MATCH
struct CategorySelectionViewForChange: View {
    let categories: [Category]
    let selectedCategoryName: String?
    let onCategorySelected: (String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(categories, id: \.objectID) { category in
                CategorySelectionRowForChange(
                    category: category,
                    isSelected: selectedCategoryName == category.name,
                    onTap: {
                        onCategorySelected(category.name)
                        dismiss()
                    }
                )
            }
            
            // Option to leave uncategorized
            Button("Leave Uncategorized") {
                onCategorySelected(nil)
                dismiss()
            }
            .foregroundStyle(ForagerTheme.textSecondary)
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Category Selection Row for Change - EXACT MATCH
struct CategorySelectionRowForChange: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category color and name
                Circle()
                    .fill(colorFromHex(category.color ?? "#4CAF50"))
                    .frame(width: 24, height: 24)
                
                Text(category.name ?? "Unknown")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ForagerTheme.accentPrimary)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Functions
func colorFromHex(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        (a, r, g, b) = (1, 1, 1, 0)
    }
    
    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue:  Double(b) / 255,
        opacity: Double(a) / 255
    )
}

// Note: AddIngredientView is now defined in AddIngredientView.swift as a standalone component
