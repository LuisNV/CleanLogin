import Foundation

struct LoginRequestDTO: Encodable, Sendable {
    // Backend nhận cả email hoặc số điện thoại trong trường `email`.
    let email: String
    let password: String
}

struct LoginResponseDTO: Decodable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String

    func toTokens() -> AuthTokens {
        AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}

struct LogoutRequestDTO: Encodable, Sendable {
    let refreshToken: String
}
