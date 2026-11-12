//
//  AppFonts.swift
//  CleanLogin
//
//  Created by Administrator on 29/10/26.
//


import UIKit

enum AppFonts {
    
    // MARK: - Headings
    
    /// Tiêu đề màn hình: "Học tiếng Trung"
    static let largeTitle = UIFont.systemFont(
        ofSize: 28,
        weight: .bold
    )
    
    /// Tiêu đề các phần: "Bài học hôm nay"
    static let title = UIFont.systemFont(
        ofSize: 22,
        weight: .bold
    )
    
    /// Tiêu đề card: "HSK 1", "Luyện nghe"
    static let titleMedium = UIFont.systemFont(
        ofSize: 18,
        weight: .semibold
    )
    
    // MARK: - Body
    
    /// Nội dung chính
    static let body = UIFont.systemFont(
        ofSize: 16,
        weight: .regular
    )
    
    /// Nội dung cần nhấn mạnh
    static let bodyMedium = UIFont.systemFont(
        ofSize: 16,
        weight: .medium
    )
    
    /// Mô tả phụ
    static let subheadline = UIFont.systemFont(
        ofSize: 14,
        weight: .regular
    )
    
    // MARK: - Small Text
    
    /// Chú thích, tiến độ học
    static let caption = UIFont.systemFont(
        ofSize: 12,
        weight: .regular
    )
    
    /// Chữ trên nút
    static let button = UIFont.systemFont(
        ofSize: 16,
        weight: .semibold
    )
    
    // MARK: - Chinese
    
    /// Chữ Hán lớn trong bài nghe
    static let chineseLarge = UIFont.systemFont(
        ofSize: 30,
        weight: .semibold
    )
    
    /// Chữ Hán trong danh sách bài học
    static let chineseBody = UIFont.systemFont(
        ofSize: 20,
        weight: .medium
    )
    
    /// Phiên âm Pinyin
    static let pinyin = UIFont.systemFont(
        ofSize: 15,
        weight: .regular
    )
    
    /// Lời chào ở đầu trang chủ
    static let greeting = UIFont.systemFont(
        ofSize: 14,
        weight: .regular
    )
}
extension AppFonts {
    
    static func scaled(
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        style: UIFont.TextStyle = .body
    ) -> UIFont {
        
        let font = UIFont.systemFont(
            ofSize: size,
            weight: weight
        )
        
        return UIFontMetrics(forTextStyle: style)
            .scaledFont(for: font)
    }
}
