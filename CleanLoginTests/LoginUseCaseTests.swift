import XCTest
@testable import CleanLogin

@MainActor
final class LoginUseCaseTests: XCTestCase {
    func testNormalizesEmailButPreservesPassword() async throws {
        let repository = RepositoryStub()
        let useCase = LoginUseCase(repository: repository)
        _ = try await useCase.execute(email: " DEMO@EXAMPLE.COM \n", password: " secret ")
        XCTAssertEqual(repository.receivedEmail, "demo@example.com")
        XCTAssertEqual(repository.receivedPassword, " secret ")
    }

    func testInvalidEmailDoesNotCallRepository() async {
        let repository = RepositoryStub()
        do {
            _ = try await LoginUseCase(repository: repository).execute(email: "abc", password: "123456")
            XCTFail("Expected validation error")
        } catch { XCTAssertEqual(error as? AuthError, .invalidLoginIdentifier) }
        XCTAssertEqual(repository.loginCalls, 0)
    }

    func testEmptyPasswordDoesNotCallRepository() async {
        let repository = RepositoryStub()
        do {
            _ = try await LoginUseCase(repository: repository).execute(email: "demo@example.com", password: "")
            XCTFail("Expected validation error")
        } catch { XCTAssertEqual(error as? AuthError, .emptyFields) }
        XCTAssertEqual(repository.loginCalls, 0)
    }
}
