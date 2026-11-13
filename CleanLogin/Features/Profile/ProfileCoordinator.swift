import UIKit

/// Điều hướng bên trong tab Cá nhân. Màn hình không tự push màn khác.
@MainActor
final class ProfileCoordinator: Coordinator {
    let navigationController = UINavigationController()

    /// Báo ra ngoài (AppCoordinator) khi người dùng đăng xuất.
    var onLogout: (() -> Void)?

    private let factory: ProfileFactory

    init(factory: ProfileFactory) {
        self.factory = factory
    }

    func start() {
        let profile = factory.makeProfile { [weak self] in
            self?.onLogout?()
        }
        profile.onEditTapped = { [weak self, weak profile] draft in
            guard let self, let profile else { return }
            self.showEditProfile(draft: draft, from: profile)
        }
        navigationController.setViewControllers([profile], animated: false)
    }

    private func showEditProfile(draft: ProfileEditDraft, from profile: ProfileViewController) {
        let screen = factory.makeEditProfile(draft: draft)
        screen.onSave = { [weak profile] draft in
            profile?.apply(editedDraft: draft)
        }
        navigationController.pushViewController(screen, animated: true)
    }
}
