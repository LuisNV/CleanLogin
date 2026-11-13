import UIKit

/// Thông tin cá nhân người dùng có thể sửa trên form.
/// Thuộc Presentation (dữ liệu của form), không phải entity Domain.
struct EditableProfile: Equatable {
    var fullName: String
    var email: String
    var phone: String
    var address: String

    var initials: String { NameInitials.make(from: fullName) }

    init(fullName: String, email: String, phone: String, address: String) {
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.address = address
    }

    init(user: User) {
        self.init(fullName: user.fullName, email: user.email, phone: user.phone, address: user.address)
    }
}

/// Bản nháp chỉnh sửa lưu cục bộ. Khi có API cập nhật hồ sơ, hãy lưu qua UserRepository.
struct ProfileEditDraft {
    let user: EditableProfile
    var birthday: Date?
    var gender: String?
    var avatar: UIImage?

    init(user: EditableProfile, birthday: Date? = nil, gender: String? = nil, avatar: UIImage? = nil) {
        self.user = user
        self.birthday = birthday
        self.gender = gender
        self.avatar = avatar
    }

    /// Tạo bản nháp từ User; ngày sinh theo định dạng "yyyy-MM-dd" của API.
    init(user: User) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        self.init(user: EditableProfile(user: user), birthday: formatter.date(from: user.dateOfBirth))
    }
}
