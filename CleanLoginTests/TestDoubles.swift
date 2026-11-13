import Foundation
@testable import CleanLogin

// MARK: - Core

@MainActor
final class MemoryTokenStore: TokenStore {
    var tokens: AuthTokens?
    var shouldFail = false

    init(tokens: AuthTokens? = nil) { self.tokens = tokens }

    func readAccessToken() throws -> String? {
        if shouldFail { throw Failure.storage }
        return tokens?.accessToken
    }
    func readRefreshToken() throws -> String? {
        if shouldFail { throw Failure.storage }
        return tokens?.refreshToken
    }
    func save(_ tokens: AuthTokens) throws {
        if shouldFail { throw Failure.storage }
        self.tokens = tokens
    }
    func clear() throws {
        if shouldFail { throw Failure.storage }
        tokens = nil
    }
    enum Failure: Error { case storage }
}

extension AuthTokens {
    static let sample = AuthTokens(accessToken: "access", refreshToken: "refresh")
}

extension User {
    static let sample = User(
        id: 1, fullName: "Nguyễn Văn Test", email: "demo@example.com", phone: "0900000000",
        address: "Hà Nội", dateOfBirth: "1998-02-22", avatarUrl: "", emailVerified: false
    )
}

// MARK: - Auth

@MainActor
final class AuthServiceStub: AuthService {
    var loginResult = LoginResponseDTO(accessToken: "access", tokenType: "Bearer", expiresIn: 900, refreshToken: "refresh")
    var loginError: Error?
    var logoutError: Error?
    var receivedLogoutToken: String?

    func login(email: String, password: String) async throws -> LoginResponseDTO {
        if let loginError { throw loginError }
        return loginResult
    }
    func logout(refreshToken: String) async throws {
        receivedLogoutToken = refreshToken
        if let logoutError { throw logoutError }
    }
}

@MainActor
final class AuthRepositoryStub: AuthRepository {
    var receivedIdentifier: String?
    var receivedPassword: String?
    var loginCalls = 0
    var error: Error?

    func login(identifier: String, password: String) async throws {
        loginCalls += 1
        receivedIdentifier = identifier
        receivedPassword = password
        if let error { throw error }
    }
    func hasSavedSession() throws -> Bool { true }
    func logout() async throws { if let error { throw error } }
}

@MainActor
final class LogoutUseCaseStub: LogoutUseCaseProtocol {
    var calls = 0
    var error: Error?
    func execute() async throws {
        calls += 1
        if let error { throw error }
    }
}

// MARK: - Profile

@MainActor
final class UserServiceStub: UserService {
    var result = UserDTO(
        id: 1, fullName: "Nguyễn Văn Test", email: "demo@example.com", phone: "0900000000",
        address: "Hà Nội", dateOfBirth: "1998-02-22", avatarUrl: "", emailVerified: false
    )
    var error: Error?
    func me() async throws -> UserDTO {
        if let error { throw error }
        return result
    }
}

@MainActor
final class GetCurrentUserUseCaseStub: GetCurrentUserUseCaseProtocol {
    var result: User = .sample
    var error: Error?
    func execute() async throws -> User {
        if let error { throw error }
        return result
    }
}
