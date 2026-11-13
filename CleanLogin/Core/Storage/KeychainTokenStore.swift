
import Foundation
import Security

@MainActor
final class KeychainTokenStore: TokenStore {
    
    private let service: String
    
    private let accessTokenAccount = "access-token"
    private let refreshTokenAccount = "refresh-token"
    
    init(service: String) {
        self.service = service
    }
    
    // MARK: - Query
    
    private func query(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
    
    // MARK: - Read
    
    func readAccessToken() throws -> String? {
        try readToken(account: accessTokenAccount)
    }
    
    func readRefreshToken() throws -> String? {
        try readToken(account: refreshTokenAccount)
    }
    
    private func readToken(account: String) throws -> String? {
        
        var query = query(account: account)
        
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: CFTypeRef?
        
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            throw StorageError.operationFailed(status)
        }
        
        return token
    }
    
    // MARK: - Save
    
    func save(_ tokens: AuthTokens) throws {
        // Kiểm tra trước để không ghi một nửa rồi mới phát hiện token rỗng.
        guard !tokens.accessToken.isEmpty, !tokens.refreshToken.isEmpty else {
            throw StorageError.operationFailed(errSecParam)
        }
        do {
            try saveToken(tokens.refreshToken, account: refreshTokenAccount)
            try saveToken(tokens.accessToken, account: accessTokenAccount)
        } catch {
            // Không để lại phiên dở dang (ví dụ còn access token nhưng mất refresh token).
            try? clear()
            throw error
        }
    }
    
    private func saveToken(
        _ token: String,
        account: String
    ) throws {
        
        guard !token.isEmpty else {
            throw StorageError.operationFailed(errSecParam)
        }
        
        let query = query(account: account)
        
        let data = Data(token.utf8)
        
        let updateValues: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(
            query as CFDictionary,
            updateValues as CFDictionary
        )
        
        if status == errSecItemNotFound {
            
            let addValues: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String:
                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let addQuery = query.merging(addValues) {
                _, new in new
            }
            
            let addStatus = SecItemAdd(
                addQuery as CFDictionary,
                nil
            )
            
            guard addStatus == errSecSuccess else {
                throw StorageError.operationFailed(addStatus)
            }
            
        } else if status != errSecSuccess {
            throw StorageError.operationFailed(status)
        }
    }
    
    // MARK: - Clear
    
    func clear() throws {
        var firstError: Error?
        
        do {
            try deleteToken(account: accessTokenAccount)
        } catch {
            firstError = error
        }
        
        do {
            try deleteToken(account: refreshTokenAccount)
        } catch {
            if firstError == nil {
                firstError = error
            }
        }
        
        if let firstError {
            throw firstError
        }
    }
    
    private func deleteToken(account: String) throws {
        
        let status = SecItemDelete(
            query(account: account) as CFDictionary
        )
        
        guard status == errSecSuccess ||
                status == errSecItemNotFound else {
            throw StorageError.operationFailed(status)
        }
    }
    
    // MARK: - Error
    
    enum StorageError: Error {
        case operationFailed(OSStatus)
    }
}
