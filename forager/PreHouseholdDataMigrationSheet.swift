//
//  PreHouseholdDataMigrationSheet.swift
//  forager
//
//  M7.2.3 Phase 4.1: Pre-Household Migration Prompt UI
//  Created on January 4, 2026
//
//  Prompts user to migrate existing personal data to household when creating
//  a new household. Shows counts of recipes, lists, and meal plans, and allows
//  user to choose "Move to Household" or "Keep Personal".
//

import SwiftUI

struct PreHouseholdDataMigrationSheet: View {
    
    // MARK: - Properties
    
    /// Number of recipes in personal library
    let recipeCount: Int
    
    /// Number of active weekly lists
    let listCount: Int
    
    /// Number of planned meals
    let mealPlanCount: Int
    
    /// Number of categories
    let categoryCount: Int
    
    /// Number of ingredient templates
    let templateCount: Int
    
    /// Callback when user chooses to move all data to household
    let onMoveAll: () -> Void
    
    /// Callback when user chooses to keep data personal
    let onKeepPersonal: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // M7.4: Removed ScrollView - content fits in .large sheet
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: "square.and.arrow.up.on.square")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding(.top, 16)

                    // Title
                    Text("Move Existing Data to Household?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    // Data summary
                    VStack(alignment: .leading, spacing: 10) {
                            if recipeCount > 0 {
                                HStack {
                                    Image(systemName: "book.pages")
                                        .foregroundColor(.blue)
                                        .frame(width: 22)
                                    Text("\(recipeCount) recipe\(recipeCount == 1 ? "" : "s")")
                                }
                                .font(.body)
                            }
                            
                            if listCount > 0 {
                                HStack {
                                    Image(systemName: "list.clipboard")
                                        .foregroundColor(.green)
                                        .frame(width: 22)
                                    Text("\(listCount) grocery list\(listCount == 1 ? "" : "s")")
                                }
                                .font(.body)
                            }
                            
                            if mealPlanCount > 0 {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                        .frame(width: 22)
                                    Text("\(mealPlanCount) meal plan\(mealPlanCount == 1 ? "" : "s")")
                                }
                                .font(.body)
                            }
                            
                            if categoryCount > 0 {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.purple)
                                        .frame(width: 22)
                                    Text("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")")
                                }
                                .font(.body)
                            }
                            
                            if templateCount > 0 {
                                HStack {
                                    Image(systemName: "text.badge.checkmark")
                                        .foregroundColor(.indigo)
                                        .frame(width: 22)
                                    Text("\(templateCount) ingredient template\(templateCount == 1 ? "" : "s")")
                                }
                                .font(.body)
                            }
                        }
                        .padding(.horizontal)

                        // Explanation
                        Text("Moving data to the household makes it visible to all members. You can keep it personal if you prefer.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }
                    .padding(.top, 8)

                Spacer()
                
                // Fixed buttons at bottom (always visible)
                VStack(spacing: 10) {
                    Divider()
                    
                    // Move to Household (Primary action)
                    Button(action: {
                        onMoveAll()
                        dismiss()
                    }) {
                        Text("Move to Household")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Keep Personal (Secondary action)
                    Button(action: {
                        onKeepPersonal()
                        dismiss()
                    }) {
                        Text("Keep Personal")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("Migration")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    PreHouseholdDataMigrationSheet(
        recipeCount: 42,
        listCount: 3,
        mealPlanCount: 7,
        categoryCount: 8,
        templateCount: 125,
        onMoveAll: { print("Move all data") },
        onKeepPersonal: { print("Keep personal") }
    )
}
