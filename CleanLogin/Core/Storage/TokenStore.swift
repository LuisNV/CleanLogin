import Foundation

/// Cặp token của một phiên đăng nhập.
/// Thuộc Core vì cả `APIClient` (refresh) lẫn repository của feature Auth đều dùng,
/// nên không được phụ thuộc DTO của bất kỳ feature nào.
struct AuthTokens: Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
}

@MainActor
protocol TokenStore: AnyObject {
    func readAccessToken() throws -> String?
    func readRefreshToken() throws -> String?
    /// Lưu cả hai token. Nếu không lưu được đủ cả hai thì không được để lại phiên dở dang.
    func save(_ tokens: AuthTokens) throws
    func clear() throws
}
