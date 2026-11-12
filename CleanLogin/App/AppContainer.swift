import UIKit

// Composition root. Chỉ nơi này biết implementation cụ thể của các tầng.
@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    private let loginUseCase: any LoginUseCaseProtocol
    let restoreSessionUseCase: any RestoreSessionUseCaseProtocol
    let logoutUseCase: any LogoutUseCaseProtocol
    let getUserUseCase: any GetUserUseCaseProtocol
    
    init(configuration: AppConfiguration) {
        self.configuration = configuration
        
        // 1. Tạo nơi lưu và đọc token trước
        let store = KeychainTokenStore(
            service: configuration.tokenNamespace
        )
        
        // 2. Tạo service theo môi trường
        let service: any AuthService
        
        switch configuration.mode {
        case .mock:
            service = MockAuthService()
            
        case .localAPI, .remoteAPI:
            // AppConfiguration.load đã kiểm tra URL của hai mode này.
            let client = APIClient(
                baseURL: configuration.baseURL!,
                tokenStore: store,
                tokenProvider: {
                    try store.read()
                },
                refreshToken: {
                    try store.readRefreshToken()
                }
            )
            
            service = RemoteAuthService(client: client)
        }
        
        // 3. Repository dùng cùng store với APIClient
        let repository = DefaultAuthRepository(
            service: service,
            tokenStore: store
        )
        
        // 4. Tạo các UseCase
        loginUseCase = LoginUseCase(repository: repository)
        
        restoreSessionUseCase = RestoreSessionUseCase(
            repository: repository
        )
        
        logoutUseCase = LogoutUseCase(repository: repository)
        
        getUserUseCase = GetUserUseCase(repository: repository)
    }
    
    func makeLogin(message: String? = nil, onSuccess: @escaping () -> Void) -> LoginViewController {
        let viewModel = LoginViewModel(loginUseCase: loginUseCase, initialMessage: message)
        viewModel.onLoginSuccess = onSuccess
        return LoginViewController(viewModel: viewModel, modeTitle: configuration.title,
                                   showDemoCredentials: configuration.mode != .remoteAPI)
    }
    
    func makeHome() -> HomeViewController {
        let viewModel = HomeViewModel()
       
        return HomeViewController(viewModel: viewModel)
    }
    func makeAbout(onSuccess: @escaping () -> Void) -> ProfileViewController{
        let viewModel = ProfileViewModel(getUserUseCase: getUserUseCase,logoutUseCase: logoutUseCase)
        viewModel.onLogoutSuccess = onSuccess
        return ProfileViewController(
            viewModel: viewModel
        )
    }
}
