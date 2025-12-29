//
// ShareSheet.swift
// forager
//
// M7.2.2: UICloudSharingController wrapper for SwiftUI
// Presents iOS native share UI for household invitations
//

import SwiftUI
import CloudKit

struct ShareSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: (() -> Void)?
        
        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ Failed to save share: \(error)")
            onDismiss?()
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Household"
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ Share saved successfully")
            onDismiss?()
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("✅ Stopped sharing")
            onDismiss?()
        }
    }
}
