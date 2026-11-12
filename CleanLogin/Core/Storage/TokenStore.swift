import Foundation

@MainActor
protocol TokenStore {
    func read() throws -> String?
    func save(_ token: LoginResponseDTO) throws
    func clear() throws
    func readRefreshToken() throws -> String?
}
