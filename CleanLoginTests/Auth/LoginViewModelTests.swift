import XCTest
import RxSwift
import RxCocoa
@testable import CleanLogin

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testLoadingThenSuccessAndNavigation() async {
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: AuthRepositoryStub()))
        var states: [LoginViewState] = []
        var navigated = false
        let subscription = viewModel.state.drive(onNext: { states.append($0) })
        defer { subscription.dispose() }
        viewModel.onLoginSuccess = { navigated = true }

        await viewModel.login(email: "demo@example.com", password: "123456")

        XCTAssertEqual(states.map(\.isLoading), [false, false, true, false])
        XCTAssertTrue(navigated)
    }

    func testFailureDoesNotNavigate() async {
        let repository = AuthRepositoryStub()
        repository.error = AuthError.invalidCredentials
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
        var navigated = false
        viewModel.onLoginSuccess = { navigated = true }

        await viewModel.login(email: "demo@example.com", password: "wrong")

        XCTAssertFalse(navigated)
        XCTAssertFalse(viewModel.currentState.isLoading)
        XCTAssertEqual(viewModel.currentState.errorMessage, AuthError.invalidCredentials.localizedDescription)
    }

    func testValidationErrorDoesNotCallRepository() async {
        let repository = AuthRepositoryStub()
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: repository))

        await viewModel.login(email: "abc", password: "")

        XCTAssertEqual(repository.loginCalls, 0)
        XCTAssertNotNil(viewModel.currentState.emailError)
        XCTAssertNotNil(viewModel.currentState.passwordError)
    }

    func testCancellationDoesNotShowErrorOrNavigate() async {
        let repository = AuthRepositoryStub()
        repository.error = CancellationError()
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
        var navigated = false
        viewModel.onLoginSuccess = { navigated = true }

        await viewModel.login(email: "demo@example.com", password: "123456")

        XCTAssertFalse(navigated)
        XCTAssertEqual(viewModel.currentState, LoginViewState())
    }
}
