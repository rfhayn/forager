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
    
    /// M10.6.17: awakeFromInsert no longer auto-assigns household (ADR 013).
    /// Callers (MealPlanService, ManagedObjectFactory) set household + householdKey explicitly.
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
}
