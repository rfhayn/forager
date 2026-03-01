//
//  LLMSettingsService.swift
//  forager
//
//  M10.6.2: Settings management for optional LLM-based ingredient parsing.
//  Toggle + API key storage + connection test + parser factory.
//  OFF by default — user must opt in via Settings > AI Import.
//

import Foundation

@MainActor
class LLMSettingsService: ObservableObject {

    static let shared = LLMSettingsService()

    // MARK: - Published State

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    @Published var isTestingConnection = false
    @Published var connectionTestResult: ConnectionTestResult?

    // MARK: - M10.6.7: Household Key Provider

    /// Closure that reads the household's shared API key.
    /// Wired in foragerApp.init() to avoid coupling to HouseholdService.
    var householdAPIKeyProvider: (() -> String?)?

    /// Resolves the active API key: household key takes priority over local Keychain.
    var resolvedAPIKey: String? {
        if let householdKey = householdAPIKeyProvider?(), !householdKey.isEmpty {
            return householdKey
        }
        return KeychainHelper.getLLMAPIKey()
    }

    /// Whether the currently resolved key comes from the household (vs local Keychain)
    var isUsingHouseholdKey: Bool {
        guard let householdKey = householdAPIKeyProvider?(), !householdKey.isEmpty else {
            return false
        }
        return true
    }

    // MARK: - Constants

    private static let enabledKey = "llmParsingEnabled"

    // MARK: - Init

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    // MARK: - API Key Management

    var hasAPIKey: Bool {
        resolvedAPIKey != nil
    }

    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainHelper.saveLLMAPIKey(trimmed)
        objectWillChange.send()
    }

    func deleteAPIKey() {
        KeychainHelper.deleteLLMAPIKey()
        objectWillChange.send()
    }

    /// Returns a masked version of the active key for display (e.g., "sk-ant-...xyz")
    var maskedAPIKey: String? {
        guard let key = resolvedAPIKey, key.count > 10 else { return nil }
        let prefix = String(key.prefix(7))
        let suffix = String(key.suffix(3))
        return "\(prefix)...\(suffix)"
    }

    // MARK: - Connection Test

    func testConnection() async {
        guard let apiKey = resolvedAPIKey else {
            connectionTestResult = .failure("No API key configured")
            return
        }

        isTestingConnection = true
        connectionTestResult = nil

        let parser = ClaudeIngredientParser(apiKey: apiKey)

        do {
            let results = try await parser.parseBatch(["1 cup flour"])
            if results.first?.name.lowercased() == "flour" {
                connectionTestResult = .success
            } else {
                connectionTestResult = .failure("Unexpected response")
            }
        } catch let error as LLMParserError {
            connectionTestResult = .failure(error.errorDescription ?? "Unknown error")
        } catch {
            connectionTestResult = .failure(error.localizedDescription)
        }

        isTestingConnection = false
    }

    // MARK: - Parser Factory

    /// Returns a configured parser when enabled + API key present, nil otherwise
    func activeParser() -> (any LLMIngredientParser)? {
        guard isEnabled,
              let apiKey = resolvedAPIKey,
              !apiKey.isEmpty else {
            return nil
        }
        return ClaudeIngredientParser(apiKey: apiKey)
    }

    // MARK: - Connection Test Result

    enum ConnectionTestResult: Equatable {
        case success
        case failure(String)
    }
}
