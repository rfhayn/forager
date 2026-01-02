//
//  CloudKitTestHarnessView.swift
//  forager
//
//  M7.2.3 Phase 3.5: CloudKit debugging and monitoring UI
//  DEBUG ONLY - Not included in Release builds
//
//  Created on December 31, 2025.
//

#if DEBUG
import SwiftUI
import CoreData

/// M7.2.3 Phase 3.5: CloudKit Test Harness
///
/// Debug-only UI for monitoring CloudKit sync and testing duplicate prevention
///
/// Features:
/// - Real-time CloudKit event monitoring
/// - Sync status display
/// - Manual sync trigger
/// - Event history (last 20 events)
/// - Duplicate prevention validation
struct CloudKitTestHarnessView: View {
    
    @StateObject private var diagnostics: CloudKitDiagnostics
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingClearConfirmation = false
    @State private var testResults: [String] = []
    
    init() {
        // Get CloudKit diagnostics from PersistenceController
        let container = PersistenceController.shared.container
        _diagnostics = StateObject(wrappedValue: CloudKitDiagnostics(container: container))
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Sync Status Section
                Section("CloudKit Sync Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        if diagnostics.isSyncing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Syncing...")
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Text("Idle")
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        if let lastSync = diagnostics.lastSyncDate {
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = diagnostics.lastError {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Error")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("Total Events")
                        Spacer()
                        Text("\(diagnostics.eventCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Recent Events Section
                Section {
                    if diagnostics.recentEvents.isEmpty {
                        Text("No events yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(diagnostics.recentEvents) { event in
                            EventRow(event: event)
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Events (\(diagnostics.recentEvents.count))")
                        Spacer()
                        if !diagnostics.recentEvents.isEmpty {
                            Button("Clear") {
                                showingClearConfirmation = true
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // MARK: - Test Actions Section
                Section("Test Actions") {
                    Button {
                        testCategoryDuplication()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Test Category Duplication")
                        }
                    }
                    
                    Button {
                        testTemplateDuplication()
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Test Template Duplication")
                        }
                    }
                    
                    Button {
                        testMealPlanDuplication()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Test Meal Plan Duplication")
                        }
                    }
                    
                    Button(role: .destructive) {
                        resetAllData()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Test Data")
                        }
                    }
                }
                
                // MARK: - Test Results Section
                if !testResults.isEmpty {
                    Section("Test Results") {
                        ForEach(testResults.indices, id: \.self) { index in
                            Text(testResults[index])
                                .font(.caption)
                                .foregroundColor(testResults[index].hasPrefix("✅") ? .green : 
                                               testResults[index].hasPrefix("❌") ? .red : .secondary)
                        }
                        
                        Button("Clear Results") {
                            testResults.removeAll()
                        }
                        .font(.caption)
                    }
                }
                
                // MARK: - Raw Status Section
                Section("Raw Status") {
                    Text(diagnostics.getStatusSummary())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("☁️ CloudKit Test Harness")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Clear event history?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    diagnostics.clearHistory()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // MARK: - Test Functions
    
    /// M7.2.3 Phase 3.5: Test category duplication prevention
    /// Attempts to create "Test Category" twice - should only create once
    private func testCategoryDuplication() {
        testResults.removeAll()
        testResults.append("🧪 Testing Category Duplication...")
        
        let repository = HouseholdCategoryRepository(context: viewContext)
        
        do {
            // Attempt 1: Create category
            let category1 = try repository.findOrCreate(
                name: "Test Category",
                color: "#FF0000",
                sortOrder: 100,
                isDefault: false
            )
            testResults.append("✅ Created category: \(category1.name ?? "unknown")")
            
            // Attempt 2: Try creating same category again
            let category2 = try repository.findOrCreate(
                name: "Test Category",
                color: "#00FF00",  // Different color
                sortOrder: 101,    // Different sort
                isDefault: false
            )
            
            // Check if same object returned
            if category1.id == category2.id {
                testResults.append("✅ PASS: Same category returned (no duplicate)")
                testResults.append("   Category ID: \(category1.id?.uuidString.prefix(8) ?? "nil")")
            } else {
                testResults.append("❌ FAIL: Different categories returned (duplicate created!)")
            }
            
            // Save
            try viewContext.save()
            
        } catch {
            testResults.append("❌ ERROR: \(error.localizedDescription)")
        }
    }
    
    /// M7.2.3 Phase 3.5: Test template duplication prevention
    /// Attempts to create "Test Ingredient" twice - should only create once
    private func testTemplateDuplication() {
        testResults.removeAll()
        testResults.append("🧪 Testing Template Duplication...")
        
        let repository = HouseholdIngredientTemplateRepository(context: viewContext)
        
        do {
            // Attempt 1: Create template
            let template1 = try repository.findOrCreate(
                name: "Test Ingredient",
                category: "Produce",
                isStaple: false
            )
            testResults.append("✅ Created template: \(template1.name ?? "unknown")")
            
            // Attempt 2: Try creating same template again
            let template2 = try repository.findOrCreate(
                name: "Test Ingredient",
                category: "Dairy & Fridge",  // Different category
                isStaple: true               // Different staple status
            )
            
            // Check if same object returned
            if template1.id == template2.id {
                testResults.append("✅ PASS: Same template returned (no duplicate)")
                testResults.append("   Template ID: \(template1.id?.uuidString.prefix(8) ?? "nil")")
                testResults.append("   Category updated: \(template2.category ?? "nil")")
            } else {
                testResults.append("❌ FAIL: Different templates returned (duplicate created!)")
            }
            
            // Save
            try viewContext.save()
            
        } catch {
            testResults.append("❌ ERROR: \(error.localizedDescription)")
        }
    }
    
    /// M7.2.3 Phase 3.5: Test meal plan duplication prevention
    /// Attempts to create meal for same date/slot twice - should only create once
    private func testMealPlanDuplication() {
        testResults.removeAll()
        testResults.append("🧪 Testing Meal Plan Duplication...")
        
        let repository = HouseholdPlannedMealRepository(context: viewContext)
        let testDate = Date()
        
        do {
            // Attempt 1: Create planned meal
            let meal1 = try repository.findOrCreate(
                date: testDate,
                mealType: "dinner",
                recipe: nil
            )
            testResults.append("✅ Created planned meal for \(meal1.slotKey ?? "unknown")")
            
            // Attempt 2: Try creating same meal again
            let meal2 = try repository.findOrCreate(
                date: testDate,
                mealType: "dinner",
                recipe: nil
            )
            
            // Check if same object returned
            if meal1.id == meal2.id {
                testResults.append("✅ PASS: Same meal returned (no duplicate)")
                testResults.append("   Meal ID: \(meal1.id?.uuidString.prefix(8) ?? "nil")")
                testResults.append("   Slot Key: \(meal1.slotKey ?? "nil")")
            } else {
                testResults.append("❌ FAIL: Different meals returned (duplicate created!)")
            }
            
            // Save
            try viewContext.save()
            
        } catch {
            testResults.append("❌ ERROR: \(error.localizedDescription)")
        }
    }
    
    /// M7.2.3 Phase 3.5: Reset test data
    /// Deletes all test categories, templates, and planned meals
    private func resetAllData() {
        testResults.removeAll()
        testResults.append("🗑️ Resetting test data...")
        
        // Delete test categories
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", "Test Category")
        
        if let categories = try? viewContext.fetch(categoryRequest) {
            for category in categories {
                viewContext.delete(category)
            }
            testResults.append("✅ Deleted \(categories.count) test categories")
        }
        
        // Delete test templates
        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", "Test Ingredient")
        
        if let templates = try? viewContext.fetch(templateRequest) {
            for template in templates {
                viewContext.delete(template)
            }
            testResults.append("✅ Deleted \(templates.count) test templates")
        }
        
        // Delete test planned meals (today's dinner slot)
        let mealRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        mealRequest.predicate = NSPredicate(format: "recipe == nil")
        
        if let meals = try? viewContext.fetch(mealRequest) {
            for meal in meals {
                viewContext.delete(meal)
            }
            testResults.append("✅ Deleted \(meals.count) test planned meals")
        }
        
        // Save
        do {
            try viewContext.save()
            testResults.append("✅ Test data reset complete")
        } catch {
            testResults.append("❌ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Event Row Component

private struct EventRow: View {
    let event: CloudKitDiagnostics.SyncEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Event type icon
            Image(systemName: event.success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(event.success ? .green : .red)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 4) {
                // Event type and time
                HStack {
                    Text(event.type.rawValue)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(event.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Error message if present
                if let error = event.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct CloudKitTestHarnessView_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitTestHarnessView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

#endif
