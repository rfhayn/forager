//
// HouseholdMembersView.swift
// forager
//
// M7.2.2 Refactor: Display members from CKShare.participants (source of truth)
// No longer uses HouseholdMember Core Data records
//

import SwiftUI

struct HouseholdMembersView: View {
    let household: Household
    @ObservedObject var service: HouseholdService
    @Environment(\.dismiss) private var dismiss

    @State private var participants: [ShareParticipant] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isCurrentUserOwner = false

    // M7.3.3: Remove member confirmation
    @State private var memberToRemove: ShareParticipant?
    @State private var showRemoveConfirmation = false

    // M9.30: Pending invitation management
    @State private var showRevokeConfirmation = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading members...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                    Text("Could not load members")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadParticipants()
                    }
                }
                .padding()
            } else if participants.isEmpty {
                ContentUnavailableView {
                    Label("No Members Found", systemImage: "person.slash")
                } description: {
                    Text("Members will appear here once they join your household")
                }
            } else {
                List {
                    // Active members from CKShare
                    ForEach(participants) { participant in
                        ShareParticipantRow(participant: participant)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // M7.3.3: Owner can remove non-owner, non-self members
                                if isCurrentUserOwner && !participant.isOwner && !participant.isCurrentUser {
                                    Button(role: .destructive) {
                                        memberToRemove = participant
                                        showRemoveConfirmation = true
                                    } label: {
                                        Label("Remove", systemImage: "person.badge.minus")
                                    }
                                }
                            }
                    }

                    // M9.30: Pending invitations section (owner-only)
                    if isCurrentUserOwner {
                        let pendingMembers = household.memberArray.filter { $0.isPending && !$0.isExpired }
                        if !pendingMembers.isEmpty {
                            Section {
                                ForEach(pendingMembers, id: \.id) { member in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(ForagerTheme.statusWarningFG.opacity(0.2))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "envelope.fill")
                                                .foregroundStyle(ForagerTheme.statusWarningFG)
                                                .font(.title3)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Pending Invitation")
                                                .font(.headline)
                                            if let invited = member.invitedDate {
                                                let remaining = max(0, 86400 - Date().timeIntervalSince(invited))
                                                let hours = Int(remaining / 3600)
                                                Text("Expires in \(hours)h")
                                                    .font(ForagerTheme.quantityFont)
                                                    .foregroundStyle(ForagerTheme.textTertiary)
                                            }
                                        }
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock.fill")
                                                .font(.caption)
                                            Text("Pending")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(ForagerTheme.statusWarningFG)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(ForagerTheme.Spacing.lg)
                                    .background(ForagerTheme.surfacePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                                            .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            cancelPendingInvitation(member)
                                        } label: {
                                            Label("Cancel", systemImage: "xmark.circle")
                                        }
                                    }
                                }

                                // Revoke all button
                                Button {
                                    showRevokeConfirmation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.shield")
                                        Text("Revoke All Invitations")
                                    }
                                    .font(ForagerTheme.captionFont)
                                    .foregroundStyle(ForagerTheme.statusDangerFG)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ForagerTheme.Spacing.sm)
                                }
                                .buttonStyle(.borderless)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } header: {
                                Text("Pending Invitations")
                                    .font(ForagerTheme.captionFont)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(ForagerTheme.backgroundCanvas)
            }
        }
        .background(ForagerTheme.backgroundCanvas.ignoresSafeArea())
        .navigationTitle("Household Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadParticipants()
        }
        .alert("Revoke All Invitations?", isPresented: $showRevokeConfirmation) {
            Button("Revoke All", role: .destructive) {
                revokeAllInvitations()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will cancel all pending invitations and close the sharing link. You can create a new invitation later.")
        }
        .alert("Remove Member?", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                if let member = memberToRemove {
                    removeMember(member)
                }
            }
            Button("Cancel", role: .cancel) {
                memberToRemove = nil
            }
        } message: {
            if let member = memberToRemove {
                Text("Remove \(member.displayName) from this household? They will lose access to all shared data.")
            }
        }
    }

    private func loadParticipants() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loaded = try await service.getParticipants(for: household)
                let ownerCheck = await service.isOwner(household: household)
                await MainActor.run {
                    self.participants = loaded
                    self.isCurrentUserOwner = ownerCheck
                    self.isLoading = false
                }
            } catch HouseholdError.noShareRecord {
                // M7.3.3: Household was deleted - dismiss this view
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // M9.30: Cancel a single pending invitation
    private func cancelPendingInvitation(_ member: HouseholdMember) {
        Task {
            do {
                try await service.cancelInvitation(member: member, household: household)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // M9.30: Revoke all pending invitations and close public link
    private func revokeAllInvitations() {
        Task {
            do {
                try await service.revokeAllPendingInvitations(household: household)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // M7.3.3: Remove member and reload participant list
    private func removeMember(_ participant: ShareParticipant) {
        Task {
            do {
                try await service.removeMember(participant, from: household)
                loadParticipants()
            } catch {
                errorMessage = error.localizedDescription
            }
            memberToRemove = nil
        }
    }
}

// MARK: - ShareParticipantRow

struct ShareParticipantRow: View {
    let participant: ShareParticipant

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(participant.isOwner ? ForagerTheme.accentSecondary.opacity(0.2) : ForagerTheme.textTertiary.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: participant.isOwner ? "crown.fill" : "person.fill")
                    .foregroundStyle(participant.isOwner ? ForagerTheme.accentSecondary : ForagerTheme.textTertiary)
                    .font(.title3)
            }

            // Name and email
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participant.displayName)
                        .font(.headline)

                    if participant.isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }

                    // Role badge — printed tag (reskin-provisions-press)
                    Text((participant.isOwner ? "Owner" : "Member").uppercased())
                        .font(.system(size: 10, weight: .bold).width(.condensed))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(participant.isOwner ? ForagerTheme.accentSecondary : ForagerTheme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
                }

                // Email (if available and not a CloudKit ID)
                if let email = participant.email, !isCloudKitUserRecordID(email) {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status indicator
            if participant.acceptanceStatus.isPending {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("Pending")
                        .font(.caption)
                }
                .foregroundStyle(ForagerTheme.statusWarningFG)
            } else if participant.acceptanceStatus.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(ForagerTheme.statusSuccessFG)
            }
        }
        .padding(.vertical, 4)
        .padding(ForagerTheme.Spacing.lg)
        .background(ForagerTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
        )
    }

    /// Checks if a string is a CloudKit user record ID (starts with "_" and contains hex chars)
    private func isCloudKitUserRecordID(_ string: String) -> Bool {
        return string.hasPrefix("_") && string.count > 20 && string.allSatisfy { $0.isHexDigit || $0 == "_" }
    }
}

// MARK: - Preview

struct HouseholdMembersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            // Use a mock view for preview since we can't easily mock CKShare
            List {
                ShareParticipantRow(participant: ShareParticipant(
                    displayName: "Sarah",
                    email: "sarah@example.com",
                    isOwner: true,
                    isCurrentUser: true,
                    acceptanceStatus: .accepted
                ))
                ShareParticipantRow(participant: ShareParticipant(
                    displayName: "Mike",
                    email: "mike@example.com",
                    isOwner: false,
                    isCurrentUser: false,
                    acceptanceStatus: .accepted
                ))
                ShareParticipantRow(participant: ShareParticipant(
                    displayName: "Alex",
                    email: "alex@example.com",
                    isOwner: false,
                    isCurrentUser: false,
                    acceptanceStatus: .pending
                ))
            }
            .navigationTitle("Household Members")
        }
    }
}
