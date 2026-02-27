//
//  DocumentScannerView.swift
//  forager
//
//  Created for M10.3.1: Document camera scanner wrapper
//  UIViewControllerRepresentable wrapping VNDocumentCameraViewController.
//  Handles multi-page scans and delegates results back via callback.
//

import SwiftUI
import VisionKit

// MARK: - Document Scanner View

/// SwiftUI wrapper for Apple's document scanner camera.
/// Returns an array of scanned page images on completion.
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: ([UIImage]) -> Void
    let onCancel: () -> Void
    let onError: (ImportError) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel, onError: onError)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
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

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            onScan(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            // Camera permission denial comes through as a specific error domain
            let nsError = error as NSError
            if nsError.domain == "com.apple.VisionKit" || nsError.code == 1 {
                onError(.cameraPermissionDenied)
            } else {
                onError(.ocrFailed(error.localizedDescription))
            }
        }
    }
}
