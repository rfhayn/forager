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

        // Settings (gear from Home) + scrolled sections
        app.buttons["Home"].firstMatch.tap()
        sleep(1)
        let gear = app.buttons["Settings"].firstMatch.exists
            ? app.buttons["Settings"].firstMatch
            : app.buttons["gearshape"].firstMatch
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
            sleep(2)
            saveShot(app, name: "05-settings-top")
            app.swipeUp()
            sleep(1)
            saveShot(app, name: "06-settings-mid")
            app.swipeUp()
            sleep(1)
            saveShot(app, name: "07-settings-bottom")
        }

        // A modal: add-item sheet from list detail (fresh launch to reset nav)
        app.terminate()
        app.launch()
        sleep(3)
        app.buttons["Lists"].firstMatch.tap()
        sleep(1)
        let cell = app.cells.firstMatch
        if cell.waitForExistence(timeout: 3) {
            cell.tap()
            sleep(2)
            let plus = app.buttons["plus.square"].firstMatch
            if plus.waitForExistence(timeout: 3) {
                plus.tap()
                sleep(2)
                saveShot(app, name: "08-add-item-modal")
            }
        }
    }

    private func saveShot(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        let dir = URL(fileURLWithPath: "/tmp/reskin-shots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
    }
}
