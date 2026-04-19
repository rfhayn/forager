//
//  IngredientTemplateNormalizationTests.swift
//  foragerTests
//
//  M8.3.1: Compound Plural Normalization Tests
//  Tests that the normalize(name:) pipeline correctly preserves plural forms
//  for compound ingredient names like "black beans", "red pepper flakes".
//

import XCTest
import CoreData
@testable import forager

final class IngredientTemplateNormalizationTests: XCTestCase {

    private var service: IngredientTemplateService!
    private var container: NSPersistentContainer!

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
        service = IngredientTemplateService(context: container.viewContext)
    }

    override func tearDown() {
        service = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Compound Plurals (Should Stay Plural)

    func testBlackBeansStaysPlural() {
        let result = service.normalize(name: "Black Beans")
        XCTAssertEqual(result, "black beans", "Compound 'black beans' should stay plural")
    }

    func testRedPepperFlakesStaysPlural() {
        let result = service.normalize(name: "Red Pepper Flakes")
        XCTAssertEqual(result, "red pepper flakes", "Compound 'red pepper flakes' should stay plural")
    }

    func testTortillaStripsStaysPlural() {
        let result = service.normalize(name: "Tortilla Strips")
        XCTAssertEqual(result, "tortilla strips", "Compound 'tortilla strips' should stay plural")
    }

    func testChocolateChipsStaysPlural() {
        let result = service.normalize(name: "Chocolate Chips")
        XCTAssertEqual(result, "chocolate chips", "Compound 'chocolate chips' should stay plural")
    }

    func testSunflowerSeedsStaysPlural() {
        let result = service.normalize(name: "Sunflower Seeds")
        XCTAssertEqual(result, "sunflower seeds", "Compound 'sunflower seeds' should stay plural")
    }

    func testBreadCrumbsStaysPlural() {
        let result = service.normalize(name: "Bread Crumbs")
        XCTAssertEqual(result, "bread crumbs", "Compound 'bread crumbs' should stay plural")
    }

    func testEggNoodlesStaysPlural() {
        let result = service.normalize(name: "Egg Noodles")
        XCTAssertEqual(result, "egg noodles", "Compound 'egg noodles' should stay plural")
    }

    // MARK: - Single-Word Plurals in Always-Plural List

    func testBeansStaysPlural() {
        let result = service.normalize(name: "Beans")
        XCTAssertEqual(result, "beans", "Single-word 'beans' should stay plural")
    }

    func testOatsStaysPlural() {
        let result = service.normalize(name: "Oats")
        XCTAssertEqual(result, "oats", "Single-word 'oats' should stay plural")
    }

    func testLentilsStaysPlural() {
        let result = service.normalize(name: "Lentils")
        XCTAssertEqual(result, "lentils", "Single-word 'lentils' should stay plural")
    }

    // MARK: - Regular Plurals (Should Singularize)

    func testEggsSingularizes() {
        let result = service.normalize(name: "Eggs")
        XCTAssertEqual(result, "egg", "'Eggs' should singularize — qty handles plurality")
    }

    func testTomatoesSingularizes() {
        let result = service.normalize(name: "Tomatoes")
        XCTAssertEqual(result, "tomato", "'Tomatoes' should singularize — qty handles plurality")
    }

    func testBerriesSingularizes() {
        let result = service.normalize(name: "Berries")
        XCTAssertEqual(result, "berry", "'Berries' should normalize to 'berry'")
    }

    // MARK: - Qualifier Stripping + Plural Preservation

    func testFrozenPeasStaysPlural() {
        let result = service.normalize(name: "Frozen Peas")
        XCTAssertEqual(result, "frozen peas", "'Frozen Peas' preserves identity qualifier — different aisle from fresh peas")
    }

    func testDicedTomatoesSingularizes() {
        let result = service.normalize(name: "Diced Tomatoes")
        // normalize order: case → plural → abbreviation → variation
        // "Diced Tomatoes" → "diced tomatoes" (case) → singularize → "diced tomato"
        // → variation removal strips "diced " → "tomato"
        let expected = "tomato"
        XCTAssertEqual(result, expected, "'Diced Tomatoes' should normalize to 'tomato' (singular, qualifier stripped)")
    }

    // MARK: - Case Normalization

    func testUppercaseNormalizes() {
        let result = service.normalize(name: "BUTTER")
        XCTAssertEqual(result, "butter", "Uppercase should normalize to lowercase")
    }

    func testMixedCaseNormalizes() {
        let result = service.normalize(name: "Sour Cream")
        XCTAssertEqual(result, "sour cream", "Mixed case should normalize to lowercase")
    }

    // MARK: - Variation Stripping

    func testLargeEggsSingularizes() {
        let result = service.normalize(name: "Large Eggs")
        // `large` is a size descriptor (like small/medium/large eggs — same product,
        // different grade) so the normalizer strips it along with the plural. Contrast
        // with `baby` in `testBabyCarrotsSingularizes` / `testBabySpinachPreserved`
        // where baby is an identity qualifier (distinct product). (fix-test-harness-
        // and-stale-assertions, 2026-04-19)
        XCTAssertEqual(result, "egg", "'Large Eggs' → 'egg' — 'large' is a size descriptor, stripped; plural singularized")
    }

    func testFreshBasilPreservesIdentity() {
        let result = service.normalize(name: "Fresh Basil")
        XCTAssertEqual(result, "fresh basil", "'Fresh Basil' preserves identity qualifier — different product from dried basil")
    }

    // MARK: - Baby Variant Preservation (distinct products, not size descriptors)

    func testBabyCarrotsSingularizes() {
        let result = service.normalize(name: "Baby Carrots")
        XCTAssertEqual(result, "baby carrot", "'Baby Carrots' singularizes — 'baby' preserved as identity qualifier")
    }

    func testBabySpinachPreserved() {
        let result = service.normalize(name: "Baby Spinach")
        XCTAssertEqual(result, "baby spinach", "'Baby Spinach' is a distinct product — should NOT strip 'baby'")
    }

    func testBabyCornPreserved() {
        let result = service.normalize(name: "Baby Corn")
        XCTAssertEqual(result, "baby corn", "'Baby Corn' is a distinct product — should NOT strip 'baby'")
    }

    func testBabyBellasSingularizes() {
        let result = service.normalize(name: "Baby Bellas")
        XCTAssertEqual(result, "baby bella", "'Baby Bellas' singularizes — 'baby' preserved as identity qualifier")
    }
}
