//
//  KeychainHelper.swift
//  forager
//
//  M7.2.2: Keychain-backed storage for left-household tracking.
//  Unlike UserDefaults, Keychain data survives app reinstalls and
//  device restores (when backed up), preventing accidental re-joining.
//

import Foundation
import Security

enum KeychainHelper {

    private static let service = "com.richhayn.forager"
    private static let leftHouseholdsKey = "leftHouseholdIDs"

    // MARK: - Left Household Tracking

    /// Returns the set of household IDs the user has left.
    static func leftHouseholdIDs() -> Set<String> {
        guard let data = read(key: leftHouseholdsKey),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(array)
    }

    /// Adds a household ID to the left set.
    static func markHouseholdAsLeft(_ householdID: String) {
        var ids = leftHouseholdIDs()
        ids.insert(householdID)
        save(ids: ids)
    }

    /// Removes a household ID from the left set (e.g. when re-invited).
    static func clearLeftHouseholdFlag(_ householdID: String) {
        var ids = leftHouseholdIDs()
        ids.remove(householdID)
        save(ids: ids)
    }

    /// Checks if the user has left this household.
    static func hasLeftHousehold(_ householdID: String) -> Bool {
        return leftHouseholdIDs().contains(householdID)
    }

    // MARK: - Private Keychain Operations

    private static func save(ids: Set<String>) {
        guard let data = try? JSONEncoder().encode(Array(ids)) else { return }
        write(key: leftHouseholdsKey, data: data)
    }

    private static func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func write(key: String, data: Data) {
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
