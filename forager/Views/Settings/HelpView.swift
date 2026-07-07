//
//  HelpView.swift
//  forager
//
//  Created by Rich Hayn on 10/20/25.
//


//
//  HelpView.swift
//  forager
//
//  M3 Phase 6: User-facing help documentation for quantity management features
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Learn how to use the quantity management features to make your grocery shopping and recipe planning more efficient.")
                        .font(.body)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .padding(.vertical, 8)
                        .foragerGlassCard()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Structured Quantities
                Section(header: Label("Structured Quantities", systemImage: "number.circle")) {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "What are structured quantities?",
                                description: "Structured quantities break down ingredient amounts into numeric values and units (e.g., \"2 cups flour\" becomes 2.0 + cups). This enables powerful features like recipe scaling and smart consolidation."
                            )

                            HelpItem(
                                title: "How does parsing work?",
                                description: "The app automatically detects quantities when you add ingredients. It recognizes common formats like \"2 cups\", \"1/2 lb\", \"3 tablespoons\", and more."
                            )

                            HelpItem(
                                title: "What if my quantity isn't recognized?",
                                description: "That's okay! You can enter any text like \"to taste\" or \"a pinch\". These items will still work normally, they just can't be scaled or consolidated automatically."
                            )
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Understanding Quantities")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foragerGlassCard()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Recipe Scaling
                Section(header: Label("Recipe Scaling", systemImage: "slider.horizontal.3")) {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "How to scale a recipe",
                                description: "Open any recipe and tap the scale button (slider icon) in the toolbar. Use the slider or quick buttons (1/2x, 2x, etc.) to adjust serving sizes."
                            )

                            HelpItem(
                                title: "Understanding auto-scaled vs manual",
                                description: "Auto-scaled: Ingredients with numeric quantities are mathematically scaled (e.g., 2 cups -> 4 cups when doubled).\n\nManual: Items like \"to taste\" stay unchanged and are marked with a note to adjust manually."
                            )

                            HelpItem(
                                title: "Scaling tips",
                                description: "The app shows fractions for readability (1.5 cups -> 1 1/2 cups). You can scale recipes from 0.25x to 4x. Preview shows all changes before adding to your list. Scale factor is remembered for each recipe."
                            )
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Scaling Guide")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foragerGlassCard()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Shopping List Consolidation
                Section(header: Label("List Consolidation", systemImage: "arrow.triangle.merge")) {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "How consolidation works",
                                description: "When you add ingredients from multiple recipes, the app can automatically combine duplicate items. Tap \"Consolidate\" in your shopping list toolbar to merge compatible ingredients."
                            )

                            HelpItem(
                                title: "Understanding unit conversions",
                                description: "The app intelligently converts between compatible units:\n- Volume: cups, tablespoons, teaspoons\n- Weight: pounds, ounces\n\nExample: \"2 cups milk\" + \"4 tbsp milk\" = \"2 1/4 cups milk\""
                            )

                            HelpItem(
                                title: "When items can and cannot merge",
                                description: "Can merge: Same ingredient with compatible units (2 cups + 4 tbsp), or same ingredient with same units (1 lb + 2 lb).\n\nCannot merge: Different unit types (cups and pounds), or text-only quantities (\"to taste\")."
                            )

                            HelpItem(
                                title: "Source tracking",
                                description: "After consolidating, tap on any merged item to see which recipes it came from. This helps you understand what's needed for each meal you're planning."
                            )
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Consolidation Guide")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foragerGlassCard()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Unit Conversions
                Section(header: Label("Supported Conversions", systemImage: "arrow.triangle.2.circlepath")) {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            ConversionGroup(
                                title: "Volume Conversions",
                                conversions: [
                                    "1 cup = 16 tablespoons",
                                    "1 cup = 48 teaspoons",
                                    "1 tablespoon = 3 teaspoons"
                                ],
                                icon: "drop"
                            )

                            Divider()

                            ConversionGroup(
                                title: "Weight Conversions",
                                conversions: [
                                    "1 pound = 16 ounces"
                                ],
                                icon: "scalemass"
                            )

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(ForagerTheme.accentSecondary)
                                    Text("Coming Soon")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                Text("Metric conversions (liters, grams, etc.) are planned for a future update!")
                                    .font(.caption)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Conversion Reference")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foragerGlassCard()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Tips & Tricks
                Section(header: Label("Tips & Tricks", systemImage: "lightbulb")) {
                    VStack(alignment: .leading, spacing: 12) {
                        TipItem(
                            icon: "magnifyingglass",
                            tip: "Recipe ingredient autocomplete learns from your entries. The more you use it, the better it gets!"
                        )

                        Divider()

                        TipItem(
                            icon: "chart.bar",
                            tip: "Check the consolidation preview before applying to see exactly what will be merged."
                        )

                        Divider()

                        TipItem(
                            icon: "tag",
                            tip: "Use recipe tags like \"quick\" or \"leftovers\" to find meals that fit your schedule."
                        )

                        Divider()

                        TipItem(
                            icon: "arrow.up.arrow.down",
                            tip: "Reorder categories to match your store layout for more efficient shopping."
                        )
                    }
                    .padding(.vertical, 8)
                    .foragerGlassCard()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(ForagerTheme.backgroundCanvas)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top, spacing: 0) {
                BroadsheetMasthead(title: "Help")
                    .padding(.horizontal, ForagerTheme.Spacing.lg)
                    .background(ForagerTheme.backgroundCanvas)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components

private struct HelpItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
    }
}

private struct ConversionGroup: View {
    let title: String
    let conversions: [String]
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(ForagerTheme.accentSecondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            ForEach(conversions, id: \.self) { conversion in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                    Text(conversion)
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
        }
    }
}

private struct TipItem: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(ForagerTheme.accentSecondary)
                .font(.title3)
                .frame(width: 24)
            
            Text(tip)
                .font(.caption)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
    }
}

#Preview {
    HelpView()
}