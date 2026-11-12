import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        let navigation = UINavigationController()
        window.rootViewController = navigation
        do {
            let container = AppContainer(configuration: try AppConfiguration.load())
            let coordinator = AppCoordinator(navigationController: navigation, container: container)
            self.coordinator = coordinator
            coordinator.start()
        } catch {
            let screen = BootstrapViewController()
            navigation.setViewControllers([screen], animated: false)
            screen.showError(error.localizedDescription, canRetry: false)
        }
        window.makeKeyAndVisible()
    }
}
