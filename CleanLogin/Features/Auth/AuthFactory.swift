import UIKit

/// Lắp ráp feature Auth. `AppContainer` chỉ đưa vào phụ thuộc dùng chung
/// (service, token store); feature tự biết cách tạo UseCase, ViewModel, màn hình.
@MainActor
final class AuthFactory {
    let restoreSessionUseCase: any RestoreSessionUseCaseProtocol
    let logoutUseCase: any LogoutUseCaseProtocol
    private let loginUseCase: any LoginUseCaseProtocol
    private let modeTitle: String
    private let showDemoCredentials: Bool

    init(service: any AuthService, tokenStore: any TokenStore, modeTitle: String, showDemoCredentials: Bool) {
        let repository = DefaultAuthRepository(service: service, tokenStore: tokenStore)
        loginUseCase = LoginUseCase(repository: repository)
        restoreSessionUseCase = RestoreSessionUseCase(repository: repository)
        logoutUseCase = LogoutUseCase(repository: repository)
        self.modeTitle = modeTitle
        self.showDemoCredentials = showDemoCredentials
    }

    func makeLogin(message: String? = nil, onSuccess: @escaping () -> Void) -> LoginViewController {
        let viewModel = LoginViewModel(loginUseCase: loginUseCase, initialMessage: message)
        viewModel.onLoginSuccess = onSuccess
        return LoginViewController(
            viewModel: viewModel,
            modeTitle: modeTitle,
            showDemoCredentials: showDemoCredentials
        )
    }
}
