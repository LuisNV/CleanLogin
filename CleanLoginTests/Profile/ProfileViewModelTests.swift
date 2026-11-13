import XCTest
@testable import CleanLogin

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testLoadUserSuccess() async {
        let viewModel = ProfileViewModel(getCurrentUserUseCase: GetCurrentUserUseCaseStub(), logoutUseCase: LogoutUseCaseStub())
        await viewModel.loadUser()
        XCTAssertEqual(viewModel.currentState, ProfileViewState(user: .sample))
    }

    func testLoadUserFailureShowsMessage() async {
        let useCase = GetCurrentUserUseCaseStub()
        useCase.error = AuthError.networkUnavailable
        let viewModel = ProfileViewModel(getCurrentUserUseCase: useCase, logoutUseCase: LogoutUseCaseStub())
        await viewModel.loadUser()
        XCTAssertNil(viewModel.currentState.user)
        XCTAssertEqual(viewModel.currentState.errorMessage, AuthError.networkUnavailable.localizedDescription)
    }

    func testLogoutSuccessNotifiesCoordinator() async {
        let logout = LogoutUseCaseStub()
        let viewModel = ProfileViewModel(getCurrentUserUseCase: GetCurrentUserUseCaseStub(), logoutUseCase: logout)
        var loggedOut = false
        viewModel.onLogoutSuccess = { loggedOut = true }
        await viewModel.logout()
        XCTAssertEqual(logout.calls, 1)
        XCTAssertTrue(loggedOut)
    }

    func testLogoutFailureKeepsUserAndShowsMessage() async {
        let logout = LogoutUseCaseStub()
        logout.error = AuthError.secureStorageUnavailable
        let viewModel = ProfileViewModel(getCurrentUserUseCase: GetCurrentUserUseCaseStub(), logoutUseCase: logout)
        var loggedOut = false
        viewModel.onLogoutSuccess = { loggedOut = true }
        await viewModel.loadUser()
        await viewModel.logout()
        XCTAssertFalse(loggedOut)
        XCTAssertEqual(viewModel.currentState.user, .sample)
        XCTAssertEqual(viewModel.currentState.errorMessage, AuthError.secureStorageUnavailable.localizedDescription)
    }
}
