//
//  KeychainHelper.swift
//  forager
//
//  M7.2.2: Keychain-backed storage for left-household tracking.
//  Unlike UserDefaults, Keychain data survives app reinstalls and
//  device restores (when backed up), preventing accidental re-joining.
//
//  M7.3.4: Added pending leave queue for offline leave operations.
//

import Foundation
import Security
import CloudKit

enum KeychainHelper {

    private static let service = "com.richhayn.forager"
    private static let leftHouseholdsKey = "leftHouseholdIDs"
    private static let pendingLeavesKey = "pendingLeaves"

    // MARK: - Pending Leave (M7.3.4)

    /// Represents a leave operation that needs to be completed when online
    struct PendingLeave: Codable {
        let householdID: String
        let shareRecordName: String
        let shareZoneName: String
        let shareZoneOwner: String
        let timestamp: Date
    }

    /// Adds a pending leave to be processed when connectivity returns
    static func addPendingLeave(householdID: String, share: CKShare) {
        var pending = pendingLeaves()
        let leave = PendingLeave(
            householdID: householdID,
            shareRecordName: share.recordID.recordName,
            shareZoneName: share.recordID.zoneID.zoneName,
            shareZoneOwner: share.recordID.zoneID.ownerName,
            timestamp: Date()
        )
        pending.append(leave)
        savePendingLeaves(pending)
        #if DEBUG
        print("📝 M7.3.4: Queued pending leave for household \(householdID)")
        #endif
    }

    /// Returns all pending leaves
    static func pendingLeaves() -> [PendingLeave] {
        guard let data = read(key: pendingLeavesKey),
              let leaves = try? JSONDecoder().decode([PendingLeave].self, from: data) else {
            return []
        }
        return leaves
    }

    /// Removes a pending leave after successful processing
    static func removePendingLeave(householdID: String) {
        var pending = pendingLeaves()
        pending.removeAll { $0.householdID == householdID }
        savePendingLeaves(pending)
        #if DEBUG
        print("✅ M7.3.4: Removed pending leave for household \(householdID)")
        #endif
    }

    /// Clears all pending leaves
    static func clearAllPendingLeaves() {
        savePendingLeaves([])
    }

    private static func savePendingLeaves(_ leaves: [PendingLeave]) {
        guard let data = try? JSONEncoder().encode(leaves) else { return }
        write(key: pendingLeavesKey, data: data)
    }

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

    // MARK: - LLM API Key (M10.6.2)

    private static let llmAPIKeyKey = "llmAPIKey"

    /// Saves the LLM API key to Keychain
    static func saveLLMAPIKey(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }
        write(key: llmAPIKeyKey, data: data)
    }

    /// Retrieves the LLM API key from Keychain
    static func getLLMAPIKey() -> String? {
        guard let data = read(key: llmAPIKeyKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Deletes the LLM API key from Keychain
    static func deleteLLMAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: llmAPIKeyKey
        ]
        SecItemDelete(query as CFDictionary)
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
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // Try update first (most common case — item already exists)
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Item doesn't exist — add it
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            #if DEBUG
            if addStatus != errSecSuccess {
                print("⚠️ Keychain write failed (add): \(addStatus)")
            }
            #endif
        } else if updateStatus != errSecSuccess {
            #if DEBUG
            print("⚠️ Keychain write failed (update): \(updateStatus)")
            #endif
        }
    }
}
