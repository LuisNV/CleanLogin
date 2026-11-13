import XCTest
@testable import CleanLogin

@MainActor
final class AuthRepositoryTests: XCTestCase {
    func testLoginSavesBothTokens() async throws {
        let store = MemoryTokenStore()
        let repository = DefaultAuthRepository(service: AuthServiceStub(), tokenStore: store)
        try await repository.login(identifier: "demo@example.com", password: "123456")
        XCTAssertEqual(store.tokens, AuthTokens(accessToken: "access", refreshToken: "refresh"))
    }

    func testWrongCredentialsDoNotSaveToken() async {
        let service = AuthServiceStub()
        service.loginError = APIError.http(401)
        let store = MemoryTokenStore()
        do {
            try await DefaultAuthRepository(service: service, tokenStore: store).login(identifier: "x", password: "x")
            XCTFail("Expected invalid credentials")
        } catch { XCTAssertEqual(error as? AuthError, .invalidCredentials) }
        XCTAssertNil(store.tokens)
    }

    func testNetworkFailureMapsToNetworkUnavailable() async {
        let service = AuthServiceStub()
        service.loginError = APIError.transport
        do {
            try await DefaultAuthRepository(service: service, tokenStore: MemoryTokenStore()).login(identifier: "x", password: "x")
            XCTFail("Expected network error")
        } catch { XCTAssertEqual(error as? AuthError, .networkUnavailable) }
    }

    func testStorageFailurePreventsSuccessfulLogin() async {
        let store = MemoryTokenStore()
        store.shouldFail = true
        do {
            try await DefaultAuthRepository(service: AuthServiceStub(), tokenStore: store).login(identifier: "x", password: "x")
            XCTFail("Expected storage error")
        } catch { XCTAssertEqual(error as? AuthError, .secureStorageUnavailable) }
    }

    func testEmptyTokenIsRejected() async {
        let service = AuthServiceStub()
        service.loginResult = LoginResponseDTO(accessToken: "", tokenType: "Bearer", expiresIn: 900, refreshToken: "refresh")
        let store = MemoryTokenStore()
        do {
            try await DefaultAuthRepository(service: service, tokenStore: store).login(identifier: "x", password: "x")
            XCTFail("Expected invalid response")
        } catch { XCTAssertEqual(error as? AuthError, .invalidResponse) }
        XCTAssertNil(store.tokens)
    }

    func testEmptyRefreshTokenIsRejected() async {
        let service = AuthServiceStub()
        service.loginResult = LoginResponseDTO(accessToken: "access", tokenType: "Bearer", expiresIn: 900, refreshToken: "")
        let store = MemoryTokenStore()
        do {
            try await DefaultAuthRepository(service: service, tokenStore: store).login(identifier: "x", password: "x")
            XCTFail("Expected invalid response")
        } catch { XCTAssertEqual(error as? AuthError, .invalidResponse) }
        XCTAssertNil(store.tokens)
    }

    func testHasSavedSession() throws {
        XCTAssertTrue(try DefaultAuthRepository(service: AuthServiceStub(), tokenStore: MemoryTokenStore(tokens: .sample)).hasSavedSession())
        XCTAssertFalse(try DefaultAuthRepository(service: AuthServiceStub(), tokenStore: MemoryTokenStore()).hasSavedSession())
    }

    func testLogoutRevokesRefreshTokenAndClearsStore() async throws {
        let service = AuthServiceStub()
        let store = MemoryTokenStore(tokens: .sample)
        try await DefaultAuthRepository(service: service, tokenStore: store).logout()
        XCTAssertEqual(service.receivedLogoutToken, "refresh")
        XCTAssertNil(store.tokens)
    }

    func testLogoutClearsStoreEvenWhenServerFails() async throws {
        let service = AuthServiceStub()
        service.logoutError = APIError.transport
        let store = MemoryTokenStore(tokens: .sample)
        try await DefaultAuthRepository(service: service, tokenStore: store).logout()
        XCTAssertNil(store.tokens)
    }

    /// Hồi quy: mock trước đây trả refresh token rỗng nên login ở mode mock luôn lỗi.
    func testMockServiceLoginProducesStorableSession() async throws {
        let store = MemoryTokenStore()
        let repository = DefaultAuthRepository(service: MockAuthService(), tokenStore: store)
        try await repository.login(identifier: DemoAccount.email, password: DemoAccount.password)
        XCTAssertEqual(store.tokens?.refreshToken.isEmpty, false)
        XCTAssertEqual(store.tokens?.accessToken.isEmpty, false)
    }
}
