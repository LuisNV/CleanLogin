import Foundation

/// Lỗi của tầng mạng. Core chỉ throw lỗi này; mỗi feature tự map sang lỗi Domain.
enum APIError: Error {
    case transport
    case http(Int)
    case server(statusCode: Int, response: APIResponseMetadata)
    case invalidResponse
    case decoding
    case invalidURL
    /// Request cần đăng nhập nhưng không có token, hoặc refresh token không còn dùng được.
    /// Khi lỗi này xảy ra, `APIClient` đã xóa token và báo `onSessionExpired`.
    case unauthorized

    var statusCode: Int? {
        switch self {
        case .http(let status), .server(let status, _): return status
        default: return nil
        }
    }
}
