//
//  KeychainHelper.swift
//  Gulgle
//
//  Created for Gulgle auth functionality.
//

import Foundation
import Security

enum KeychainHelper {
    private static let service = "link.gulgle.auth"
    private static let tokenAccount = "jwt-token"

    // MARK: - Token

    static func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }

        // Delete existing first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - JWT Expiration Check

    /// Checks if a JWT token is expired (with a 5-minute buffer).
    /// Returns true if the token is still valid, false if expired or unparseable.
    static func isTokenValid(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return false }

        var base64 = String(parts[1])
        // Pad base64 to multiple of 4
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let payloadData = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return false
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        let bufferSeconds: TimeInterval = 5 * 60 // 5 minutes
        return Date().addingTimeInterval(bufferSeconds) < expirationDate
    }
}
