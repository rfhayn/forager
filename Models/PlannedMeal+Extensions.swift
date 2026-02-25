//
//  PlannedMeal+Extensions.swift
//  forager
//
//  Created by Richard Hayn on 12/18/25.
//

import Foundation

extension PlannedMeal {
    
    // MARK: - M15.5: Quick Option Support

    enum QuickOption: String, CaseIterable {
        case takeout = "Takeout"
        case diningOut = "Dining Out"
        case leftovers = "Leftovers"
        case noMeal = "No Meal"

        var icon: String {
            switch self {
            case .takeout: return "bag"
            case .diningOut: return "fork.knife"
            case .leftovers: return "refrigerator"
            case .noMeal: return "moon.zzz"
            }
        }
    }

    var isQuickOption: Bool { quickOption != nil }
    var quickOptionEnum: QuickOption? { QuickOption(rawValue: quickOption ?? "") }

    // MARK: - M7.1.3 Semantic Key Helpers
    
    /// Single source of truth for meal slot keys
    /// 
    /// Format: "YYYY-MM-DD-mealType"
    /// Uses Calendar.current timezone to keep meals on calendar dates
    /// 
    /// Examples:
    /// - Date(2024-12-13 18:00 UTC), "dinner" → "2024-12-13-dinner"
    /// - Date(2024-12-13 07:00 UTC), "breakfast" → "2024-12-13-breakfast"
    /// 
    /// Why ISO8601 date format:
    /// - Unambiguous, sortable
    /// - No timezone confusion
    /// - Consistent across devices
    static func slotKey(date: Date, mealType: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]  // YYYY-MM-DD only
        formatter.timeZone = Calendar.current.timeZone  // Use user's timezone
        
        let dateString = formatter.string(from: date)
        let normalizedMealType = mealType.lowercased()
        
        return "\(dateString)-\(normalizedMealType)"
    }
    
    /// Valid meal types for validation
    static let validMealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    /// Validate mealType is one of the accepted values
    static func isValidMealType(_ mealType: String) -> Bool {
        validMealTypes.contains(mealType.lowercased())
    }
    
    /// DEPRECATED: Use slotKey(date:mealType:) instead
    /// Kept for backward compatibility
    static func generateSlotKey(date: Date, mealType: String) -> String {
        return slotKey(date: date, mealType: mealType)
    }
}
