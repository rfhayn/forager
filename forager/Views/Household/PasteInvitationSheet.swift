//
// PasteInvitationSheet.swift
// forager
//
// M7.2.2: Manual invitation URL input for troubleshooting
// Workaround for when system share acceptance doesn't trigger URL handlers
//

import SwiftUI
import CloudKit

struct PasteInvitationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service: HouseholdService

    @State private var invitationURL: String = ""
    @State private var isAccepting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(ForagerTheme.accentPrimary)
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("Join with Link")
                        .font(ForagerTheme.detailTitle)
                        .foregroundStyle(ForagerTheme.textPrimary)

                    Text("Paste your invitation link")
                        .font(ForagerTheme.cardTitle)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }

                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Long-press the invitation link in Messages")
                    Text("2. Tap 'Copy'")
                    Text("3. Paste it below")
                }
                .font(.callout)
                .foregroundStyle(ForagerTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // URL Input
                TextField("https://www.icloud.com/share/...", text: $invitationURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .padding(.horizontal)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await acceptInvitation()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Join Household")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ForagerPrimaryButtonStyle())
                    .disabled(invitationURL.isEmpty || isAccepting)

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                    .disabled(isAccepting)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .overlay {
                if isAccepting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Joining household...")
                                .font(ForagerTheme.bodyCondensed.weight(.semibold))
                        }
                        .padding(40)
                        .background(.regularMaterial)
                        .cornerRadius(20)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func acceptInvitation() async {
        isAccepting = true
        defer { isAccepting = false }

        do {
            #if DEBUG
            print("🔗 Attempting to accept invitation from URL: \(invitationURL)")
            #endif

            // Parse URL
            guard let url = URL(string: invitationURL.trimmingCharacters(in: .whitespaces)) else {
                throw HouseholdError.invitationFailed("Invalid URL format")
            }

            // Verify it's an iCloud share URL
            guard url.host?.contains("icloud.com") == true else {
                throw HouseholdError.invitationFailed("Not an iCloud share URL")
            }

            #if DEBUG
            print("📝 Fetching share metadata from CloudKit...")
            #endif

            // Fetch share metadata
            let container = CKContainer(identifier: "iCloud.com.richhayn.forager")
            let metadata = try await container.shareMetadata(for: url)

            #if DEBUG
            print("✅ Fetched share metadata")
            print("   Root record: \(metadata.hierarchicalRootRecordID?.recordName ?? "unknown")")
            print("   Container: \(metadata.containerIdentifier)")
            #endif

            // Accept the share via NSPersistentCloudKitContainer so Core Data mirroring picks it up
            #if DEBUG
            print("📝 Accepting share via NSPersistentCloudKitContainer...")
            #endif
            let persistenceController = PersistenceController.shared
            let sharedStore = persistenceController.sharedStore

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                persistenceController.container.acceptShareInvitations(
                    from: [metadata],
                    into: sharedStore
                ) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            #if DEBUG
            print("✅ Share accepted via NSPersistentCloudKitContainer")
            #endif

            // Wait for CloudKit sync to propagate with retries
            #if DEBUG
            print("⏳ Waiting for CloudKit sync (this may take 10-30 seconds)...")
            #endif

            var household: Household?
            let maxRetries = 6

            for attempt in 1...maxRetries {
                #if DEBUG
                print("   Attempt \(attempt)/\(maxRetries) - waiting 5 seconds...")
                #endif
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                // Check for household
                await service.checkForAcceptedInvitations()

                if let found = service.currentHousehold {
                    household = found
                    #if DEBUG
                    print("✅ Household synced! Found: \(found.name ?? "Unnamed")")
                    #endif
                    break
                } else {
                    #if DEBUG
                    print("   Not yet... (\(attempt * 5) seconds elapsed)")
                    #endif
                }
            }

            // If found, check member status
            if let household = household {
                // Check if we're already an active member (from auto-creation)
                let currentEmail = try await service.getCurrentUserEmail()
                if let member = household.memberArray.first(where: { $0.email == currentEmail }) {
                    if member.isPending {
                        // Member exists but is pending - activate them
                        try await service.acceptInvitation(for: household)
                    } else {
                        // Member already active (auto-created) - just dismiss
                        #if DEBUG
                        print("✅ Member already active - no need to accept invitation")
                        #endif
                    }
                }
                dismiss()
            } else {
                throw HouseholdError.invitationFailed("Share accepted! Please close and restart the app, then the household data will appear. (This is a NSPersistentCloudKitContainer limitation)")
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            #if DEBUG
            print("❌ Failed to accept invitation: \(error)")
            #endif
        }
    }
}
