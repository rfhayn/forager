import SwiftUI
import CoreData

struct CategoryAssignmentModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    // Data
    let uncategorizedTemplates: [IngredientTemplate]
    let onAssignmentsComplete: () -> Void

    // State - FIXED: Optional String assignments to support "Choose Category" state
    @State private var categoryAssignments: [UUID: String?] = [:]
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
                // Header Section
                headerSection
                
                // Ingredient Assignment List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(uncategorizedTemplates, id: \.objectID) { template in
                            IngredientAssignmentRow(
                                template: template,
                                categories: realCategories,
                                selectedCategoryName: categoryAssignments[template.id ?? UUID()] ?? nil,
                                onCategorySelected: { categoryName in
                                    categoryAssignments[template.id ?? UUID()] = categoryName
                                }
                            )
                        }
                        
                        // Add New Category Option
                        addNewCategoryButton
                    }
                    .padding(.horizontal, 16) // Consistent padding
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                // Action Buttons
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
    
    // MARK: - View Components
    
    // IMPROVED: Simplified header with better spacing
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Categories")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("\(uncategorizedTemplates.count) ingredients need categories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text("Assign categories to organize ingredients.")
                .font(.callout)
                .foregroundColor(.secondary)
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
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Category")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Text("Create a custom category for these ingredients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
    
    // IMPROVED: Better spaced action buttons section
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Assign Categories Button
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
                .background(properlyAssignedCount > 0 ? Color.blue : Color.blue.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            // Skip Assignment Button
            Button(action: skipAssignment) {
                HStack {
                    Image(systemName: "arrow.right")
                    Text("Keep in Uncategorized")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            // IMPROVED: Conditional assignment summary with better layout
            if uncategorizedTemplates.count > 1 {
                VStack(spacing: 4) {
                    HStack {
                        Text("\(properlyAssignedCount) of \(uncategorizedTemplates.count) assigned")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if properlyAssignedCount < uncategorizedTemplates.count {
                        HStack {
                            Text("\(uncategorizedTemplates.count - properlyAssignedCount) will remain uncategorized")
                                .font(.footnote)
                                .foregroundColor(.secondary)
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
    
    private var assignedCount: Int {
        categoryAssignments.values.compactMap { $0 }.count
    }
    
    // FIXED: Handle optional String values properly
    private var properlyAssignedCount: Int {
        categoryAssignments.values.compactMap { $0 }.filter { categoryName in
            return categoryName.lowercased() != "uncategorized" && !categoryName.isEmpty
        }.count
    }
    
    // MARK: - Helper Methods
    
    private func initializeAssignments() {
        // FIXED: Initialize with nil so all ingredients show "Choose Category"
        for template in uncategorizedTemplates {
            categoryAssignments[template.id ?? UUID()] = nil
        }
    }
    
    private func assignCategories() {
        isLoading = true
        errorMessage = nil
        
        // Assign categories to templates
        for template in uncategorizedTemplates {
            guard let templateID = template.id else { continue }
            
            // Assign selected category string, or leave as "Uncategorized" if none selected
            if let selectedCategoryName = categoryAssignments[templateID],
               let categoryName = selectedCategoryName,
               !categoryName.isEmpty,
               categoryName.lowercased() != "uncategorized" {
                template.category = categoryName
            } else {
                // If no category was selected, keep as "Uncategorized"
                template.category = "Uncategorized"
            }
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
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to assign categories: \(error.localizedDescription)"
            }
        }
    }
    
    private func skipAssignment() {
        // Keep all templates as "Uncategorized" - don't change their category
        for template in uncategorizedTemplates {
            template.category = "Uncategorized"
        }
        
        // Save changes
        do {
            try viewContext.save()
            onAssignmentsComplete()
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }
}

// MARK: - Ingredient Assignment Row - IMPROVED Layout
struct IngredientAssignmentRow: View {
    let template: IngredientTemplate
    let categories: [Category]
    let selectedCategoryName: String?
    let onCategorySelected: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // IMPROVED: Ingredient Info without usage line
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name ?? "Unknown ingredient")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    // REMOVED: Usage line since these are new ingredients being categorized
                }
                
                Spacer()
                
                // Category Assignment Status
                categoryStatusView
            }
            
            // IMPROVED: Category Selection Button with better padding
            NavigationLink(destination: CategorySelectionViewForAssignment(
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
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Choose Category")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12) // Increased for better touch target
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16) // Consistent horizontal padding
        .padding(.vertical, 12)    // Reduced vertical padding
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isProperlyAssigned ? Color.green.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
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
                        .foregroundColor(.primary)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 16, height: 16)
                    Text("Needs category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // Helper function for color conversion
    private func colorFromHex(_ hex: String) -> Color {
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
}

// MARK: - Category Selection View for Assignment
struct CategorySelectionViewForAssignment: View {
    let categories: [Category]
    let selectedCategoryName: String?
    let onCategorySelected: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(categories, id: \.objectID) { category in
                CategorySelectionRowForAssignment(
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
            .foregroundColor(.secondary)
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

// MARK: - Category Selection Row for Assignment
struct CategorySelectionRowForAssignment: View {
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
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function for color conversion
    private func colorFromHex(_ hex: String) -> Color {
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
}
