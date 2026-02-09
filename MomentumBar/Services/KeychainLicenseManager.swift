//
//  KeychainLicenseManager.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import Security

/// Manages secure storage of license data in the macOS Keychain
final class KeychainLicenseManager {

    // MARK: - Singleton
    static let shared = KeychainLicenseManager()
    private init() {}

    // MARK: - Constants
    private let serviceName = "com.momentumbar.license"

    private enum KeychainKey: String {
        case license = "license_data"
        case trialStart = "trial_start"
        case cacheExpiry = "cache_expiry"
    }

    // MARK: - Errors
    enum KeychainError: LocalizedError {
        case storeFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case encodingFailed
        case decodingFailed
        case unexpectedData
        case missingEntitlement

        var errorDescription: String? {
            switch self {
            case .storeFailed(let status):
                return "Failed to store in Keychain (status: \(status))"
            case .retrieveFailed(let status):
                return "Failed to retrieve from Keychain (status: \(status))"
            case .deleteFailed(let status):
                return "Failed to delete from Keychain (status: \(status))"
            case .encodingFailed:
                return "Failed to encode data"
            case .decodingFailed:
                return "Failed to decode data"
            case .unexpectedData:
                return "Unexpected data format"
            case .missingEntitlement:
                return "Keychain access is not available in this build."
            }
        }
    }

    // MARK: - License Storage

    /// Store a license in the Keychain
    func storeLicense(_ license: License) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(license) else {
            throw KeychainError.encodingFailed
        }

        try storeData(data, forKey: .license)
    }

    /// Retrieve license from Keychain
    func retrieveLicense() throws -> License? {
        guard let data = try retrieveData(forKey: .license) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let license = try? decoder.decode(License.self, from: data) else {
            throw KeychainError.decodingFailed
        }

        return license
    }

    /// Delete license from Keychain
    func deleteLicense() throws {
        try deleteData(forKey: .license)
    }

    // MARK: - Trial Storage

    /// Store trial start date
    func storeTrialStart(_ date: Date) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let trialInfo = TrialInfo(startDate: date)
        guard let data = try? encoder.encode(trialInfo) else {
            throw KeychainError.encodingFailed
        }

        try storeData(data, forKey: .trialStart)
    }

    /// Retrieve trial info
    func retrieveTrialInfo() throws -> TrialInfo? {
        guard let data = try retrieveData(forKey: .trialStart) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let trialInfo = try? decoder.decode(TrialInfo.self, from: data) else {
            throw KeychainError.decodingFailed
        }

        return trialInfo
    }

    /// Delete trial info
    func deleteTrialInfo() throws {
        try deleteData(forKey: .trialStart)
    }

    // MARK: - Cache Expiry Storage

    /// Store cache expiry date
    func storeCacheExpiry(_ date: Date) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(date) else {
            throw KeychainError.encodingFailed
        }

        try storeData(data, forKey: .cacheExpiry)
    }

    /// Retrieve cache expiry date
    func retrieveCacheExpiry() throws -> Date? {
        guard let data = try retrieveData(forKey: .cacheExpiry) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(Date.self, from: data)
    }

    // MARK: - Clear All

    /// Clear all license-related data from Keychain
    func clearAll() throws {
        try? deleteData(forKey: .license)
        try? deleteData(forKey: .trialStart)
        try? deleteData(forKey: .cacheExpiry)
    }

    // MARK: - Private Keychain Operations

    private func storeData(_ data: Data, forKey key: KeychainKey) throws {
        guard EntitlementService.shared.hasKeychainAccess else {
            throw KeychainError.missingEntitlement
        }

        // First, try to delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item - use kSecAttrAccessibleAfterFirstUnlock for persistence across app rebuilds
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    private func retrieveData(forKey key: KeychainKey) throws -> Data? {
        guard EntitlementService.shared.hasKeychainAccess else {
            throw KeychainError.missingEntitlement
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.retrieveFailed(status)
        }
    }

    private func deleteData(forKey key: KeychainKey) throws {
        guard EntitlementService.shared.hasKeychainAccess else {
            throw KeychainError.missingEntitlement
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Convenience Extensions
extension KeychainLicenseManager {
    /// Check if a license exists in the Keychain
    var hasStoredLicense: Bool {
        (try? retrieveLicense()) != nil
    }

    /// Check if trial info exists
    var hasTrialInfo: Bool {
        (try? retrieveTrialInfo()) != nil
    }
}
