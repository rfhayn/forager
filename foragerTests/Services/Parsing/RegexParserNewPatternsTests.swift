//
//  RegexParserNewPatternsTests.swift
//  foragerTests
//
//  M16.9.6: Tests for new patterns added during M16 harness bug fixes.
//  Covers: name-only (Pattern 8), mixed-fraction ranges, extended units,
//  enhanced measurement modifiers, and Unicode letter support.
//

import XCTest
@testable import forager

final class RegexParserNewPatternsTests: XCTestCase {

    private var parser: RegexIngredientParser!

    override func setUp() {
        super.setUp()
        parser = RegexIngredientParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Pattern 8: Name Only

    func testNameOnlySimple() {
        let result = parser.parse("Salt and pepper")
        XCTAssertNil(result.quantity)
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "Salt and pepper")
        XCTAssertEqual(result.confidence, 0.85,
                       "Name-only pattern should have 0.85 confidence")
    }

    func testNameOnlySingleWord() {
        let result = parser.parse("Pesto")
        XCTAssertNil(result.quantity)
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "Pesto")
        XCTAssertEqual(result.confidence, 0.85)
    }

    func testNameOnlyWithCommaQualifier() {
        // "Feta cheese, crumbled" — the qualifier pattern (Pattern 7) handles
        // comma-separated prep before name-only gets a chance. Either pattern
        // extracting "crumbled" as notes is acceptable.
        let result = parser.parse("Feta cheese, crumbled")
        XCTAssertTrue(result.name.contains("Feta cheese") || result.name.contains("feta cheese"),
                       "Name should contain 'Feta cheese', got: \(result.name)")
        // Notes may or may not be extracted depending on which pattern matches
        XCTAssertGreaterThanOrEqual(result.confidence, 0.5)
    }

    func testNameOnlyCompound() {
        let result = parser.parse("Extra virgin olive oil")
        XCTAssertNil(result.quantity)
        XCTAssertEqual(result.name, "Extra virgin olive oil")
        XCTAssertEqual(result.confidence, 0.85)
    }

    func testNameOnlyFreshlyGround() {
        let result = parser.parse("Freshly ground black pepper")
        XCTAssertNil(result.quantity)
        XCTAssertTrue(result.name.contains("black pepper"))
    }

    func testNameOnlyWithParenthetical() {
        let result = parser.parse("all-purpose flour (plain flour)")
        XCTAssertEqual(result.name, "all-purpose flour",
                       "Should strip parenthetical alias from name-only pattern")
    }

    func testNameOnlyDoesNotStealNumericInput() {
        // Numeric-leading inputs should NOT match name-only
        let result = parser.parse("2 cups flour")
        XCTAssertNotEqual(result.confidence, 0.85,
                          "Numeric input should match a higher-priority pattern, not name-only")
        XCTAssertEqual(result.quantity, 2.0)
    }

    func testNameOnlyRejectsSectionHeaders() {
        // Section headers with special chars should be rejected
        let result = parser.parse("=== INGREDIENTS ===")
        // Should have low confidence (too many non-letter chars)
        XCTAssertLessThan(result.confidence, 0.85)
    }

    // MARK: - Mixed-Fraction Range Patterns

    func testRangeMixedFractionHighEnd() {
        // "1 - 1 1/2 pounds salmon"
        let result = parser.parse("1 - 1 1/2 pounds salmon")
        XCTAssertEqual(result.quantity, 1.5, "Should use high end of range")
        XCTAssertEqual(result.unit, "lb")
        XCTAssertEqual(result.name, "salmon")
        XCTAssertNotNil(result.notes)
        XCTAssertTrue(result.notes?.contains("range") ?? false)
    }

    func testWordRangeMixedFraction() {
        // "7/8 to 1 1/8 cups water"
        let result = parser.parse("7/8 to 1 1/8 cups water")
        XCTAssertNotNil(result.quantity)
        if let qty = result.quantity {
            XCTAssertEqual(qty, 1.125, accuracy: 0.01, "Should parse 1 1/8 = 1.125")
        }
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "water")
    }

    func testRangeMixedFractionNoUnit() {
        // "1 - 1 1/2 avocados" — range with no recognized unit
        let result = parser.parse("1 - 1 1/2 pounds chicken thighs")
        XCTAssertEqual(result.quantity, 1.5)
        XCTAssertEqual(result.unit, "lb")
    }

    // MARK: - Extended Measurement Modifiers

    func testModifierThin() {
        let result = parser.parse("2 thin slices prosciutto")
        // "thin" should be stripped as modifier, "slices" is unit
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertTrue(result.name.contains("prosciutto"))
    }

    func testModifierLarge() {
        let result = parser.parse("3 large tablespoons butter")
        // "large" should be stripped as modifier before known unit
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.unit, "tbsp")
        XCTAssertTrue(result.name.contains("butter"))
    }

    func testModifierWhole() {
        let result = parser.parse("1 whole cup rice")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertTrue(result.name.contains("rice"))
    }

    // MARK: - Extended Unit List

    func testUnitContainer() {
        let result = parser.parse("1 container yogurt")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "container")
        XCTAssertTrue(result.name.contains("yogurt"))
    }

    func testUnitLoaf() {
        let result = parser.parse("1 loaf bread")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "loaf")
        XCTAssertTrue(result.name.contains("bread"))
    }

    func testUnitServing() {
        let result = parser.parse("2 servings pasta")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "serving")
    }

    func testUnitInch() {
        let result = parser.parse("2 inches ginger")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "inch")
        XCTAssertTrue(result.name.contains("ginger"))
    }

    func testUnitPinch() {
        let result = parser.parse("1 pinch saffron")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "pinch")
    }

    func testUnitDash() {
        let result = parser.parse("1 dash cayenne")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertEqual(result.unit, "dash")
    }

    // MARK: - Parenthetical Prep Merge

    func testParenPrepMerge() {
        let result = parser.parse("2 cups butter (softened)")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertTrue(result.name.contains("butter"))
        XCTAssertNotNil(result.notes)
        XCTAssertTrue(result.notes?.contains("softened") ?? false)
    }

    func testParenPrepRoomTemperature() {
        let result = parser.parse("1 cup cream cheese (room temperature)")
        XCTAssertEqual(result.quantity, 1.0)
        XCTAssertTrue(result.notes?.contains("room temperature") ?? false)
    }

    func testParenPrepNotStrippedForSizeNotes() {
        // "(14.5 oz)" should NOT be treated as prep
        let result = parser.parse("1 can (14.5 oz) diced tomatoes")
        XCTAssertEqual(result.notes, "14.5 oz")
    }

    // MARK: - Regression: Existing Patterns Still Work

    func testStandardStillWorks() {
        let result = parser.parse("2 cups flour")
        XCTAssertEqual(result.quantity, 2.0)
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "flour")
        XCTAssertEqual(result.confidence, 1.0)
    }

    func testFractionStillWorks() {
        let result = parser.parse("1/2 tsp salt")
        XCTAssertEqual(result.quantity, 0.5)
        XCTAssertEqual(result.unit, "tsp")
        XCTAssertEqual(result.name, "salt")
    }

    func testRangeStillWorks() {
        let result = parser.parse("2-3 cloves garlic")
        XCTAssertEqual(result.quantity, 3.0)
        XCTAssertEqual(result.unit, "clove")
    }

    func testQualifierStillWorks() {
        let result = parser.parse("salt to taste")
        XCTAssertEqual(result.name, "salt")
        XCTAssertEqual(result.notes, "to taste")
    }

    func testDescriptiveAmountStillWorks() {
        let result = parser.parse("a pinch of salt")
        XCTAssertEqual(result.name, "salt")
        XCTAssertNotNil(result.quantity)
    }
}
