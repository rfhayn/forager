//
// Household+Extensions.swift
// forager
//
// M7.2.1: Household computed properties
//

import CoreData

extension Household {
    /// Returns count of household members
    public var memberCount: Int {
        return members?.count ?? 0
    }
    
    /// Returns members as sorted array
    public var memberArray: [HouseholdMember] {
        let set = members as? Set<HouseholdMember> ?? []
        return set.sorted { 
            ($0.joinedDate ?? Date.distantPast) < ($1.joinedDate ?? Date.distantPast) 
        }
    }
}
