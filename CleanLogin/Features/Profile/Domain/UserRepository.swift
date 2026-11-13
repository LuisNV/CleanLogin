import Foundation

@MainActor
protocol UserRepository {
    /// Thông tin người dùng đang đăng nhập.
    func getCurrentUser() async throws -> User
}
