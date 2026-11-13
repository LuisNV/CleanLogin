import Foundation

@MainActor
protocol AuthService {
    func login(email: String, password: String) async throws -> LoginResponseDTO
    func logout(refreshToken: String) async throws
}
