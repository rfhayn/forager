//
//  DefaultSeeder.swift
//  forager
//
//  M7.2.3 Phase 1.2: Extracted from Persistence.swift
//  M7.2.3 Phase 3.1: Updated to use HouseholdCategoryRepository
//  Single responsibility: Idempotent default data seeding
//
//  Created on December 30, 2025.
//

import CoreData
import Foundation

/// M7.2.3 Phase 1.2: Idempotent default data seeding
/// M7.2.3 Phase 3.1: Uses HouseholdCategoryRepository for semantic uniqueness
///
/// Responsibilities:
/// - Seed default categories (7 categories)
/// - Be idempotent: safe to run multiple times
/// - CloudKit-safe: query before create (semantic uniqueness)
/// - Handle race conditions gracefully
///
/// Does NOT handle:
/// - Sample data (only in SwiftUI previews)
/// - Migrations (handled by old Persistence.swift)
/// - Container setup (see PersistenceCore)
final class DefaultSeeder {
    
    // MARK: - Seeding Status Tracking
    
    /// UserDefaults key for tracking if default seeding has completed
    private static let defaultsSeedingKey = "M7.2.3_DefaultsSeedingCompleted"
    
    /// Check if default seeding has been completed
    static var hasSeededDefaults: Bool {
        return UserDefaults.standard.bool(forKey: defaultsSeedingKey)
    }
    
    /// Mark default seeding as complete
    private static func markSeedingComplete() {
        UserDefaults.standard.set(true, forKey: defaultsSeedingKey)
        UserDefaults.standard.set(Date(), forKey: "M7.2.3_DefaultsSeedingDate")
        print("✅ M7.2.3: Default seeding marked as complete")
    }
    
    // MARK: - Default Categories Data
    
    /// M7.2.3: Default categories with their display properties
    /// These are the 7 core categories that every user should have
    private static let defaultCategories: [(name: String, color: String, sortOrder: Int16)] = [
        ("Produce", "#4CAF50", 0),
        ("Deli & Meat", "#FF9800", 1),
        ("Dairy & Fridge", "#2196F3", 2),
        ("Bread & Frozen", "#9C27B0", 3),
        ("Pantry & Canned", "#795548", 4),
        ("Snacks & Beverages", "#F44336", 5),
        ("Health & Personal", "#00BCD4", 6)
    ]
    
    // MARK: - Public Seeding Methods
    
    /// M7.2.3: Seeds default data if needed
    /// Idempotent: safe to run multiple times
    /// CloudKit-safe: uses query-before-create pattern via repositories
    ///
    /// - Parameter context: Core Data managed object context
    /// - Throws: Core Data errors during save
    static func seedDefaultsIfNeeded(in context: NSManagedObjectContext) throws {
        // Quick exit if already seeded (UserDefaults check)
        if hasSeededDefaults {
            print("ℹ️ M7.2.3: Defaults already seeded, skipping")
            return
        }
        
        print("🌱 M7.2.3: Starting default data seeding...")
        let startTime = Date()
        
        // Seed default categories using repository (Phase 3.1)
        try seedDefaultCategories(in: context)
        
        // Mark as complete
        markSeedingComplete()
        
        let duration = Date().timeIntervalSince(startTime)
        print("✅ M7.2.3: Default seeding completed in \(String(format: "%.2f", duration))s")
    }
    
    // MARK: - Category Seeding (Phase 3.1: Using Repository)
    
    /// M7.2.3 Phase 3.1: Seeds default categories using HouseholdCategoryRepository
    /// Idempotent: repository checks if category exists before creating
    /// CloudKit-safe: tolerates race conditions and concurrent creates
    ///
    /// - Parameter context: Core Data managed object context
    /// - Throws: Core Data errors during fetch or save
    private static func seedDefaultCategories(in context: NSManagedObjectContext) throws {
        print("🏷️ M7.2.3 Phase 3.1: Seeding default categories via repository...")
        
        // Create repository instance
        let repository = HouseholdCategoryRepository(context: context)
        
        var createdCount = 0
        var existingCount = 0
        
        for (name, color, sortOrder) in defaultCategories {
            // Use repository's findOrCreate (handles semantic uniqueness)
            let category = try repository.findOrCreate(
                name: name,
                color: color,
                sortOrder: sortOrder,
                isDefault: true
            )
            
            // Check if it was newly created or already existed
            if category.dateCreated?.timeIntervalSinceNow ?? -1000 > -1 {
                createdCount += 1
            } else {
                existingCount += 1
            }
        }
        
        // Save if any changes were made
        if context.hasChanges {
            try context.save()
            print("✅ M7.2.3 Phase 3.1: Repository seeding complete - \(createdCount) created, \(existingCount) existing")
        } else {
            print("ℹ️ M7.2.3 Phase 3.1: All \(existingCount) categories already exist")
        }
    }
    
    // MARK: - Development/Testing Support
    
    #if DEBUG
    /// M7.2.3: Reset seeding status for testing (DEBUG only)
    /// Allows re-running seeding logic during development
    static func resetSeedingStatus() {
        UserDefaults.standard.removeObject(forKey: defaultsSeedingKey)
        UserDefaults.standard.removeObject(forKey: "M7.2.3_DefaultsSeedingDate")
        print("🔄 M7.2.3: Seeding status reset for testing")
    }
    
    /// M7.2.3: Get seeding status report (DEBUG only)
    /// Useful for debugging and verification
    static func getSeedingStatusReport(context: NSManagedObjectContext) -> String {
        var report = "🔍 M7.2.3 DEFAULT SEEDING STATUS\n\n"
        
        if hasSeededDefaults {
            report += "✅ Seeding Status: COMPLETED\n"
            if let date = UserDefaults.standard.object(forKey: "M7.2.3_DefaultsSeedingDate") as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                report += "📅 Completion Date: \(formatter.string(from: date))\n"
            }
        } else {
            report += "⏳ Seeding Status: PENDING\n"
        }
        
        // Count actual categories in database
        do {
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            let categoryCount = try context.count(for: request)
            
            report += "\n📊 Current Data:\n"
            report += "   Total categories: \(categoryCount)\n"
            report += "   Expected categories: \(defaultCategories.count)\n"
            
            if categoryCount >= defaultCategories.count {
                report += "\n🎯 Status: All default categories present"
            } else {
                report += "\n⚠️ Status: Missing categories (\(defaultCategories.count - categoryCount))"
            }
            
        } catch {
            report += "\n❌ Error fetching category count: \(error.localizedDescription)"
        }
        
        return report
    }
    #endif
}
