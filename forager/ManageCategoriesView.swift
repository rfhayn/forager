import SwiftUI
import CoreData

struct ManageCategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    // Fetch categories sorted by current order
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ],
        animation: .default
    ) private var allCategories: FetchedResults<Category>

    // M7.3.2: Filter categories based on current household context
    // M7.2.2 FIX: Use currentHouseholdKey which has fallback for nil household.id
    // This prevents showing duplicates from both private and shared stores
    private var categories: [Category] {
        let currentHouseholdKey = householdService.currentHouseholdKey
        return allCategories.filter { category in
            if let householdKey = currentHouseholdKey {
                // User is in a household: show only household categories
                return category.householdKey == householdKey
            } else {
                // User is not in a household: show only personal categories (no householdKey)
                return category.householdKey == nil
            }
        }
    }

    // State management
    @State private var isReordering = false
    @State private var showingAddCategory = false
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var isLoading = false
    
    // Enhanced state for ingredient template protection
    @State private var showingReassignmentDialog = false
    @State private var assignedIngredientCount = 0
    @State private var reassignmentCategories: [Category] = []
    @State private var selectedReassignmentCategory: Category? = nil
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            categoriesListSection
        }
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .alert("Delete Category", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text(enhancedDeleteAlertMessage(for: category))
            }
        }
        .sheet(isPresented: $showingReassignmentDialog) {
            NavigationView {
                reassignmentDialog
                    .navigationTitle("Reassign Ingredients")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingReassignmentDialog = false
                                categoryToDelete = nil
                            }
                        }
                    }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .onChange(of: popToRoot) { _, _ in
            if showingAddCategory { showingAddCategory = false }
            if showingDeleteAlert { showingDeleteAlert = false }
            if showingReassignmentDialog { showingReassignmentDialog = false }
            if showingError { showingError = false }
            if showingSuccessAlert { showingSuccessAlert = false }
            if isReordering {
                isReordering = false
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Drag to Reorder Categories")
                .font(.subheadline)
                .foregroundStyle(ForagerTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("Arrange categories to match your store layout")
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.textSecondary)
                
                Spacer()
                
                Button("Reset to Default") {
                    resetToDefaultOrder()
                }
                .font(.caption)
                .foregroundStyle(ForagerTheme.accentPrimary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    private var categoriesListSection: some View {
        List {
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                CategoryRowView(
                    category: category,
                    position: index + 1,
                    onDelete: {
                        prepareForCategoryDeletion(category)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onMove(perform: moveCategories)
            .onDelete(perform: deleteCategories)

            // Footer help text
            Section { } footer: {
                Text("Drag categories to reorder. Swipe left to delete — its ingredients will be reassigned.")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: ForagerTheme.Spacing.md) {
                Button { showingAddCategory = true } label: {
                    Image(systemName: "plus")
                }

                Button(isReordering ? "Done" : "Reorder") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isReordering.toggle()
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Category Deletion Protection
    // M7.3.4: Filter by householdKey to only count templates in current scope
    private func checkIngredientTemplateAssignments(for category: Category) -> Int {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()

        // M7.3.4: Filter by both category name AND householdKey
        if let householdKey = householdService.currentHouseholdKey {
            request.predicate = NSPredicate(format: "category == %@ AND householdKey == %@", category.displayName, householdKey)
        } else {
            request.predicate = NSPredicate(format: "category == %@ AND householdKey == nil", category.displayName)
        }

        do {
            let assignedTemplates = try viewContext.fetch(request)
            #if DEBUG
            print("📊 Category '\(category.displayName)' has \(assignedTemplates.count) assigned ingredient templates")
            #endif
            return assignedTemplates.count
        } catch {
            #if DEBUG
            print("❌ Error checking ingredient template assignments: \(error)")
            #endif
            return 0
        }
    }
    
    private func prepareForCategoryDeletion(_ category: Category) {
        categoryToDelete = category
        
        // M7.2.3 Phase 3.7.2: BLOCK DELETION of protected categories (isDefault = true)
        // Only "Uncategorized" is protected - it's needed for unassigned ingredients
        if category.isDefault {
            errorMessage = "The '\(category.displayName)' category cannot be deleted as it's needed for unassigned ingredients."
            showingError = true
            categoryToDelete = nil
            return
        }
        
        // Check both grocery items and ingredient template assignments
        let groceryItemCount = category.groceryItemsArray.count
        let ingredientTemplateCount = checkIngredientTemplateAssignments(for: category)
        
        #if DEBUG
        print("🔍 Category '\(category.displayName)' deletion check:")
        print("   - Grocery items: \(groceryItemCount)")
        print("   - Ingredient templates: \(ingredientTemplateCount)")
        #endif
        
        if ingredientTemplateCount > 0 {
            // Category has ingredient template assignments - show enhanced dialog
            assignedIngredientCount = ingredientTemplateCount
            prepareReassignmentOptions(excluding: category)
            showingReassignmentDialog = true
        } else {
            // No ingredient template assignments - use standard deletion flow
            showingDeleteAlert = true
        }
    }
    
    private func prepareReassignmentOptions(excluding categoryToExclude: Category) {
        reassignmentCategories = categories.filter { $0 != categoryToExclude }
        selectedReassignmentCategory = reassignmentCategories.first
        #if DEBUG
        print("📋 Prepared \(reassignmentCategories.count) reassignment options")
        #endif
    }
    
    private func enhancedDeleteAlertMessage(for category: Category) -> String {
        let groceryItemCount = category.groceryItemsArray.count
        let hasGroceryItems = groceryItemCount > 0
        
        if hasGroceryItems {
            return "Delete '\(category.displayName)'?\n\n\(groceryItemCount) item\(groceryItemCount == 1 ? "" : "s") in this category will keep their category name for existing lists, but new items will need a different category."
        } else {
            return "Delete '\(category.displayName)'?\n\nThis category will no longer be available for new items."
        }
    }
    
    // MARK: - Reassignment Dialog
    private var reassignmentDialog: some View {
        VStack(spacing: 24) {
            // Header with better spacing
            VStack(spacing: 12) {
                Text("Category Has Assigned Ingredients")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if let category = categoryToDelete {
                    VStack(spacing: 8) {
                        Text("\(assignedIngredientCount) ingredient\(assignedIngredientCount == 1 ? "" : "s") \(assignedIngredientCount == 1 ? "is" : "are") assigned to '\(category.displayName)'.")
                            .font(.body)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose how to handle these assignments:")
                            .font(.body)
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            // Reassignment options with better styling
            VStack(spacing: 16) {
                // Option 1: Reassign to different category
                if !reassignmentCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(ForagerTheme.accentPrimary)
                            Text("Reassign to Different Category")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        // Replace picker with NavigationLink to selection view
                        NavigationLink(destination: CategorySelectionView(
                            categories: reassignmentCategories,
                            selectedCategory: $selectedReassignmentCategory
                        )) {
                            HStack {
                                if let selected = selectedReassignmentCategory {
                                    Circle()
                                        .fill(ForagerTheme.categoryColor(for: selected.displayName))
                                        .frame(width: 16, height: 16)
                                    Text(selected.displayName)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Select Category")
                                        .foregroundStyle(ForagerTheme.accentPrimary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(ForagerTheme.textSecondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(ForagerTheme.Radius.md)
                }
                
                // Option 2: Move to Uncategorized
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(ForagerTheme.textTertiary)
                        Text("Move to \"Uncategorized\" Category")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    Text("Ingredients will be moved to the Uncategorized category")
                        .font(.subheadline)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(ForagerTheme.Radius.md)
            }
            
            // Action buttons with better layout
            VStack(spacing: 12) {
                if !reassignmentCategories.isEmpty {
                    Button("Reassign to Selected Category") {
                        if let category = categoryToDelete,
                           let newCategory = selectedReassignmentCategory {
                            reassignIngredientTemplates(from: category, to: newCategory)
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(selectedReassignmentCategory == nil ? ForagerTheme.textSecondary : Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedReassignmentCategory == nil ? Color(.systemGray4) : ForagerTheme.accentPrimary)
                    .cornerRadius(ForagerTheme.Radius.md)
                    .disabled(selectedReassignmentCategory == nil)
                }
                
                Button("Move to Uncategorized") {
                    if let category = categoryToDelete {
                        moveIngredientTemplatesToUncategorized(from: category)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ForagerTheme.textTertiary)
                .cornerRadius(ForagerTheme.Radius.md)
                
                Button("Cancel") {
                    showingReassignmentDialog = false
                    categoryToDelete = nil
                    selectedReassignmentCategory = nil
                }
                .font(.body)
                .foregroundStyle(ForagerTheme.accentPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(ForagerTheme.Radius.md)
            }
        }
        .padding(20)
    }
    
    // MARK: - Reassignment Implementation
    // M7.3.4: Filter by householdKey to only reassign templates in current scope
    private func reassignIngredientTemplates(from sourceCategory: Category, to targetCategory: Category) {
        let sourceCategoryID = sourceCategory.objectID
        let targetCategoryID = targetCategory.objectID
        let sourceCategoryName = sourceCategory.displayName
        let targetCategoryName = targetCategory.displayName
        let currentHouseholdKey = householdService.currentHouseholdKey

        PersistenceController.shared.performWrite({ context in
            // Get references to categories in write context
            let sourceCategoryInContext = context.object(with: sourceCategoryID) as! Category

            // M7.3.4: Filter by both category name AND householdKey
            let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            if let householdKey = currentHouseholdKey {
                request.predicate = NSPredicate(format: "category == %@ AND householdKey == %@", sourceCategoryName, householdKey)
            } else {
                request.predicate = NSPredicate(format: "category == %@ AND householdKey == nil", sourceCategoryName)
            }

            do {
                let templates = try context.fetch(request)
                for template in templates {
                    template.category = targetCategoryName  // Assign String, not Category object
                    let templateName = template.name ?? "Unknown"
                    #if DEBUG
                    print("🔄 Reassigned '\(templateName)' from '\(sourceCategoryName)' to '\(targetCategoryName)'")
                    #endif
                }

                // Now delete the source category
                context.delete(sourceCategoryInContext)
                #if DEBUG
                print("✅ Successfully reassigned \(templates.count) ingredient templates and deleted category '\(sourceCategoryName)'")
                #endif
            } catch {
                #if DEBUG
                print("❌ Error during reassignment: \(error)")
                #endif
            }

        }, onError: { error in
            DispatchQueue.main.async {
                self.errorMessage = "Failed to reassign ingredients: \(error.localizedDescription)"
                self.showingError = true
            }
        })

        // Clean up state
        showingReassignmentDialog = false
        categoryToDelete = nil
        selectedReassignmentCategory = nil
    }
    
    // M7.3.4: Filter by householdKey to only move templates in current scope
    private func moveIngredientTemplatesToUncategorized(from sourceCategory: Category) {
        let sourceCategoryID = sourceCategory.objectID
        let sourceCategoryName = sourceCategory.displayName
        let currentHouseholdKey = householdService.currentHouseholdKey

        PersistenceController.shared.performWrite({ context in
            // Get reference to category in write context
            let sourceCategoryInContext = context.object(with: sourceCategoryID) as! Category

            // M7.3.4: Find Uncategorized category within the same household scope
            let uncategorizedRequest: NSFetchRequest<Category> = Category.fetchRequest()
            if let householdKey = currentHouseholdKey {
                uncategorizedRequest.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == %@", "Uncategorized", householdKey)
            } else {
                uncategorizedRequest.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == nil", "Uncategorized")
            }

            do {
                let uncategorizedCategories = try context.fetch(uncategorizedRequest)
                let uncategorizedCategory: Category

                if let existing = uncategorizedCategories.first {
                    uncategorizedCategory = existing
                } else {
                    // Create Uncategorized category if it doesn't exist
                    uncategorizedCategory = Category(context: context)
                    uncategorizedCategory.id = UUID()
                    uncategorizedCategory.name = "Uncategorized"
                    uncategorizedCategory.color = "#9E9E9E" // Gray color
                    uncategorizedCategory.isDefault = false
                    uncategorizedCategory.dateCreated = Date()
                    uncategorizedCategory.sortOrder = Int16.max
                    // M7.3.4: Set householdKey for proper scoping
                    uncategorizedCategory.householdKey = currentHouseholdKey
                    #if DEBUG
                    print("✅ Created Uncategorized category during reassignment")
                    #endif
                }

                // M7.3.4: Move only ingredient templates in current household scope
                let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
                if let householdKey = currentHouseholdKey {
                    templateRequest.predicate = NSPredicate(format: "category == %@ AND householdKey == %@", sourceCategoryName, householdKey)
                } else {
                    templateRequest.predicate = NSPredicate(format: "category == %@ AND householdKey == nil", sourceCategoryName)
                }

                let templates = try context.fetch(templateRequest)
                for template in templates {
                    template.category = uncategorizedCategory.displayName  // Assign to Uncategorized, not nil
                    let templateName = template.name ?? "Unknown"
                    #if DEBUG
                    print("🔄 Moved '\(templateName)' to Uncategorized category")
                    #endif
                }

                // Now delete the source category
                context.delete(sourceCategoryInContext)
                #if DEBUG
                print("✅ Successfully moved \(templates.count) ingredient templates to Uncategorized and deleted category '\(sourceCategoryName)'")
                #endif
                
            } catch {
                #if DEBUG
                print("❌ Error moving templates to Uncategorized: \(error)")
                #endif
            }
            
        }, onError: { error in
            DispatchQueue.main.async {
                self.errorMessage = "Failed to move ingredients to Uncategorized: \(error.localizedDescription)"
                self.showingError = true
            }
        })
        
        // Clean up state
        showingReassignmentDialog = false
        categoryToDelete = nil
    }
    
    // MARK: - Actions
    private func moveCategories(from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        // Extract category IDs before entering performWrite
        var categoryArray = Array(categories)
        categoryArray.move(fromOffsets: source, toOffset: destination)
        let categoryOrderUpdates = categoryArray.enumerated().map { (index, category) in
            (objectID: category.objectID, sortOrder: Int16(index))
        }
        
        PersistenceController.shared.performWrite({ context in
            // Update sort orders using object IDs
            for update in categoryOrderUpdates {
                let categoryToUpdate = context.object(with: update.objectID) as! Category
                categoryToUpdate.sortOrder = update.sortOrder
            }
            
            #if DEBUG
            print("✅ Reordered categories successfully")
            #endif
        }, onError: { error in
            DispatchQueue.main.async {
                self.errorMessage = "Failed to reorder categories: \(error.localizedDescription)"
                self.showingError = true
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            prepareForCategoryDeletion(category)
            break // Handle one at a time for better UX
        }
    }
    
    private func deleteCategory(_ category: Category) {
        let categoryID = category.objectID
        let itemCount = category.groceryItemsArray.count
        let categoryName = category.displayName
        
        PersistenceController.shared.performWrite({ context in
            let categoryToDelete = context.object(with: categoryID) as! Category
            
            // Update grocery items to remove the relationship but keep the category name
            // This ensures existing list items maintain their category display
            if let items = categoryToDelete.groceryItems {
                for case let item as GroceryItem in items {
                    // Remove the relationship but preserve the category string
                    item.categoryEntity = nil
                    // Keep the original category name so existing lists still show it
                    item.category = categoryName
                }
                
                if itemCount > 0 {
                    #if DEBUG
                    print("📝 Updated \(itemCount) item\(itemCount == 1 ? "" : "s") - removed category relationship but preserved category name '\(categoryName)'")
                    #endif
                }
            }
            
            context.delete(categoryToDelete)
            #if DEBUG
            print("✅ Deleted category: \(categoryName)")
            #endif
        }, onError: { error in
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete category: \(error.localizedDescription)"
                self.showingError = true
            }
        })
        
        // Clear the categoryToDelete after successful deletion
        categoryToDelete = nil
    }
    
    private func resetToDefaultOrder() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        PersistenceController.shared.performWrite({ context in
            Category.resetToDefaultOrder(in: context)
            #if DEBUG
            print("✅ Reset categories to default order")
            #endif
        }, onError: { error in
            DispatchQueue.main.async {
                self.errorMessage = "Failed to reset order: \(error.localizedDescription)"
                self.showingError = true
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
}

// MARK: - Category Row View
struct CategoryRowView: View {
    let category: Category
    let position: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Position indicator
            Text("\(position)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(ForagerTheme.textSecondary)
                .frame(width: 30)
            
            // Category color indicator
            Circle()
                .fill(ForagerTheme.categoryColor(for: category.displayName))
                .frame(width: 32, height: 32)

            // Category info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    Text(category.displayName)
                        .font(.headline)
                        .fontWeight(.medium)

                    if category.isDefault {
                        Image(systemName: "lock.fill")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Delete button — hidden for protected categories (isDefault = true)
            if !category.isDefault {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(ForagerTheme.statusDangerFG)
                        .font(.title3)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Spacer()
                    .frame(width: 24)
            }

            // Drag handle — hidden for Uncategorized
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(category.isDefault ? .clear : ForagerTheme.textSecondary)
                .font(.title2)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
}

#Preview {
    NavigationView {
        ManageCategoriesView(popToRoot: .constant(false))  // ← ADD PARAMETER HERE
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// MARK: - Category Selection View
struct CategorySelectionView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(categories, id: \.self) { category in
                CategorySelectionRow(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    selectedCategory = category
                    dismiss()
                }
            }
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

// MARK: - Category Selection Row
struct CategorySelectionRow: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category color indicator
                Circle()
                    .fill(ForagerTheme.categoryColor(for: category.displayName))
                    .frame(width: 32, height: 32)
                
                // Category name
                Text(category.displayName)
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
#Preview {
    NavigationView {
        ManageCategoriesView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
