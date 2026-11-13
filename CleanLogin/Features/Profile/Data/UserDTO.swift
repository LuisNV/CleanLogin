import Foundation

struct UserDTO: Decodable, Sendable {
    let id: Int64
    let fullName: String
    let email: String
    let phone: String
    let address: String
    let dateOfBirth: String
    let avatarUrl: String
    let emailVerified: Bool

    func toDomain() -> User {
        User(
            id: id,
            fullName: fullName,
            email: email,
            phone: phone,
            address: address,
            dateOfBirth: dateOfBirth,
            avatarUrl: avatarUrl,
            emailVerified: emailVerified
        )
    }
}
