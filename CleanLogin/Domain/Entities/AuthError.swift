import Foundation

enum AuthError: LocalizedError, Equatable {
    case emptyFields
    case invalidEmail
    case invalidLoginIdentifier
    case invalidCredentials
    case sessionExpired
    case networkUnavailable
    case serviceUnavailable
    case invalidResponse
    case secureStorageUnavailable
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .emptyFields: return "Vui lòng nhập email hoặc số điện thoại và mật khẩu."
        case .invalidEmail: return "Email chưa đúng định dạng."
        case .invalidLoginIdentifier: return "Email hoặc số điện thoại chưa đúng định dạng."
        case .invalidCredentials: return "Email, số điện thoại hoặc mật khẩu không đúng."
        case .sessionExpired: return "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        case .networkUnavailable: return "Không thể kết nối máy chủ. Kiểm tra mạng và thử lại."
        case .serviceUnavailable: return "Máy chủ chưa sẵn sàng. Vui lòng thử lại."
        case .invalidResponse: return "Dữ liệu máy chủ trả về không hợp lệ."
        case .secureStorageUnavailable: return "Không thể truy cập phiên đăng nhập an toàn. Hãy mở khóa thiết bị và thử lại."
        case .invalidURL:
                   return "Địa chỉ API không hợp lệ."
        }
    }
}
