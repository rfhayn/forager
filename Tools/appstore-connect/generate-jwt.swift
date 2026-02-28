#!/usr/bin/env swift
//
// generate-jwt.swift
// Generates a signed JWT for App Store Connect API authentication.
//
// Usage: swift generate-jwt.swift <key-path> <key-id> <issuer-id>
// Output: JWT token string to stdout (20-minute expiry)
//
// Requirements: macOS 10.15+ (CryptoKit)
//

import Foundation
import CryptoKit

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: generate-jwt.swift <key-path> <key-id> <issuer-id>\n", stderr)
    fputs("  key-path:   Path to AuthKey_XXXX.p8 file\n", stderr)
    fputs("  key-id:     API Key ID from App Store Connect\n", stderr)
    fputs("  issuer-id:  Issuer ID from App Store Connect\n", stderr)
    exit(1)
}

let keyPath = CommandLine.arguments[1]
let keyId = CommandLine.arguments[2]
let issuerId = CommandLine.arguments[3]

// Read and parse the .p8 private key (PKCS#8 PEM format)
let keyString = try String(contentsOfFile: keyPath, encoding: .utf8)
let keyPEM = keyString
    .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
    .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .replacingOccurrences(of: "\n", with: "")

guard let keyData = Data(base64Encoded: keyPEM) else {
    fputs("Error: Could not decode base64 key data from \(keyPath)\n", stderr)
    exit(1)
}

let privateKey: P256.Signing.PrivateKey
do {
    privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)
} catch {
    fputs("Error: Could not create P256 private key: \(error)\n", stderr)
    exit(1)
}

// Base64url encoding (RFC 7515)
func base64url(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

// Build JWT components
let header = """
{"alg":"ES256","kid":"\(keyId)","typ":"JWT"}
"""

let now = Int(Date().timeIntervalSince1970)
let exp = now + 1200 // 20-minute expiry

let payload = """
{"iss":"\(issuerId)","iat":\(now),"exp":\(exp),"aud":"appstoreconnect-v1"}
"""

let headerB64 = base64url(Data(header.utf8))
let payloadB64 = base64url(Data(payload.utf8))
let signingInput = "\(headerB64).\(payloadB64)"

// Sign with ES256 (P-256 + SHA-256)
let signature: P256.Signing.ECDSASignature
do {
    signature = try privateKey.signature(for: Data(signingInput.utf8))
} catch {
    fputs("Error: Signing failed: \(error)\n", stderr)
    exit(1)
}

// Output the complete JWT (raw representation = R||S, which is what JWT expects)
let signatureB64 = base64url(signature.rawRepresentation)
print("\(signingInput).\(signatureB64)")
