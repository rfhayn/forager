//
//  IngredientTemplateValidationTests.swift
//  foragerTests
//
//  M8.3.1: Template Quality Heuristic Tests
//  Tests for the needsReview computed property on IngredientTemplate.
//  Requires in-memory Core Data stack to instantiate managed objects.
//

import XCTest
import CoreData
@testable import forager

final class IngredientTemplateValidationTests: XCTestCase {

    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        let bundle = Bundle(for: IngredientTemplate.self)
        guard let modelURL = bundle.url(forResource: "forager", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            XCTFail("Could not load forager managed object model")
            return
        }
        container = NSPersistentContainer(name: "forager", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load in-memory store: \(error?.localizedDescription ?? "")")
        }
        context = container.viewContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    private func makeTemplate(name: String) -> IngredientTemplate {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.dateCreated = Date()
        template.usageCount = 1
        return template
    }

    // MARK: - Rule 1: Parenthetical Text

    func testDetectsParenthetical() {
        let template = makeTemplate(name: "butter (room temperature)")
        XCTAssertTrue(template.needsReview, "Parenthetical text should trigger review")
    }

    func testDetectsParentheticalWithSize() {
        let template = makeTemplate(name: "can (14.5 oz) diced tomatoes")
        XCTAssertTrue(template.needsReview, "Parenthetical size should trigger review")
    }

    // MARK: - Rule 2: Digits and Unicode Fractions

    func testDetectsDigits() {
        let template = makeTemplate(name: "2 cloves garlic")
        XCTAssertTrue(template.needsReview, "Digits should trigger review")
    }

    func testDetectsUnicodeFractionHalf() {
        let template = makeTemplate(name: "½ cup sour cream")
        XCTAssertTrue(template.needsReview, "Unicode ½ should trigger review")
    }

    func testDetectsUnicodeFractionQuarter() {
        let template = makeTemplate(name: "¼ tsp cayenne")
        XCTAssertTrue(template.needsReview, "Unicode ¼ should trigger review")
    }

    func testDetectsUnicodeFractionThird() {
        let template = makeTemplate(name: "⅓ cup sugar")
        XCTAssertTrue(template.needsReview, "Unicode ⅓ should trigger review")
    }

    // MARK: - Rule 3: Qualifier Suffixes

    func testDetectsToTaste() {
        let template = makeTemplate(name: "salt to taste")
        XCTAssertTrue(template.needsReview, "'to taste' suffix should trigger review")
    }

    func testDetectsForGarnish() {
        let template = makeTemplate(name: "herbs for garnish")
        XCTAssertTrue(template.needsReview, "'for garnish' suffix should trigger review")
    }

    func testDetectsAsNeeded() {
        let template = makeTemplate(name: "oil as needed")
        XCTAssertTrue(template.needsReview, "'as needed' suffix should trigger review")
    }

    func testDetectsForServing() {
        let template = makeTemplate(name: "parsley for serving")
        XCTAssertTrue(template.needsReview, "'for serving' suffix should trigger review")
    }

    // MARK: - Rule 4: Leading Unit/Measure Words

    func testDetectsLeadingLoaf() {
        let template = makeTemplate(name: "loaf french bread")
        XCTAssertTrue(template.needsReview, "Leading 'loaf' should trigger review")
    }

    func testDetectsLeadingCan() {
        let template = makeTemplate(name: "can tomatoes")
        XCTAssertTrue(template.needsReview, "Leading 'can' should trigger review")
    }

    func testDetectsLeadingPinch() {
        let template = makeTemplate(name: "pinch saffron")
        XCTAssertTrue(template.needsReview, "Leading 'pinch' should trigger review")
    }

    func testDetectsLeadingHandful() {
        let template = makeTemplate(name: "handful parsley")
        XCTAssertTrue(template.needsReview, "Leading 'handful' should trigger review")
    }

    // MARK: - Clean Names (Should NOT Trigger Review)

    func testCleanSimpleName() {
        let template = makeTemplate(name: "butter")
        XCTAssertFalse(template.needsReview, "Clean single-word name should not trigger review")
    }

    func testCleanCompoundName() {
        let template = makeTemplate(name: "sour cream")
        XCTAssertFalse(template.needsReview, "Clean compound name should not trigger review")
    }

    func testCleanHyphenatedName() {
        let template = makeTemplate(name: "all-purpose flour")
        XCTAssertFalse(template.needsReview, "Hyphenated name should not trigger review")
    }

    func testCleanPluralName() {
        let template = makeTemplate(name: "black beans")
        XCTAssertFalse(template.needsReview, "Plural compound name should not trigger review")
    }

    func testCleanLongName() {
        let template = makeTemplate(name: "extra virgin olive oil")
        XCTAssertFalse(template.needsReview, "Multi-word clean name should not trigger review")
    }

    func testEmptyNameDoesNotTrigger() {
        let template = makeTemplate(name: "")
        XCTAssertFalse(template.needsReview, "Empty name should not trigger review")
    }

    func testNilNameDoesNotTrigger() {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = nil
        template.dateCreated = Date()
        XCTAssertFalse(template.needsReview, "Nil name should not trigger review")
    }
}
