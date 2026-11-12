import Foundation

@MainActor
protocol AuthService {
    func login(email: String, password: String) async throws -> LoginResponseDTO
    func me() async throws -> UserDTO?
    func getUser(id: String) async throws -> UserDTO?
    func logout(refreshToken: String) async throws
    func refresh(refreshToken: String) async throws -> LoginResponseDTO
}
