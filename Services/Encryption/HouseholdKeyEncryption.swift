//
//  HouseholdKeyEncryption.swift
//  forager
//
//  M9.30: AES-GCM encryption for household-shared API keys.
//  Uses household UUID as key derivation input for defense-in-depth.
//
//  Security model: Encryption protects against casual SQLite snooping.
//  The primary security boundary is CloudKit access revocation on member removal.
//  A removed member who has the household UUID AND cached ciphertext could
//  theoretically decrypt — but CloudKit prevents them from reading new ciphertext.
//

import Foundation
import CryptoKit

struct HouseholdKeyEncryption {

    /// Encrypted value prefix — used to detect unencrypted legacy values
    private static let encryptedPrefix = "ENC:"

    /// Encrypt a plaintext string using AES-GCM with a household-derived key.
    /// Returns base64-encoded ciphertext prefixed with "ENC:" marker.
    static func encrypt(_ plaintext: String, householdID: UUID) throws -> String {
        let key = deriveKey(from: householdID)
        let plaintextData = Data(plaintext.utf8)
        let sealedBox = try AES.GCM.seal(plaintextData, using: key)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.sealFailed
        }

        return encryptedPrefix + combined.base64EncodedString()
    }

    /// Decrypt an encrypted string. Returns nil if the value is not encrypted (legacy plaintext).
    static func decrypt(_ ciphertext: String, householdID: UUID) throws -> String {
        // Check for encryption prefix — legacy values are plaintext
        guard ciphertext.hasPrefix(encryptedPrefix) else {
            return ciphertext // Legacy plaintext, return as-is
        }

        let base64 = String(ciphertext.dropFirst(encryptedPrefix.count))
        guard let combined = Data(base64Encoded: base64) else {
            throw EncryptionError.invalidBase64
        }

        let key = deriveKey(from: householdID)
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidUTF8
        }

        return plaintext
    }

    /// Check if a stored value is encrypted (has the ENC: prefix)
    static func isEncrypted(_ value: String) -> Bool {
        value.hasPrefix(encryptedPrefix)
    }

    // MARK: - Key Derivation

    /// Derive a 256-bit AES key from the household UUID using HKDF.
    private static func deriveKey(from householdID: UUID) -> SymmetricKey {
        let inputData = Data(householdID.uuidString.utf8)
        let salt = Data("forager-llm-key".utf8)
        let inputKey = SymmetricKey(data: inputData)

        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("api-key-encryption".utf8),
            outputByteCount: 32
        )

        return derivedKey
    }

    // MARK: - Errors

    enum EncryptionError: LocalizedError {
        case sealFailed
        case invalidBase64
        case invalidUTF8

        var errorDescription: String? {
            switch self {
            case .sealFailed: return "Failed to encrypt data"
            case .invalidBase64: return "Invalid encrypted data format"
            case .invalidUTF8: return "Decrypted data is not valid text"
            }
        }
    }
}
