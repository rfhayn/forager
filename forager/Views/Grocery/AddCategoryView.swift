import SwiftUI
import CoreData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var categoryService: CategoryService

    @State private var name = ""
    @State private var selectedColor = "#4CAF50"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let availableColors = [
        "#4CAF50", // Green
        "#F44336", // Red
        "#2196F3", // Blue
        "#FF9800", // Orange
        "#795548", // Brown
        "#9C27B0", // Purple
        "#E91E63", // Pink
        "#00BCD4", // Cyan
        "#FFC107", // Amber
        "#607D8B"  // Blue Grey
    ]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Add Category") {
                        createCategory()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("New Category")
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
    
    private func createCategory() {
        switch categoryService.createCustomCategory(displayName: name, color: selectedColor) {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = error.errorDescription ?? "Failed to create category"
            showingError = true
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let householdService = HouseholdService(context: context)
    let categoryService = CategoryService(context: context, householdService: householdService)

    AddCategoryView()
        .environment(\.managedObjectContext, context)
        .environmentObject(householdService)
        .environmentObject(categoryService)
}
