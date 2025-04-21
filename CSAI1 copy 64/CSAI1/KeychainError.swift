//
//  KeychainError.swift
//  CSAI1
//
//  Created by DM on 4/20/25.
//


import Foundation
import Security

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    /// Save a string value to the Keychain
    func save(_ value: String, service: String, account: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
        ]
        let update: [String: Any] = [
            kSecValueData as String   : data
        ]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return }
        if status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
        // Item not found, add it
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }

    /// Read a string value from the Keychain
    func read(service: String, account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = item as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.unexpectedStatus(status)
        }
        return string
    }

    /// Delete a value from the Keychain
    func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}