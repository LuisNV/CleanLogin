
import Foundation
import RxRelay
import RxCocoa

@MainActor
final class LoginViewModel {

    private let loginUseCase: any LoginUseCaseProtocol

    private let stateRelay: BehaviorRelay<LoginViewState>

    var onLoginSuccess: (() -> Void)?

    // Controller chỉ được đọc State
    var state: Driver<LoginViewState> {
        stateRelay.asDriver()
    }

    var currentState: LoginViewState {
        stateRelay.value
    }

    init(
        loginUseCase: any LoginUseCaseProtocol,
        initialMessage: String? = nil
    ) {
        self.loginUseCase = loginUseCase

        stateRelay = BehaviorRelay(
            value: LoginViewState(errorMessage: initialMessage)
        )
    }

    // MARK: - Validation

    private func validate(
        email: String,
        password: String
    ) -> Bool {

        var newState = LoginViewState()

        if email.isEmpty {
            newState.emailError = "Vui lòng nhập email hoặc số điện thoại"
        } else if !LoginIdentifier.isValid(email) {
            newState.emailError = AuthError.invalidLoginIdentifier.localizedDescription
        }

        if password.isEmpty {
            newState.passwordError = "Vui lòng nhập mật khẩu"
        }

        stateRelay.accept(newState)

        return newState.emailError == nil
            && newState.passwordError == nil
    }

    // MARK: - Login

    func login(email: String, password: String) async {

        guard !stateRelay.value.isLoading else {
            return
        }

        let email = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // 1. Validate dữ liệu
        guard validate(
            email: email,
            password: password
        ) else {
            return
        }

        // 2. Loading
        stateRelay.accept(
            LoginViewState(isLoading: true)
        )

        // 3. Call API
        do {
            try await loginUseCase.execute(
                email: email,
                password: password
            )

            try Task.checkCancellation()

            // 4. Thành công
            stateRelay.accept(LoginViewState())

            onLoginSuccess?()

        } catch {

            if error is CancellationError || Task.isCancelled {
                stateRelay.accept(LoginViewState())
                return
            }

            let message = (error as? AuthError)?
                .localizedDescription
                ?? AuthError.serviceUnavailable.localizedDescription

            stateRelay.accept(
                LoginViewState(errorMessage: message)
            )
        }
    }

    // MARK: - Clear Errors

    func clearEmailError() {
        var newState = stateRelay.value
        newState.emailError = nil
        stateRelay.accept(newState)
    }

    func clearPasswordError() {
        var newState = stateRelay.value
        newState.passwordError = nil
        stateRelay.accept(newState)
    }

    func clearGeneralError() {
        var newState = stateRelay.value
        newState.errorMessage = nil
        stateRelay.accept(newState)
    }
}
