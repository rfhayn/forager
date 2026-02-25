// Add this temporary view to check what data you actually have
// Put this in a new Swift file or at the bottom of SettingsView.swift

import SwiftUI
import CoreData

struct DataDebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var debugOutput: String = "Loading..."
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Debug Report")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(debugOutput)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(ForagerTheme.Radius.sm)
                
                Button("Refresh Data Check") {
                    checkData()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            checkData()
        }
    }
    
    private func checkData() {
        var output = "🔍 ACTUAL DATA CHECK\n\n"
        
        // Check Ingredients
        let ingredientRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        ingredientRequest.fetchLimit = 5
        
        do {
            let ingredients = try viewContext.fetch(ingredientRequest)
            output += "📊 Found \(ingredients.count) ingredients\n\n"
            
            for (index, ingredient) in ingredients.enumerated() {
                output += "Ingredient \(index + 1):\n"
                output += "  name: '\(ingredient.name ?? "nil")'\n"
                output += "  displayText: '\(ingredient.displayText ?? "nil")'\n"
                output += "  numericValue: \(ingredient.numericValue)\n"
                output += "  standardUnit: '\(ingredient.standardUnit ?? "nil")'\n"
                output += "  isParseable: \(ingredient.isParseable)\n"
                output += "\n"
            }
        } catch {
            output += "❌ Error fetching ingredients: \(error)\n"
        }
        
        // Check GroceryListItems
        let itemRequest: NSFetchRequest<GroceryListItem> = GroceryListItem.fetchRequest()
        itemRequest.fetchLimit = 5
        
        do {
            let items = try viewContext.fetch(itemRequest)
            output += "\n📊 Found \(items.count) grocery items\n\n"
            
            for (index, item) in items.enumerated() {
                output += "Item \(index + 1):\n"
                output += "  name: '\(item.name ?? "nil")'\n"
                output += "  displayText: '\(item.displayText ?? "nil")'\n"
                output += "  numericValue: \(item.numericValue)\n"
                output += "  standardUnit: '\(item.standardUnit ?? "nil")'\n"
                output += "  isParseable: \(item.isParseable)\n"
                output += "\n"
            }
        } catch {
            output += "❌ Error fetching items: \(error)\n"
        }
        
        debugOutput = output
    }
}
