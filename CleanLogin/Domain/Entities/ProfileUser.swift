//
//  ProfileUser.swift
//  CleanLogin
//
//  Created by Administrator on 26/10/26.
//


struct ProfileUser {
    let fullName: String
    let email: String
    let phone: String
    let address: String

    // Ví dụ: Nguyễn Văn Thành → NT
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