//
//  GroceryMergeServiceTests.swift
//  foragerTests
//
//  M8.3.2: Automatic Grocery List Quantity Merging
//  Tests for GroceryMergeService — pure logic, no Core Data required.
//

import XCTest
@testable import forager

final class GroceryMergeServiceTests: XCTestCase {

    private var service: GroceryMergeService!

    override func setUp() {
        super.setUp()
        service = GroceryMergeService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Quantity Merging: Same Unit

    func testSameUnitAddition() {
        let existing = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 12, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 20, accuracy: 0.01)
        XCTAssertEqual(result.standardUnit, "oz")
        XCTAssertTrue(result.didMergeQuantity)
    }

    func testSameUnitFractional() {
        let existing = GroceryMergeInput(numericValue: 0.5, standardUnit: "cup", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 0.25, standardUnit: "cup", isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 0.75, accuracy: 0.01)
        XCTAssertEqual(result.standardUnit, "cup")
        XCTAssertTrue(result.didMergeQuantity)
    }

    // MARK: - Quantity Merging: Convertible Units

    func testConvertibleVolumeUnits() {
        // 8 tbsp = 0.5 cup, so 2 cup + 8 tbsp = 2.5 cup
        let existing = GroceryMergeInput(numericValue: 2, standardUnit: "cup", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 8, standardUnit: "tbsp", isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 2.5, accuracy: 0.01)
        XCTAssertEqual(result.standardUnit, "cup")
        XCTAssertTrue(result.didMergeQuantity)
    }

    func testConvertibleWeightUnits() {
        // 8 oz ≈ 0.502 lb (using 454g/lb, 28g/oz), so 1 lb + 8 oz ≈ 1.5 lb
        let existing = GroceryMergeInput(numericValue: 1, standardUnit: "lb", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        // 8oz = 224g, 224g / 454g = ~0.493lb, so total ≈ 1.493
        XCTAssertEqual(result.numericValue, 1.0 + (8.0 * 28.0 / 454.0), accuracy: 0.01)
        XCTAssertEqual(result.standardUnit, "lb")
        XCTAssertTrue(result.didMergeQuantity)
    }

    // MARK: - Quantity Merging: Unitless

    func testUnitlessAddition() {
        let existing = GroceryMergeInput(numericValue: 3, standardUnit: nil, isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 2, standardUnit: nil, isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 5, accuracy: 0.01)
        XCTAssertNil(result.standardUnit)
        XCTAssertTrue(result.didMergeQuantity)
    }

    // MARK: - Quantity Merging: Incompatible

    func testIncompatibleUnits() {
        let existing = GroceryMergeInput(numericValue: 2, standardUnit: "cup", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 3, standardUnit: "clove", isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 2, accuracy: 0.01, "Existing quantity should be unchanged")
        XCTAssertEqual(result.standardUnit, "cup")
        XCTAssertFalse(result.didMergeQuantity)
    }

    // MARK: - Confidence Tracking

    func testConfidenceBothHigh() {
        let existing = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 12, standardUnit: "oz", isParseable: true, parseConfidence: 0.90)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.parseConfidence, 0.90, accuracy: 0.001)
    }

    func testConfidenceOneLow() {
        let existing = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 4, standardUnit: "oz", isParseable: true, parseConfidence: 0.60)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.parseConfidence, 0.60, accuracy: 0.001)
    }

    func testConfidenceBothLow() {
        let existing = GroceryMergeInput(numericValue: 2, standardUnit: "cup", isParseable: true, parseConfidence: 0.60)
        let incoming = GroceryMergeInput(numericValue: 1, standardUnit: "cup", isParseable: true, parseConfidence: 0.30)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.parseConfidence, 0.30, accuracy: 0.001)
    }

    func testConfidenceAtThreshold() {
        let existing = GroceryMergeInput(numericValue: 1, standardUnit: "tsp", isParseable: true, parseConfidence: 0.70)
        let incoming = GroceryMergeInput(numericValue: 1, standardUnit: "tsp", isParseable: true, parseConfidence: 0.70)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.parseConfidence, 0.70, accuracy: 0.001)
    }

    // MARK: - Parseable / Unparseable Collisions

    func testParseableIntoUnparseable() {
        let existing = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 0, standardUnit: nil, isParseable: false, parseConfidence: 0.30)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 8, accuracy: 0.01, "Existing quantity should be unchanged")
        XCTAssertEqual(result.parseConfidence, 0.30, accuracy: 0.001, "Confidence should be min")
        XCTAssertFalse(result.didMergeQuantity)
    }

    func testUnparseableIntoUnparseable() {
        let existing = GroceryMergeInput(numericValue: 0, standardUnit: nil, isParseable: false, parseConfidence: 0.30)
        let incoming = GroceryMergeInput(numericValue: 0, standardUnit: nil, isParseable: false, parseConfidence: 0.0)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 0, accuracy: 0.01)
        XCTAssertEqual(result.parseConfidence, 0.0, accuracy: 0.001)
        XCTAssertFalse(result.didMergeQuantity)
    }

    func testZeroIntoPositive() {
        let existing = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let incoming = GroceryMergeInput(numericValue: 0, standardUnit: nil, isParseable: true, parseConfidence: 0.70)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 8, accuracy: 0.01, "Existing quantity should be unchanged")
        XCTAssertFalse(result.didMergeQuantity)
    }

    func testPositiveIntoZero() {
        let existing = GroceryMergeInput(numericValue: 0, standardUnit: nil, isParseable: true, parseConfidence: 0.70)
        let incoming = GroceryMergeInput(numericValue: 8, standardUnit: "oz", isParseable: true, parseConfidence: 0.95)
        let result = service.merge(existing: existing, incoming: incoming)

        XCTAssertEqual(result.numericValue, 8, accuracy: 0.01, "Should adopt incoming value")
        XCTAssertEqual(result.standardUnit, "oz")
        XCTAssertTrue(result.didMergeQuantity)
    }

    // MARK: - Display Text Formatting

    func testFormatWholeNumber() {
        let text = service.formatDisplayText(value: 20.0, unit: "oz")
        XCTAssertEqual(text, "20 oz")
    }

    func testFormatFractional() {
        let text = service.formatDisplayText(value: 1.5, unit: "cup")
        XCTAssertEqual(text, "1.5 cup")
    }

    func testFormatSmallFraction() {
        let text = service.formatDisplayText(value: 0.25, unit: "tsp")
        XCTAssertEqual(text, "0.25 tsp")
    }

    func testFormatNoUnit() {
        let text = service.formatDisplayText(value: 3.0, unit: nil)
        XCTAssertEqual(text, "3")
    }

    func testFormatZero() {
        let text = service.formatDisplayText(value: 0.0, unit: "oz")
        XCTAssertEqual(text, "0 oz")
    }
}
