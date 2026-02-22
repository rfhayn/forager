//
//  ParsingTelemetryService.swift
//  forager
//
//  Created for M8.1: Parsing Resilience & Telemetry
//  Purpose: Log parsing events locally for data-driven improvement decisions
//  Privacy: All data stored locally - never transmitted
//

import Foundation

// MARK: - Telemetry Event Models

/// Represents a single parsing event for telemetry analysis
struct ParsingTelemetryEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let rawInput: String
    let parsedName: String
    let parsedQuantity: Double?
    let parsedUnit: String?
    let parseConfidence: Float
    let parserUsed: String?     // M8.4: "regex", "ml", or "nlp" (winner-only attribution)
    let source: ParsingSource

    /// Where the parsing occurred
    enum ParsingSource: String, Codable {
        case recipeIngredient       // Adding ingredient to recipe
        case groceryListItem        // Adding item to grocery list
        case mealPlanBulkAdd        // Bulk add from meal plan
        case import_               // Recipe import (underscore to avoid keyword)
    }

    init(
        rawInput: String,
        parsedName: String,
        parsedQuantity: Double?,
        parsedUnit: String?,
        parseConfidence: Float,
        parserUsed: String? = nil,
        source: ParsingSource
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.rawInput = rawInput
        self.parsedName = parsedName
        self.parsedQuantity = parsedQuantity
        self.parsedUnit = parsedUnit
        self.parseConfidence = parseConfidence
        self.parserUsed = parserUsed
        self.source = source
    }
}

/// Represents a user correction to a parsed ingredient
struct ParsingCorrectionEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let originalEventId: UUID?

    // Original parsed values
    let originalName: String
    let originalQuantity: Double?
    let originalUnit: String?
    let originalConfidence: Float

    // User-corrected values
    let correctedName: String
    let correctedQuantity: Double?
    let correctedUnit: String?

    // What changed
    let nameChanged: Bool
    let quantityChanged: Bool
    let unitChanged: Bool

    // M8.4 Phase 7: Schema v3 — correction attribution
    let parserUsed: String?         // "regex", "ml", or "nlp" (nil for unattributed)
    let source: CorrectionSource?   // Where the correction occurred

    /// M8.4 Phase 7: Where a user correction originated
    enum CorrectionSource: String, Codable {
        case editRecipe
        case createRecipe
        case groceryListEdit
        case templateRename
    }

    init(
        originalEventId: UUID? = nil,
        originalName: String,
        originalQuantity: Double?,
        originalUnit: String?,
        originalConfidence: Float,
        correctedName: String,
        correctedQuantity: Double?,
        correctedUnit: String?,
        parserUsed: String? = nil,
        source: CorrectionSource? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.originalEventId = originalEventId
        self.originalName = originalName
        self.originalQuantity = originalQuantity
        self.originalUnit = originalUnit
        self.originalConfidence = originalConfidence
        self.correctedName = correctedName
        self.correctedQuantity = correctedQuantity
        self.correctedUnit = correctedUnit
        self.nameChanged = originalName != correctedName
        self.quantityChanged = originalQuantity != correctedQuantity
        self.unitChanged = originalUnit != correctedUnit
        self.parserUsed = parserUsed
        self.source = source
    }
}

/// Container for all telemetry data
struct ParsingTelemetryData: Codable {
    var parsingEvents: [ParsingTelemetryEvent]
    var correctionEvents: [ParsingCorrectionEvent]
    var schemaVersion: Int

    static let currentSchemaVersion = 3  // M8.4 Phase 7: Added correction source + parserUsed

    init() {
        self.parsingEvents = []
        self.correctionEvents = []
        self.schemaVersion = Self.currentSchemaVersion
    }
}

// MARK: - ParsingTelemetryService

/// M8.1: Service for logging parsing telemetry to enable data-driven improvements
/// All data is stored locally in JSON format - never transmitted externally
class ParsingTelemetryService: ObservableObject {

    // MARK: - Singleton

    static let shared = ParsingTelemetryService()

    // MARK: - Published Properties

    /// Total parsing events logged this session
    @Published private(set) var sessionEventCount: Int = 0

    /// Total corrections logged this session
    @Published private(set) var sessionCorrectionCount: Int = 0

    /// Low confidence events this session (parseConfidence < 0.5)
    @Published private(set) var sessionLowConfidenceCount: Int = 0

    // MARK: - Private Properties

    private var telemetryData: ParsingTelemetryData
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.forager.parsingTelemetry", qos: .utility)

    /// Threshold below which parsing is considered "low confidence"
    static let lowConfidenceThreshold: Float = 0.5

    // MARK: - Initialization

    private init() {
        // Store in Documents directory for persistence
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("parsing_telemetry.json")

        // Load existing data or create new
        self.telemetryData = Self.loadTelemetryData(from: fileURL) ?? ParsingTelemetryData()

        #if DEBUG
        print("📊 ParsingTelemetryService initialized - \(telemetryData.parsingEvents.count) events, \(telemetryData.correctionEvents.count) corrections loaded")
        #endif
    }

    // MARK: - Public API

    /// Log a parsing event
    /// Call this after every ingredient parsing operation
    func logParsingEvent(
        rawInput: String,
        parsedName: String,
        parsedQuantity: Double?,
        parsedUnit: String?,
        parseConfidence: Float,
        parserUsed: String? = nil,
        source: ParsingTelemetryEvent.ParsingSource
    ) -> UUID {
        let event = ParsingTelemetryEvent(
            rawInput: rawInput,
            parsedName: parsedName,
            parsedQuantity: parsedQuantity,
            parsedUnit: parsedUnit,
            parseConfidence: parseConfidence,
            parserUsed: parserUsed,
            source: source
        )

        queue.async { [weak self] in
            self?.telemetryData.parsingEvents.append(event)
            self?.saveTelemetryData()
        }

        // Update counters synchronously for immediate visibility in tests
        // Safe because these are simple increments and @Published handles thread safety
        if Thread.isMainThread {
            sessionEventCount += 1
            if parseConfidence < Self.lowConfidenceThreshold {
                sessionLowConfidenceCount += 1
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.sessionEventCount += 1
                if parseConfidence < Self.lowConfidenceThreshold {
                    self?.sessionLowConfidenceCount += 1
                }
            }
        }

        #if DEBUG
        if parseConfidence < Self.lowConfidenceThreshold {
            print("📊 [Telemetry] Low confidence parse: \"\(rawInput)\" → \"\(parsedName)\" (conf: \(String(format: "%.2f", parseConfidence)))")
        }
        #endif

        return event.id
    }

    /// Log a user correction to a previously parsed ingredient
    /// Call this when user manually edits an ingredient
    func logCorrection(
        originalEventId: UUID? = nil,
        originalName: String,
        originalQuantity: Double?,
        originalUnit: String?,
        originalConfidence: Float,
        correctedName: String,
        correctedQuantity: Double?,
        correctedUnit: String?,
        parserUsed: String? = nil,
        source: ParsingCorrectionEvent.CorrectionSource? = nil
    ) {
        let correction = ParsingCorrectionEvent(
            originalEventId: originalEventId,
            originalName: originalName,
            originalQuantity: originalQuantity,
            originalUnit: originalUnit,
            originalConfidence: originalConfidence,
            correctedName: correctedName,
            correctedQuantity: correctedQuantity,
            correctedUnit: correctedUnit,
            parserUsed: parserUsed,
            source: source
        )

        queue.async { [weak self] in
            self?.telemetryData.correctionEvents.append(correction)
            self?.saveTelemetryData()
        }

        // Update counter synchronously for immediate visibility in tests
        if Thread.isMainThread {
            sessionCorrectionCount += 1
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.sessionCorrectionCount += 1
            }
        }

        #if DEBUG
        print("📊 [Telemetry] User correction: \"\(originalName)\" → \"\(correctedName)\"")
        if correction.quantityChanged {
            print("   Quantity: \(originalQuantity ?? 0) → \(correctedQuantity ?? 0)")
        }
        if correction.unitChanged {
            print("   Unit: \(originalUnit ?? "none") → \(correctedUnit ?? "none")")
        }
        #endif
    }

    // MARK: - Analysis API (for M8.2)

    /// Get all parsing events for analysis
    func getAllParsingEvents() -> [ParsingTelemetryEvent] {
        return telemetryData.parsingEvents
    }

    /// Get all correction events for analysis
    func getAllCorrectionEvents() -> [ParsingCorrectionEvent] {
        return telemetryData.correctionEvents
    }

    /// M8.4 Phase 7: Total correction count across all sessions (for corpus gate display)
    func getTotalCorrectionCount() -> Int {
        return telemetryData.correctionEvents.count
    }

    /// Get low confidence events (parseConfidence < threshold)
    func getLowConfidenceEvents(threshold: Float = lowConfidenceThreshold) -> [ParsingTelemetryEvent] {
        return telemetryData.parsingEvents.filter { $0.parseConfidence < threshold }
    }

    /// Get summary statistics
    func getStatistics() -> TelemetryStatistics {
        let events = telemetryData.parsingEvents
        let corrections = telemetryData.correctionEvents

        let lowConfidenceCount = events.filter { $0.parseConfidence < Self.lowConfidenceThreshold }.count
        let avgConfidence = events.isEmpty ? 0 : events.map { Double($0.parseConfidence) }.reduce(0, +) / Double(events.count)

        // Calculate correction rate
        let correctionRate = events.isEmpty ? 0 : Double(corrections.count) / Double(events.count)

        // Count by source
        var sourceBreakdown: [ParsingTelemetryEvent.ParsingSource: Int] = [:]
        for event in events {
            sourceBreakdown[event.source, default: 0] += 1
        }

        return TelemetryStatistics(
            totalEvents: events.count,
            totalCorrections: corrections.count,
            lowConfidenceCount: lowConfidenceCount,
            lowConfidenceRate: events.isEmpty ? 0 : Double(lowConfidenceCount) / Double(events.count),
            averageConfidence: avgConfidence,
            correctionRate: correctionRate,
            sourceBreakdown: sourceBreakdown
        )
    }

    /// Export telemetry data as JSON string (for debugging/analysis)
    func exportAsJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(telemetryData) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Clear all telemetry data (for testing/privacy)
    func clearAllData() {
        queue.async { [weak self] in
            self?.telemetryData = ParsingTelemetryData()
            self?.saveTelemetryData()
        }

        // Reset counters synchronously for immediate visibility
        if Thread.isMainThread {
            sessionEventCount = 0
            sessionCorrectionCount = 0
            sessionLowConfidenceCount = 0
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.sessionEventCount = 0
                self?.sessionCorrectionCount = 0
                self?.sessionLowConfidenceCount = 0
            }
        }

        #if DEBUG
        print("📊 [Telemetry] All data cleared")
        #endif
    }

    // MARK: - Testing Support

    /// Synchronously reset all telemetry data for test isolation
    /// This method blocks until reset is complete - use only in tests
    func resetForTesting() {
        // Synchronously clear in-memory data
        queue.sync {
            telemetryData = ParsingTelemetryData()
        }

        // Synchronously update counters on main thread
        if Thread.isMainThread {
            sessionEventCount = 0
            sessionCorrectionCount = 0
            sessionLowConfidenceCount = 0
        } else {
            DispatchQueue.main.sync {
                sessionEventCount = 0
                sessionCorrectionCount = 0
                sessionLowConfidenceCount = 0
            }
        }

        // Synchronously delete the JSON file
        queue.sync {
            try? FileManager.default.removeItem(at: fileURL)
        }

        #if DEBUG
        print("📊 [Telemetry] Reset for testing complete")
        #endif
    }

    /// Wait for all pending async operations to complete
    /// Useful in tests to ensure data is persisted before assertions
    func waitForPendingOperations() {
        queue.sync { /* barrier */ }
    }

    // MARK: - Private Methods

    private func saveTelemetryData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(telemetryData)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("📊 [Telemetry] Failed to save: \(error.localizedDescription)")
            #endif
        }
    }

    private static func loadTelemetryData(from url: URL) -> ParsingTelemetryData? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ParsingTelemetryData.self, from: data)
        } catch {
            #if DEBUG
            print("📊 [Telemetry] Failed to load: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}

// MARK: - Statistics Model

struct TelemetryStatistics {
    let totalEvents: Int
    let totalCorrections: Int
    let lowConfidenceCount: Int
    let lowConfidenceRate: Double      // 0.0-1.0
    let averageConfidence: Double      // 0.0-1.0
    let correctionRate: Double         // corrections / events
    let sourceBreakdown: [ParsingTelemetryEvent.ParsingSource: Int]

    var formattedLowConfidenceRate: String {
        String(format: "%.1f%%", lowConfidenceRate * 100)
    }

    var formattedAverageConfidence: String {
        String(format: "%.1f%%", averageConfidence * 100)
    }

    var formattedCorrectionRate: String {
        String(format: "%.1f%%", correctionRate * 100)
    }
}
