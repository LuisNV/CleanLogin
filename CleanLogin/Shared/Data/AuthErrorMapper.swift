import Foundation

/// Chuyển lỗi tầng mạng/lưu trữ (Core) thành `AuthError` (Domain).
/// Repository của mọi feature dùng chung để cách hiển thị lỗi nhất quán.
enum AuthErrorMapper {
    enum Context {
        /// Đăng nhập: 401 nghĩa là sai tài khoản/mật khẩu.
        case login
        /// Request đã đăng nhập: 401 nghĩa là phiên hết hạn.
        case authenticated
    }

    static func map(_ error: Error, context: Context = .authenticated) -> Error {
        if error is CancellationError || Task.isCancelled { return CancellationError() }
        if let authError = error as? AuthError { return authError }
        if error is KeychainTokenStore.StorageError { return AuthError.secureStorageUnavailable }
        guard let apiError = error as? APIError else { return AuthError.serviceUnavailable }

        if apiError.statusCode == 401 {
            return context == .login ? AuthError.invalidCredentials : AuthError.sessionExpired
        }
        switch apiError {
        case .unauthorized: return AuthError.sessionExpired
        case .http, .server: return AuthError.serviceUnavailable
        case .transport: return AuthError.networkUnavailable
        case .decoding, .invalidResponse: return AuthError.invalidResponse
        case .invalidURL: return AuthError.invalidURL
        }
    }
}
