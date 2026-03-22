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

    /// M9.30: Returns true if pending invitation has expired (>24 hours)
    public var isExpired: Bool {
        guard isPending, let invited = invitedDate else { return false }
        return Date().timeIntervalSince(invited) > 86400 // 24 hours
    }
}
