import Foundation

struct LoginViewState: Equatable {
    var isLoading = false
    var errorMessage: String?
    var emailError: String?
    var passwordError: String?
}
