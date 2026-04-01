// DashboardView.swift
// FUI-1.1: Placeholder dashboard — greeting + gear icon to Settings
// FUI-1.7 will build this out with TodaysMealsCard, GroceryRunCard, etc.

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                Text(greeting)
                    .font(ForagerTheme.screenTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .padding(.top, ForagerTheme.Spacing.md)

                ContentUnavailableView(
                    "Dashboard Coming Soon",
                    systemImage: "sparkles",
                    description: Text("Meal plans, grocery status, and recipe spotlights will appear here.")
                )
            }
            .padding(.horizontal, ForagerTheme.Spacing.md)
        }
        .background(ForagerTheme.backgroundPrimary)
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
}
