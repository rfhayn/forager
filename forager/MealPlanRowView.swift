//
//  MealPlanRowView.swift
//  forager
//
//  Created for M4.2.4: Multiple Meal Plans List View
//  Row component for displaying meal plan summary in list
//  Follows WeeklyListRowView pattern with @FetchRequest for live updates
//

import SwiftUI
import CoreData

// M4.2.4: Row view for displaying meal plan in list
// Shows plan name, date range, progress, and status indicator
// Uses @FetchRequest for live progress updates (follows WeeklyListRowView pattern)
struct MealPlanRowView: View {
    @ObservedObject var mealPlan: MealPlan
    let status: MealPlanStatus
    
    // M4.2.4: Fetch planned meals for this specific plan
    // Live updates when meals are added/removed
    // Pattern: Matches WeeklyListRowView @FetchRequest approach
    @FetchRequest private var plannedMeals: FetchedResults<PlannedMeal>
    
    // M4.2.4: Initialize with meal plan and configure fetch request
    // Filters plannedMeals by plan ID for accurate progress calculation
    init(mealPlan: MealPlan, status: MealPlanStatus) {
        self.mealPlan = mealPlan
        self.status = status
        
        // Configure FetchRequest for this plan's meals
        let planID = mealPlan.id ?? UUID()
        let predicate = NSPredicate(format: "mealPlan.id == %@", planID as CVarArg)
        self._plannedMeals = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)],
            predicate: predicate
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // M4.2.4: Plan name or auto-generated date range
            HStack {
                // Status indicator circle
                Circle()
                    .fill(status.indicatorColor)
                    .frame(width: 8, height: 8)
                
                Text(displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // M4.2.4: Active badge for current plan
                if status == .active {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ForagerTheme.statusSuccessFG.opacity(0.2))
                        .foregroundStyle(ForagerTheme.statusSuccessFG)
                        .cornerRadius(ForagerTheme.Radius.sm)
                }
            }
            
            // M4.2.4: Date range
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.textSecondary)
                
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
            
            // M4.2.4: Progress indicator
            // Shows how many days have recipes assigned
            HStack {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                    }
                }
                .frame(height: 8)
                
                // Progress text
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    
    // M4.2.4: Display name - either custom name or auto-generated date range
    private var displayName: String {
        if let name = mealPlan.name, !name.isEmpty {
            return name
        }
        // Auto-generate from date if no custom name
        return "Week of \(startDateText)"
    }
    
    // M4.2.4: Date range text for display
    private var dateRangeText: String {
        guard let startDate = mealPlan.startDate else { return "No date set" }
        let endDate = Calendar.current.date(byAdding: .day, value: Int(mealPlan.duration) - 1, to: startDate) ?? startDate
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    // M4.2.4: Start date text for auto-generated names
    private var startDateText: String {
        guard let startDate = mealPlan.startDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: startDate)
    }
    
    // M4.2.4: Progress text showing meals assigned
    // Uses live @FetchRequest count for accuracy
    private var progressText: String {
        let plannedCount = plannedMeals.count
        let totalDays = Int(mealPlan.duration)
        return "\(plannedCount) of \(totalDays) days"
    }
    
    // M4.2.4: Progress percentage for visual bar
    private var progressPercentage: Double {
        let totalDays = Double(mealPlan.duration)
        guard totalDays > 0 else { return 0 }
        return Double(plannedMeals.count) / totalDays
    }
    
    // M4.2.4: Progress bar color
    // Green when fully planned, blue otherwise
    // Gray for completed plans
    private var progressColor: Color {
        if status == .completed {
            return ForagerTheme.textTertiary
        }
        return progressPercentage >= 1.0 ? ForagerTheme.statusSuccessFG : ForagerTheme.accentPrimary
    }
}

// MARK: - Preview

#Preview("Active Plan") {
    @Previewable @State var context = PersistenceController.preview.container.viewContext
    
    let plan = MealPlan(context: context)
    plan.id = UUID()
    plan.name = "This Week's Meals"
    plan.startDate = Date()
    plan.duration = 7
    plan.isActive = true
    plan.isCompleted = false
    
    return List {
        MealPlanRowView(mealPlan: plan, status: .active)
    }
    .environment(\.managedObjectContext, context)
}

#Preview("Upcoming Plan") {
    @Previewable @State var context = PersistenceController.preview.container.viewContext
    
    let plan = MealPlan(context: context)
    plan.id = UUID()
    plan.name = nil  // Will auto-generate
    plan.startDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
    plan.duration = 7
    plan.isActive = false
    plan.isCompleted = false
    
    return List {
        MealPlanRowView(mealPlan: plan, status: .upcoming)
    }
    .environment(\.managedObjectContext, context)
}

#Preview("Completed Plan") {
    @Previewable @State var context = PersistenceController.preview.container.viewContext
    
    let plan = MealPlan(context: context)
    plan.id = UUID()
    plan.name = "Holiday Dinner Week"
    plan.startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())
    plan.duration = 7
    plan.isActive = false
    plan.isCompleted = true
    plan.completedDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
    
    return List {
        MealPlanRowView(mealPlan: plan, status: .completed)
    }
    .environment(\.managedObjectContext, context)
}
