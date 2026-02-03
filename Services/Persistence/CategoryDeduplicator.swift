//
//  CategoryDeduplicator.swift
//  forager
//
//  M7.2.3 Phase 3.8: Cross-device duplicate detection and removal
//  Handles the case where multiple devices seed default categories simultaneously
//
//  Created on December 31, 2025.
//

import CoreData
import Foundation

/// M7.2.3 Phase 3.8: Detects and removes duplicate categories after CloudKit sync
/// M7.3.3 FIX: Now groups by BOTH normalizedName AND householdKey
///
/// Purpose:
/// When multiple devices seed default categories simultaneously, CloudKit will sync
/// all of them, resulting in duplicates (e.g., 2x "Produce", 2x "Deli & Meat").
/// This service detects duplicates by semantic key (normalizedName + householdKey) and removes them.
///
/// Strategy:
/// 1. Fetch all categories
/// 2. Group by (normalizedName, householdKey) - semantic uniqueness within scope
/// 3. For each group with >1 category: keep oldest, delete rest
/// 4. Save changes → CloudKit syncs deletions to other devices
///
/// CRITICAL: Categories with different householdKey values are NOT duplicates!
/// - Personal categories (householdKey = nil) can coexist with
/// - Household categories (householdKey = "ABC123")
///
/// When to run:
/// - After CloudKit sync notifications (NSPersistentStoreRemoteChange)
/// - Automatically via CloudKitSyncMonitor
/// - Can also be triggered manually for testing
final class CategoryDeduplicator {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Public Deduplication Methods
    
    /// M7.2.3 Phase 3.8: Detect and remove duplicate categories
    ///
    /// This is the main entry point for deduplication.
    /// Safe to call multiple times - it's idempotent.
    ///
    /// - Returns: Number of duplicate categories removed
    /// - Throws: Core Data errors during fetch or save
    @discardableResult
    func removeDuplicates() throws -> Int {
        // Fetch all categories
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Category.normalizedName, ascending: true),
            NSSortDescriptor(keyPath: \Category.dateCreated, ascending: true)
        ]

        let allCategories = try context.fetch(request)

        // M7.3.3 FIX: Group by BOTH normalizedName AND householdKey
        // This ensures personal categories (nil) don't conflict with household categories
        let grouped = Dictionary(grouping: allCategories) { category -> String in
            let name = category.normalizedName ?? ""
            let key = category.householdKey ?? "personal"  // nil = personal scope
            return "\(name)|\(key)"  // Compound key for grouping
        }
        
        var deletedCount = 0
        
        // Process each group
        for (compoundKey, categories) in grouped {
            if categories.count > 1 {
                // M7.3.3: compoundKey is "normalizedName|householdKey"
                let parts = compoundKey.split(separator: "|", maxSplits: 1)
                let normalizedName = String(parts.first ?? "")
                let scope = parts.count > 1 ? String(parts[1]) : "personal"
                print("⚠️ M7.2.3: Found \(categories.count) duplicates for '\(normalizedName)' in scope '\(scope)'")
                
                // Keep the oldest one (earliest dateCreated)
                let sorted = categories.sorted { (a, b) in
                    guard let dateA = a.dateCreated, let dateB = b.dateCreated else {
                        return false
                    }
                    return dateA < dateB
                }
                
                let keeper = sorted.first!
                let duplicates = Array(sorted.dropFirst())
                
                print("  ✅ Keeping: '\(keeper.displayName)' (created: \(keeper.dateCreated ?? Date()))")
                
                // Delete duplicates
                for duplicate in duplicates {
                    print("  🗑️ Deleting: '\(duplicate.displayName)' (created: \(duplicate.dateCreated ?? Date()))")
                    context.delete(duplicate)
                    deletedCount += 1
                }
            }
        }
        
        // Save if we deleted anything
        if deletedCount > 0 {
            try context.save()
            print("✅ M7.2.3: Removed \(deletedCount) duplicate categories")
            print("   CloudKit will sync deletions to other devices")
        } else {
            print("✅ M7.2.3: No duplicate categories found")
        }
        
        return deletedCount
    }
    
    /// M7.2.3 Phase 3.8: Check if duplicates exist (without removing them)
    ///
    /// Useful for diagnostics and testing.
    ///
    /// - Returns: Number of duplicate categories found
    /// - Throws: Core Data errors during fetch
    func countDuplicates() throws -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let allCategories = try context.fetch(request)

        // M7.3.3 FIX: Group by BOTH normalizedName AND householdKey
        let grouped = Dictionary(grouping: allCategories) { category -> String in
            let name = category.normalizedName ?? ""
            let key = category.householdKey ?? "personal"
            return "\(name)|\(key)"
        }
        
        var duplicateCount = 0
        for categories in grouped.values {
            if categories.count > 1 {
                duplicateCount += (categories.count - 1) // All but one are duplicates
            }
        }
        
        return duplicateCount
    }
    
    /// M7.2.3 Phase 3.8: Get detailed duplicate report
    ///
    /// Returns a human-readable report of all duplicates.
    /// Useful for debugging and logging.
    ///
    /// - Returns: Formatted string with duplicate details
    /// - Throws: Core Data errors during fetch
    func getDuplicateReport() throws -> String {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.normalizedName, ascending: true)]
        let allCategories = try context.fetch(request)

        // M7.3.3 FIX: Group by BOTH normalizedName AND householdKey
        let grouped = Dictionary(grouping: allCategories) { category -> String in
            let name = category.normalizedName ?? ""
            let key = category.householdKey ?? "personal"
            return "\(name)|\(key)"
        }
        
        var report = "📊 M7.2.3: CATEGORY DUPLICATE REPORT\n\n"
        report += "Total categories: \(allCategories.count)\n"
        report += "Unique categories: \(grouped.count)\n"
        
        var hasDuplicates = false
        for (normalizedName, categories) in grouped.sorted(by: { $0.key < $1.key }) {
            if categories.count > 1 {
                hasDuplicates = true
                report += "\n⚠️ '\(normalizedName)': \(categories.count) copies\n"
                for (index, category) in categories.enumerated() {
                    report += "   [\(index + 1)] '\(category.displayName)' - created: \(category.dateCreated ?? Date())\n"
                }
            }
        }
        
        if !hasDuplicates {
            report += "\n✅ No duplicates found!\n"
        }
        
        return report
    }
}
