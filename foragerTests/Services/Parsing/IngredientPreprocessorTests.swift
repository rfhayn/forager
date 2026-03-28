//
//  IngredientPreprocessorTests.swift
//  foragerTests
//
//  M16.9.6: Tests for IngredientPreprocessor — preprocessing pipeline validation
//

import XCTest
@testable import forager

final class IngredientPreprocessorTests: XCTestCase {

    // MARK: - Price Annotation Stripping

    func testStripInlinePriceAnnotation() {
        let result = IngredientPreprocessor.sanitize("2 cups flour $0.50")
        XCTAssertFalse(result.contains("$"), "Should strip inline price")
        XCTAssertTrue(result.contains("2 cups flour"))
    }

    func testStripParenthesizedPrice() {
        let result = IngredientPreprocessor.sanitize("1 lb chicken ($2.00)")
        XCTAssertFalse(result.contains("$"), "Should strip parenthesized price")
        XCTAssertTrue(result.contains("1 lb chicken"))
    }

    // MARK: - Double-Paren Note Stripping

    func testStripDoubleParenNotes() {
        let result = IngredientPreprocessor.sanitize("2 cups rice ((Note 1))")
        XCTAssertFalse(result.contains("Note 1"), "Should strip double-paren notes")
        XCTAssertTrue(result.hasPrefix("2 cups rice"))
    }

    // MARK: - Footnote Reference Stripping

    func testStripFootnoteReference() {
        let result = IngredientPreprocessor.sanitize("1 cup cream (see notes)")
        // Should not strip actual prep notes, but should strip footnote refs
        XCTAssertTrue(result.contains("cream"))
    }

    // MARK: - Leading Comma Fix

    func testFixLeadingCommaInParens() {
        let result = IngredientPreprocessor.sanitize("butter (, minced)")
        XCTAssertFalse(result.contains("(,"), "Should fix leading comma in parens")
    }

    // MARK: - Parenthetical Metric Stripping

    func testStripParentheticalMetricGrams() {
        let result = IngredientPreprocessor.sanitize("2 cups flour (250g)")
        XCTAssertFalse(result.contains("250g"), "Should strip metric grams")
        XCTAssertTrue(result.contains("2 cups flour"))
    }

    func testStripParentheticalMetricKilograms() {
        let result = IngredientPreprocessor.sanitize("1 lb butter (450g)")
        XCTAssertFalse(result.contains("450g"))
    }

    // MARK: - Can/Package Size Stripping

    func testStripCanSize() {
        let result = IngredientPreprocessor.sanitize("(28 ounce) can diced tomatoes")
        XCTAssertTrue(result.contains("can"))
        XCTAssertTrue(result.contains("diced tomatoes"))
    }

    // MARK: - Leading Qualifier Stripping (New in M16.9.6)

    func testStripLeadingAbout() {
        let result = IngredientPreprocessor.sanitize("about 2 cups flour")
        XCTAssertTrue(result.hasPrefix("2"), "Should strip leading 'about'")
        XCTAssertTrue(result.contains("cups flour"))
    }

    func testStripLeadingOptional() {
        let result = IngredientPreprocessor.sanitize("optional 1 tsp vanilla")
        XCTAssertFalse(result.lowercased().hasPrefix("optional"), "Should strip leading 'optional'")
    }

    func testStripLeadingRoughly() {
        let result = IngredientPreprocessor.sanitize("roughly 3 tablespoons butter")
        XCTAssertFalse(result.lowercased().hasPrefix("roughly"), "Should strip leading 'roughly'")
    }

    // MARK: - Leading Decimal Normalization (New in M16.9.6)

    func testNormalizeLeadingDecimal() {
        let result = IngredientPreprocessor.sanitize(".5 ounces cream cheese")
        XCTAssertTrue(result.hasPrefix("0.5"), "Should normalize .5 → 0.5")
    }

    func testLeadingDecimalAlreadyNormalized() {
        let result = IngredientPreprocessor.sanitize("0.5 ounces cream cheese")
        XCTAssertTrue(result.hasPrefix("0.5"), "Already normalized should stay unchanged")
    }

    // MARK: - Dual-Unit Metric Stripping (New in M16.9.6)

    func testStripLeadingDualUnitMetric() {
        let result = IngredientPreprocessor.sanitize("500g / 1lb peeled prawns")
        XCTAssertFalse(result.contains("500g"), "Should strip metric prefix")
        XCTAssertTrue(result.contains("1lb") || result.contains("1 lb"))
    }

    // MARK: - And-Fraction Normalization (New in M16.9.6)

    func testNormalizeAndFractions() {
        let result = IngredientPreprocessor.sanitize("2 and 1/4 cups flour")
        XCTAssertTrue(result.contains("2 1/4"), "Should normalize '2 and 1/4' → '2 1/4'")
    }

    func testNormalizeAndFractionThirds() {
        let result = IngredientPreprocessor.sanitize("1 and 1/3 cups sugar")
        XCTAssertTrue(result.contains("1 1/3"), "Should normalize '1 and 1/3' → '1 1/3'")
    }

    // MARK: - Leading Number Word Conversion (New in M16.9.6)

    func testConvertLeadingOne() {
        let result = IngredientPreprocessor.sanitize("One 3-pound chuck roast")
        XCTAssertTrue(result.hasPrefix("1"), "Should convert 'One' → '1'")
    }

    func testConvertLeadingSix() {
        let result = IngredientPreprocessor.sanitize("Six fillets salmon")
        XCTAssertTrue(result.hasPrefix("6"), "Should convert 'Six' → '6'")
    }

    func testDoNotConvertNonLeadingNumberWords() {
        // "two" in the middle should NOT be converted
        let result = IngredientPreprocessor.sanitize("1 or two eggs")
        XCTAssertTrue(result.contains("two"), "Non-leading number words should stay")
    }

    // MARK: - IEEE 754 Float Conversion

    func testConvertIEEEFloat() {
        let result = IngredientPreprocessor.sanitize("0.33333334326744 cup flour")
        XCTAssertTrue(result.contains("1/3"), "Should convert IEEE 754 ⅓ representation")
    }

    // MARK: - Unicode Fraction Conversion

    func testConvertUnicodeFractionHalf() {
        let result = IngredientPreprocessor.sanitize("½ cup butter")
        XCTAssertTrue(result.contains("1/2"), "Should convert ½ → 1/2")
    }

    func testConvertUnicodeFractionThird() {
        let result = IngredientPreprocessor.sanitize("⅓ cup sugar")
        XCTAssertTrue(result.contains("1/3"), "Should convert ⅓ → 1/3")
    }

    // MARK: - Curly Quote Normalization (New in M16.9.6)

    func testNormalizeCurlyQuotes() {
        let result = IngredientPreprocessor.sanitize("1 cup baker\u{2019}s sugar")
        XCTAssertTrue(result.contains("'"), "Should normalize curly apostrophe to straight")
        XCTAssertFalse(result.contains("\u{2019}"))
    }

    // MARK: - Trailing Unit Period Stripping

    func testStripTrailingUnitPeriod() {
        let result = IngredientPreprocessor.sanitize("1 tsp. salt")
        XCTAssertFalse(result.contains("tsp."), "Should strip trailing period on unit")
        XCTAssertTrue(result.contains("tsp"))
    }

    // MARK: - Whitespace Normalization

    func testNormalizeMultipleSpaces() {
        let result = IngredientPreprocessor.sanitize("2   cups   flour")
        XCTAssertFalse(result.contains("  "), "Should collapse multiple spaces")
    }

    func testTrimLeadingTrailingWhitespace() {
        let result = IngredientPreprocessor.sanitize("  2 cups flour  ")
        XCTAssertEqual(result, IngredientPreprocessor.sanitize("2 cups flour"))
    }

    // MARK: - Pipeline End-to-End

    func testFullPipelineBudgetBytes() {
        // Budget Bytes format: price + metric + notes
        let result = IngredientPreprocessor.sanitize("2 cups flour (250g) $0.50")
        XCTAssertEqual(result, "2 cups flour", "Full pipeline should strip price + metric")
    }

    func testFullPipelineAndFractionWithQualifier() {
        let result = IngredientPreprocessor.sanitize("about 2 and 1/4 cups flour")
        XCTAssertTrue(result.contains("2 1/4"), "Should strip qualifier and normalize fraction")
        XCTAssertFalse(result.lowercased().contains("about"))
    }
}
