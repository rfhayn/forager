//
//  ParsingTelemetryServiceTests.swift
//  foragerTests
//
//  M8.1: Parsing Resilience & Telemetry
//  Created: February 6, 2026
//
//  Unit tests for ParsingTelemetryService
//  Test plan: docs/testing/M8.1-ParsingTelemetryService-test-plan.md
//

import XCTest
@testable import forager

final class ParsingTelemetryServiceTests: XCTestCase {

    // MARK: - Properties

    private var service: ParsingTelemetryService!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        service = ParsingTelemetryService.shared
        // Clear data before each test for isolation
        service.clearAllData()

        // Wait for async clear to complete
        let expectation = XCTestExpectation(description: "Clear data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    override func tearDown() {
        service.clearAllData()
        service = nil
        super.tearDown()
    }

    // MARK: - P0: Event Logging Tests

    /// TEST-TEL-001: Basic Parsing Event Logging
    func testBasicParsingEventLogging() {
        // When
        let eventId = service.logParsingEvent(
            rawInput: "2 cups flour",
            parsedName: "flour",
            parsedQuantity: 2.0,
            parsedUnit: "cup",
            parseConfidence: 0.95,
            source: .recipeIngredient
        )

        // Then
        XCTAssertNotNil(eventId, "Event ID should not be nil")

        // Wait for async update
        let expectation = XCTestExpectation(description: "Session count update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.service.sessionEventCount, 1, "Session event count should be 1")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-002: Low Confidence Event Detection
    func testLowConfidenceEventDetection() {
        // Given - Low confidence event (below 0.5 threshold)
        _ = service.logParsingEvent(
            rawInput: "some flour",
            parsedName: "flour",
            parsedQuantity: nil,
            parsedUnit: nil,
            parseConfidence: 0.3,
            source: .recipeIngredient
        )

        // When - High confidence event (above threshold)
        _ = service.logParsingEvent(
            rawInput: "2 cups flour",
            parsedName: "flour",
            parsedQuantity: 2.0,
            parsedUnit: "cup",
            parseConfidence: 0.8,
            source: .recipeIngredient
        )

        // Then
        let expectation = XCTestExpectation(description: "Low confidence count")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.service.sessionEventCount, 2, "Should have 2 total events")
            XCTAssertEqual(self.service.sessionLowConfidenceCount, 1, "Should have 1 low confidence event")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-003: Multiple Event Sources
    func testMultipleEventSources() {
        // When
        _ = service.logParsingEvent(
            rawInput: "2 cups flour", parsedName: "flour",
            parsedQuantity: 2.0, parsedUnit: "cup",
            parseConfidence: 0.9, source: .recipeIngredient
        )
        _ = service.logParsingEvent(
            rawInput: "1 lb chicken", parsedName: "chicken",
            parsedQuantity: 1.0, parsedUnit: "lb",
            parseConfidence: 0.9, source: .groceryListItem
        )
        _ = service.logParsingEvent(
            rawInput: "3 eggs", parsedName: "eggs",
            parsedQuantity: 3.0, parsedUnit: nil,
            parseConfidence: 0.9, source: .mealPlanBulkAdd
        )

        // Then - Wait for persistence and check statistics
        let expectation = XCTestExpectation(description: "Source breakdown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let stats = self.service.getStatistics()
            XCTAssertEqual(stats.totalEvents, 3, "Should have 3 events")
            XCTAssertEqual(stats.sourceBreakdown[.recipeIngredient], 1)
            XCTAssertEqual(stats.sourceBreakdown[.groceryListItem], 1)
            XCTAssertEqual(stats.sourceBreakdown[.mealPlanBulkAdd], 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-004: Nil Quantity/Unit Handling
    func testNilQuantityUnitHandling() {
        // When
        let eventId = service.logParsingEvent(
            rawInput: "salt to taste",
            parsedName: "salt",
            parsedQuantity: nil,
            parsedUnit: nil,
            parseConfidence: 0.4,
            source: .recipeIngredient
        )

        // Then
        XCTAssertNotNil(eventId, "Should log event with nil quantity/unit")

        let expectation = XCTestExpectation(description: "Nil handling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let events = self.service.getAllParsingEvents()
            XCTAssertEqual(events.count, 1)
            XCTAssertNil(events.first?.parsedQuantity)
            XCTAssertNil(events.first?.parsedUnit)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-005: Empty/Whitespace Input Handling
    func testEmptyWhitespaceInputHandling() {
        // When
        _ = service.logParsingEvent(
            rawInput: "",
            parsedName: "",
            parsedQuantity: nil,
            parsedUnit: nil,
            parseConfidence: 0.0,
            source: .recipeIngredient
        )
        _ = service.logParsingEvent(
            rawInput: "   ",
            parsedName: "",
            parsedQuantity: nil,
            parsedUnit: nil,
            parseConfidence: 0.0,
            source: .recipeIngredient
        )

        // Then
        let expectation = XCTestExpectation(description: "Empty input")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.service.sessionEventCount, 2, "Should log empty inputs")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-006: Special Characters in Input
    func testSpecialCharactersInInput() {
        // When
        _ = service.logParsingEvent(
            rawInput: "1/2 cup \"fresh\" flour (sifted)",
            parsedName: "flour",
            parsedQuantity: 0.5,
            parsedUnit: "cup",
            parseConfidence: 0.7,
            source: .recipeIngredient
        )

        // Then
        let expectation = XCTestExpectation(description: "Special chars")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let events = self.service.getAllParsingEvents()
            XCTAssertEqual(events.count, 1)
            XCTAssertTrue(events.first?.rawInput.contains("\"") ?? false, "Quotes should be preserved")
            XCTAssertTrue(events.first?.rawInput.contains("(") ?? false, "Parentheses should be preserved")

            // Verify JSON export handles special characters
            let json = self.service.exportAsJSON()
            XCTAssertNotNil(json)
            XCTAssertTrue(json?.contains("fresh") ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - P0: Correction Logging Tests

    /// TEST-TEL-007: Basic Correction Logging
    func testBasicCorrectionLogging() {
        // Given
        let eventId = service.logParsingEvent(
            rawInput: "2 cups flour",
            parsedName: "flour",
            parsedQuantity: 2.0,
            parsedUnit: "cup",
            parseConfidence: 0.6,
            source: .recipeIngredient
        )

        // When
        service.logCorrection(
            originalEventId: eventId,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.6,
            correctedName: "all-purpose flour",
            correctedQuantity: 2.0,
            correctedUnit: "cup"
        )

        // Then
        let expectation = XCTestExpectation(description: "Correction logged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.service.sessionCorrectionCount, 1, "Should have 1 correction")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-008: Correction Change Detection - Name Only
    func testCorrectionChangeDetectionNameOnly() {
        // When
        service.logCorrection(
            originalEventId: nil,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.6,
            correctedName: "all-purpose flour",
            correctedQuantity: 2.0,
            correctedUnit: "cup"
        )

        // Then
        let expectation = XCTestExpectation(description: "Name change detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let corrections = self.service.getAllCorrectionEvents()
            XCTAssertEqual(corrections.count, 1)

            let correction = corrections.first!
            XCTAssertTrue(correction.nameChanged, "Name should be marked as changed")
            XCTAssertFalse(correction.quantityChanged, "Quantity should not be marked as changed")
            XCTAssertFalse(correction.unitChanged, "Unit should not be marked as changed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-009: Correction Change Detection - Quantity Only
    func testCorrectionChangeDetectionQuantityOnly() {
        // When
        service.logCorrection(
            originalEventId: nil,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.6,
            correctedName: "flour",
            correctedQuantity: 2.5,
            correctedUnit: "cup"
        )

        // Then
        let expectation = XCTestExpectation(description: "Quantity change detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let corrections = self.service.getAllCorrectionEvents()
            let correction = corrections.first!
            XCTAssertFalse(correction.nameChanged)
            XCTAssertTrue(correction.quantityChanged, "Quantity should be marked as changed")
            XCTAssertFalse(correction.unitChanged)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-010: Correction Change Detection - Unit Only
    func testCorrectionChangeDetectionUnitOnly() {
        // When
        service.logCorrection(
            originalEventId: nil,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.6,
            correctedName: "flour",
            correctedQuantity: 2.0,
            correctedUnit: "cups"
        )

        // Then
        let expectation = XCTestExpectation(description: "Unit change detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let corrections = self.service.getAllCorrectionEvents()
            let correction = corrections.first!
            XCTAssertFalse(correction.nameChanged)
            XCTAssertFalse(correction.quantityChanged)
            XCTAssertTrue(correction.unitChanged, "Unit should be marked as changed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-011: Correction Without Original Event ID
    func testCorrectionWithoutOriginalEventId() {
        // When - Log correction without linking to original event
        service.logCorrection(
            originalEventId: nil,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.6,
            correctedName: "bread flour",
            correctedQuantity: 2.0,
            correctedUnit: "cup"
        )

        // Then
        let expectation = XCTestExpectation(description: "Correction without event ID")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let corrections = self.service.getAllCorrectionEvents()
            XCTAssertEqual(corrections.count, 1, "Should log correction without event ID")
            XCTAssertNil(corrections.first?.originalEventId)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - P0: Persistence Tests

    /// TEST-TEL-013: JSON File Format Valid
    func testJSONFileFormatValid() {
        // Given
        _ = service.logParsingEvent(
            rawInput: "2 cups flour",
            parsedName: "flour",
            parsedQuantity: 2.0,
            parsedUnit: "cup",
            parseConfidence: 0.95,
            source: .recipeIngredient
        )

        service.logCorrection(
            originalEventId: nil,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.95,
            correctedName: "all-purpose flour",
            correctedQuantity: 2.0,
            correctedUnit: "cup"
        )

        // When
        let expectation = XCTestExpectation(description: "JSON export")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let json = self.service.exportAsJSON()

            // Then
            XCTAssertNotNil(json, "JSON export should not be nil")

            // Verify it's valid JSON by parsing it
            if let jsonData = json?.data(using: .utf8) {
                do {
                    let parsed = try JSONSerialization.jsonObject(with: jsonData)
                    XCTAssertNotNil(parsed, "Should be valid JSON")
                } catch {
                    XCTFail("JSON parsing failed: \(error)")
                }
            }

            // Verify key fields are present
            XCTAssertTrue(json?.contains("parsingEvents") ?? false)
            XCTAssertTrue(json?.contains("correctionEvents") ?? false)
            XCTAssertTrue(json?.contains("schemaVersion") ?? false)
            XCTAssertTrue(json?.contains("rawInput") ?? false)
            XCTAssertTrue(json?.contains("parseConfidence") ?? false)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-014: Clear All Data
    func testClearAllData() {
        // Given
        _ = service.logParsingEvent(
            rawInput: "2 cups flour",
            parsedName: "flour",
            parsedQuantity: 2.0,
            parsedUnit: "cup",
            parseConfidence: 0.95,
            source: .recipeIngredient
        )

        service.logCorrection(
            originalEventId: nil,
            originalName: "flour",
            originalQuantity: 2.0,
            originalUnit: "cup",
            originalConfidence: 0.95,
            correctedName: "bread flour",
            correctedQuantity: 2.0,
            correctedUnit: "cup"
        )

        // Wait for data to be logged
        let setupExpectation = XCTestExpectation(description: "Setup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 1.0)

        // When
        service.clearAllData()

        // Then
        let expectation = XCTestExpectation(description: "Clear data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.service.sessionEventCount, 0, "Session event count should be 0")
            XCTAssertEqual(self.service.sessionCorrectionCount, 0, "Session correction count should be 0")
            XCTAssertEqual(self.service.sessionLowConfidenceCount, 0, "Low confidence count should be 0")
            XCTAssertEqual(self.service.getAllParsingEvents().count, 0, "Events array should be empty")
            XCTAssertEqual(self.service.getAllCorrectionEvents().count, 0, "Corrections array should be empty")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - P1: Statistics Tests

    /// TEST-TEL-016: Statistics Calculation - Empty Data
    func testStatisticsWithEmptyData() {
        // Given - Data is already cleared in setUp

        // When
        let stats = service.getStatistics()

        // Then
        XCTAssertEqual(stats.totalEvents, 0)
        XCTAssertEqual(stats.totalCorrections, 0)
        XCTAssertEqual(stats.lowConfidenceCount, 0)
        XCTAssertEqual(stats.lowConfidenceRate, 0)
        XCTAssertEqual(stats.averageConfidence, 0)
        XCTAssertEqual(stats.correctionRate, 0)
        // No division by zero errors - test passes if we get here
    }

    /// TEST-TEL-017: Statistics Calculation - With Data
    func testStatisticsWithData() {
        // Given - Log 10 events with varying confidence
        let confidences: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0, 0.3, 0.5, 0.7, 0.9, 0.95]
        for confidence in confidences {
            _ = service.logParsingEvent(
                rawInput: "test",
                parsedName: "test",
                parsedQuantity: 1.0,
                parsedUnit: "cup",
                parseConfidence: confidence,
                source: .recipeIngredient
            )
        }

        // Log 2 corrections
        service.logCorrection(
            originalEventId: nil,
            originalName: "test", originalQuantity: 1.0, originalUnit: "cup", originalConfidence: 0.5,
            correctedName: "corrected", correctedQuantity: 1.0, correctedUnit: "cup"
        )
        service.logCorrection(
            originalEventId: nil,
            originalName: "test", originalQuantity: 1.0, originalUnit: "cup", originalConfidence: 0.5,
            correctedName: "corrected2", correctedQuantity: 1.0, correctedUnit: "cup"
        )

        // When
        let expectation = XCTestExpectation(description: "Statistics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let stats = self.service.getStatistics()

            // Then
            XCTAssertEqual(stats.totalEvents, 10, "Should have 10 events")
            XCTAssertEqual(stats.totalCorrections, 2, "Should have 2 corrections")
            // Low confidence: 0.2, 0.4, 0.3 (3 events < 0.5)
            XCTAssertEqual(stats.lowConfidenceCount, 3, "Should have 3 low confidence events")
            XCTAssertEqual(stats.lowConfidenceRate, 0.3, accuracy: 0.01, "Low confidence rate should be 30%")
            // Average: (0.2+0.4+0.6+0.8+1.0+0.3+0.5+0.7+0.9+0.95) / 10 = 6.35 / 10 = 0.635
            XCTAssertEqual(stats.averageConfidence, 0.635, accuracy: 0.01, "Average confidence should be ~0.635")
            XCTAssertEqual(stats.correctionRate, 0.2, accuracy: 0.01, "Correction rate should be 20%")

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-018: Get Low Confidence Events Filter
    func testLowConfidenceEventsFilter() {
        // Given - Log 5 events with confidence: 0.2, 0.4, 0.6, 0.8, 1.0
        let confidences: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0]
        for confidence in confidences {
            _ = service.logParsingEvent(
                rawInput: "test \(confidence)",
                parsedName: "test",
                parsedQuantity: 1.0,
                parsedUnit: "cup",
                parseConfidence: confidence,
                source: .recipeIngredient
            )
        }

        // When / Then
        let expectation = XCTestExpectation(description: "Filter")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Default threshold (0.5): should get 2 events (0.2, 0.4)
            let defaultFiltered = self.service.getLowConfidenceEvents()
            XCTAssertEqual(defaultFiltered.count, 2, "Default threshold should return 2 events")

            // Custom threshold (0.7): should get 3 events (0.2, 0.4, 0.6)
            let customFiltered = self.service.getLowConfidenceEvents(threshold: 0.7)
            XCTAssertEqual(customFiltered.count, 3, "Threshold 0.7 should return 3 events")

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - P1: Edge Cases

    /// TEST-TEL-020: Unicode/Emoji in Input
    func testUnicodeEmojiInInput() {
        // When
        _ = service.logParsingEvent(
            rawInput: "2 カップ 小麦粉",  // Japanese
            parsedName: "小麦粉",
            parsedQuantity: 2.0,
            parsedUnit: "カップ",
            parseConfidence: 0.8,
            source: .recipeIngredient
        )
        _ = service.logParsingEvent(
            rawInput: "🥕 carrots",
            parsedName: "carrots",
            parsedQuantity: nil,
            parsedUnit: nil,
            parseConfidence: 0.7,
            source: .groceryListItem
        )

        // Then
        let expectation = XCTestExpectation(description: "Unicode")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let events = self.service.getAllParsingEvents()
            XCTAssertEqual(events.count, 2)
            XCTAssertTrue(events.contains { $0.rawInput.contains("カップ") })
            XCTAssertTrue(events.contains { $0.rawInput.contains("🥕") })

            // Verify JSON export handles Unicode
            let json = self.service.exportAsJSON()
            XCTAssertTrue(json?.contains("小麦粉") ?? false)
            XCTAssertTrue(json?.contains("🥕") ?? false)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    /// TEST-TEL-022: Rapid Sequential Logging
    func testRapidSequentialLogging() {
        // When - Log 100 events in rapid succession
        for i in 0..<100 {
            _ = service.logParsingEvent(
                rawInput: "item \(i)",
                parsedName: "item",
                parsedQuantity: Double(i),
                parsedUnit: "cup",
                parseConfidence: Float(i) / 100.0,
                source: .recipeIngredient
            )
        }

        // Then - Wait for all async operations
        let expectation = XCTestExpectation(description: "Rapid logging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let events = self.service.getAllParsingEvents()
            XCTAssertEqual(events.count, 100, "All 100 events should be logged")
            XCTAssertEqual(self.service.sessionEventCount, 100)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    /// TEST-TEL-023: Confidence Boundary Values
    func testConfidenceBoundaryValues() {
        // When
        _ = service.logParsingEvent(
            rawInput: "test 0.0", parsedName: "test",
            parsedQuantity: 1.0, parsedUnit: "cup",
            parseConfidence: 0.0,  // Minimum
            source: .recipeIngredient
        )
        _ = service.logParsingEvent(
            rawInput: "test 0.5", parsedName: "test",
            parsedQuantity: 1.0, parsedUnit: "cup",
            parseConfidence: 0.5,  // Exactly at threshold
            source: .recipeIngredient
        )
        _ = service.logParsingEvent(
            rawInput: "test 1.0", parsedName: "test",
            parsedQuantity: 1.0, parsedUnit: "cup",
            parseConfidence: 1.0,  // Maximum
            source: .recipeIngredient
        )

        // Then
        let expectation = XCTestExpectation(description: "Boundary values")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Low confidence is < 0.5, so only 0.0 should count
            XCTAssertEqual(self.service.sessionLowConfidenceCount, 1, "Only confidence 0.0 should be low")

            let lowEvents = self.service.getLowConfidenceEvents()
            XCTAssertEqual(lowEvents.count, 1)
            XCTAssertEqual(lowEvents.first?.parseConfidence, 0.0)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - P2: Performance Tests

    /// TEST-TEL-025: Logging Performance
    func testLoggingPerformance() {
        // Measure time to log 1000 events
        measure {
            for i in 0..<1000 {
                _ = service.logParsingEvent(
                    rawInput: "item \(i)",
                    parsedName: "item",
                    parsedQuantity: Double(i),
                    parsedUnit: "cup",
                    parseConfidence: 0.9,
                    source: .recipeIngredient
                )
            }
        }
        // XCTest will report average time - should be < 100ms
    }

    // MARK: - Helper Methods

    /// TEST-TEL-019: Statistics Formatted Strings
    func testStatisticsFormattedStrings() {
        // Given
        _ = service.logParsingEvent(
            rawInput: "test", parsedName: "test",
            parsedQuantity: 1.0, parsedUnit: "cup",
            parseConfidence: 0.3,  // Low confidence
            source: .recipeIngredient
        )
        _ = service.logParsingEvent(
            rawInput: "test2", parsedName: "test",
            parsedQuantity: 1.0, parsedUnit: "cup",
            parseConfidence: 0.9,
            source: .recipeIngredient
        )

        service.logCorrection(
            originalEventId: nil,
            originalName: "test", originalQuantity: 1.0, originalUnit: "cup", originalConfidence: 0.3,
            correctedName: "corrected", correctedQuantity: 1.0, correctedUnit: "cup"
        )

        // When
        let expectation = XCTestExpectation(description: "Formatted strings")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let stats = self.service.getStatistics()

            // Then - Verify formatted strings work
            XCTAssertTrue(stats.formattedLowConfidenceRate.contains("%"))
            XCTAssertTrue(stats.formattedAverageConfidence.contains("%"))
            XCTAssertTrue(stats.formattedCorrectionRate.contains("%"))

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
