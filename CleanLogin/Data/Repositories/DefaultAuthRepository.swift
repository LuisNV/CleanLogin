import Foundation

@MainActor
final class DefaultAuthRepository: AuthRepository {
    func refresh() async throws -> LoginResponseDTO {
        
        guard let refreshToken = try tokenStore.readRefreshToken(),
              !refreshToken.isEmpty else {
            throw AuthError.sessionExpired
        }
        
        let response = try await service.refresh(
            refreshToken: refreshToken
        )
        
        guard !response.accessToken.isEmpty else {
            throw AuthError.invalidResponse
        }
        
        try tokenStore.save(response)
        
        return response
    }
    
    
    
    func getMe() async throws -> User? {
        do {
            let dto = try await service.me()
            try Task.checkCancellation()
            guard let dto else { throw AuthError.invalidResponse }
            return dto.toDomain()
        } catch let error as APIError where error.statusCode == 401 {
            // Chỉ xóa token khi backend xác nhận không còn hợp lệ.
            try await logout()
            return nil
        } catch {
            throw mapServiceError(error, login: false)
        }
    }
    
    
    private let service: any AuthService
    private let tokenStore: any TokenStore
    
    init(service: any AuthService, tokenStore: any TokenStore) {
        self.service = service
        self.tokenStore = tokenStore
    }
    
    func login(email: String, password: String) async throws -> LoginResponseDTO {
        let response: LoginResponseDTO
        do {
            response = try await service.login(email: email, password: password)
            try Task.checkCancellation()
        } catch {
            throw mapServiceError(error, login: true)
        }
        guard !response.accessToken.isEmpty else {
            throw AuthError.invalidResponse
        }
        do { try tokenStore.save(response) }
        catch { throw AuthError.secureStorageUnavailable }
        return response
    }
    
    func restoreSession() async throws -> String? {
        let token: String?
        do { token = try tokenStore.read() }
        catch { throw AuthError.secureStorageUnavailable }
        guard let token else { return nil }
        return token
    }
    
    func logout() async throws {
        // Logout cục bộ; hợp đồng mẫu không có revoke endpoint.
        let refreshToken: String?
        do {
            refreshToken = try tokenStore.readRefreshToken()
        } catch {
            throw AuthError.secureStorageUnavailable
        }
        if let refreshToken {
            do {
                try await service.logout(
                    refreshToken: refreshToken
                )
            } catch {
                print("Remote logout failed: \(error)")
            }
        }
        do { try tokenStore.clear() }
        catch { throw AuthError.secureStorageUnavailable }
    }
    
    func getUser(id: String) async throws -> User? {
        do {
            let dto = try await service.getUser(id: id)
            try Task.checkCancellation()
            guard let dto else { throw AuthError.invalidResponse }
            return dto.toDomain()
        } catch let error as APIError where error.statusCode == 401 {
            // Chỉ xóa token khi backend xác nhận không còn hợp lệ.
            try await logout()
            return nil
        } catch {
            throw mapServiceError(error, login: false)
        }
        
        
    }
    
    private func mapServiceError(_ error: Error, login: Bool) -> Error {
        if error is CancellationError || Task.isCancelled { return CancellationError() }
        if let authError = error as? AuthError { return authError }
        guard let apiError = error as? APIError else { return AuthError.serviceUnavailable }
        if apiError.statusCode == 401 {
            return login ? AuthError.invalidCredentials : AuthError.sessionExpired
        }
        switch apiError {
        case .http(401): return login ? AuthError.invalidCredentials : AuthError.sessionExpired
        case .http, .server: return AuthError.serviceUnavailable
        case .transport: return AuthError.networkUnavailable
        case .decoding, .invalidResponse: return AuthError.invalidResponse
        case .invalidURL: return AuthError.invalidURL
        case .missingToken: return AuthError.networkUnavailable
        }
    }
}
