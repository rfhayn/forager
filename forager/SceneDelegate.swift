//
// SceneDelegate.swift
// forager
//
// M7.2.2: CloudKit share invitation handling via SceneDelegate
// Required for iOS to deliver CloudKit share URLs to the app
//

import UIKit
import CoreData
import CloudKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {

    // MARK: - CloudKit Share Invitation Handling

    /// Called when user taps a CloudKit share link while app is running
    /// This is the primary callback for share invitations when app is active/backgrounded
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        print("📨 CloudKit share invitation received (app running)")
        print("   Share URL: \(cloudKitShareMetadata.share.url?.absoluteString ?? "none")")
        print("   Root record: \(cloudKitShareMetadata.hierarchicalRootRecordID?.recordName ?? "unknown")")

        acceptShareInvitation(metadata: cloudKitShareMetadata)
    }

    /// Called when app is launched via CloudKit share link (cold start)
    /// This handles the case where the app was not running when user tapped the link
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Check if launched via CloudKit share invitation
        if let cloudKitShareMetadata = connectionOptions.cloudKitShareMetadata {
            print("📨 CloudKit share invitation received (cold start)")
            print("   Share URL: \(cloudKitShareMetadata.share.url?.absoluteString ?? "none")")
            print("   Root record: \(cloudKitShareMetadata.hierarchicalRootRecordID?.recordName ?? "unknown")")

            acceptShareInvitation(metadata: cloudKitShareMetadata)
        }
    }

    // MARK: - Share Acceptance Logic

    /// Accepts a CloudKit share invitation using NSPersistentCloudKitContainer's built-in method
    /// This properly integrates the shared data into Core Data's persistence layer
    private func acceptShareInvitation(metadata: CKShare.Metadata) {
        print("🔄 Accepting share invitation...")

        let persistenceController = PersistenceController.shared
        let sharedStore = persistenceController.sharedStore
        let viewContext = persistenceController.viewContext

        // M7.3.3: Check if user is already in a household before accepting
        // This prevents data integrity issues where householdKey doesn't match household.id
        let existingRequest: NSFetchRequest<Household> = Household.fetchRequest()
        existingRequest.fetchLimit = 1
        if let existingHouseholds = try? viewContext.fetch(existingRequest),
           let existing = existingHouseholds.first {
            print("⚠️ M7.3.3: User already in household '\(existing.name ?? "Unknown")'")
            print("   Cannot accept new share invitation")
            print("   User must leave/delete current household first")

            // Post notification to inform UI about the conflict
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .cloudKitShareRejectedAlreadyInHousehold,
                    object: nil,
                    userInfo: ["existingHousehold": existing.name ?? "Unknown"]
                )
            }
            return
        }

        // Use NSPersistentCloudKitContainer's acceptShareInvitations method
        // This is the correct way to accept shares with Core Data + CloudKit
        persistenceController.container.acceptShareInvitations(
            from: [metadata],
            into: sharedStore
        ) { _, error in
            if let error = error {
                print("❌ Failed to accept share invitation: \(error)")
                print("   Error details: \(error.localizedDescription)")
            } else {
                print("✅ Share invitation accepted successfully")
                print("   Core Data will now sync household data from CloudKit")
                print("   This may take 10-30 seconds depending on data size")

                // M7.2.2 FIX: Post notification instead of creating a new HouseholdService instance
                // The main app's HouseholdService will listen for this and check for invitations
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("📢 Posting notification to check for accepted invitations")
                    NotificationCenter.default.post(
                        name: .cloudKitShareAccepted,
                        object: nil
                    )
                }
            }
        }
    }
}

// MARK: - M7.2.2: Notification for CloudKit Share Acceptance

extension Notification.Name {
    /// Posted when a CloudKit share invitation is accepted
    /// Listeners should check for and load the newly shared household
    static let cloudKitShareAccepted = Notification.Name("cloudKitShareAccepted")

    /// M7.3.3: Posted when a share invitation is rejected because user is already in a household
    /// The userInfo contains "existingHousehold" key with the name of the existing household
    static let cloudKitShareRejectedAlreadyInHousehold = Notification.Name("cloudKitShareRejectedAlreadyInHousehold")
}
