//
// HouseholdMember+Extensions.swift
// forager
//
// M7.2.1: HouseholdMember computed properties
//

import CoreData

extension HouseholdMember {
    /// Returns true if member is household owner
    public var isOwner: Bool {
        return role == "owner"
    }
    
    /// Returns true if invitation is pending
    public var isPending: Bool {
        return status == "pending"
    }
    
    /// Returns true if member is active
    public var isActive: Bool {
        return status == "active"
    }
}
