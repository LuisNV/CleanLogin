import UIKit

/// Lắp ráp feature Profile từ các phụ thuộc dùng chung.
@MainActor
final class ProfileFactory {
    private let getCurrentUserUseCase: any GetCurrentUserUseCaseProtocol
    private let logoutUseCase: any LogoutUseCaseProtocol

    /// `logoutUseCase` đến từ feature Auth qua AppContainer; Profile không tự tạo phần của Auth.
    init(service: any UserService, logoutUseCase: any LogoutUseCaseProtocol) {
        getCurrentUserUseCase = GetCurrentUserUseCase(
            repository: DefaultUserRepository(service: service)
        )
        self.logoutUseCase = logoutUseCase
    }

    func makeProfile(onLogout: @escaping () -> Void) -> ProfileViewController {
        let viewModel = ProfileViewModel(
            getCurrentUserUseCase: getCurrentUserUseCase,
            logoutUseCase: logoutUseCase
        )
        viewModel.onLogoutSuccess = onLogout
        return ProfileViewController(viewModel: viewModel)
    }

    func makeEditProfile(draft: ProfileEditDraft) -> EditProfileViewController {
        EditProfileViewController(draft: draft)
    }
}
