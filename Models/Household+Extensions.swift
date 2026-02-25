//
// Household+Extensions.swift
// forager
//
// M7.2.1: Household computed properties
//

import CoreData

extension Household {
    /// M7.6.8: Owner display name stored on the shared root record.
    /// Repurposes ownerEmail field so the name survives CloudKit share migration.
    public var ownerDisplayName: String? {
        get { ownerEmail }
        set { ownerEmail = newValue }
    }

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
