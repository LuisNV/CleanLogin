import Foundation
import RxRelay
import RxCocoa

struct ProfileViewState: Equatable {
    var user: User?
    var isLoading = false
    var errorMessage: String?
}

@MainActor
final class ProfileViewModel {
    private let getCurrentUserUseCase: any GetCurrentUserUseCaseProtocol
    private let logoutUseCase: any LogoutUseCaseProtocol
    private let stateRelay: BehaviorRelay<ProfileViewState>

    var onLogoutSuccess: (() -> Void)?
    var state: Driver<ProfileViewState> { stateRelay.asDriver() }
    var currentState: ProfileViewState { stateRelay.value }

    init(
        getCurrentUserUseCase: any GetCurrentUserUseCaseProtocol,
        logoutUseCase: any LogoutUseCaseProtocol
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        stateRelay = BehaviorRelay(value: ProfileViewState())
    }

    func loadUser() async {
        guard !stateRelay.value.isLoading else { return }
        let previousUser = stateRelay.value.user
        stateRelay.accept(ProfileViewState(user: previousUser, isLoading: true))

        do {
            let user = try await getCurrentUserUseCase.execute()
            try Task.checkCancellation()
            stateRelay.accept(ProfileViewState(user: user))
        } catch {
            // Giữ lại user cũ (nếu có) để màn hình không bị trống khi lỗi.
            if ErrorMessage.isCancellation(error) {
                stateRelay.accept(ProfileViewState(user: previousUser))
                return
            }
            stateRelay.accept(ProfileViewState(user: previousUser, errorMessage: ErrorMessage.from(error)))
        }
    }

    func logout() async {
        guard !stateRelay.value.isLoading else { return }
        let user = stateRelay.value.user
        stateRelay.accept(ProfileViewState(user: user, isLoading: true))

        do {
            try await logoutUseCase.execute()
            stateRelay.accept(ProfileViewState())
            onLogoutSuccess?()
        } catch {
            if ErrorMessage.isCancellation(error) {
                stateRelay.accept(ProfileViewState(user: user))
                return
            }
            stateRelay.accept(ProfileViewState(user: user, errorMessage: ErrorMessage.from(error)))
        }
    }
}
