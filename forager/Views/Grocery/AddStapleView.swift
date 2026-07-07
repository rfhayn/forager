import SwiftUI
import CoreData

struct AddStapleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    // Dynamic categories fetch (sorted by custom order)
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ],
        animation: .default
    ) private var allCategories: FetchedResults<Category>

    // M7.6.8: Filter categories by household scope to prevent duplicates
    private var categories: [Category] {
        let key = householdService.currentHouseholdKey
        return allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
    }
    
    // Form state
    @State private var name = ""
    @State private var selectedCategory = ""
    @State private var lastPurchased: Date? = nil
    @State private var includeLastPurchased = false
    
    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Smart duplicate handling
    @State private var showingConvertAlert = false
    @State private var showingEditAlert = false
    @State private var existingItem: GroceryItem?
    
    // Validation
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedCategory.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Staple Information")) {
                    TextField("Staple Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                HStack {
                                    Circle()
                                        .fill(ForagerTheme.categoryColor(for: category))
                                        .frame(width: 16, height: 16)
                                    Text(category.displayName)
                                }
                                .tag(category.displayName)
                            }
                        }
                    } else {
                        Text("Loading categories...")
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }
                
                Section(header: Text("Purchase History")) {
                    Toggle("Include Last Purchased Date", isOn: $includeLastPurchased)
                    
                    if includeLastPurchased {
                        DatePicker("Last Purchased",
                                 selection: Binding(
                                    get: { lastPurchased ?? Date() },
                                    set: { lastPurchased = $0 }
                                 ),
                                 displayedComponents: .date)
                    }
                }
                
                Section {
                    Button("Save Staple") {
                        saveStaple()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid)
                }
            }
                .scrollContentBackground(.hidden)
                .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("Add Staple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setDefaultCategory()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Convert to Staple?", isPresented: $showingConvertAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Convert") {
                    if let item = existingItem {
                        convertToStaple(item)
                    }
                }
            } message: {
                if let item = existingItem {
                    Text("'\(item.name ?? "Unknown")' already exists but isn't a staple. Convert it to a staple in '\(selectedCategory)' category?")
                }
            }
            .alert("Already a Staple", isPresented: $showingEditAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Edit Existing") {
                    if let item = existingItem {
                        editExistingStaple(item)
                    }
                }
            } message: {
                if let item = existingItem {
                    Text("'\(item.name ?? "Unknown")' is already a staple in '\(item.effectiveCategory)' category. Would you like to edit it instead?")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setDefaultCategory() {
        if selectedCategory.isEmpty && !categories.isEmpty {
            selectedCategory = categories.first?.displayName ?? "Produce"
        }
    }
    
    private func findCategoryEntity(named categoryName: String) -> Category? {
        return categories.first { $0.displayName == categoryName }
    }
    
    private func saveStaple() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // GroceryItem has no householdKey — scoped through categoryEntity relationship.
        // Name-based duplicate check is sufficient for staples.
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", trimmedName)
        
        do {
            let existingItems = try viewContext.fetch(request)
            
            if let existingItem = existingItems.first {
                self.existingItem = existingItem
                
                if existingItem.isStaple {
                    // Already a staple - offer to edit
                    showingEditAlert = true
                } else {
                    // Not a staple - offer to convert
                    showingConvertAlert = true
                }
            } else {
                // No existing item - create new staple
                createNewStaple(trimmedName)
            }
        } catch {
            errorMessage = "Failed to check for existing items: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func createNewStaple(_ name: String) {
        PersistenceController.shared.performWrite({ context in
            let newStaple = GroceryItem(context: context)
            newStaple.id = UUID()
            newStaple.name = name
            // M9.12: category string removed — categoryEntity is the source of truth
            newStaple.isStaple = true
            newStaple.dateCreated = Date()
            
            // Set category relationship
            if let categoryEntity = findCategoryEntity(named: selectedCategory) {
                let categoryInContext = context.object(with: categoryEntity.objectID) as! Category
                newStaple.categoryEntity = categoryInContext
            }
            
            if includeLastPurchased {
                newStaple.lastPurchased = lastPurchased
            }
            
            #if DEBUG
            print("✅ Created new staple: \(name) in \(selectedCategory)")
            #endif
        }, onError: { error in
            DispatchQueue.main.async {
                errorMessage = "Failed to save staple: \(error.localizedDescription)"
                showingError = true
            }
        })
        
        dismiss()
    }
    
    private func convertToStaple(_ item: GroceryItem) {
        let itemID = item.objectID
        PersistenceController.shared.performWrite({ context in
            let itemToUpdate = context.object(with: itemID) as! GroceryItem
            itemToUpdate.isStaple = true
            // M9.12: category string removed — categoryEntity is the source of truth
            
            // Set category relationship
            if let categoryEntity = findCategoryEntity(named: selectedCategory) {
                let categoryInContext = context.object(with: categoryEntity.objectID) as! Category
                itemToUpdate.categoryEntity = categoryInContext
            }
            
            if includeLastPurchased {
                itemToUpdate.lastPurchased = lastPurchased
            }
            
            #if DEBUG
            print("✅ Converted '\(itemToUpdate.name ?? "Unknown")' to staple in \(selectedCategory)")
            #endif
        }, onError: { error in
            DispatchQueue.main.async {
                errorMessage = "Failed to convert item to staple: \(error.localizedDescription)"
                showingError = true
            }
        })
        
        dismiss()
    }
    
    private func editExistingStaple(_ item: GroceryItem) {
        // For now, just dismiss and let user find it in StaplesView
        // Later you could navigate directly to EditStapleView
        dismiss()
        
        // TODO: Could implement navigation to edit the existing staple
        #if DEBUG
        print("ℹ️ User should edit existing staple: \(item.name ?? "Unknown")")
        #endif
    }
}

// Color extension moved to Color+Extensions.swift

#Preview {
    AddStapleView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
