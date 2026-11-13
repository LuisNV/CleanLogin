import XCTest
@testable import CleanLogin

@MainActor
final class LoginUseCaseTests: XCTestCase {
    func testNormalizesIdentifierButPreservesPassword() async throws {
        let repository = AuthRepositoryStub()
        try await LoginUseCase(repository: repository).execute(identifier: " DEMO@EXAMPLE.COM \n", password: " secret ")
        XCTAssertEqual(repository.receivedIdentifier, "demo@example.com")
        XCTAssertEqual(repository.receivedPassword, " secret ")
    }

    func testAcceptsPhoneNumber() async throws {
        let repository = AuthRepositoryStub()
        try await LoginUseCase(repository: repository).execute(identifier: "0776426233", password: "123456")
        XCTAssertEqual(repository.receivedIdentifier, "0776426233")
    }

    func testInvalidIdentifierDoesNotCallRepository() async {
        let repository = AuthRepositoryStub()
        do {
            try await LoginUseCase(repository: repository).execute(identifier: "abc", password: "123456")
            XCTFail("Expected validation error")
        } catch { XCTAssertEqual(error as? AuthError, .invalidLoginIdentifier) }
        XCTAssertEqual(repository.loginCalls, 0)
    }

    func testEmptyPasswordDoesNotCallRepository() async {
        let repository = AuthRepositoryStub()
        do {
            try await LoginUseCase(repository: repository).execute(identifier: "demo@example.com", password: "")
            XCTFail("Expected validation error")
        } catch { XCTAssertEqual(error as? AuthError, .emptyFields) }
        XCTAssertEqual(repository.loginCalls, 0)
    }
}
