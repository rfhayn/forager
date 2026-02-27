//
//  DocumentScannerView.swift
//  forager
//
//  Created for M10.3.1: Camera capture wrapper
//  UIViewControllerRepresentable wrapping UIImagePickerController in camera mode.
//  Takes a single photo and returns it via callback.
//

import SwiftUI

// MARK: - Document Scanner View

/// SwiftUI wrapper for the system camera (single photo capture).
/// Returns the captured image on completion.
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: ([UIImage]) -> Void
    let onCancel: () -> Void
    let onError: (ImportError) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel, onError: onError)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onScan: ([UIImage]) -> Void
        let onCancel: () -> Void
        let onError: (ImportError) -> Void

        init(onScan: @escaping ([UIImage]) -> Void,
             onCancel: @escaping () -> Void,
             onError: @escaping (ImportError) -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
            self.onError = onError
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onScan([image])
            } else {
                onError(.ocrFailed("Could not capture image from camera."))
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
