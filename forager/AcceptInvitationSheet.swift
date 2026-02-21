//
// AcceptInvitationSheet.swift
// forager
//
// M7.2.2 Task 3: Invitation acceptance UI
// Presents "Join Household?" dialog when user receives invitation
//

import SwiftUI
import CloudKit

struct AcceptInvitationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service: HouseholdService
    let share: CKShare.Metadata
    
    @State private var isAccepting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showRetryAlert: Bool = false
    @State private var isRetrying: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(ForagerTheme.accentPrimary)
                    .padding(.top, 40)
                
                // Title
                VStack(spacing: 8) {
                    Text("Join Household?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Display household invitation
                    Text("Household Invitation")
                        .font(.title2)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                
                // Description
                VStack(spacing: 12) {
                    Label {
                        Text("You've been invited to join this household")
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(ForagerTheme.statusSuccessFG)
                    }
                    
                    Text("You'll have full access to all grocery lists, recipes, and meal plans. Any changes you make will be visible to all household members.")
                        .font(.callout)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                
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
                        .padding()
                        .background(ForagerTheme.accentPrimary)
                        .foregroundStyle(.white)
                        .cornerRadius(ForagerTheme.Radius.md)
                    }
                    .disabled(isAccepting)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Not Now")
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
                if isAccepting || isRetrying {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(isRetrying ? "Checking for household..." : "Joining household...")
                                .font(.headline)
                        }
                        .padding(40)
                        .background(.regularMaterial)
                        .cornerRadius(20)
                    }
                }
            }
            .alert("Error Joining Household", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            // M7.3.4: Replaced exit(0) with "Check Again" button - Apple discourages exit()
            .alert("Still Syncing", isPresented: $showRetryAlert) {
                Button("Check Again") {
                    Task {
                        await retryCheck()
                    }
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("The household data is still syncing from iCloud. This can take longer on slow networks.\n\nTap 'Check Again' to retry, or wait and try again later.")
            }
        }
    }
    
    private func acceptInvitation() async {
        isAccepting = true
        defer { isAccepting = false }

        do {
            #if DEBUG
            print("📝 Accepting CloudKit share...")
            #endif

            // Accept the share in CloudKit using metadata
            let container = CKContainer(identifier: "iCloud.com.richhayn.forager")
            let acceptedShare = try await container.accept(share)

            #if DEBUG
            print("✅ Share accepted in CloudKit: \(acceptedShare.recordID)")
            print("⏳ Waiting for CloudKit sync (this may take 10-30 seconds)...")
            #endif

            // Retry loop: wait for household to sync
            var household: Household?
            let maxRetries = 6

            for attempt in 1...maxRetries {
                #if DEBUG
                print("   Attempt \(attempt)/\(maxRetries) - waiting 5 seconds...")
                #endif
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                // Check for household using auto-member creation logic
                await service.checkForAcceptedInvitations()

                if let found = service.currentHousehold {
                    household = found
                    #if DEBUG
                    print("✅ Household synced! Found: \(found.name ?? "Unnamed")")
                    #endif
                    break
                } else {
                    #if DEBUG
                    print("   Not yet synced... (\(attempt * 5) seconds elapsed)")
                    #endif
                }
            }

            // If found, check member status (auto-creation may have already activated us)
            if let household = household {
                let currentEmail = try await service.getCurrentUserEmail()
                if let member = household.memberArray.first(where: { $0.email == currentEmail }) {
                    if member.isPending {
                        // Member exists but is pending - activate them
                        try await service.acceptInvitation(for: household)
                    } else {
                        // Member already active (auto-created) - just dismiss
                        #if DEBUG
                        print("✅ Member already active - household ready to use")
                        #endif
                    }
                }
                dismiss()
            } else {
                // Household didn't sync in time - show retry alert
                #if DEBUG
                print("⚠️ Household not synced after 30 seconds - showing retry alert")
                #endif
                showRetryAlert = true
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            #if DEBUG
            print("❌ Failed to accept invitation: \(error)")
            #endif
        }
    }

    // M7.3.4: Retry check for household sync (replaces exit(0) anti-pattern)
    private func retryCheck() async {
        isRetrying = true
        defer { isRetrying = false }

        #if DEBUG
        print("🔄 M7.3.4: Retrying household check...")
        #endif

        // Check for household using auto-member creation logic
        await service.checkForAcceptedInvitations()

        if let found = service.currentHousehold {
            #if DEBUG
            print("✅ M7.3.4: Household found on retry: \(found.name ?? "Unnamed")")
            #endif
            dismiss()
        } else {
            #if DEBUG
            print("⚠️ M7.3.4: Household still not synced - showing retry alert again")
            #endif
            showRetryAlert = true
        }
    }
}
