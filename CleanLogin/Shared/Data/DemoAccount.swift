import Foundation

/// Dữ liệu tài khoản demo cho chế độ mock. Mock service của các feature dùng chung một nguồn.
enum DemoAccount {
    static let id: Int64 = 1
    static let fullName = "Nguyễn Thành"
    static let email = "demo@example.com"
    static let phone = "0776426233"
    static let password = "123456"
    static let address = "Hà Nội"
    static let dateOfBirth = "1998-02-22"
}
