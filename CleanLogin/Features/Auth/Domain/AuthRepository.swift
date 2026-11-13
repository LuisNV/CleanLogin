import Foundation

// Domain không import UIKit, RxSwift, Alamofire hoặc Security,
// và không biết DTO hay token của tầng Data.
@MainActor
protocol AuthRepository {
    /// Đăng nhập bằng email hoặc số điện thoại. Token được Data tự lưu, Domain không cần biết.
    func login(identifier: String, password: String) async throws
    /// Có phiên đăng nhập đã lưu trên máy hay không.
    func hasSavedSession() throws -> Bool
    func logout() async throws
}
