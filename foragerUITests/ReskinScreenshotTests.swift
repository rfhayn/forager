//
//  ReskinScreenshotTests.swift
//  foragerUITests
//
//  reskin-provisions-press: throwaway navigation harness — drives to the
//  grocery list detail and recipe screens and saves screenshots so the
//  Provisions Press component grammar can be verified headlessly.
//  DELETE before PR (task 6.5 checklist).
//

import XCTest

final class ReskinScreenshotTests: XCTestCase {

    func testCaptureReskinScreens() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(3)

        // Lists tab → first list → detail (store bands + square checks)
        app.buttons["Lists"].firstMatch.tap()
        sleep(2)
        saveShot(app, name: "01-lists")

        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()
            sleep(2)
            saveShot(app, name: "02-list-detail")
        }

        // Recipes tab
        app.buttons["Recipes"].firstMatch.tap()
        sleep(2)
        saveShot(app, name: "03-recipes")

        // Meals tab
        app.buttons["Meals"].firstMatch.tap()
        sleep(2)
        saveShot(app, name: "04-meals")
    }

    private func saveShot(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        let dir = URL(fileURLWithPath: "/tmp/reskin-shots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
    }
}
