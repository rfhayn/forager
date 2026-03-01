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
        service.householdAPIKeyProvider = nil
    }

    override func tearDown() {
        service.householdAPIKeyProvider = nil
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

    // MARK: - 5. M10.6.7: Household Key Resolution

    func testResolvedAPIKeyPrefersHouseholdKey() {
        // Local key in Keychain
        service.saveAPIKey("sk-ant-api03-local-key1234")
        // Household key via provider
        service.householdAPIKeyProvider = { "sk-ant-api03-household-key5678" }

        XCTAssertEqual(service.resolvedAPIKey, "sk-ant-api03-household-key5678",
                       "Household key should take priority over local Keychain key")
    }

    func testResolvedAPIKeyFallsBackToLocalWhenNoHouseholdKey() {
        service.saveAPIKey("sk-ant-api03-local-key1234")
        // Provider returns nil (no household key set)
        service.householdAPIKeyProvider = { nil }

        XCTAssertEqual(service.resolvedAPIKey, "sk-ant-api03-local-key1234",
                       "Should fall back to local key when household key is nil")
    }

    func testResolvedAPIKeyFallsBackToLocalWhenNotInHousehold() {
        service.saveAPIKey("sk-ant-api03-local-key1234")
        // No provider at all (solo user)
        service.householdAPIKeyProvider = nil

        XCTAssertEqual(service.resolvedAPIKey, "sk-ant-api03-local-key1234",
                       "Should use local key when no household provider is set")
    }

    func testIsUsingHouseholdKeyWhenHouseholdKeySet() {
        service.householdAPIKeyProvider = { "sk-ant-api03-household-key5678" }
        XCTAssertTrue(service.isUsingHouseholdKey)
    }

    func testIsUsingHouseholdKeyFalseWhenNoProvider() {
        service.householdAPIKeyProvider = nil
        XCTAssertFalse(service.isUsingHouseholdKey)
    }

    func testIsUsingHouseholdKeyFalseWhenProviderReturnsEmpty() {
        service.householdAPIKeyProvider = { "" }
        XCTAssertFalse(service.isUsingHouseholdKey,
                       "Empty string from provider should not count as a household key")
    }
}
