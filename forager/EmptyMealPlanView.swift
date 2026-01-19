//
//  EmptyMealPlanView.swift
//  forager
//
//  Created for M4.2: Calendar-Based Meal Planning Core
//  Empty state view shown when no active meal plan exists
//

import SwiftUI

// M4.2: Empty state for meal planning
// Shown when user first accesses meal planning or after archiving a plan
// Provides clear call-to-action to create first meal plan
struct EmptyMealPlanView: View {
    
    // MARK: - Properties
    
    // M4.2: Closure to trigger meal plan creation
    let onCreatePlan: () -> Void
    
    // M4.2: User preferences for displaying configured settings
    @StateObject private var preferences = UserPreferencesService.shared
    
    // M7.2.1: Core Data context for SettingsView
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // Title and description
            VStack(spacing: 8) {
                Text("No Active Meal Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first meal plan to start organizing your weekly meals")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Settings preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Your meal plan will:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                settingRow(
                    icon: "calendar",
                    text: "Last \(preferences.mealPlanDuration) days"
                )
                
                settingRow(
                    icon: "calendar.day.timeline.leading",
                    text: "Start on \(dayName(for: preferences.mealPlanStartDay))"
                )
                
                if preferences.autoNameMealPlans {
                    settingRow(
                        icon: "text.badge.checkmark",
                        text: "Auto-name based on dates"
                    )
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 32)
            
            // Create button
            Button(action: onCreatePlan) {
                Label("Create Meal Plan", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            // Settings link
            NavigationLink(destination: SettingsView()) {
                Text("Change meal plan settings")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    // M4.2: Individual setting row with icon and text
    @ViewBuilder
    private func settingRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Helpers
    
    // M4.2: Converts day index (0-6) to day name
    private func dayName(for dayIndex: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[min(max(dayIndex, 0), 6)]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmptyMealPlanView {
            print("Create meal plan tapped")
        }
    }
}
