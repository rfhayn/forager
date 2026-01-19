//
// ShareParticipant.swift
// forager
//
// M7.2.2 Refactor: Use CKShare.participants as source of truth for household members
// This struct wraps CKShare.Participant data for easy display in SwiftUI
//

import Foundation
import CloudKit

/// Represents a household member derived from CKShare.Participant
/// This is the source of truth for who's in a household - not Core Data records
struct ShareParticipant: Identifiable {
    let id: String  // userRecordID or generated UUID
    let displayName: String
    let email: String?
    let isOwner: Bool
    let isCurrentUser: Bool
    let acceptanceStatus: AcceptanceStatus

    enum AcceptanceStatus {
        case accepted
        case pending
        case removed
        case unknown

        var displayText: String {
            switch self {
            case .accepted: return "Active"
            case .pending: return "Pending"
            case .removed: return "Removed"
            case .unknown: return "Unknown"
            }
        }

        var isPending: Bool {
            return self == .pending
        }

        var isActive: Bool {
            return self == .accepted
        }
    }

    /// Creates a ShareParticipant from a CKShare.Participant
    /// - Parameters:
    ///   - participant: The CloudKit participant
    ///   - isCurrentUser: Whether this participant is the current user
    init(from participant: CKShare.Participant, isCurrentUser: Bool = false) {
        // Get user record ID as stable identifier
        if let userRecordID = participant.userIdentity.userRecordID {
            self.id = userRecordID.recordName
        } else {
            self.id = UUID().uuidString
        }

        // Get display name from name components
        if let nameComponents = participant.userIdentity.nameComponents {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .medium
            self.displayName = formatter.string(from: nameComponents)
        } else {
            // Fallback to email or "User"
            if let email = participant.userIdentity.lookupInfo?.emailAddress {
                // Extract name from email (before @)
                let name = email.components(separatedBy: "@").first ?? "User"
                self.displayName = name.capitalized
            } else {
                self.displayName = isCurrentUser ? "You" : "User"
            }
        }

        // Get email if available
        self.email = participant.userIdentity.lookupInfo?.emailAddress

        // Check role
        self.isOwner = participant.role == .owner
        self.isCurrentUser = isCurrentUser

        // Map acceptance status
        switch participant.acceptanceStatus {
        case .accepted:
            self.acceptanceStatus = .accepted
        case .pending:
            self.acceptanceStatus = .pending
        case .removed:
            self.acceptanceStatus = .removed
        @unknown default:
            self.acceptanceStatus = .unknown
        }
    }

    /// Creates a preview/mock ShareParticipant for SwiftUI previews
    init(
        id: String = UUID().uuidString,
        displayName: String,
        email: String? = nil,
        isOwner: Bool = false,
        isCurrentUser: Bool = false,
        acceptanceStatus: AcceptanceStatus = .accepted
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.isOwner = isOwner
        self.isCurrentUser = isCurrentUser
        self.acceptanceStatus = acceptanceStatus
    }
}

// MARK: - Equatable

extension ShareParticipant: Equatable {
    static func == (lhs: ShareParticipant, rhs: ShareParticipant) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension ShareParticipant: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
