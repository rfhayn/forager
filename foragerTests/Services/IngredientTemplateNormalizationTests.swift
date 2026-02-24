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

    func testEggsPreferPlural() {
        let result = service.normalize(name: "Eggs")
        XCTAssertEqual(result, "eggs", "'Eggs' should stay plural via preferPlural for natural grocery naming")
    }

    func testTomatoesPreferPlural() {
        let result = service.normalize(name: "Tomatoes")
        XCTAssertEqual(result, "tomatoes", "'Tomatoes' should stay plural via preferPlural for natural grocery naming")
    }

    func testBerriesSingularizes() {
        let result = service.normalize(name: "Berries")
        XCTAssertEqual(result, "berry", "'Berries' should normalize to 'berry'")
    }

    // MARK: - Qualifier Stripping + Plural Preservation

    func testFrozenPeasStaysPlural() {
        let result = service.normalize(name: "Frozen Peas")
        XCTAssertEqual(result, "peas", "'Frozen Peas' should strip qualifier and keep plural")
    }

    func testDicedTomatoesPreferPlural() {
        let result = service.normalize(name: "Diced Tomatoes")
        // normalize order: case → plural → abbreviation → variation
        // "Diced Tomatoes" → "diced tomatoes" (case) → preferPlural keeps "tomatoes"
        // → variation removal strips "diced " → "tomatoes"
        let expected = "tomatoes"
        XCTAssertEqual(result, expected, "'Diced Tomatoes' should normalize to 'tomatoes' via preferPlural")
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

    func testLargeEggsStripsQualifier() {
        let result = service.normalize(name: "Large Eggs")
        XCTAssertEqual(result, "eggs", "'Large Eggs' should strip 'large' and keep plural via preferPlural")
    }

    func testFreshBasilStripsQualifier() {
        let result = service.normalize(name: "Fresh Basil")
        XCTAssertEqual(result, "basil", "'Fresh Basil' should strip 'fresh'")
    }

    // MARK: - Baby Variant Preservation (distinct products, not size descriptors)

    func testBabyCarrotsPreserved() {
        let result = service.normalize(name: "Baby Carrots")
        XCTAssertEqual(result, "baby carrots", "'Baby Carrots' is a distinct product — should NOT strip 'baby'")
    }

    func testBabySpinachPreserved() {
        let result = service.normalize(name: "Baby Spinach")
        XCTAssertEqual(result, "baby spinach", "'Baby Spinach' is a distinct product — should NOT strip 'baby'")
    }

    func testBabyCornPreserved() {
        let result = service.normalize(name: "Baby Corn")
        XCTAssertEqual(result, "baby corn", "'Baby Corn' is a distinct product — should NOT strip 'baby'")
    }

    func testBabyBellasPreserved() {
        let result = service.normalize(name: "Baby Bellas")
        XCTAssertEqual(result, "baby bellas", "'Baby Bellas' is a distinct product — should NOT strip 'baby'")
    }
}
