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

    @State private var showingShareSheet: Bool = false
    @State private var invitationURL: URL?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("Invite Member")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Add people to your household")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Description
                VStack(spacing: 12) {
                    Label {
                        Text("Share with family & friends")
                    } icon: {
                        Image(systemName: "house.fill")
                            .foregroundStyle(.green)
                    }

                    Text("New members will have full access to all grocery lists, recipes, and meal plans. They'll receive a notification to join.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)

                Spacer()

                // Button
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await presentShareSheet()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Invite People")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .overlay {
                if isLoading {
                    ProgressView("Creating invitation...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = invitationURL {
                    ShareSheet(invitationURL: url) {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to create invitation")
            }
        }
    }

    private func presentShareSheet() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Create one-time invitation URL (works around UICloudSharingController issues)
            let url = try await service.createOneTimeInvitationURL(household: household)

            print("📝 Presenting share sheet with one-time URL...")

            // Store URL and present share sheet
            invitationURL = url
            showingShareSheet = true

        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            print("❌ Failed to create invitation: \(error)")
        }
    }
}
