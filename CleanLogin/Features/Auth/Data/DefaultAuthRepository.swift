import Foundation

@MainActor
final class DefaultAuthRepository: AuthRepository {
    private let service: any AuthService
    private let tokenStore: any TokenStore

    init(service: any AuthService, tokenStore: any TokenStore) {
        self.service = service
        self.tokenStore = tokenStore
    }

    func login(identifier: String, password: String) async throws {
        let response: LoginResponseDTO
        do {
            response = try await service.login(email: identifier, password: password)
            try Task.checkCancellation()
        } catch {
            throw AuthErrorMapper.map(error, context: .login)
        }

        guard !response.accessToken.isEmpty, !response.refreshToken.isEmpty else {
            throw AuthError.invalidResponse
        }

        do { try tokenStore.save(response.toTokens()) }
        catch { throw AuthError.secureStorageUnavailable }
    }

    func hasSavedSession() throws -> Bool {
        do { return try tokenStore.readAccessToken() != nil }
        catch { throw AuthError.secureStorageUnavailable }
    }

    func logout() async throws {
        let refreshToken: String?
        do { refreshToken = try tokenStore.readRefreshToken() }
        catch { throw AuthError.secureStorageUnavailable }

        if let refreshToken {
            // Thu hồi token trên server là "best effort": lỗi mạng không được chặn logout cục bộ.
            try? await service.logout(refreshToken: refreshToken)
        }

        do { try tokenStore.clear() }
        catch { throw AuthError.secureStorageUnavailable }
    }
}
