import Foundation
@testable import CleanLogin

@MainActor
final class RepositoryStub: AuthRepository {
    let user = User(id: "1", name: "Test", email: "demo@example.com")
    var receivedEmail: String?
    var receivedPassword: String?
    var loginCalls = 0
    var error: Error?

    func login(email: String, password: String) async throws -> User {
        loginCalls += 1
        receivedEmail = email
        receivedPassword = password
        if let error { throw error }
        return user
    }
    func restoreSession() async throws -> User? { user }
    func logout() throws {}
}

@MainActor
final class ServiceStub: AuthService {
    var loginResult = LoginResponseDTO(accessToken: "token", user: UserDTO(id: "1", fullName: "Test", email: "demo@example.com"))
    var error: Error?
    var meCalls = 0
    func login(email: String, password: String) async throws -> LoginResponseDTO {
        if let error { throw error }
        return loginResult
    }
    func me(token: String) async throws -> UserDTO {
        meCalls += 1
        if let error { throw error }
        return loginResult.user
    }
}

@MainActor
final class MemoryTokenStore: TokenStore {
    var token: String?
    var shouldFail = false
    init(token: String? = nil) { self.token = token }
    func read() throws -> String? {
        if shouldFail { throw Failure.storage }
        return token
    }
    func save(_ token: String) throws {
        if shouldFail { throw Failure.storage }
        self.token = token
    }
    func clear() throws {
        if shouldFail { throw Failure.storage }
        token = nil
    }
    enum Failure: Error { case storage }
}
