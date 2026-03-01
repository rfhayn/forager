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

    // MARK: - Constants

    private static let enabledKey = "llmParsingEnabled"

    // MARK: - Init

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    // MARK: - API Key Management

    var hasAPIKey: Bool {
        KeychainHelper.getLLMAPIKey() != nil
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

    /// Returns a masked version of the stored key for display (e.g., "sk-ant-...xyz")
    var maskedAPIKey: String? {
        guard let key = KeychainHelper.getLLMAPIKey(), key.count > 10 else { return nil }
        let prefix = String(key.prefix(7))
        let suffix = String(key.suffix(3))
        return "\(prefix)...\(suffix)"
    }

    // MARK: - Connection Test

    func testConnection() async {
        guard let apiKey = KeychainHelper.getLLMAPIKey() else {
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
              let apiKey = KeychainHelper.getLLMAPIKey(),
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
