import Foundation
import Security
import SharedContracts

public struct CredentialMetadata: Codable, Equatable, Sendable {
    public let accountId: UUID
    public let authType: AuthType
    public let keychainService: String
    public let keychainAccount: String
}

public enum CredentialServiceError: Error {
    case encodingFailure
    case keychainFailure(OSStatus)
    case notFound
}

public final class CredentialService: @unchecked Sendable {
    private let keychainService = "com.sparkai.credentials"

    public init() {}

    public func saveSecret(accountId: UUID, authType: AuthType, secret: String) throws -> CredentialMetadata {
        let keychainAccount = "\(accountId.uuidString).\(authType.rawValue)"
        guard let data = secret.data(using: .utf8) else {
            throw CredentialServiceError.encodingFailure
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)

        var saveQuery = query
        saveQuery[kSecValueData as String] = data
        saveQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(saveQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CredentialServiceError.keychainFailure(status)
        }

        return CredentialMetadata(
            accountId: accountId,
            authType: authType,
            keychainService: keychainService,
            keychainAccount: keychainAccount
        )
    }

    public func loadSecret(metadata: CredentialMetadata) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: metadata.keychainService,
            kSecAttrAccount as String: metadata.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            throw CredentialServiceError.notFound
        }
        guard status == errSecSuccess else {
            throw CredentialServiceError.keychainFailure(status)
        }
        guard
            let data = result as? Data,
            let string = String(data: data, encoding: .utf8)
        else {
            throw CredentialServiceError.encodingFailure
        }
        return string
    }

    public func deleteSecret(metadata: CredentialMetadata) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: metadata.keychainService,
            kSecAttrAccount as String: metadata.keychainAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialServiceError.keychainFailure(status)
        }
    }
}
