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

        // normalize() strips qualifiers and pluralizes: "Diced Tomatoes" → "tomatoes"
        XCTAssertEqual(template.name, "tomatoes",
                       "Name should go through full normalization pipeline (case + plural + qualifier removal)")
    }

    // MARK: - Idempotency

    @MainActor
    func testFindOrCreateIdempotency() {
        let first = service.findOrCreateTemplate(name: "Basil")
        let second = service.findOrCreateTemplate(name: "basil")

        XCTAssertEqual(first.objectID, second.objectID,
                       "findOrCreateTemplate should return the same template for normalized-equivalent names")
    }
}
