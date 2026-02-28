//
//  ImageOCRService.swift
//  forager
//
//  Created for M10.3.1: Vision.framework OCR wrapper
//  Recognizes text in images using VNRecognizeTextRequest → [OCRLine] with real boundingBox.
//  Used by PhotoImportView for both camera scans and photo library images.
//

import Foundation
import Vision
import CoreGraphics
import UIKit

// MARK: - Image OCR Service

/// Wraps Vision.framework text recognition, producing [OCRLine] sorted in reading order.
/// Each OCRLine carries the real boundingBox from VNRecognizedTextObservation.
enum ImageOCRService {

    /// Recognize text in a CGImage, returning lines sorted top-to-bottom.
    /// - Parameter image: The source image to scan for text.
    /// - Returns: Array of OCRLine with text, confidence, and normalized boundingBox.
    /// - Throws: ImportError.ocrFailed or .noTextDetected
    static func recognizeText(in image: CGImage) async throws -> [OCRLine] {
        let observations = try await performRecognition(on: image)

        guard !observations.isEmpty else {
            throw ImportError.noTextDetected
        }

        let lines = observations.compactMap { observation -> OCRLine? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return OCRLine(
                text: candidate.string,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            )
        }

        guard !lines.isEmpty else {
            throw ImportError.noTextDetected
        }

        // Sort top-to-bottom: Vision uses bottom-left origin, so higher y = higher on page
        return lines.sorted { (1 - $0.boundingBox.origin.y) < (1 - $1.boundingBox.origin.y) }
    }

    /// Recognize text across multiple pages, concatenating results in page order.
    static func recognizeText(in images: [UIImage]) async throws -> [OCRLine] {
        var allLines: [OCRLine] = []

        for image in images {
            guard let cgImage = image.cgImage else { continue }
            let pageLines = try await recognizeText(in: cgImage)
            allLines.append(contentsOf: pageLines)
        }

        guard !allLines.isEmpty else {
            throw ImportError.noTextDetected
        }

        return allLines
    }

    // MARK: - Private

    private static func performRecognition(on image: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ImportError.ocrFailed(error.localizedDescription))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "fr-FR", "de-DE", "es-ES"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ImportError.ocrFailed(error.localizedDescription))
            }
        }
    }
}
