import Foundation

// Dùng chung cho validation ở use case và form đăng nhập.
enum LoginIdentifier {
    static func isValid(_ value: String) -> Bool {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailPattern = #"\A[^\s@]+@[^\s@]+\.[^\s@]+\z"#
        // Giữ số 0 đầu và mã quốc gia; không tự chuyển đổi số điện thoại.
        let phonePattern = #"\A\+?[0-9]{7,15}\z"#
        return value.range(of: emailPattern, options: .regularExpression) != nil
            || value.range(of: phonePattern, options: .regularExpression) != nil
    }
}

@MainActor
protocol LoginUseCaseProtocol {
    func execute(email: String, password: String) async throws -> LoginResponseDTO
}

@MainActor
final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> LoginResponseDTO {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty, !password.isEmpty else { throw AuthError.emptyFields }
        guard LoginIdentifier.isValid(email) else {
            throw AuthError.invalidLoginIdentifier
        }
        // Không trim password hoặc tự đặt giới hạn không có trong hợp đồng API.
        return try await repository.login(email: email, password: password)
    }
}
