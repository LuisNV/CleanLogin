import UIKit

@MainActor
final class AppCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let container: AppContainer
    private var childCoordinators: [any Coordinator] = []

    init(navigationController: UINavigationController, container: AppContainer) {
        self.navigationController = navigationController
        self.container = container

        container.onSessionExpired = { [weak self] in
            self?.handleSessionExpired()
        }
    }

    func start() {
        let screen = BootstrapViewController()

        screen.onRetry = { [weak self] in
            self?.start()
        }

        screen.onReset = { [weak self, weak screen] in
            Task { @MainActor [weak self, weak screen] in
                guard let self else { return }
                do {
                    try await self.container.auth.logoutUseCase.execute()
                    self.showLogin()
                } catch {
                    screen?.showError(ErrorMessage.from(error))
                }
            }
        }

        navigationController.setViewControllers([screen], animated: false)
        screen.showLoading()

        do {
            if try container.auth.restoreSessionUseCase.execute() {
                showHome()
            } else {
                showLogin()
            }
        } catch {
            screen.showError(ErrorMessage.from(error))
        }
    }

    // MARK: - Flows

    private func showLogin(message: String? = nil) {
        childCoordinators.removeAll()

        let screen = container.auth.makeLogin(message: message) { [weak self] in
            self?.showHome()
        }
        navigationController.setViewControllers([screen], animated: false)
    }

    private func showHome() {
        let profileCoordinator = ProfileCoordinator(factory: container.profile)
        profileCoordinator.onLogout = { [weak self] in
            self?.showLogin()
        }
        profileCoordinator.start()
        childCoordinators = [profileCoordinator]

        // Listening và Progress chưa có feature, tạm dùng màn trống.
        let tabBarController = MainTabBarController(
            home: container.makeHome(),
            listening: UIViewController(),
            progress: UIViewController(),
            profile: profileCoordinator.navigationController
        )

        navigationController.setViewControllers([tabBarController], animated: true)
        navigationController.setNavigationBarHidden(true, animated: false)
    }

    private func handleSessionExpired() {
        // Nhiều request có thể cùng hết phiên; chỉ chuyển màn một lần.
        guard !(navigationController.viewControllers.first is LoginViewController) else { return }
        showLogin(message: AuthError.sessionExpired.localizedDescription)
    }
}
