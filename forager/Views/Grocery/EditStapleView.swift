import SwiftUI
import CoreData

struct EditStapleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var householdService: HouseholdService

    // The staple item being edited
    let staple: GroceryItem

    // Form state - initialized from existing staple
    @State private var name: String
    @State private var selectedCategory: String
    @State private var lastPurchased: Date?
    @State private var includeLastPurchased: Bool

    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""

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
    
    // Validation
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Check if form has changes
    private var hasChanges: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName != (staple.name ?? "") ||
               selectedCategory != staple.effectiveCategory ||
               lastPurchased != staple.lastPurchased ||
               includeLastPurchased != (staple.lastPurchased != nil)
    }
    
    // Initialize form state from existing staple
    init(staple: GroceryItem) {
        self.staple = staple
        // Ensure we have valid data or provide defaults
        self._name = State(initialValue: staple.name ?? "")
        self._selectedCategory = State(initialValue: staple.effectiveCategory)
        self._lastPurchased = State(initialValue: staple.lastPurchased)
        self._includeLastPurchased = State(initialValue: staple.lastPurchased != nil)
        
        #if DEBUG
        print("📝 EditStapleView init - Name: \(staple.name ?? "nil"), Category: \(staple.effectiveCategory)")
        #endif
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Staple Information")) {
                    TextField("Staple Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.displayColor))
                                    .frame(width: 12, height: 12)
                                Text(category.displayName)
                            }.tag(category.displayName)
                        }
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
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid || !hasChanges)
                }
                
                if !hasChanges {
                    Section {
                        Text("No changes to save")
                            .foregroundStyle(ForagerTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Edit Staple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // GroceryItem has no householdKey — scoped through categoryEntity relationship.
        // Name-based duplicate check is sufficient for staples.
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        if let stapleID = staple.id {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND id != %@", trimmedName, stapleID as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@", trimmedName)
        }
        
        do {
            let existingItems = try viewContext.fetch(request)
            if !existingItems.isEmpty {
                let existingItem = existingItems.first!
                errorMessage = "A staple with this name already exists in '\(existingItem.effectiveCategory)' category. IsStaple: \(existingItem.isStaple)"
                showingError = true
                return
            }
        } catch {
            errorMessage = "Failed to check for duplicates: \(error.localizedDescription)"
            showingError = true
            return
        }
        
        // Save using background context
        let stapleID = staple.objectID
        let currentHouseholdKey = householdService.currentHouseholdKey
        PersistenceController.shared.performWrite({ context in
            // Get the staple in the background context
            let stapleToUpdate = context.object(with: stapleID) as! GroceryItem
            
            // Update the staple properties
            stapleToUpdate.name = trimmedName
            // M9.12: category string removed — categoryEntity is the source of truth
            
            // M10.6.18: Scope category lookup to household (ADR 013)
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            if let key = currentHouseholdKey {
                categoryRequest.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == %@", selectedCategory, key)
            } else {
                categoryRequest.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == nil", selectedCategory)
            }
            if let matchingCategory = try? context.fetch(categoryRequest).first {
                stapleToUpdate.categoryEntity = matchingCategory
            }
            
            if includeLastPurchased {
                stapleToUpdate.lastPurchased = lastPurchased
            } else {
                stapleToUpdate.lastPurchased = nil
            }
            
            #if DEBUG
            print("✅ Updated staple: \(trimmedName) in \(selectedCategory)")
            #endif
        }, onError: { error in
            DispatchQueue.main.async {
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                showingError = true
            }
        })
        
        // Dismiss on successful save
        dismiss()
    }
}

#Preview {
    // Create a sample staple for preview
    let context = PersistenceController.preview.container.viewContext
    let sampleStaple = GroceryItem(context: context)
    sampleStaple.id = UUID()
    sampleStaple.name = "Sample Staple"
    sampleStaple.category = "Produce"
    sampleStaple.isStaple = true
    sampleStaple.dateCreated = Date()
    sampleStaple.lastPurchased = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
    
    return EditStapleView(staple: sampleStaple)
        .environment(\.managedObjectContext, context)
}
