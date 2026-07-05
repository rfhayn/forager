//
//  RecipeScalingView.swift
//  forager
//
//  Created for M3 Phase 4: Recipe Scaling Service
//  WITH TICK MARKS - No quick buttons
//

import SwiftUI
import CoreData

struct RecipeScalingView: View {
    @Environment(\.dismiss) var dismiss
    let recipe: Recipe
    let scalingService: RecipeScalingService
    
    @State private var scaleFactor: Double = 1.0
    @State private var scaledRecipe: ScaledRecipe?
    
    // Valid scale factors (1x to 4x only, with standard fractions)
    private let validScaleFactors: [Double] = [
        1.0,                                   // 1x
        1.25, 1.33, 1.5, 1.67, 1.75,          // 1x to 2x
        2.0, 2.25, 2.33, 2.5, 2.67, 2.75,     // 2x to 3x
        3.0, 3.25, 3.33, 3.5, 3.67, 3.75, 4.0 // 3x to 4x
    ]
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var categories: FetchedResults<Category>
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .background(ForagerTheme.backgroundSecondary)
            
            scaleControlsSection
                .padding()
            
            Divider()
                .padding(.vertical)
            
            if let scaled = scaledRecipe {
                ingredientsPreviewList(scaled: scaled)
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            updateScaledRecipe()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Scale Recipe")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                VStack {
                    Text("Original")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Text("\(recipe.servings)")
                        .font(.system(.title, design: .monospaced).weight(.bold))
                    Text("servings")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(ForagerTheme.textSecondary)
                
                VStack {
                    Text("Scaled")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                    Text("\(scaledServings)")
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .foregroundStyle(ForagerTheme.accentPrimary)
                    Text("servings")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Slider with Tick Marks
    
    private var scaleControlsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Scale Factor: \(formatScaleFactor(scaleFactor))x")
                .font(.headline)
            
            VStack(spacing: 8) {
                // Slider
                Slider(
                    value: Binding(
                        get: { scaleFactor },
                        set: { newValue in
                            scaleFactor = snapToValidScale(newValue)
                        }
                    ),
                    in: 1.0...4.0
                )
                .onChange(of: scaleFactor) { _, _ in
                    updateScaledRecipe()
                }
                
                // Tick marks and labels
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let minValue = 1.0
                    let maxValue = 4.0
                    let range = maxValue - minValue
                    
                    ZStack(alignment: .topLeading) {
                        // Major tick marks (whole numbers) - taller and darker
                        ForEach([1.0, 2.0, 3.0, 4.0], id: \.self) { factor in
                            let position = CGFloat((factor - minValue) / range) * width
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.8))
                                .frame(width: 2, height: 16)
                                .position(x: position, y: 8)
                        }
                        
                        // Minor tick marks (fractions) - shorter and lighter
                        ForEach(validScaleFactors.filter { ![$0].contains(where: { $0.truncatingRemainder(dividingBy: 1.0) == 0 }) }, id: \.self) { factor in
                            let position = CGFloat((factor - minValue) / range) * width
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.4))
                                .frame(width: 1.5, height: 8)
                                .position(x: position, y: 8)
                        }
                        
                        // Labels only for major marks
                        ForEach([1.0, 2.0, 3.0, 4.0], id: \.self) { factor in
                            let position = CGFloat((factor - minValue) / range) * width
                            
                            Text(formatScaleFactor(factor) + "x")
                                .font(ForagerTheme.quantityFont)
                                .foregroundStyle(ForagerTheme.textSecondary)
                                .position(x: position, y: 28)
                        }
                    }
                }
                .frame(height: 40)
            }
        }
    }
    
    // MARK: - Ingredients Preview
    
    private func ingredientsPreviewList(scaled: ScaledRecipe) -> some View {
        List {
            Section {
                Text(scaled.summary)
                    .font(.subheadline)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            
            ForEach(sortedCategoryNames(for: scaled), id: \.self) { categoryName in
                Section(categoryName) {
                    ForEach(ingredientsForCategory(categoryName, in: scaled)) { ingredient in
                        ingredientRow(ingredient)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ForagerTheme.backgroundCanvas)
    }
    
    private func ingredientRow(_ ingredient: ScaledIngredient) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ingredient.wasScaled ? "checkmark.circle.fill" : "info.circle")
                .foregroundStyle(ingredient.wasScaled ? ForagerTheme.statusSuccessFG : ForagerTheme.statusWarningFG)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(ingredient.displayText)
                    .font(.subheadline)
                    .foregroundStyle(ingredient.wasScaled ? .primary : .secondary)
                
                if !ingredient.wasScaled, let original = ingredient.originalText {
                    Text("Original: \(original)")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helpers
    
    private var scaledServings: Int {
        Int(round(Double(recipe.servings) * scaleFactor))
    }
    
    private func updateScaledRecipe() {
        scaledRecipe = scalingService.scale(recipe: recipe, scaleFactor: scaleFactor)
    }
    
    private func sortedCategoryNames(for scaled: ScaledRecipe) -> [String] {
        let grouped = Dictionary(grouping: scaled.scaledIngredients) { $0.category }
        let categoryMap = Dictionary(categories.map { ($0.displayName, $0.sortOrder) }, uniquingKeysWith: { first, _ in first })
        
        return grouped.keys.sorted { category1, category2 in
            if category1 == "Uncategorized" && category2 != "Uncategorized" { return false }
            if category2 == "Uncategorized" && category1 != "Uncategorized" { return true }
            if category1 == "Uncategorized" && category2 == "Uncategorized" { return false }
            
            let order1 = categoryMap[category1] ?? Int16.max
            let order2 = categoryMap[category2] ?? Int16.max
            
            return order1 < order2
        }
    }
    
    private func ingredientsForCategory(_ categoryName: String, in scaled: ScaledRecipe) -> [ScaledIngredient] {
        scaled.scaledIngredients.filter { $0.category == categoryName }
    }
    
    private func snapToValidScale(_ value: Double) -> Double {
        var closestFactor = validScaleFactors[0]
        var minDistance = abs(value - closestFactor)
        
        for factor in validScaleFactors {
            let distance = abs(value - factor)
            if distance < minDistance {
                minDistance = distance
                closestFactor = factor
            }
        }
        
        return closestFactor
    }
    
    private func formatScaleFactor(_ factor: Double) -> String {
        let fractions: [(value: Double, display: String)] = [
            (1.0, "1"), (1.25, "1 1/4"), (1.33, "1 1/3"), (1.5, "1 1/2"), (1.67, "1 2/3"), (1.75, "1 3/4"),
            (2.0, "2"), (2.25, "2 1/4"), (2.33, "2 1/3"), (2.5, "2 1/2"), (2.67, "2 2/3"), (2.75, "2 3/4"),
            (3.0, "3"), (3.25, "3 1/4"), (3.33, "3 1/3"), (3.5, "3 1/2"), (3.67, "3 2/3"), (3.75, "3 3/4"),
            (4.0, "4")
        ]
        
        for (fValue, fDisplay) in fractions {
            if abs(factor - fValue) < 0.01 {
                return fDisplay
            }
        }
        
        return String(format: "%.2f", factor)
    }
}
