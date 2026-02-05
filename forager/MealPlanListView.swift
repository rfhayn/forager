//
//  MealPlansListView.swift
//  forager
//
//  Created for M4.2.4: Multiple Meal Plans List View
//  Main entry point for meal planning, displays all meal plans organized by status
//  Follows WeeklyListsView architecture pattern from M1
//

import SwiftUI
import CoreData

// M4.2.4: Main list view for all meal plans
// Displays plans organized into Active, Upcoming, and Completed sections
// Pattern: Follows proven WeeklyListsView architecture
struct MealPlansListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    // M4.2.4: Fetch all meal plans, sorted by start date (newest first)
    // Uses @FetchRequest for automatic UI updates when plans change
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MealPlan.startDate, ascending: false)],
        animation: .default
    ) private var allMealPlansFetch: FetchedResults<MealPlan>

    // M7.3.2: Filter meal plans based on current household context
    // M7.2.2 FIX: Use currentHouseholdKey which has fallback for nil household.id
    private var allMealPlans: [MealPlan] {
        let currentHouseholdKey = householdService.currentHouseholdKey
        return allMealPlansFetch.filter { plan in
            if let householdKey = currentHouseholdKey {
                return plan.householdKey == householdKey
            } else {
                return plan.householdKey == nil
            }
        }
    }

    // M4.2.4: UI state management
    @State private var showingCreateSheet = false
    @State private var showCompleted = false  // Completed section collapsed by default
    @State private var refreshID = UUID()
    
    // M4.2.4: Service for plan management
    @StateObject private var mealPlanService = MealPlanService.shared
    
    var body: some View {
        contentView
            .navigationTitle("Meal Plans")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateMealPlanSheet()
            }
            .onAppear {
                // M4.2.4: Update plan statuses on view appear
                // Ensures active plan logic is current
                mealPlanService.updateActivePlanStatus()
                mealPlanService.updateCompletedStatus()
                viewContext.refreshAllObjects()
            }
            .onChange(of: popToRoot) { _, _ in
                if showingCreateSheet { showingCreateSheet = false }
            }
    }
    
    // MARK: - Content View
    
    // M4.2.4: Main content - shows empty state or plan list
    // Matches WeeklyListsView pattern for consistency
    private var contentView: some View {
        ZStack {
            if allMealPlans.isEmpty {
                emptyStateView
            } else {
                plansListView
            }
        }
    }
    
    // MARK: - Empty State
    
    // M4.2.4: Empty state when no meal plans exist
    // Encourages user to create first plan
    // Pattern: Uses StandardEmptyStateView for consistency
    private var emptyStateView: some View {
        StandardEmptyStateView(
            iconName: "calendar.badge.plus",
            title: "No Meal Plans Yet",
            subtitle: "Start organizing your weekly meals!",
            buttonIcon: "calendar.badge.plus",
            buttonText: "Create Meal Plan",
            buttonAction: { showingCreateSheet = true }
        )
    }
    
    // MARK: - Plans List
    
    // M4.2.4: List of all meal plans organized into sections
    // Active plans at top, then upcoming, then completed (collapsible)
    private var plansListView: some View {
        List {
            // M4.2.4: Active Plans Section
            // Shows plans containing today's date
            // Should be 0 or 1 plan (only one active at a time)
            if !activePlans.isEmpty {
                Section {
                    ForEach(activePlans, id: \.self) { plan in
                        NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                            MealPlanRowView(mealPlan: plan, status: .active)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(.green)
                        Text("Active Plan")
                    }
                }
            }
            
            // M4.2.4: Upcoming Plans Section
            // Shows plans with start date in the future
            if !upcomingPlans.isEmpty {
                Section {
                    ForEach(upcomingPlans, id: \.self) { plan in
                        NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                            MealPlanRowView(mealPlan: plan, status: .upcoming)
                        }
                    }
                    .onDelete(perform: deletePlans)
                } header: {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text("Upcoming Plans")
                    }
                }
            }
            
            // M4.2.4: Completed Plans Section (Collapsible)
            // Shows historical plans, collapsed by default to reduce clutter
            // Preserved for analytics and recipe usage history
            if !completedPlans.isEmpty {
                Section {
                    // M4.2.4: Disclosure group for collapsible section
                    DisclosureGroup(
                        isExpanded: $showCompleted,
                        content: {
                            ForEach(completedPlans, id: \.self) { plan in
                                NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                                    MealPlanRowView(mealPlan: plan, status: .completed)
                                }
                            }
                            .onDelete(perform: deletePlans)
                        },
                        label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gray)
                                Text("Completed Plans (\(completedPlans.count))")
                                    .font(.headline)
                            }
                        }
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            // M4.2.4: Pull-to-refresh updates plan statuses
            mealPlanService.updateActivePlanStatus()
            mealPlanService.updateCompletedStatus()
            viewContext.refreshAllObjects()
            refreshID = UUID()
        }
    }
    
    // MARK: - Toolbar

    // M4.2.4: Toolbar with create button
    // M7.4: Standardized to simple "+" icon (iOS convention)
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingCreateSheet = true }) {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Plan Categorization
    
    // M4.2.4: Active plans - contains today's date and not completed
    // Should only be 0 or 1 plan (enforced by status update logic)
    private var activePlans: [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        return allMealPlans.filter { plan in
            guard let startDate = plan.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: startDate)
            guard let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDay) else { return false }
            
            return (startDay <= today) && (today <= endDate) && !plan.isCompleted
        }
    }
    
    // M4.2.4: Upcoming plans - start date in future and not completed
    private var upcomingPlans: [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        return allMealPlans.filter { plan in
            guard let startDate = plan.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: startDate)
            return startDay > today && !plan.isCompleted
        }
    }
    
    // M4.2.4: Completed plans - either manually completed or end date passed
    private var completedPlans: [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        return allMealPlans.filter { plan in
            // Manually completed
            if plan.isCompleted {
                return true
            }
            
            // Auto-completed (end date passed)
            guard let startDate = plan.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: startDate)
            guard let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDay) else { return false }
            
            return endDate < today
        }
    }
    
    // MARK: - Actions
    
    // M4.2.4: Delete meal plans with confirmation
    // Uses swipe-to-delete gesture on rows
    private func deletePlans(at offsets: IndexSet) {
        // Note: Determine which section the delete came from based on context
        // For now, handle upcoming and completed plans
        withAnimation {
            for index in offsets {
                let planToDelete: MealPlan
                if !upcomingPlans.isEmpty && index < upcomingPlans.count {
                    planToDelete = upcomingPlans[index]
                } else if !completedPlans.isEmpty {
                    planToDelete = completedPlans[index]
                } else {
                    continue
                }
                
                mealPlanService.deleteMealPlan(planToDelete)
            }
        }
    }
}

// MARK: - M4.2.4: Plan Status Enum

// M4.2.4: Status categories for meal plans
// Used by MealPlanRowView to display appropriate indicator
enum MealPlanStatus {
    case active    // Contains today, not completed
    case upcoming  // Starts in future, not completed
    case completed // Manually completed or end date passed
    
    // Visual indicator color for each status
    var indicatorColor: Color {
        switch self {
        case .active:
            return .green
        case .upcoming:
            return .blue
        case .completed:
            return .gray
        }
    }
    
    // Icon for each status
    var iconName: String {
        switch self {
        case .active:
            return "calendar.circle.fill"
        case .upcoming:
            return "calendar.badge.clock"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        MealPlansListView(popToRoot: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
