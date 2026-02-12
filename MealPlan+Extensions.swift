//
//  MealPlan+Extensions.swift
//  forager
//
//  Created for M7.2.3 Phase 4.3: Household Auto-Assignment
//

import Foundation
import CoreData

extension MealPlan {
    
    // MARK: - M7.2.3 Phase 4.3: Household Auto-Assignment
    
    /// Automatically assigns new meal plans to existing household
    /// Called when a new MealPlan entity is inserted into the context
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // M7.2.3 Phase 4.3: Auto-assign to household if one exists
        if household == nil, let context = managedObjectContext {
            let fetchRequest: NSFetchRequest<Household> = Household.fetchRequest()
            fetchRequest.fetchLimit = 1
            
            if let existingHousehold = try? context.fetch(fetchRequest).first {
                household = existingHousehold
                householdKey = existingHousehold.id?.uuidString
                #if DEBUG
                print("🏠 M7.2.3 Phase 4.3: Auto-assigned MealPlan '\(name ?? "untitled")' to household '\(existingHousehold.name ?? "unknown")'")
                #endif
            }
        }
    }
}
