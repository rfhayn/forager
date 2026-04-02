import XCTest
import CoreData
@testable import forager

/// Tests for Recipe+ComputedProperties attribution and hero image computed properties.
/// Covers hasAttribution, displayAuthor, sourceURLDomain, sourceURLObject, hasHeroImage.
final class RecipeComputedPropertiesTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
    }

    @MainActor
    override func tearDown() {
        context = nil
        persistence = nil
        super.tearDown()
    }

    @MainActor
    private func makeRecipe(
        author: String? = nil,
        sourceURL: String? = nil,
        imageURL: String? = nil
    ) -> Recipe {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = "Test Recipe"
        recipe.author = author
        recipe.sourceURL = sourceURL
        recipe.imageURL = imageURL
        return recipe
    }

    // MARK: - hasAttribution

    @MainActor
    func testHasAttributionWithAuthorOnly() {
        let recipe = makeRecipe(author: "Julia Child")
        XCTAssertTrue(recipe.hasAttribution)
    }

    @MainActor
    func testHasAttributionWithSourceURLOnly() {
        let recipe = makeRecipe(sourceURL: "https://example.com/recipe")
        XCTAssertTrue(recipe.hasAttribution)
    }

    @MainActor
    func testHasAttributionWithBothNil() {
        let recipe = makeRecipe()
        XCTAssertFalse(recipe.hasAttribution)
    }

    @MainActor
    func testHasAttributionWithBothEmpty() {
        let recipe = makeRecipe(author: "", sourceURL: "")
        XCTAssertFalse(recipe.hasAttribution)
    }

    // MARK: - displayAuthor

    @MainActor
    func testDisplayAuthorValidName() {
        let recipe = makeRecipe(author: "Julia Child")
        XCTAssertEqual(recipe.displayAuthor, "Julia Child")
    }

    @MainActor
    func testDisplayAuthorTrimsWhitespace() {
        let recipe = makeRecipe(author: "  Julia Child  ")
        XCTAssertEqual(recipe.displayAuthor, "Julia Child")
    }

    @MainActor
    func testDisplayAuthorWhitespaceOnly() {
        let recipe = makeRecipe(author: "   ")
        XCTAssertNil(recipe.displayAuthor)
    }

    @MainActor
    func testDisplayAuthorNil() {
        let recipe = makeRecipe()
        XCTAssertNil(recipe.displayAuthor)
    }

    // MARK: - sourceURLDomain

    @MainActor
    func testSourceURLDomainExtractsHost() {
        let recipe = makeRecipe(sourceURL: "https://example.com/recipe/123")
        XCTAssertEqual(recipe.sourceURLDomain, "example.com")
    }

    @MainActor
    func testSourceURLDomainNilForNilURL() {
        let recipe = makeRecipe()
        XCTAssertNil(recipe.sourceURLDomain)
    }

    @MainActor
    func testSourceURLDomainNilForEmptyString() {
        let recipe = makeRecipe(sourceURL: "")
        XCTAssertNil(recipe.sourceURLDomain)
    }

    // MARK: - sourceURLObject

    @MainActor
    func testSourceURLObjectValidURL() {
        let recipe = makeRecipe(sourceURL: "https://example.com/recipe")
        XCTAssertNotNil(recipe.sourceURLObject)
        XCTAssertEqual(recipe.sourceURLObject?.absoluteString, "https://example.com/recipe")
    }

    @MainActor
    func testSourceURLObjectEmptyString() {
        let recipe = makeRecipe(sourceURL: "")
        XCTAssertNil(recipe.sourceURLObject)
    }

    @MainActor
    func testSourceURLObjectNil() {
        let recipe = makeRecipe()
        XCTAssertNil(recipe.sourceURLObject)
    }

    // MARK: - hasHeroImage

    @MainActor
    func testHasHeroImageValidURL() {
        let recipe = makeRecipe(imageURL: "https://example.com/image.jpg")
        XCTAssertTrue(recipe.hasHeroImage)
    }

    @MainActor
    func testHasHeroImageEmptyString() {
        let recipe = makeRecipe(imageURL: "")
        XCTAssertFalse(recipe.hasHeroImage)
    }

    @MainActor
    func testHasHeroImageNil() {
        let recipe = makeRecipe()
        XCTAssertFalse(recipe.hasHeroImage)
    }

    @MainActor
    func testHasHeroImageWhitespaceOnly() {
        let recipe = makeRecipe(imageURL: "   ")
        XCTAssertFalse(recipe.hasHeroImage)
    }
}
