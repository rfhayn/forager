import SwiftUI
import CoreData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var categoryService: CategoryService

    @State private var name = ""
    @State private var selectedColor = "#2E7A52"
    @State private var showingError = false
    @State private var errorMessage = ""

    // reskin-provisions-press: selectable colors in the print gamut
    private let availableColors = [
        "#2E7A52", // Print Green
        "#C8402E", // Tomato
        "#34689A", // Label Blue
        "#B0762A", // Golden Brown
        "#77563A", // Kraft Brown
        "#6A4E92", // Plum
        "#C2662C", // Crate Orange
        "#1F6E6A", // Teal
        "#3C7D96", // Ice Blue
        "#5E6E60"  // Market Grey-Green
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
                                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                            .stroke(selectedColor == color ? ForagerTheme.textPrimary : Color.clear, lineWidth: 3)
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
                .scrollContentBackground(.hidden)
                .background(ForagerTheme.backgroundCanvas)
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
