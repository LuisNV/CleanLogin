import Foundation

@MainActor
final class RemoteAuthService: AuthService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> LoginResponseDTO {
        try await client.post(
            path: "auth/login",
            body: LoginRequestDTO(email: email, password: password),
            as: LoginResponseDTO.self
        )
    }

    func logout(refreshToken: String) async throws {
        try await client.post(
            path: "auth/logout",
            body: LogoutRequestDTO(refreshToken: refreshToken)
        )
    }
}
