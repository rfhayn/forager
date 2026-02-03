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

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading members...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Could not load members")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadParticipants()
                    }
                }
                .padding()
            } else if participants.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No members found")
                        .font(.headline)
                }
            } else {
                List {
                    ForEach(participants) { participant in
                        ShareParticipantRow(participant: participant)
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
                }
            }
        }
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
                    .fill(participant.isOwner ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: participant.isOwner ? "crown.fill" : "person.fill")
                    .foregroundStyle(participant.isOwner ? .blue : .gray)
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
                            .foregroundColor(.secondary)
                    }

                    // Role badge
                    Text(participant.isOwner ? "Owner" : "Member")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(participant.isOwner ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .foregroundStyle(participant.isOwner ? .blue : .gray)
                        .cornerRadius(4)
                }

                // Email (if available and not a CloudKit ID)
                if let email = participant.email, !isCloudKitUserRecordID(email) {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                .foregroundStyle(.orange)
            } else if participant.acceptanceStatus.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
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
