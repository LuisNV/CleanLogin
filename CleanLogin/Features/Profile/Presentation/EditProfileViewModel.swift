import UIKit

/// A local editing draft. Persist through a repository when an update API is available.
struct ProfileEditDraft {
    let user: ProfileUser
    var birthday: Date?
    var gender: String?
    var avatar: UIImage?
}

@MainActor
final class EditProfileViewModel {
    var fullName: String
    var email: String
    var phone: String
    var address: String
    var birthday: Date?
    var gender: String?
    var avatar: UIImage?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    var birthdayText: String? {
        birthday.map { dateFormatter.string(from: $0) }
    }

    var initials: String {
        ProfileUser(fullName: fullName, email: email, phone: phone, address: address).initials
    }

    init(draft: ProfileEditDraft) {
        fullName = draft.user.fullName
        email = draft.user.email
        phone = draft.user.phone
        address = draft.user.address
        birthday = draft.birthday
        gender = draft.gender
        avatar = draft.avatar
    }

    enum ValidationError: LocalizedError {
        case invalidNameOrEmail

        var errorDescription: String? {
            "Vui lòng nhập họ tên và email hợp lệ."
        }
    }

    func makeDraft() throws -> ProfileEditDraft {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, email.contains("@"), email.split(separator: "@").count == 2 else {
            throw ValidationError.invalidNameOrEmail
        }
        let user = ProfileUser(
            fullName: name,
            email: email,
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return ProfileEditDraft(user: user, birthday: birthday, gender: gender, avatar: avatar)
    }
}
