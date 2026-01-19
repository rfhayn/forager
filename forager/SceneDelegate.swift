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
        print("   Root record: \(cloudKitShareMetadata.rootRecordID.recordName)")

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
            print("   Root record: \(cloudKitShareMetadata.rootRecordID.recordName)")

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

        // M7.2.2: Request user discoverability permission for display names
        // This allows us to fetch the user's iCloud display name and email
        let container = CKContainer(identifier: "iCloud.com.richhayn.forager")
        Task {
            do {
                let status = try await container.accountStatus()
                if status == .available {
                    let permission = try await container.applicationPermissionStatus(for: .userDiscoverability)
                    if permission != .granted {
                        print("📋 Requesting user discoverability permission...")
                        let newPermission = try await container.requestApplicationPermission(.userDiscoverability)
                        if newPermission == .granted {
                            print("✅ User discoverability permission granted")
                        } else {
                            print("⚠️ User discoverability permission denied - will use fallback name")
                        }
                    } else {
                        print("✅ User discoverability permission already granted")
                    }
                }
            } catch {
                print("⚠️ Could not check user discoverability permission: \(error)")
            }
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
}
