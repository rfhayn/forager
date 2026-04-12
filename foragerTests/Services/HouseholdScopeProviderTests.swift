import XCTest
import CoreData
@testable import forager

/// M19: HouseholdScopeProvider tests
/// Validates scope resolution based on household state.
@MainActor
final class HouseholdScopeProviderTests: XCTestCase {

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

    // MARK: - No Household

    func testNoHouseholdReturnsPersonalScope() {
        let householdService = HouseholdService(context: context)
        let provider = HouseholdScopeProvider(householdService: householdService, persistence: persistence)

        let scope = provider.activeScope

        if case .personal = scope {
            // Expected
        } else {
            XCTFail("Expected .personal scope when no household exists, got \(scope)")
        }
    }

    // MARK: - Scope Snapshot

    func testScopeSnapshotMatchesActiveScope() {
        let householdService = HouseholdService(context: context)
        let provider = HouseholdScopeProvider(householdService: householdService, persistence: persistence)

        let active = provider.activeScope
        let snapshot = provider.scopeSnapshot()

        // Both should be .personal when no household
        if case .personal = active, case .personal = snapshot {
            // Expected — both personal
        } else {
            XCTFail("Snapshot should match active scope")
        }
    }

    // MARK: - Household with Deleted Object

    func testDeletedHouseholdFallsBackToPersonal() {
        let householdService = HouseholdService(context: context)

        // Create and immediately delete a household
        let household = Household(context: context)
        household.id = UUID()
        household.name = "To Delete"
        household.ownerEmail = "test@example.com"
        household.createdDate = Date()
        try? context.save()

        context.delete(household)
        try? context.save()

        let provider = HouseholdScopeProvider(householdService: householdService, persistence: persistence)

        // With no current household, should be personal
        let scope = provider.activeScope
        if case .personal = scope {
            // Expected
        } else {
            XCTFail("Expected .personal scope after household deleted, got \(scope)")
        }
    }
}
