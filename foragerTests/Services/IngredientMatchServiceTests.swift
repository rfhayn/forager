import XCTest
import CoreData
@testable import forager

/// M10.6.8: IngredientMatchService unit tests
/// Validates shared ingredient matching logic: parse → template lookup → status determination.
final class IngredientMatchServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var templateService: IngredientTemplateService!
    private var parsingService: IngredientParsingService!
    private var matchService: IngredientMatchService!

    @MainActor
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        templateService = IngredientTemplateService(context: context)
        parsingService = IngredientParsingService(context: context, templateService: templateService)
        matchService = IngredientMatchService(parsingService: parsingService, templateService: templateService)
    }

    override func tearDown() {
        matchService = nil
        parsingService = nil
        templateService = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helper

    @MainActor
    private func createCategory(named name: String) -> forager.Category {
        let cat = forager.Category(context: context)
        cat.id = UUID()
        cat.name = name
        cat.sortOrder = 0
        return cat
    }

    // MARK: - Single Match

    @MainActor
    func testMatchIngredientFindsTemplate() {
        // Create a template with a category
        let template = templateService.findOrCreateTemplate(name: "flour")
        let bakingCategory = createCategory(named: "Baking")
        templateService.updateCategory(template, category: bakingCategory)

        let result = matchService.matchIngredient(text: "2 cups flour")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.parsedName, "flour")
        XCTAssertEqual(result?.status, .ready)
        XCTAssertEqual(result?.categoryName, "Baking")
        XCTAssertEqual(result?.templateName, "flour")
        XCTAssertFalse(result?.wasAIParsed ?? true)
    }

    @MainActor
    func testMatchIngredientNeedsCategory() {
        // Create a template without a category
        _ = templateService.findOrCreateTemplate(name: "chicken")

        let result = matchService.matchIngredient(text: "1 lb chicken")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.parsedName, "chicken")
        XCTAssertEqual(result?.status, .needsCategory)
        XCTAssertNil(result?.categoryName)
        XCTAssertEqual(result?.templateName, "chicken")
    }

    @MainActor
    func testMatchIngredientNeedsTemplate() {
        // No template exists for this ingredient
        let result = matchService.matchIngredient(text: "2 cups quinoa")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.status, .needsTemplate)
        XCTAssertNil(result?.categoryName)
        XCTAssertNil(result?.templateName)
    }

    @MainActor
    func testMatchIngredientReturnsNilForShortText() {
        let result = matchService.matchIngredient(text: "a")
        XCTAssertNil(result, "Text shorter than 2 characters should return nil")
    }

    @MainActor
    func testMatchIngredientReturnsNilForEmptyText() {
        let result = matchService.matchIngredient(text: "  ")
        XCTAssertNil(result, "Whitespace-only text should return nil")
    }

    // MARK: - Batch Match

    @MainActor
    func testMatchBatchReturnsCorrectCount() {
        let texts = ["2 cups flour", "1 lb chicken", "salt"]
        let results = matchService.matchBatch(texts: texts)
        XCTAssertEqual(results.count, 3)
    }

    @MainActor
    func testMatchBatchPreservesOrder() {
        let template = templateService.findOrCreateTemplate(name: "flour")
        let bakingCategory = createCategory(named: "Baking")
        templateService.updateCategory(template, category: bakingCategory)

        let texts = ["2 cups flour", "unknown ingredient xyz"]
        let results = matchService.matchBatch(texts: texts)

        XCTAssertEqual(results[0]?.status, .ready, "First result should match the flour template")
        XCTAssertEqual(results[1]?.status, .needsTemplate, "Second result should need a template")
    }

    // MARK: - Match Summary

    @MainActor
    func testMatchSummaryCounts() {
        let template = templateService.findOrCreateTemplate(name: "flour")
        let bakingCategory = createCategory(named: "Baking")
        templateService.updateCategory(template, category: bakingCategory)

        let results = matchService.matchBatch(texts: ["2 cups flour", "chicken", "quinoa"])
        let summary = matchService.matchSummary(from: results)

        XCTAssertEqual(summary.categorized, 1, "Only flour has a category")
        XCTAssertEqual(summary.uncategorized, 2, "Chicken and quinoa lack categories")
    }

    // MARK: - Match Result Properties

    @MainActor
    func testMatchResultPreservesRawText() {
        let rawText = "2 cups all-purpose flour, sifted"
        let result = matchService.matchIngredient(text: rawText)

        XCTAssertEqual(result?.rawText, rawText)
    }

    @MainActor
    func testMatchResultIncludesParsedQuantity() {
        let result = matchService.matchIngredient(text: "2 cups flour")

        XCTAssertNotNil(result)
        // The parser extracts quantity and unit
        XCTAssertNotNil(result?.parsedQuantity, "Should extract a quantity from '2 cups flour'")
    }

    // MARK: - withCategory Helper

    @MainActor
    func testWithCategoryReturnsUpdatedCopy() {
        let result = matchService.matchIngredient(text: "2 cups quinoa")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.status, .needsTemplate)

        let updated = result?.withCategory("Grains")
        XCTAssertEqual(updated?.status, .ready)
        XCTAssertEqual(updated?.categoryName, "Grains")
        // Original fields preserved
        XCTAssertEqual(updated?.rawText, result?.rawText)
        XCTAssertEqual(updated?.parsedName, result?.parsedName)
    }

    // MARK: - Uncategorized Template

    @MainActor
    func testUncategorizedTemplateIsReady() {
        let template = templateService.findOrCreateTemplate(name: "butter")
        let uncategorized = createCategory(named: "Uncategorized")
        templateService.updateCategory(template, category: uncategorized)

        let result = matchService.matchIngredient(text: "1 tbsp butter")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.status, .ready, "Templates with 'Uncategorized' category should be ready — user explicitly chose it")
        XCTAssertEqual(result?.categoryName, "Uncategorized")
    }

    @MainActor
    func testNewTemplateDefaultsToUncategorizedWhenEntityExists() {
        // Seed the Uncategorized category (simulates DefaultSeeder startup)
        let uncategorized = createCategory(named: "Uncategorized")
        uncategorized.normalizedName = "uncategorized"
        try? context.save()

        // Create a template with no explicit category — should auto-assign Uncategorized
        let template = templateService.findOrCreateTemplate(name: "paprika")

        XCTAssertNotNil(template.categoryEntity, "Template should auto-default to Uncategorized")
        XCTAssertEqual(template.categoryEntity?.name, "Uncategorized")

        let result = matchService.matchIngredient(text: "1 tsp paprika")
        XCTAssertEqual(result?.status, .ready, "Auto-categorized template should be ready")
        XCTAssertEqual(result?.categoryName, "Uncategorized")
    }

    // MARK: - Match Summary Edge Cases

    @MainActor
    func testMatchSummaryExcludesNilResults() {
        // Mix of valid and nil results (nil from short/empty text)
        let results: [IngredientMatchResult?] = [
            matchService.matchIngredient(text: "2 cups flour"),
            nil, // simulates empty/too-short text
            matchService.matchIngredient(text: "chicken"),
            nil
        ]
        let summary = matchService.matchSummary(from: results)

        // Should only count the 2 non-nil results, not include nils as uncategorized
        XCTAssertEqual(summary.categorized + summary.uncategorized, 2,
                       "Summary should exclude nil results from both counts")
    }

    // MARK: - withCategory from needsCategory State

    @MainActor
    func testWithCategoryFromNeedsCategoryState() {
        // Template exists but has no category — use "2 cups flour" so parsed name
        // is "flour" which matches the template exactly
        _ = templateService.findOrCreateTemplate(name: "flour")

        let result = matchService.matchIngredient(text: "2 cups flour")
        XCTAssertEqual(result?.status, .needsCategory,
                       "Template exists without category → needsCategory")

        let updated = result?.withCategory("Baking")
        XCTAssertEqual(updated?.status, .ready)
        XCTAssertEqual(updated?.categoryName, "Baking")
        // Template name should be preserved
        XCTAssertEqual(updated?.templateName, "flour")
    }

    // MARK: - Boundary: Minimum Valid Text

    @MainActor
    func testMatchIngredientWithTwoCharacterText() {
        // Exactly 2 characters should be processed (not rejected)
        let result = matchService.matchIngredient(text: "ox")
        XCTAssertNotNil(result, "Text with exactly 2 characters should be processed")
    }

    // MARK: - wasAIParsed Default

    @MainActor
    func testLocalMatchIsNotMarkedAsAIParsed() {
        _ = templateService.findOrCreateTemplate(name: "sugar")

        let result = matchService.matchIngredient(text: "1 cup sugar")
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.wasAIParsed, "Local matches should not be marked as AI parsed")
        XCTAssertNil(result?.aiParsedName, "Local matches should have nil aiParsedName")
    }

    // TODO (M10.7): Add AI parsing tests (aiParseSingle, aiParseBatch) when
    // IngredientParsingService supports injected LLMIngredientParser.
    // Currently uses LLMSettingsService.shared singleton, blocking mock injection.
}
