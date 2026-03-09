//
//  DefaultSeeder.swift
//  forager
//
//  M7.2.3 Phase 1.2: Extracted from Persistence.swift
//  M7.2.3 Phase 3.1: Updated to use HouseholdCategoryRepository
//  M7.2.3 Phase 3.7: Using NSUbiquitousKeyValueStore for cross-device coordination
//  M7.2.3 Phase 2.6: Added factory-based seeding pattern
//  Single responsibility: Idempotent default data seeding
//
//  Created on December 30, 2025.
//

import CoreData
import Foundation

/// M7.2.3 Phase 1.2: Idempotent default data seeding
/// M7.2.3 Phase 3.1: Uses HouseholdCategoryRepository for semantic uniqueness
/// M7.2.3 Phase 3.8: Simplified - duplicates handled by CategoryDeduplicator
/// M7.2.3 Phase 2.6: Example of factory-based household seeding
///
/// Responsibilities:
/// - Seed default categories (7 categories total, only "Uncategorized" is protected)
/// - CloudKit-safe: repository pattern ensures semantic uniqueness on same device
/// - (NEW) Demonstrate performScopedWrite + factory pattern for household data
///
/// Strategy:
/// - Let each device seed independently (fast, simple)
/// - CategoryDeduplicator removes duplicates after CloudKit sync
/// - Repository prevents duplicates on same device via semanticKey
///
/// Does NOT handle:
/// - Cross-device coordination (handled by CategoryDeduplicator)
/// - Sample data (only in SwiftUI previews)
/// - Migrations (handled by old Persistence.swift)
/// - Container setup (see PersistenceController)
final class DefaultSeeder {
    
    /// Per-device flag (local only, for quick exit)
    private static let defaultsSeedingKey = "M7.2.3_DefaultsSeedingCompleted"
    
    /// Check if default seeding has been completed (local device)
    static var hasSeededDefaults: Bool {
        return UserDefaults.standard.bool(forKey: defaultsSeedingKey)
    }
    
    /// Mark default seeding as complete
    private static func markSeedingComplete() {
        UserDefaults.standard.set(true, forKey: defaultsSeedingKey)
        UserDefaults.standard.set(Date(), forKey: "M7.2.3_DefaultsSeedingDate")
        #if DEBUG
        print("✅ M7.2.3: Default seeding marked as complete")
        #endif
    }
    
    // MARK: - Default Categories Data
    
    /// M7.2.3: Default categories with their display properties
    /// These are the 7 core categories that every user should have
    /// "Uncategorized" is the ONLY protected category (isDefault = true) - needed for unassigned ingredients
    private static let defaultCategories: [(name: String, color: String, sortOrder: Int16, isProtected: Bool)] = [
        ("Produce", "#4CAF50", 0, false),                    // Green - Store entrance
        ("Deli & Meat", "#F44336", 1, false),                // Red - Back perimeter
        ("Dairy & Fridge", "#2196F3", 2, false),            // Blue - Back wall
        ("Bread & Frozen", "#FF9800", 3, false),            // Orange - Side aisles
        ("Pantry", "#795548", 4, false),                      // Brown - Center aisles
        ("Snacks, Drinks, & Other", "#9C27B0", 5, false),   // Purple - Checkout area
        ("Uncategorized", "#9E9E9E", 999, true)             // PROTECTED: Gray - Default for unassigned
    ]
    
    // MARK: - Public Seeding Methods
    
    /// M7.2.3: Seeds default data if needed
    /// M7.2.3 Phase 3.8: Simplified approach - let each device seed independently
    /// 
    /// Strategy:
    /// 1. Check if THIS device has already seeded (UserDefaults)
    /// 2. Check local database count (quick exit if categories exist)
    /// 3. Seed categories using repository (idempotent on same device)
    /// 4. CategoryDeduplicator handles cross-device duplicates after sync
    ///
    /// - Parameter context: Core Data managed object context
    /// - Throws: Core Data errors during save
    static func seedDefaultsIfNeeded(in context: NSManagedObjectContext) throws {
        // Quick exit if already seeded on THIS device
        if hasSeededDefaults {
            #if DEBUG
            print("ℹ️ M7.2.3: Defaults already seeded on this device, skipping")
            #endif
            return
        }
        
        // Check local database - maybe CloudKit already synced categories
        let categoryCount = (try? context.count(for: Category.fetchRequest())) ?? 0
        if categoryCount >= defaultCategories.count {
            #if DEBUG
            print("✅ M7.2.3: Categories already exist (count: \(categoryCount)), skipping seeding")
            #endif
            markSeedingComplete()
            return
        }
        
        #if DEBUG
        print("🌱 M7.2.3: Starting default data seeding...")
        #endif
        let startTime = Date()
        
        // Seed default categories using repository (Phase 3.1)
        try seedDefaultCategories(in: context)
        
        // Mark as complete locally
        markSeedingComplete()
        
        let duration = Date().timeIntervalSince(startTime)
        #if DEBUG
        print("✅ M7.2.3: Default seeding completed in \(String(format: "%.2f", duration))s")
        print("   Note: CategoryDeduplicator will handle any cross-device duplicates after CloudKit sync")
        #endif
    }
    
    // MARK: - Uncategorized Safety Net

    /// M9.12: Ensure "Uncategorized" category exists in the personal store.
    /// Runs every startup (no UserDefaults gate) — cheap fetch, no-op if it exists.
    /// Handles the edge case where a user leaves a household without migrating data,
    /// leaving no categories in the personal store.
    static func ensureUncategorizedExists(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == nil", "Uncategorized")
        request.fetchLimit = 1

        let existing = (try? context.fetch(request))?.first
        if existing != nil { return }

        // Create "Uncategorized" in the personal store (householdKey = nil)
        let uncategorized = Category(context: context)
        uncategorized.id = UUID()
        uncategorized.name = "Uncategorized"
        uncategorized.normalizedName = "uncategorized"
        uncategorized.color = "#9E9E9E"
        uncategorized.sortOrder = 999
        uncategorized.isDefault = true
        uncategorized.dateCreated = Date()
        uncategorized.updatedAt = Date()
        // householdKey stays nil — personal store

        #if DEBUG
        print("🏷️ M9.12: Created missing 'Uncategorized' category in personal store")
        #endif
    }

    // MARK: - Category Seeding (Phase 3.1: Using Repository)
    
    /// M7.2.3 Phase 3.1: Seeds default categories using HouseholdCategoryRepository
    /// M7.2.3 Phase 3.7.2: Only "Uncategorized" is protected (isDefault = true)
    /// Idempotent: repository checks if category exists before creating
    /// CloudKit-safe: tolerates race conditions and concurrent creates
    ///
    /// - Parameter context: Core Data managed object context
    /// - Throws: Core Data errors during fetch or save
    private static func seedDefaultCategories(in context: NSManagedObjectContext) throws {
        #if DEBUG
        print("🏷️ M7.2.3 Phase 3.1: Seeding default categories via repository...")
        #endif
        
        // M10.6.15: Rename "Boxed & Canned" → "Pantry" for existing users
        let renameRequest: NSFetchRequest<Category> = Category.fetchRequest()
        renameRequest.predicate = NSPredicate(format: "name == %@", "Boxed & Canned")
        if let oldCategories = try? context.fetch(renameRequest) {
            for cat in oldCategories {
                cat.name = "Pantry"
            }
        }

        // Create repository instance
        let repository = HouseholdCategoryRepository(context: context)

        var createdCount = 0
        var existingCount = 0
        
        for (name, color, sortOrder, isProtected) in defaultCategories {
            // Use repository's findOrCreate (handles semantic uniqueness)
            let category = try repository.findOrCreate(
                name: name,
                color: color,
                sortOrder: sortOrder,
                isDefault: isProtected  // Only "Uncategorized" is protected
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
            #if DEBUG
            print("✅ M7.2.3 Phase 3.1: Repository seeding complete - \(createdCount) created, \(existingCount) existing")
            #endif
        } else {
            #if DEBUG
            print("ℹ️ M7.2.3 Phase 3.1: All \(existingCount) categories already exist")
            #endif
        }
    }
    
    // MARK: - M7.2.3 Phase 2.6: Factory-Based Household Seeding
    
    /// M7.2.3 Phase 2.6: Seed household categories using performScopedWrite + factory
    ///
    /// ## Purpose
    /// Demonstrates the new Phase 2.6 pattern for background operations:
    /// - Uses performScopedWrite helper (ChatGPT pattern)
    /// - Factory with explicit scope (Gemini pattern)
    /// - Automatic store assignment + household linking
    ///
    /// ## When to Use
    /// This pattern is ideal for seeding household-scoped data when:
    /// - Creating data for a newly created household
    /// - Migrating personal data to household (Phase 4)
    /// - Background batch operations on household data
    ///
    /// ## Parameters
    /// - householdID: NSManagedObjectID of the household to seed for
    /// - persistence: PersistenceController instance
    ///
    /// ## Example Usage
    /// ```swift
    /// // After creating household on main thread:
    /// let householdID = household.objectID
    ///
    /// // Seed categories in background:
    /// await DefaultSeeder.seedHouseholdCategories(
    ///     householdID: householdID,
    ///     persistence: PersistenceController.shared
    /// )
    /// ```
    ///
    /// Source: ChatGPT + Gemini - Phase 2.6 external validation
    static func seedHouseholdCategories(
        householdID: NSManagedObjectID,
        persistence: PersistenceController
    ) async {
        #if DEBUG
        print("🌱 M7.2.3 Phase 2.6: Seeding household categories with factory pattern...")
        #endif
        
        // M7.2.3 Phase 2.6: Construct DataScope with StoreID (Gemini feedback)
        let scope = DataScope.household(id: householdID, storeID: .shared)
        
        // M7.2.3 Phase 2.6: Use performScopedWrite helper (ChatGPT pattern)
        persistence.performScopedWrite(scope: scope) { context, factory in
            var createdCount = 0
            
            for (name, color, sortOrder, isProtected) in defaultCategories {
                do {
                    // M7.2.3 Phase 2.6: Factory with explicit scope
                    // Store + household automatically assigned! ✨
                    _ = try factory.make(Category.self, in: scope) { category in
                        category.id = UUID()
                        category.name = name
                        category.color = color  // ✅ Fixed: 'color' not 'colorHex'
                        category.sortOrder = sortOrder
                        category.isDefault = isProtected
                        category.dateCreated = Date()
                        // household + householdKey set by factory!
                    }
                    
                    createdCount += 1
                    
                } catch {
                    #if DEBUG
                    print("❌ M7.2.3 Phase 2.6: Failed to create category '\(name)': \(error)")
                    #endif
                }
            }
            
            #if DEBUG
            print("✅ M7.2.3 Phase 2.6: Factory seeding complete - \(createdCount) categories created")
            #endif
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
