//
//  MealPlansListView.swift
//  forager
//
//  Created for M4.2.4: Multiple Meal Plans List View
//  M15.5: Rewritten with summary cards, day dots, Tonight snippet, Generate button
//

import SwiftUI
import CoreData

// MARK: - Main View

struct MealPlansListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MealPlan.startDate, ascending: false)],
        animation: .default
    ) private var allMealPlansFetch: FetchedResults<MealPlan>

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

    @State private var showingCreateSheet = false
    @State private var showCompleted = false
    @State private var refreshID = UUID()
    @State private var showingGroceryListAlert = false
    @State private var groceryListMessage = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    @StateObject private var mealPlanService = MealPlanService.shared

    var body: some View {
        contentView
            .navigationTitle("Meal Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateMealPlanSheet()
            }
            .alert("Grocery List", isPresented: $showingGroceryListAlert) {
                Button("OK") { }
            } message: {
                Text(groceryListMessage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                mealPlanService.updateActivePlanStatus()
                mealPlanService.updateCompletedStatus()
                viewContext.refreshAllObjects()
            }
            .onChange(of: popToRoot) { _, _ in
                if showingCreateSheet { showingCreateSheet = false }
            }
    }

    // MARK: - Content

    private var contentView: some View {
        ZStack {
            ForagerTheme.backgroundCanvas.ignoresSafeArea()

            if allMealPlans.isEmpty {
                ContentUnavailableView {
                    Label("Plan Your Week's Meals", systemImage: "calendar.badge.plus")
                } description: {
                    Text("Create a meal plan to organize your weekly cooking")
                } actions: {
                    Button("Create Your First Plan", systemImage: "calendar.badge.plus") {
                        showingCreateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ForagerTheme.accentPrimary)
                }
            } else {
                List {
                    // Active plans
                    ForEach(activePlans, id: \.objectID) { plan in
                        NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                            MealPlanSummaryCard(
                                mealPlan: plan,
                                status: .active,
                                onGenerateGroceryList: { generateGroceryList(from: plan) }
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(
                            top: ForagerTheme.Spacing.xs,
                            leading: ForagerTheme.Spacing.lg,
                            bottom: ForagerTheme.Spacing.xs,
                            trailing: ForagerTheme.Spacing.lg
                        ))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteMealPlan(plan)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    // Upcoming plans
                    ForEach(upcomingPlans, id: \.objectID) { plan in
                        NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                            MealPlanSummaryCard(mealPlan: plan, status: .upcoming)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(
                            top: ForagerTheme.Spacing.xs,
                            leading: ForagerTheme.Spacing.lg,
                            bottom: ForagerTheme.Spacing.xs,
                            trailing: ForagerTheme.Spacing.lg
                        ))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteMealPlan(plan)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    // Completed plans
                    if !completedPlans.isEmpty {
                        Section {
                            if showCompleted {
                                ForEach(completedPlans, id: \.objectID) { plan in
                                    NavigationLink(destination: MealPlanDetailView(mealPlan: plan)) {
                                        MealPlanSummaryCard(mealPlan: plan, status: .completed)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: ForagerTheme.Spacing.xs,
                                        leading: ForagerTheme.Spacing.lg,
                                        bottom: ForagerTheme.Spacing.xs,
                                        trailing: ForagerTheme.Spacing.lg
                                    ))
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteMealPlan(plan)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        } header: {
                            Button {
                                withAnimation { showCompleted.toggle() }
                            } label: {
                                HStack(spacing: ForagerTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ForagerTheme.textTertiary)
                                    Text("Completed (\(completedPlans.count))")
                                        .font(ForagerTheme.secondaryFont)
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                    Spacer()
                                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(ForagerTheme.textTertiary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(ForagerTheme.backgroundCanvas)
                .scrollContentBackground(.hidden)
                .refreshable {
                    mealPlanService.updateActivePlanStatus()
                    mealPlanService.updateCompletedStatus()
                    viewContext.refreshAllObjects()
                    refreshID = UUID()
                }
            }
        }
    }

    // MARK: - Plan Categorization

    private var activePlans: [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        return allMealPlans.filter { plan in
            guard let startDate = plan.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: startDate)
            guard let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDay) else { return false }
            return (startDay <= today) && (today <= endDate) && !plan.isCompleted
        }
    }

    private var upcomingPlans: [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        return allMealPlans.filter { plan in
            guard let startDate = plan.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: startDate)
            return startDay > today && !plan.isCompleted
        }
    }

    private var completedPlans: [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        return allMealPlans.filter { plan in
            if plan.isCompleted { return true }
            guard let startDate = plan.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: startDate)
            guard let endDate = Calendar.current.date(byAdding: .day, value: Int(plan.duration) - 1, to: startDay) else { return false }
            return endDate < today
        }
    }

    // MARK: - Actions

    private func deleteMealPlan(_ plan: MealPlan) {
        mealPlanService.deleteMealPlan(plan)
        if let error = mealPlanService.lastError {
            errorMessage = "Failed to delete meal plan: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func generateGroceryList(from plan: MealPlan) {
        if let list = mealPlanService.generateGroceryList(from: plan) {
            groceryListMessage = "Created \"\(list.name ?? "Grocery List")\" with \(list.items?.count ?? 0) items."
        } else {
            groceryListMessage = "No recipes found in this plan to generate a list from."
        }
        showingGroceryListAlert = true
    }
}

// MARK: - Summary Card

struct MealPlanSummaryCard: View {
    @ObservedObject var mealPlan: MealPlan
    let status: MealPlanStatus
    var onGenerateGroceryList: (() -> Void)? = nil

    @FetchRequest private var plannedMeals: FetchedResults<PlannedMeal>
    @ScaledMetric(relativeTo: .caption) private var dayCircleSize: CGFloat = 22

    init(mealPlan: MealPlan, status: MealPlanStatus, onGenerateGroceryList: (() -> Void)? = nil) {
        self.mealPlan = mealPlan
        self.status = status
        self.onGenerateGroceryList = onGenerateGroceryList

        let planID = mealPlan.id ?? UUID()
        self._plannedMeals = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \PlannedMeal.date, ascending: true)],
            predicate: NSPredicate(format: "mealPlan.id == %@", planID as CVarArg)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.md) {
            // Name + status
            HStack {
                Text(mealPlan.name ?? "Unnamed Plan")
                    .font(ForagerTheme.cardTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)
                Spacer()
                if status == .active {
                    Text("Active")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.accentPrimary)
                        .padding(.horizontal, ForagerTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(ForagerTheme.accentTint)
                        .clipShape(Capsule())
                }
            }

            // Date range
            Text(dateRangeText)
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)

            // Day dots — left-aligned to match Lists/Recipes card style
            dayDotsRow

            // Tonight snippet (active only)
            if status == .active, let todayMeal = mealForToday {
                Divider()
                tonightSnippet(todayMeal)
            }

            // Generate button — left-aligned to match card style
            if status == .active, let action = onGenerateGroceryList {
                Button(action: action) {
                    HStack(spacing: ForagerTheme.Spacing.xs) {
                        Image(systemName: "cart.badge.plus")
                        Text("Generate Grocery List")
                    }
                    .font(ForagerTheme.footnoteFont)
                    .foregroundStyle(ForagerTheme.accentPrimary)
                    .padding(.horizontal, ForagerTheme.Spacing.md)
                    .padding(.vertical, ForagerTheme.Spacing.sm)
                    .background(ForagerTheme.accentTint)
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
                }
            }
        }
        .foragerGlassCard()
        .opacity(status == .completed ? 0.6 : 1.0)
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mealPlan.name ?? "Unnamed Plan"), \(dateRangeText), \(plannedMeals.count) of \(Int(mealPlan.duration)) days planned")
        .accessibilityHint("Double tap to open meal plan")
    }

    // MARK: - Day Dots

    private var dayDotsRow: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            ForEach(Array(daysInPlan.enumerated()), id: \.offset) { _, date in
                let isPlanned = plannedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
                let dayInitial = dayLetter(for: date)

                Text(dayInitial)
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(isPlanned ? .white : ForagerTheme.textTertiary)
                    .frame(width: dayCircleSize, height: dayCircleSize)
                    .background(
                        Circle()
                            .fill(isPlanned ? ForagerTheme.accentPrimary : .clear)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(isPlanned ? .clear : ForagerTheme.borderDefault, lineWidth: 1)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly schedule: \(plannedMeals.count) days planned")
    }

    // MARK: - Tonight Snippet

    private func tonightSnippet(_ meal: PlannedMeal) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
                Text("TONIGHT")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(ForagerTheme.textTertiary)

                if meal.isQuickOption, let option = meal.quickOptionEnum {
                    HStack(spacing: ForagerTheme.Spacing.xs) {
                        Image(systemName: option.icon)
                        Text(option.rawValue)
                    }
                    .font(ForagerTheme.secondaryFont.bold())
                    .foregroundStyle(ForagerTheme.textPrimary)
                } else if let recipe = meal.recipe {
                    Text("\(recipe.recipeDisplayTitle) · \(recipe.recipeServingsDescription)")
                        .font(ForagerTheme.secondaryFont.bold())
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private var daysInPlan: [Date] {
        guard let start = mealPlan.startDate else { return [] }
        return (0..<Int(mealPlan.duration)).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: start)
        }
    }

    private var plannedDates: [Date] {
        plannedMeals.compactMap { $0.date }
    }

    private var mealForToday: PlannedMeal? {
        plannedMeals.first { meal in
            guard let mealDate = meal.date else { return false }
            return Calendar.current.isDateInToday(mealDate)
        }
    }

    private func dayLetter(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        let initials = ["S", "M", "T", "W", "T", "F", "S"]
        return initials[weekday - 1]
    }

    private var dateRangeText: String {
        guard let startDate = mealPlan.startDate else { return "No date set" }
        let endDate = Calendar.current.date(byAdding: .day, value: Int(mealPlan.duration) - 1, to: startDate) ?? startDate
        return "\(DateFormatter.monthDay.string(from: startDate)) – \(DateFormatter.monthDay.string(from: endDate))"
    }
}

// MARK: - Status Enum

enum MealPlanStatus {
    case active
    case upcoming
    case completed

    var indicatorColor: Color {
        switch self {
        case .active: return ForagerTheme.accentPrimary
        case .upcoming: return ForagerTheme.accentSecondary
        case .completed: return ForagerTheme.textTertiary
        }
    }

    var iconName: String {
        switch self {
        case .active: return "calendar.circle.fill"
        case .upcoming: return "calendar.badge.clock"
        case .completed: return "checkmark.circle.fill"
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
