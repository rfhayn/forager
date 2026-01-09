//
// ShareSheet.swift
// forager
//
// M7.2.2: UIActivityViewController wrapper for one-time invitation URLs
// Uses one-time URL participant pattern to work around UICloudSharingController LaunchServices issues
// Per ChatGPT recommendation: reliable fallback for iOS 18.x with private sharing
//

import SwiftUI
import CloudKit

struct ShareSheet: UIViewControllerRepresentable {
    let invitationURL: URL
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [invitationURL],
            applicationActivities: nil
        )

        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                print("❌ Share failed: \(error)")
            } else if completed {
                print("✅ Invitation shared successfully via \(activityType?.rawValue ?? "unknown")")
            } else {
                print("ℹ️ User cancelled share")
            }

            DispatchQueue.main.async {
                onDismiss?()
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
