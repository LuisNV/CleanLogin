import UIKit

// Composition root. Chỉ nơi này chọn implementation cụ thể (mock hay API)
// và chia phụ thuộc dùng chung cho factory của từng feature.
@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    let auth: AuthFactory
    let profile: ProfileFactory

    /// Phiên hết hạn và không refresh được. AppCoordinator đăng ký để đưa người dùng về Login.
    var onSessionExpired: (() -> Void)?

    init(configuration: AppConfiguration) {
        self.configuration = configuration

        // 1. Một token store dùng chung cho APIClient và repository.
        let tokenStore = KeychainTokenStore(service: configuration.tokenNamespace)

        // 2. Chọn service theo môi trường.
        let authService: any AuthService
        let userService: any UserService
        let client: APIClient?

        switch configuration.mode {
        case .mock:
            authService = MockAuthService()
            userService = MockUserService()
            client = nil

        case .localAPI, .remoteAPI:
            // AppConfiguration.load đã kiểm tra URL của hai mode này.
            guard let baseURL = configuration.baseURL else {
                preconditionFailure("AppConfiguration phải có baseURL cho mode \(configuration.mode)")
            }
            let apiClient = APIClient(baseURL: baseURL, tokenStore: tokenStore)
            authService = RemoteAuthService(client: apiClient)
            userService = RemoteUserService(client: apiClient)
            client = apiClient
        }

        // 3. Mỗi feature tự lắp ráp UseCase/ViewModel của mình.
        auth = AuthFactory(
            service: authService,
            tokenStore: tokenStore,
            modeTitle: configuration.title,
            showDemoCredentials: configuration.mode != .remoteAPI
        )
        profile = ProfileFactory(service: userService, logoutUseCase: auth.logoutUseCase)

        client?.onSessionExpired = { [weak self] in
            self?.onSessionExpired?()
        }
    }

    func makeHome() -> HomeViewController {
        HomeViewController(viewModel: HomeViewModel())
    }
}
