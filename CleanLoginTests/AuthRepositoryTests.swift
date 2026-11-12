import XCTest
@testable import CleanLogin

@MainActor
final class AuthRepositoryTests: XCTestCase {
    func testLoginMapsUserAndSavesToken() async throws {
        let store = MemoryTokenStore()
        let repository = DefaultAuthRepository(service: ServiceStub(), tokenStore: store)
        let user = try await repository.login(email: "demo@example.com", password: "123456")
        XCTAssertEqual(user.name, "Test")
        XCTAssertEqual(store.token, "token")
    }

    func testWrongCredentialsDoNotSaveToken() async {
        let service = ServiceStub()
        service.error = APIError.http(401)
        let store = MemoryTokenStore()
        do {
            _ = try await DefaultAuthRepository(service: service, tokenStore: store).login(email: "x", password: "x")
            XCTFail("Expected invalid credentials")
        } catch { XCTAssertEqual(error as? AuthError, .invalidCredentials) }
        XCTAssertNil(store.token)
    }

    func testExpiredSessionClearsToken() async throws {
        let service = ServiceStub()
        service.error = APIError.http(401)
        let store = MemoryTokenStore(token: "expired")
        let user = try await DefaultAuthRepository(service: service, tokenStore: store).restoreSession()
        XCTAssertNil(user)
        XCTAssertNil(store.token)
    }

    func testNetworkFailurePreservesToken() async {
        let service = ServiceStub()
        service.error = APIError.transport
        let store = MemoryTokenStore(token: "valid")
        do {
            _ = try await DefaultAuthRepository(service: service, tokenStore: store).restoreSession()
            XCTFail("Expected network error")
        } catch { XCTAssertEqual(error as? AuthError, .networkUnavailable) }
        XCTAssertEqual(store.token, "valid")
    }

    func testNoTokenSkipsNetwork() async throws {
        let service = ServiceStub()
        let user = try await DefaultAuthRepository(service: service, tokenStore: MemoryTokenStore()).restoreSession()
        XCTAssertNil(user)
        XCTAssertEqual(service.meCalls, 0)
    }

    func testStorageFailurePreventsSuccessfulLogin() async {
        let store = MemoryTokenStore()
        store.shouldFail = true
        do {
            _ = try await DefaultAuthRepository(service: ServiceStub(), tokenStore: store).login(email: "x", password: "x")
            XCTFail("Expected storage error")
        } catch { XCTAssertEqual(error as? AuthError, .secureStorageUnavailable) }
    }

    func testEmptyTokenIsRejected() async {
        let service = ServiceStub()
        service.loginResult = LoginResponseDTO(accessToken: "", user: service.loginResult.user)
        let store = MemoryTokenStore()
        do {
            _ = try await DefaultAuthRepository(service: service, tokenStore: store).login(email: "x", password: "x")
            XCTFail("Expected invalid response")
        } catch { XCTAssertEqual(error as? AuthError, .invalidResponse) }
        XCTAssertNil(store.token)
    }

    func testLogoutClearsToken() throws {
        let store = MemoryTokenStore(token: "saved")
        try DefaultAuthRepository(service: ServiceStub(), tokenStore: store).logout()
        XCTAssertNil(store.token)
    }
}
