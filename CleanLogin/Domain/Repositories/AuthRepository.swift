import Foundation

// Domain không import UIKit, RxSwift, Alamofire hoặc Security.
@MainActor
protocol AuthRepository {
    func login(email: String, password: String) async throws -> LoginResponseDTO
    func restoreSession() async throws -> String?
    func logout() async throws
    func getUser(id: String) async throws -> User?
    func getMe() async throws -> User?
    func refresh() async throws -> LoginResponseDTO
}
