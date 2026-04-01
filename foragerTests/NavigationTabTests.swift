import XCTest
@testable import forager

/// FUI-1.1: NavigationTab enum tests
/// Verifies tab cases, titles, icons, and default selection
final class NavigationTabTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(NavigationTab.allCases.count, 4, "Should have exactly 4 tabs")
    }

    func testCaseOrder() {
        let expected: [NavigationTab] = [.home, .lists, .recipes, .mealPlans]
        XCTAssertEqual(NavigationTab.allCases, expected, "Tab order should be Home, Lists, Recipes, Meals")
    }

    func testTitles() {
        XCTAssertEqual(NavigationTab.home.title, "Home")
        XCTAssertEqual(NavigationTab.lists.title, "Lists")
        XCTAssertEqual(NavigationTab.recipes.title, "Recipes")
        XCTAssertEqual(NavigationTab.mealPlans.title, "Meals")
    }

    func testIcons() {
        XCTAssertEqual(NavigationTab.home.icon, "house")
        XCTAssertEqual(NavigationTab.lists.icon, "list.bullet")
        XCTAssertEqual(NavigationTab.recipes.icon, "book")
        XCTAssertEqual(NavigationTab.mealPlans.icon, "calendar")
    }

    func testRemovedCasesDoNotExist() {
        let caseNames = NavigationTab.allCases.map(\.rawValue)
        XCTAssertFalse(caseNames.contains("search"), "Search tab should be removed")
        XCTAssertFalse(caseNames.contains("settings"), "Settings tab should be removed")
    }
}
