import Foundation

struct User: Equatable, Sendable {
    let id: Int64
    let fullName: String
    let email: String
    let phone: String
    let address: String
    let dateOfBirth: String
    let avatarUrl: String
    let emailVerified: Bool
    
    var initials: String {
        let words = fullName.split(separator: " ")

        guard let first = words.first?.first else {
            return "?"
        }

        guard words.count > 1,
              let last = words.last?.first else {
            return String(first).uppercased()
        }

        return "\(first)\(last)".uppercased()
    }
}
