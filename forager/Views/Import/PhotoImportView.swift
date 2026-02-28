//
//  PhotoImportView.swift
//  forager
//
//  Created for M10.3.2-M10.3.4: Photo/image import view
//  Local phase state machine: pick → process → review (split-screen) → preview.
//  Dual path: Foundation Models (primary) with heuristic classification fallback.
//  Flow: pick image → OCR → FM extraction (or classify → review) → assemble draft → preview.
//

import SwiftUI
import PhotosUI

// MARK: - Photo Import Phase

/// Local state machine for the photo import flow
private enum PhotoImportPhase: Equatable {
    case picking
    case captured([UIImage])  // Post-camera review: accept or retake
    case processing(String)
    case reviewing([EditableClassifiedLine], Data)
    case error(ImportError)

    static func == (lhs: PhotoImportPhase, rhs: PhotoImportPhase) -> Bool {
        switch (lhs, rhs) {
        case (.picking, .picking): return true
        case (.captured, .captured): return true
        case (.processing(let a), .processing(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        case (.reviewing, .reviewing): return false
        default: return false
        }
    }
}

// MARK: - Photo Import View

/// Photo import view supporting camera scan and photo library.
/// After image acquisition, runs Vision OCR then either Foundation Models extraction
/// (fast path) or heuristic classification with split-screen review (fallback path).
struct PhotoImportView: View {
    @ObservedObject var importService: RecipeImportService

    @State private var phase: PhotoImportPhase = .picking
    @State private var showingScanner = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannedImage: UIImage?

    // OCR stats for the review screen
    @State private var ocrLineCount = 0
    @State private var ocrAvgConfidence: Float = 0
    @State private var ocrTimeMs = 0

    var body: some View {
        switch phase {
        case .picking:
            sourcePickerView

        case .captured(let images):
            capturedReviewView(images: images)

        case .processing(let status):
            processingView(status: status)

        case .reviewing(let lines, let imageData):
            reviewingView(lines: lines, imageData: imageData)

        case .error(let error):
            errorView(error)
        }
    }

    // MARK: - Source Picker

    private var sourcePickerView: some View {
        VStack(spacing: ForagerTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(ForagerTheme.accentSecondary)

            Text("Import from Photo")
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)

            Text("Scan a recipe page or choose a photo from your library")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ForagerTheme.Spacing.lg)

            VStack(spacing: ForagerTheme.Spacing.md) {
                Button {
                    showingScanner = true
                } label: {
                    Label("Scan Document", systemImage: "doc.viewfinder")
                        .font(ForagerTheme.bodyFont.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ForagerTheme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .font(ForagerTheme.bodyFont.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ForagerTheme.Spacing.md)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)

            Spacer()
            Spacer()
        }
        .padding(ForagerTheme.Spacing.lg)
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScannerView(
                onScan: { images in
                    showingScanner = false
                    guard !images.isEmpty else { return }
                    scannedImage = images.first
                    phase = .captured(images)
                },
                onCancel: {
                    showingScanner = false
                },
                onError: { error in
                    showingScanner = false
                    phase = .error(error)
                }
            )
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else { return }
            loadFromPhotoPicker(item)
        }
    }

    // MARK: - Captured Image Review

    private func capturedReviewView(images: [UIImage]) -> some View {
        VStack(spacing: 0) {
            // Show the captured image
            if let image = images.first {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.05))
            }

            Spacer()

            // Accept / Retake buttons
            VStack(spacing: ForagerTheme.Spacing.md) {
                Button {
                    processImages(images)
                } label: {
                    Label("Use Photo", systemImage: "checkmark.circle")
                        .font(ForagerTheme.bodyFont.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ForagerTheme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)

                Button {
                    phase = .picking
                    scannedImage = nil
                    showingScanner = true
                } label: {
                    Label("Retake", systemImage: "camera")
                        .font(ForagerTheme.bodyFont.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ForagerTheme.Spacing.md)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)
            .padding(.bottom, ForagerTheme.Spacing.xl)
        }
    }

    // MARK: - Processing View

    private func processingView(status: String) -> some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, ForagerTheme.Spacing.md)

            Text(status)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textSecondary)

            Spacer()
        }
    }

    // MARK: - Split-Screen Review

    private func reviewingView(lines: [EditableClassifiedLine], imageData: Data) -> some View {
        let binding = Binding<[EditableClassifiedLine]>(
            get: {
                if case .reviewing(let current, _) = phase { return current }
                return lines
            },
            set: {
                if case .reviewing(_, let data) = phase {
                    phase = .reviewing($0, data)
                }
            }
        )

        return GeometryReader { geometry in
            VStack(spacing: 0) {
                // Image preview (top ~35%)
                if let uiImage = UIImage(data: imageData) {
                    imagePreview(uiImage)
                        .frame(maxHeight: geometry.size.height * 0.35)
                }

                // OCR stats bar
                statsBar

                Divider()

                // Classified text review (bottom ~65%)
                SectionHighlightView(classifiedLines: binding) { correctedLines in
                    assembleDraftAndContinue(from: correctedLines)
                }
            }
        }
    }

    private func imagePreview(_ image: UIImage) -> some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width)
            }
        }
        .background(Color.black.opacity(0.05))
    }

    private var statsBar: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            Label("\(ocrLineCount) lines", systemImage: "text.alignleft")
            Label("\(Int(ocrAvgConfidence * 100))% confidence", systemImage: "checkmark.seal")
            Label("\(ocrTimeMs)ms", systemImage: "clock")
            Spacer()
        }
        .font(ForagerTheme.captionFont)
        .foregroundStyle(ForagerTheme.textTertiary)
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.xs)
    }

    // MARK: - Error View

    private func errorView(_ error: ImportError) -> some View {
        VStack(spacing: ForagerTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ForagerTheme.surfaceWarning)
                    .frame(width: 80, height: 80)

                Image(systemName: error.errorIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(ForagerTheme.statusWarningFG)
            }

            Text(error.errorTitle)
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)

            Text(error.userMessage)
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ForagerTheme.Spacing.lg)

            Button("Try Again") {
                phase = .picking
                selectedPhoto = nil
                scannedImage = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(ForagerTheme.accentPrimary)

            Spacer()
        }
    }

    // MARK: - Image Loading

    private func loadFromPhotoPicker(_ item: PhotosPickerItem) {
        phase = .processing("Loading image...")

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                phase = .error(.ocrFailed("Could not load the selected image."))
                return
            }
            scannedImage = image
            processImages([image])
        }
    }

    // MARK: - OCR + Classification Pipeline

    private func processImages(_ images: [UIImage]) {
        phase = .processing("Recognizing text...")

        Task {
            let startTime = CFAbsoluteTimeGetCurrent()

            do {
                let ocrLines = try await ImageOCRService.recognizeText(in: images)
                let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

                // Store stats
                ocrLineCount = ocrLines.count
                ocrAvgConfidence = ocrLines.isEmpty ? 0 : ocrLines.map(\.confidence).reduce(0, +) / Float(ocrLines.count)
                ocrTimeMs = elapsed

                // Concatenate OCR text for Foundation Models
                let ocrText = ocrLines.map(\.text).joined(separator: "\n")

                // Try Foundation Models first (fast path)
                phase = .processing("Extracting recipe...")
                if let fmDraft = await tryFoundationModelsExtraction(ocrText: ocrText, timeMs: elapsed) {
                    importService.state = .needsReview(fmDraft)
                    return
                }

                // Fall back to heuristic classification → review
                phase = .processing("Classifying lines...")
                let classified = OCRLineClassifier.classifyLines(ocrLines)
                let editableLines = classified.map { line in
                    EditableClassifiedLine(
                        text: line.text,
                        type: line.type,
                        confidence: line.confidence
                    )
                }

                guard !editableLines.isEmpty else {
                    phase = .error(.noTextDetected)
                    return
                }

                // Store image data for split-screen review
                let imageData = images.first?.jpegData(compressionQuality: 0.5) ?? Data()
                phase = .reviewing(editableLines, imageData)

            } catch let error as ImportError {
                phase = .error(error)
            } catch {
                phase = .error(.ocrFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Foundation Models Extraction (M10.3.4)

    /// Try FM structured extraction from concatenated OCR text.
    /// Returns nil if FM unavailable or fails — caller falls back to heuristic.
    private func tryFoundationModelsExtraction(ocrText: String, timeMs: Int) async -> ImportDraftRecipe? {
        let extractor = FoundationModelsExtractor()
        do {
            if var draft = try await extractor.extract(from: .text(ocrText)) {
                // Override extraction method to indicate OCR + FM path
                draft.extractionMethod = "ocr_fm"
                draft.extractionTimeMs = timeMs
                return draft
            }
        } catch {
            // FM failed — fall back silently
        }
        return nil
    }

    // MARK: - Draft Assembly

    /// Assemble an ImportDraftRecipe from user-corrected classified lines.
    /// Mirrors TextPasteImportView.assembleDraftAndContinue exactly.
    private func assembleDraftAndContinue(from lines: [EditableClassifiedLine]) {
        let startTime = CFAbsoluteTimeGetCurrent()

        var title = ""
        var ingredients: [String] = []
        var instructions: [String] = []
        var servings: Int?
        var prepMinutes: Int?
        var cookMinutes: Int?

        for line in lines {
            switch line.type {
            case .title:
                if title.isEmpty { title = line.text }
            case .ingredient:
                ingredients.append(line.text)
            case .instruction:
                instructions.append(line.text)
            case .metadata:
                extractMetadata(from: line.text, prepMinutes: &prepMinutes, cookMinutes: &cookMinutes, servings: &servings)
            case .sectionHeader, .unknown:
                break
            }
        }

        // Fallback title: first line
        if title.isEmpty, let first = lines.first {
            title = first.text
        }

        // Assemble instructions
        let instructionText: String
        if instructions.count > 1 {
            let alreadyNumbered = instructions.allSatisfy { $0.first?.isNumber == true || $0.lowercased().hasPrefix("step") }
            instructionText = alreadyNumbered
                ? instructions.joined(separator: "\n")
                : instructions.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        } else {
            instructionText = instructions.first ?? ""
        }

        let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000) + ocrTimeMs

        let draft = ImportDraftRecipe(
            title: ImportField(value: title, confidence: title.isEmpty ? .missing : .medium, source: .ocr),
            ingredients: ImportField(value: ingredients, confidence: ingredients.isEmpty ? .missing : .medium, source: .ocr),
            instructions: ImportField(value: instructionText, confidence: instructionText.isEmpty ? .missing : .medium, source: .ocr),
            prepTimeMinutes: ImportField(value: prepMinutes, confidence: prepMinutes != nil ? .medium : .missing, source: .ocr),
            cookTimeMinutes: ImportField(value: cookMinutes, confidence: cookMinutes != nil ? .medium : .missing, source: .ocr),
            servings: ImportField(value: servings ?? 4, confidence: servings != nil ? .medium : .low, source: .ocr),
            imageURL: ImportField(value: nil, confidence: .missing, source: .ocr),
            author: ImportField(value: nil, confidence: .missing, source: .ocr),
            sourceURL: nil,
            description: nil,
            cuisine: nil,
            category: nil,
            tags: nil,
            extractionMethod: "ocr_heuristic_reviewed",
            extractionTimeMs: elapsed
        )

        importService.state = .needsReview(draft)
    }

    // MARK: - Metadata Extraction

    private func extractMetadata(from text: String, prepMinutes: inout Int?, cookMinutes: inout Int?, servings: inout Int?) {
        let lower = text.lowercased()

        if let match = lower.range(of: #"(?:serves?|servings?|makes?|yields?)\s*:?\s*(\d+)"#, options: .regularExpression) {
            let digits = lower[match].filter(\.isNumber)
            if let num = Int(digits), num > 0, num <= 100 { servings = num }
        }

        if let match = lower.range(of: #"prep\s*(?:time)?\s*:?\s*(\d+)\s*(?:min|m\b|hour|hr|h\b)"#, options: .regularExpression) {
            let digits = lower[match].filter(\.isNumber)
            if let value = Int(digits), value > 0 {
                prepMinutes = lower[match].contains("hour") || lower[match].contains("hr") ? value * 60 : value
            }
        }

        if let match = lower.range(of: #"(?:cook|bake)\s*(?:time)?\s*:?\s*(\d+)\s*(?:min|m\b|hour|hr|h\b)"#, options: .regularExpression) {
            let digits = lower[match].filter(\.isNumber)
            if let value = Int(digits), value > 0 {
                cookMinutes = lower[match].contains("hour") || lower[match].contains("hr") ? value * 60 : value
            }
        }
    }
}
