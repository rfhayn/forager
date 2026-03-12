//
//  CreateMealPlanSheet.swift
//  forager
//
//  Created for M4.2.4: Multiple Meal Plans List View
//  Quick plan creation with start and end date pickers
//  Enhanced with day-of-week display for better UX
//

import SwiftUI
import CoreData

// M4.2.4: Quick meal plan creation sheet
// Uses start and end date pickers instead of duration stepper
// Shows day of week + date for clarity (e.g., "Mon, Nov 3")
struct CreateMealPlanSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // M4.2.4: User preferences for smart defaults
    @StateObject private var prefs = UserPreferencesService.shared
    
    // M4.2.4: Inline mode support for use within other sheets
    var isInline: Bool = false
    var onCreated: ((MealPlan) -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    // M4.2.4: Form fields - now using end date instead of duration
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate: Date
    
    // M4.2.4: Validation state
    @State private var validationError: String?
    @State private var isValidating = false
    
    // M4.2.4: Initialize with smart end date based on user preference
    init(isInline: Bool = false, onCreated: ((MealPlan) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.isInline = isInline
        self.onCreated = onCreated
        self.onCancel = onCancel
        
        // Calculate default end date from preferences
        let prefsDuration = UserPreferencesService.shared.mealPlanDuration
        let defaultEndDate = Calendar.current.date(byAdding: .day, value: prefsDuration - 1, to: Date()) ?? Date()
        _endDate = State(initialValue: defaultEndDate)
    }
    
    var body: some View {
        if isInline {
            // Inline mode - no NavigationView wrapper
            formContent
        } else {
            // Modal mode - wrapped in NavigationView
            NavigationView {
                formContent
                    .navigationTitle("Create Meal Plan")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                createMealPlan()
                            }
                            .disabled(isValidating)
                        }
                    }
            }
        }
    }
    
    // MARK: - Form Content
    
    // M4.2.4: Main form layout with date range pickers
    private var formContent: some View {
        Form {
            nameSection
            dateRangeSection
            
            if let error = validationError {
                validationErrorSection(error)
            }
            
            if isInline {
                actionButtonsSection
            }
        }
    }
    
    // M4.2.4: Optional name field with auto-generation hint
    private var nameSection: some View {
        Section {
            TextField("Plan name (optional)", text: $name)
        } header: {
            Text("Name")
        } footer: {
            if name.isEmpty {
                Text("If left empty, a name will be auto-generated based on the date range")
                    .font(.caption)
            }
        }
    }
    
    // M4.2.4: Date range section with start and end date pickers
    // Shows day of week + date for better UX
    private var dateRangeSection: some View {
        Section {
            // Start Date Picker with day of week display
            DatePicker(
                selection: $startDate,
                displayedComponents: .date
            ) {
                HStack {
                    Text("Start Date")
                    Spacer()
                    Text(formatDateWithDay(startDate))
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
            .onChange(of: startDate) { oldValue, newValue in
                // Ensure end date is after start date
                if newValue > endDate {
                    endDate = Calendar.current.date(byAdding: .day, value: 6, to: newValue) ?? newValue
                }
                validateDates()
            }
            
            // End Date Picker with day of week display
            DatePicker(
                selection: $endDate,
                in: startDate...,  // End date must be >= start date
                displayedComponents: .date
            ) {
                HStack {
                    Text("End Date")
                    Spacer()
                    Text(formatDateWithDay(endDate))
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
            .onChange(of: endDate) { oldValue, newValue in
                validateDates()
            }
        } header: {
            Text("Dates")
        } footer: {
            Text(dateRangeSummary)
                .font(.caption)
        }
    }
    
    // M4.2.4: Display validation errors
    private func validationErrorSection(_ message: String) -> some View {
        Section {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(ForagerTheme.statusDangerFG)
        }
    }
    
    // M4.2.4: Inline action buttons (for use within other sheets)
    private var actionButtonsSection: some View {
        Section {
            Button(action: createMealPlan) {
                HStack {
                    Spacer()
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Create Plan")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(isValidating)
            
            if let cancel = onCancel {
                Button("Cancel", role: .cancel, action: cancel)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // M4.2.4: Format date with day of week only
    // Returns "Mon" or "Sun"
    private func formatDateWithDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"  // "Mon", "Tue", etc.
        return formatter.string(from: date)
    }
    
    // M4.2.4: Calculate duration from date range
    private var calculatedDuration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1  // +1 because both start and end days are included
    }
    
    // M4.2.4: Summary text showing full date range
    private var dateRangeSummary: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let days = calculatedDuration
        let dayText = days == 1 ? "day" : "days"
        
        return "Plan will run from \(formatter.string(from: startDate)) to \(formatter.string(from: endDate)) (\(days) \(dayText))"
    }
    
    // M4.2.4: Validate dates using MealPlanService
    // Checks for overlaps with existing plans and valid duration
    private func validateDates() {
        isValidating = true
        
        let duration = calculatedDuration
        
        // Check duration bounds (3-14 days)
        if duration < 3 {
            validationError = "Plan must be at least 3 days"
            isValidating = false
            return
        }
        
        if duration > 14 {
            validationError = "Plan cannot exceed 14 days"
            isValidating = false
            return
        }
        
        // Use MealPlanService validation for overlaps
        let service = MealPlanService.shared
        let result = service.validatePlanDates(
            startDate: startDate,
            duration: duration,
            excludingPlan: nil
        )
        
        if result.isValid {
            validationError = nil
        } else {
            validationError = result.errorMessage
        }
        
        isValidating = false
    }
    
    // M4.2.4: Generate auto-name if user didn't provide one
    // Uses "Week of [start] - [end]" format with medium dates
    private func generateAutoName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Week of \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    // M4.2.4: Create the meal plan with validation
    // Calls appropriate callback based on mode (inline vs modal)
    private func createMealPlan() {
        // Final validation check
        validateDates()
        
        if validationError != nil {
            return
        }
        
        let duration = calculatedDuration
        
        // M9.13: Route through MealPlanService for factory-based creation (ADR 014)
        // Pass all values so MealPlanService applies them in a single save.
        if let plan = MealPlanService.shared.createMealPlan(
            startDate: Calendar.current.startOfDay(for: startDate),
            name: name.isEmpty ? nil : name,
            duration: duration
        ) {
            MealPlanService.shared.updateActivePlanStatus()

            if isInline, let callback = onCreated {
                callback(plan)
            } else {
                dismiss()
            }
        } else {
            validationError = "Failed to create meal plan. Please try again."
        }
    }
}

// MARK: - Preview

#Preview("Modal Mode") {
    let context = PersistenceController.preview.container.viewContext
    
    return CreateMealPlanSheet()
        .environment(\.managedObjectContext, context)
}

#Preview("Inline Mode") {
    let context = PersistenceController.preview.container.viewContext
    
    return NavigationView {
        Form {
            Section {
                Text("Parent Form Content")
            }
            
            CreateMealPlanSheet(
                isInline: true,
                onCreated: { plan in
                    print("Created plan: \(plan.name ?? "unnamed")")
                },
                onCancel: {
                    print("Cancelled")
                }
            )
        }
        .navigationTitle("Test Container")
    }
    .environment(\.managedObjectContext, context)
}
