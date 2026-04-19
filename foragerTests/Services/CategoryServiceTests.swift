import XCTest
import CoreData
@testable import forager

/// architecture-compliance-sweep: CategoryService unit tests
///
/// Scope note: these tests cover the validation / error-path logic that runs
/// BEFORE the ManagedObjectFactory.make() call. The factory-success paths
/// (sortOrder assignment, actual category creation, save persistence) require
/// dual-store setup via PersistenceController in a way that the in-memory
/// test harness doesn't support today — covering those requires a harness
/// investment that is out of scope for this change.
///
/// What IS covered:
/// - Dedup rejection (case-insensitive, scoped by household)
/// - Whitespace trimming in the dedup check
/// - Factory-unavailable error path
/// - errorMessage wiring on failure
///
/// What is NOT covered (deferred to a test-harness change):
/// - Happy-path success (needs configured factory + stores)
/// - sortOrder assignment
/// - persistToContext verification
@MainActor
final class CategoryServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var context: NSManagedObjectContext!
    private var householdService: HouseholdService!
    private var service: CategoryService!

    override func setUp() {
        super.setUp()
        #if DEBUG
        DefaultSeeder.resetSeedingStatus()
        #endif
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        householdService = HouseholdService(context: context)
        service = CategoryService(context: context, householdService: householdService)
        // NOTE: intentionally NOT calling service.configure(factory:) — tests here
        // exercise paths that reject before reaching the factory.
    }

    override func tearDown() {
        service = nil
        householdService = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Seeds a Category directly (bypassing the service) so dedup checks have
    /// something to match against. Scoped by householdKey so it matches the
    /// dedup query the service runs.
    private func seedCategory(
        name: String,
        sortOrder: Int16 = 6,
        householdKey: String? = nil
    ) {
        let cat = forager.Category(context: context)
        cat.id = UUID()
        cat.name = name
        cat.sortOrder = sortOrder
        cat.householdKey = householdKey
        cat.isDefault = false
        cat.dateCreated = Date()
        try? context.save()
    }

    // MARK: - Dedup within scope

    func testCreateCustomCategory_rejectsDuplicateNameInSameScope() {
        seedCategory(name: "Dairy")

        let result = service.createCustomCategory(displayName: "Dairy", color: "#2196F3")

        guard case .failure(let err) = result, case .duplicateName = err else {
            XCTFail("Expected .failure(.duplicateName), got \(result)")
            return
        }
        XCTAssertNotNil(service.errorMessage)
        XCTAssertEqual(service.errorMessage, "A category with this name already exists.")
    }

    func testCreateCustomCategory_dedupIsCaseInsensitive() {
        seedCategory(name: "Dairy")

        let variants = ["DAIRY", "dairy", "DaIrY"]
        for variant in variants {
            let result = service.createCustomCategory(displayName: variant, color: "#F44336")
            guard case .failure(let err) = result, case .duplicateName = err else {
                XCTFail("Expected .duplicateName rejection for '\(variant)', got \(result)")
                continue
            }
        }
    }

    func testCreateCustomCategory_dedupTrimsWhitespace() {
        seedCategory(name: "Dairy")

        let result = service.createCustomCategory(displayName: "  Dairy  ", color: "#F44336")

        guard case .failure(let err) = result, case .duplicateName = err else {
            XCTFail("Leading/trailing whitespace should be stripped; expected .duplicateName, got \(result)")
            return
        }
    }

    // MARK: - Factory unavailable

    func testCreateCustomCategory_factoryUnavailable_returnsError() {
        // No seed — the dedup check passes, and execution advances to the
        // factory guard, which fails because configure(factory:) was not called.
        let result = service.createCustomCategory(displayName: "Snacks", color: "#FF9800")

        guard case .failure(let err) = result, case .factoryUnavailable = err else {
            XCTFail("Expected .failure(.factoryUnavailable), got \(result)")
            return
        }
        XCTAssertNotNil(service.errorMessage)
    }

    func testCreateCustomCategory_errorMessageClearedOnFreshCall() {
        // Trigger a failure to populate errorMessage.
        _ = service.createCustomCategory(displayName: "Snacks", color: "#FF9800")
        XCTAssertNotNil(service.errorMessage)

        // Subsequent call should clear errorMessage at the start (clearError()
        // is called first), even if it subsequently fails for a different reason.
        seedCategory(name: "Dairy")
        let result = service.createCustomCategory(displayName: "Dairy", color: "#4CAF50")

        guard case .failure = result else {
            XCTFail("Expected .failure")
            return
        }
        // errorMessage is populated again (by the new failure), but it reflects
        // the CURRENT failure, not the previous one.
        XCTAssertEqual(service.errorMessage, "A category with this name already exists.")
    }
}
