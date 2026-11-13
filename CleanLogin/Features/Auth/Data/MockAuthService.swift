import Foundation

@MainActor
final class MockAuthService: AuthService {
    static let accessToken = "mock-access-token-for-learning-only"
    static let refreshToken = "mock-refresh-token-for-learning-only"

    func login(email: String, password: String) async throws -> LoginResponseDTO {
        try await Task.sleep(nanoseconds: 650_000_000)
        guard email == DemoAccount.email || email == DemoAccount.phone,
              password == DemoAccount.password else {
            throw APIError.http(401)
        }
        // Refresh token phải khác rỗng, nếu không Keychain sẽ từ chối lưu phiên.
        return LoginResponseDTO(
            accessToken: Self.accessToken,
            tokenType: "Bearer",
            expiresIn: 900,
            refreshToken: Self.refreshToken
        )
    }

    func logout(refreshToken: String) async throws {}
}
