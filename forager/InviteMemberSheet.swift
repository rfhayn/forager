//
// InviteMemberSheet.swift
// forager
//
// M7.2.2: Email input sheet for inviting household members
//

import SwiftUI
import CloudKit

struct InviteMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service: HouseholdService
    let household: Household
    
    @State private var email: String = ""
    @State private var isInviting: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var shareToPresent: CKShare?
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Invite Member")
                } footer: {
                    Text("Enter the iCloud email address of the person you want to invite. They'll receive a notification and can join your household.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Full Access", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("New members will have full read and write access to all recipes, grocery lists, and meal plans.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isInviting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invitation") {
                        Task {
                            await sendInvitation()
                        }
                    }
                    .disabled(email.isEmpty || isInviting || !isValidEmail(email))
                }
            }
            .overlay {
                if isInviting {
                    ProgressView("Preparing invitation...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let share = shareToPresent {
                    ShareSheet(
                        share: share,
                        container: CKContainer(identifier: "iCloud.com.richhayn.forager")
                    ) {
                        dismiss()
                    }
                }
            }
            .alert("Invitation Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to send invitation")
            }
        }
    }
    
    private func sendInvitation() async {
        isInviting = true
        defer { isInviting = false }
        
        do {
            // Create pending member and get share
            let share = try await service.inviteMember(email: email, to: household)
            
            // Present UICloudSharingController
            shareToPresent = share
            showingShareSheet = true
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
