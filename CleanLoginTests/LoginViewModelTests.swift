import XCTest
import RxSwift
import RxCocoa
@testable import CleanLogin

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testLoadingThenSuccessAndNavigation() async {
        let repository = RepositoryStub()
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
        var states: [LoginViewState] = []
        var navigatedUser: User?
        let subscription = viewModel.state.drive(onNext: { states.append($0) })
        defer { subscription.dispose() }
        viewModel.onLoginSuccess = { navigatedUser = $0 }
        await viewModel.login(email: "demo@example.com", password: "123456")
        XCTAssertEqual(states.map(\.isLoading), [false, true, false])
        XCTAssertEqual(navigatedUser, repository.user)
    }

    func testFailureDoesNotNavigate() async {
        let repository = RepositoryStub()
        repository.error = AuthError.invalidCredentials
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
        var navigated = false
        viewModel.onLoginSuccess = { _ in navigated = true }
        await viewModel.login(email: "demo@example.com", password: "wrong")
        XCTAssertFalse(navigated)
        XCTAssertFalse(viewModel.currentState.isLoading)
        XCTAssertEqual(viewModel.currentState.errorMessage, AuthError.invalidCredentials.localizedDescription)
    }

    func testCancellationDoesNotShowErrorOrNavigate() async {
        let repository = RepositoryStub()
        repository.error = CancellationError()
        let viewModel = LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
        var navigated = false
        viewModel.onLoginSuccess = { _ in navigated = true }
        await viewModel.login(email: "demo@example.com", password: "123456")
        XCTAssertFalse(navigated)
        XCTAssertEqual(viewModel.currentState, LoginViewState())
    }
}
