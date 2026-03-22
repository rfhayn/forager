//
//  LLMSettingsService.swift
//  forager
//
//  M10.6.2: Settings management for optional LLM-based ingredient parsing.
//  Toggle + API key storage + connection test + parser factory.
//  OFF by default — user must opt in via Settings > AI Import.
//

import Foundation
import CoreData

@MainActor
class LLMSettingsService: ObservableObject {

    static let shared = LLMSettingsService()

    // MARK: - Published State

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    @Published var isTestingConnection = false
    @Published var connectionTestResult: ConnectionTestResult?

    // MARK: - API Key Resolution

    /// M9.22: API key resolution order:
    /// 1. Per-user Keychain (local override, takes priority)
    /// 2. Household.llmAPIKey (shared via CloudKit, set by owner)
    var resolvedAPIKey: String? {
        if let keychainKey = KeychainHelper.getLLMAPIKey(), !keychainKey.isEmpty {
            return keychainKey
        }
        let hhKey = householdAPIKey
        if hhKey == nil {
            DiagnosticLogger.shared.debug("resolvedAPIKey: keychain=nil, household=nil", category: .household)
        }
        return hhKey
    }

    /// Fetch the household's shared API key from Core Data (M9.30: decrypts if encrypted)
    private var householdAPIKey: String? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1
        guard let household = (try? context.fetch(request))?.first,
              let storedKey = household.llmAPIKey, !storedKey.isEmpty else {
            return nil
        }

        // M9.30: Decrypt if encrypted, return plaintext if legacy
        guard let householdID = household.id else { return storedKey }
        do {
            return try HouseholdKeyEncryption.decrypt(storedKey, householdID: householdID)
        } catch {
            #if DEBUG
            print("⚠️ LLMSettingsService: Failed to decrypt API key: \(error)")
            #endif
            return nil
        }
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
        // M9.22: Also save to Household for sharing via CloudKit
        saveToHousehold(trimmed)
        // Verify the save worked
        let verified = KeychainHelper.getLLMAPIKey()
        DiagnosticLogger.shared.info(
            "saveAPIKey: saved \(trimmed.count)-char key, verify=\(verified != nil ? "OK (\(verified!.count) chars)" : "FAILED")",
            category: .household)
        objectWillChange.send()
    }

    func deleteAPIKey() {
        KeychainHelper.deleteLLMAPIKey()
        // M9.22: Also clear from Household
        saveToHousehold(nil)
        #if DEBUG
        DebugLogService.shared.log("deleteAPIKey: cleared Keychain + Household", category: "Settings")
        #endif
        objectWillChange.send()
    }

    /// M9.22+M9.30: Save API key to Household entity (encrypted) for CloudKit sharing
    private func saveToHousehold(_ key: String?) {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1
        guard let household = (try? context.fetch(request))?.first else { return }

        if let plaintext = key, let householdID = household.id {
            // M9.30: Encrypt before storing
            household.llmAPIKey = try? HouseholdKeyEncryption.encrypt(plaintext, householdID: householdID)
        } else {
            household.llmAPIKey = nil
        }
        try? context.save()
    }

    /// M9.30: Migrate unencrypted API key to encrypted on first launch after update
    func migrateAPIKeyEncryptionIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1
        guard let household = (try? context.fetch(request))?.first,
              let storedKey = household.llmAPIKey, !storedKey.isEmpty,
              let householdID = household.id,
              !HouseholdKeyEncryption.isEncrypted(storedKey) else {
            return
        }

        // Legacy plaintext — encrypt in place
        do {
            household.llmAPIKey = try HouseholdKeyEncryption.encrypt(storedKey, householdID: householdID)
            try context.save()
            DiagnosticLogger.shared.info("M9.30: Migrated API key to encrypted storage", category: .household)
        } catch {
            DiagnosticLogger.shared.error("M9.30: Failed to migrate API key encryption: \(error.localizedDescription)", category: .household)
        }
    }

    /// Returns a masked indicator that a key is configured (no key content revealed)
    var maskedAPIKey: String? {
        guard resolvedAPIKey != nil else { return nil }
        return "••••••••••••"
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
        #if DEBUG
        DebugLogService.shared.log(
            "activeParser() — isEnabled=\(isEnabled), hasKey=\(resolvedAPIKey != nil), "
            + "keyLength=\(resolvedAPIKey?.count ?? 0)",
            category: "Settings"
        )
        #endif
        guard isEnabled,
              let apiKey = resolvedAPIKey,
              !apiKey.isEmpty else {
            #if DEBUG
            DebugLogService.shared.log(
                "activeParser() → nil (isEnabled=\(isEnabled), keyPresent=\(resolvedAPIKey != nil))",
                category: "Settings"
            )
            #endif
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
