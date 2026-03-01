//
//  LLMSettingsServiceTests.swift
//  foragerTests
//
//  M10.6.2: Tests for LLMSettingsService — toggle persistence,
//  API key management, connection test, parser factory.
//

import XCTest
@testable import forager

@MainActor
final class LLMSettingsServiceTests: XCTestCase {

    private var service: LLMSettingsService!

    override func setUp() {
        super.setUp()
        // Clean slate for each test
        UserDefaults.standard.removeObject(forKey: "llmParsingEnabled")
        KeychainHelper.deleteLLMAPIKey()
        service = LLMSettingsService()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "llmParsingEnabled")
        KeychainHelper.deleteLLMAPIKey()
        super.tearDown()
    }

    // MARK: - 1. Toggle Persistence

    func testTogglePersistsToUserDefaults() {
        XCTAssertFalse(service.isEnabled, "Default should be OFF")

        service.isEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "llmParsingEnabled"))

        service.isEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "llmParsingEnabled"))
    }

    func testToggleRestoredFromUserDefaults() {
        UserDefaults.standard.set(true, forKey: "llmParsingEnabled")
        let restored = LLMSettingsService()
        XCTAssertTrue(restored.isEnabled)
    }

    // MARK: - 2. API Key Save/Retrieve/Delete

    func testAPIKeySaveRetrieveDelete() {
        XCTAssertFalse(service.hasAPIKey)
        XCTAssertNil(service.maskedAPIKey)

        service.saveAPIKey("sk-ant-api03-testkey123456")
        XCTAssertTrue(service.hasAPIKey)
        XCTAssertEqual(service.maskedAPIKey, "sk-ant-...456")

        service.deleteAPIKey()
        XCTAssertFalse(service.hasAPIKey)
        XCTAssertNil(service.maskedAPIKey)
    }

    func testSaveAPIKeyTrimsWhitespace() {
        service.saveAPIKey("  sk-ant-api03-padded  \n")
        XCTAssertTrue(service.hasAPIKey)
        // Verify the stored key was trimmed
        XCTAssertEqual(KeychainHelper.getLLMAPIKey(), "sk-ant-api03-padded")
    }

    func testSaveEmptyAPIKeyIsIgnored() {
        service.saveAPIKey("sk-ant-api03-original")
        service.saveAPIKey("   ")
        // Original key should still be there
        XCTAssertTrue(service.hasAPIKey)
    }

    // MARK: - 3. activeParser() Factory

    func testActiveParserReturnsNilWhenDisabled() {
        service.saveAPIKey("sk-ant-api03-testkey")
        service.isEnabled = false
        XCTAssertNil(service.activeParser())
    }

    func testActiveParserReturnsNilWhenNoKey() {
        service.isEnabled = true
        XCTAssertNil(service.activeParser())
    }

    func testActiveParserReturnsParserWhenEnabledAndConfigured() {
        service.saveAPIKey("sk-ant-api03-testkey")
        service.isEnabled = true

        let parser = service.activeParser()
        XCTAssertNotNil(parser)
        XCTAssertEqual(parser?.providerName, "claude")
    }

    // MARK: - 4. Connection Test (No API Key)

    func testConnectionTestFailsWithoutAPIKey() async {
        await service.testConnection()
        XCTAssertEqual(service.connectionTestResult, .failure("No API key configured"))
        XCTAssertFalse(service.isTestingConnection)
    }
}
