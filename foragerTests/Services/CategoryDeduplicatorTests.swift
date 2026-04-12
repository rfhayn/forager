import XCTest
import CoreData
@testable import forager

/// M19: CategoryDeduplicator tests
/// Validates deduplication logic, relationship preservation, and edge cases.
final class CategoryDeduplicatorTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        #if DEBUG
        DefaultSeeder.resetSeedingStatus()
        #endif
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
    }

    override func tearDown() {
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createCategory(name: String, normalizedName: String? = nil, date: Date = Date()) -> forager.Category {
        let category = forager.Category(context: context)
        category.id = UUID()
        category.name = name
        category.normalizedName = normalizedName ?? forager.Category.normalizedName(from: name)
        category.dateCreated = date
        category.updatedAt = Date()
        category.color = "#4CAF50"
        return category
    }

    private func createTemplate(name: String, category: forager.Category) -> IngredientTemplate {
        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.canonicalName = name.lowercased()
        template.categoryEntity = category
        template.dateCreated = Date()
        return template
    }

    // MARK: - Basic Deduplication

    func testNoDuplicatesDoesNothing() throws {
        let _ = createCategory(name: "Produce")
        let _ = createCategory(name: "Dairy")
        let _ = createCategory(name: "Meat")
        try context.save()

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        let request: NSFetchRequest<forager.Category> = forager.Category.fetchRequest()
        let count = try context.count(for: request)
        XCTAssertEqual(count, 3, "No categories should be removed when there are no duplicates")
    }

    func testDuplicatesSameNameAreMerged() throws {
        let older = createCategory(name: "Produce", date: Date().addingTimeInterval(-100))
        let newer = createCategory(name: "Produce", date: Date())
        try context.save()

        // Both should exist before dedup
        let beforeCount = try context.count(for: forager.Category.fetchRequest())
        XCTAssertEqual(beforeCount, 2)

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        let afterCount = try context.count(for: forager.Category.fetchRequest())
        XCTAssertEqual(afterCount, 1, "Duplicate should be removed")

        // The older one should be kept (sorted by dateCreated ascending, first is keeper)
        let remaining = try context.fetch(forager.Category.fetchRequest())
        XCTAssertEqual(remaining.first?.dateCreated, older.dateCreated, "Older category should be the keeper")
        _ = newer // suppress unused warning
    }

    // MARK: - Relationship Behavior During Dedup

    func testTemplateOnKeeperCategorySurvives() throws {
        let older = createCategory(name: "Produce", date: Date().addingTimeInterval(-100))
        let _ = createCategory(name: "Produce", date: Date())

        // Assign template to the keeper (older) category
        let template = createTemplate(name: "Lettuce", category: older)
        try context.save()

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        // Template on the keeper should still be linked
        XCTAssertEqual(template.categoryEntity, older, "Template on keeper should survive dedup")
        XCTAssertFalse(template.isDeleted, "Template should not be deleted during dedup")
    }

    func testTemplateOnDeletedCategoryGetsNullified() throws {
        let _ = createCategory(name: "Dairy", date: Date().addingTimeInterval(-100))
        let newer = createCategory(name: "Dairy", date: Date())

        // Assign templates to the duplicate (newer) — will be deleted
        let t1 = createTemplate(name: "Milk", category: newer)
        let t2 = createTemplate(name: "Cheese", category: newer)
        try context.save()

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        // Core Data nullify rule: templates lose their category when duplicate is deleted
        XCTAssertNil(t1.categoryEntity, "Template on deleted duplicate gets nullified")
        XCTAssertNil(t2.categoryEntity, "Template on deleted duplicate gets nullified")
        XCTAssertFalse(t1.isDeleted, "Template should NOT be cascade deleted")
        XCTAssertFalse(t2.isDeleted, "Template should NOT be cascade deleted")
    }

    // MARK: - Edge Cases

    func testEmptyContextDoesNotCrash() throws {
        // No categories at all — should not crash
        try CategoryDeduplicator(context: context).removeDuplicates()
        // If we get here, it didn't crash
    }

    func testSingleCategoryDoesNotCrash() throws {
        let _ = createCategory(name: "Solo")
        try context.save()

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        let count = try context.count(for: forager.Category.fetchRequest())
        XCTAssertEqual(count, 1)
    }

    func testTripleDuplicatesReducedToOne() throws {
        let _ = createCategory(name: "Snacks", date: Date().addingTimeInterval(-200))
        let _ = createCategory(name: "Snacks", date: Date().addingTimeInterval(-100))
        let _ = createCategory(name: "Snacks", date: Date())
        try context.save()

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        let count = try context.count(for: forager.Category.fetchRequest())
        XCTAssertEqual(count, 1, "Three duplicates should reduce to one")
    }

    func testDifferentNamesNotMerged() throws {
        let _ = createCategory(name: "Produce")
        let _ = createCategory(name: "produce") // different display, but same normalizedName
        let _ = createCategory(name: "Dairy")
        try context.save()

        try CategoryDeduplicator(context: context).removeDuplicates()
        try context.save()

        let request: NSFetchRequest<forager.Category> = forager.Category.fetchRequest()
        let remaining = try context.fetch(request)

        // "Produce" and "produce" have the same normalizedName — should be deduped to 1
        // "Dairy" is different — should remain
        XCTAssertEqual(remaining.count, 2)
        let names = Set(remaining.map { $0.normalizedName ?? "" })
        XCTAssertTrue(names.contains(forager.Category.normalizedName(from: "Produce")))
        XCTAssertTrue(names.contains(forager.Category.normalizedName(from: "Dairy")))
    }
}
