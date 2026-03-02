import XCTest
import CoreData
@testable import forager

/// M7.5 Chunk 1.2b: IngredientTemplateService unit tests
/// Validates the new public CRUD methods and normalization chokepoint.
final class IngredientTemplateServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var service: IngredientTemplateService!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        service = IngredientTemplateService(context: context)
    }

    override func tearDown() {
        service = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Update Template

    @MainActor
    func testUpdateTemplateNormalizesName() {
        let template = service.findOrCreateTemplate(name: "basil")

        service.updateTemplate(template, name: "FLOUR", category: "Baking", isStaple: true)

        XCTAssertEqual(template.name, "flour", "Name should be normalized to lowercase")
        XCTAssertEqual(template.category, "Baking")
        XCTAssertTrue(template.isStaple)
        XCTAssertNotNil(template.canonicalName)
        XCTAssertNil(service.errorMessage)
    }

    @MainActor
    func testUpdateCategory() {
        let template = service.findOrCreateTemplate(name: "chicken")

        service.updateCategory(template, category: "Meat")
        XCTAssertEqual(template.category, "Meat")

        service.updateCategory(template, category: nil)
        XCTAssertNil(template.category)
    }

    @MainActor
    func testUpdateStaple() {
        let template = service.findOrCreateTemplate(name: "salt")

        service.updateStaple(template, isStaple: true)
        XCTAssertTrue(template.isStaple)

        service.updateStaple(template, isStaple: false)
        XCTAssertFalse(template.isStaple)
    }

    // MARK: - Delete Template

    @MainActor
    func testDeleteTemplate() throws {
        let template = service.findOrCreateTemplate(name: "oregano")
        let templateID = template.objectID

        service.deleteTemplate(template)

        let deleted = try? context.existingObject(with: templateID)
        XCTAssertTrue(deleted == nil || deleted!.isDeleted)
    }

    // MARK: - Normalization Chokepoint

    @MainActor
    func testNormalizationChokepoint() {
        // updateTemplate routes through normalize() — "FLOUR" becomes "flour"
        let template = service.findOrCreateTemplate(name: "test ingredient")

        service.updateTemplate(template, name: "Diced Tomatoes", category: nil, isStaple: false)

        // normalize() strips qualifiers and singularizes: "Diced Tomatoes" → "tomato"
        XCTAssertEqual(template.name, "tomato",
                       "Name should go through full normalization pipeline (case + singular + qualifier removal)")
    }

    // MARK: - Idempotency

    @MainActor
    func testFindOrCreateIdempotency() {
        let first = service.findOrCreateTemplate(name: "Basil")
        let second = service.findOrCreateTemplate(name: "basil")

        XCTAssertEqual(first.objectID, second.objectID,
                       "findOrCreateTemplate should return the same template for normalized-equivalent names")
    }

    // MARK: - Identity Qualifier Preservation

    @MainActor
    func testGroundBeefPreserved() {
        let normalized = service.normalize(name: "ground beef")
        XCTAssertEqual(normalized, "ground beef",
                       "\"ground\" is an identity qualifier — ground beef is a distinct product from beef")
    }

    @MainActor
    func testGroundTurkeyPreserved() {
        let normalized = service.normalize(name: "ground turkey")
        XCTAssertEqual(normalized, "ground turkey")
    }

    @MainActor
    func testGroundCinnamonPreserved() {
        let normalized = service.normalize(name: "ground cinnamon")
        XCTAssertEqual(normalized, "ground cinnamon")
    }

    @MainActor
    func testDarkChocolatePreserved() {
        let normalized = service.normalize(name: "dark chocolate")
        XCTAssertEqual(normalized, "dark chocolate")
    }

    @MainActor
    func testWholeWheatFlourPreserved() {
        let normalized = service.normalize(name: "whole wheat flour")
        XCTAssertEqual(normalized, "whole wheat flour")
    }

    @MainActor
    func testUnsaltedButterPreserved() {
        let normalized = service.normalize(name: "unsalted butter")
        XCTAssertEqual(normalized, "unsalted butter")
    }

    @MainActor
    func testHeavyCreamPreserved() {
        let normalized = service.normalize(name: "heavy cream")
        XCTAssertEqual(normalized, "heavy cream")
    }

    @MainActor
    func testFrozenPeasPreserved() {
        let normalized = service.normalize(name: "frozen peas")
        XCTAssertEqual(normalized, "frozen peas")
    }

    @MainActor
    func testDriedCranberriesPreserved() {
        let normalized = service.normalize(name: "dried cranberries")
        XCTAssertEqual(normalized, "dried cranberries")
    }

    @MainActor
    func testFreshBasilPreserved() {
        let normalized = service.normalize(name: "fresh basil")
        XCTAssertEqual(normalized, "fresh basil")
    }

    // MARK: - Preparation Qualifiers Still Stripped

    @MainActor
    func testDicedTomatoStillStripped() {
        let normalized = service.normalize(name: "diced tomato")
        XCTAssertEqual(normalized, "tomato",
                       "\"diced\" is a preparation qualifier — should be stripped")
    }

    @MainActor
    func testChoppedOnionStillStripped() {
        let normalized = service.normalize(name: "chopped onion")
        XCTAssertEqual(normalized, "onion",
                       "\"chopped\" is a preparation qualifier — should be stripped")
    }

    @MainActor
    func testSlicedMushroomsStillStripped() {
        let normalized = service.normalize(name: "sliced mushrooms")
        XCTAssertEqual(normalized, "mushroom",
                       "\"sliced\" is a preparation qualifier — should be stripped")
    }

    @MainActor
    func testMincedGarlicStillStripped() {
        let normalized = service.normalize(name: "minced garlic")
        XCTAssertEqual(normalized, "garlic")
    }

    // MARK: - Template Dedup with Identity Qualifiers

    @MainActor
    func testGroundBeefAndBeefAreSeparateTemplates() {
        let groundBeef = service.findOrCreateTemplate(name: "ground beef")
        let beef = service.findOrCreateTemplate(name: "beef")

        XCTAssertNotEqual(groundBeef.objectID, beef.objectID,
                          "ground beef and beef should be separate templates")
    }
}
