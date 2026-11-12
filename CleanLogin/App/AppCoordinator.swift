import UIKit

@MainActor
final class AppCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let container: AppContainer
    private var bootstrapTask: Task<Void, Never>?
    
    init(navigationController: UINavigationController, container: AppContainer) {
        self.navigationController = navigationController
        self.container = container
    }
    
    func start() {
        bootstrapTask?.cancel()
        
        let screen = BootstrapViewController()
        
        screen.onRetry = { [weak self] in
            self?.start()
        }
        
        screen.onReset = { [weak self, weak screen] in
            guard let self else { return }
            
            Task { @MainActor [weak self, weak screen] in
                guard let self else { return }
                
                do {
                    try await self.container.logoutUseCase.execute()
                    self.showLogin()
                } catch {
                    screen?.showError(error.localizedDescription)
                }
            }
        }
        
        navigationController.setViewControllers(
            [screen],
            animated: false
        )
        
        screen.showLoading()
        
        let useCase = container.restoreSessionUseCase
        
        bootstrapTask = Task { [weak self, weak screen, useCase] in
            do {
                let token = try await useCase.execute()
                
                try Task.checkCancellation()
                
                if token != nil {
                    self?.showHome()
                } else {
                    self?.showLogin()
                }
                
            } catch is CancellationError {
                return
            } catch {
                if !Task.isCancelled {
                    screen?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func showLogin(message: String? = nil) {
        let screen = container.makeLogin(
            message: message
        ) { [weak self] in
            // Được gọi khi đăng nhập thành công
            self?.showHome()
        }
        
        navigationController.setViewControllers(
            [screen],
            animated: false
        )
    }
    
    private func showHome() {
        let homeVC = container.makeHome()
        
        let listeningVC = UIViewController()
        let progressVC = UIViewController()
        let profileVC = container.makeAbout( onSuccess:  { [weak self] in
            Task { @MainActor [weak self] in
                await self?.logout()
            }
        } )
        
        let tabBarController = MainTabBarController(
            home: homeVC,
            listening: listeningVC,
            progress: progressVC,
            profile: profileVC
        )
        
        navigationController.setViewControllers(
            [tabBarController],
            animated: true
        )
        
        navigationController.setNavigationBarHidden(
            true,
            animated: false
        )
    }
    private func showAbout() {
        //                let screen = container.makeAbout(
        //                    onSuccess:  { [weak self] in
        //                        Task { @MainActor [weak self] in
        //                            await self?.logout()
        //                        }
        //                    }
        //                )
        //
        //        navigationController.setViewControllers(
        //            [screen],
        //            animated: true
        //        )
    }
    @MainActor
    func logout() async {
        showLogin()
    }
}
