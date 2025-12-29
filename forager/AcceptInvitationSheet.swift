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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                // Title
                VStack(spacing: 8) {
                    Text("Join Household?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Display household invitation
                    Text("Household Invitation")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                // Description
                VStack(spacing: 12) {
                    Label {
                        Text("You've been invited to join this household")
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.green)
                    }
                    
                    Text("You'll have full access to all grocery lists, recipes, and meal plans. Any changes you make will be visible to all household members.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isAccepting)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.blue)
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
        }
    }
    
    private func acceptInvitation() async {
        isAccepting = true
        defer { isAccepting = false }
        
        do {
            // Accept the share in CloudKit using metadata
            let container = CKContainer(identifier: "iCloud.com.richhayn.forager")
            
            // Accept the share using the metadata
            let acceptedShare = try await container.accept(share)
            
            print("✅ Share accepted in CloudKit: \(acceptedShare.recordID)")
            
            // Wait a moment for CloudKit sync to propagate
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Reload household from local database (should be synced now)
            await service.loadCurrentHousehold()
            
            // Find the household and accept invitation
            if let household = service.currentHousehold {
                try await service.acceptInvitation(for: household)
                dismiss()
            } else {
                throw HouseholdError.invitationFailed("Household not found after accepting share")
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to accept invitation: \(error)")
        }
    }
}
