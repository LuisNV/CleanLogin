//
//  ContinueLearningCardView.swift
//  CleanLogin
//
//  Created by Administrator on 29/10/26.
//

import UIKit
import SwiftUI
final class ContinueLearningCardView: UIView{
    var onContinueTapped:(()->Void)?
    private let titleLabel = UILabel()
    private let chineseLabel = UILabel()
    private let pinyinLabel = UILabel()
    private let lessonLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    private func setupUI(){
        backgroundColor = AppColors.primary
        layer.cornerRadius = 20
        clipsToBounds = true
        
        //Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .fill
        
        titleLabel.text = "TIẾP TỤC HỌC"
        titleLabel.font = AppFonts.subheadline
        titleLabel.textColor = .white
        
        let headphoneIcon = UIImageView(image: UIImage(systemName: "headphones"))
        headphoneIcon.tintColor = .white
        headphoneIcon.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            headphoneIcon.widthAnchor.constraint(equalToConstant: 20),
            headphoneIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(headphoneIcon)
        
        // Lesson
        chineseLabel.text = "你今天做什么?"
        chineseLabel.font = AppFonts.chineseBody
        chineseLabel.textColor = .white
        
        pinyinLabel.text = "Nǐ jīntiān zuò shénme?"
        pinyinLabel.font = AppFonts.pinyin
        pinyinLabel.textColor = .white
        
        lessonLabel.text = "Bài 05 · Chủ đề sinh hoạt hằng ngày"
        lessonLabel.font = AppFonts.caption
        lessonLabel.textColor = .white
        
        // Progress
        progressView.progress = 0.65
        progressView.progressTintColor = .white
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        
        progressLabel.text = "Đã hoàn thành 65%"
        progressLabel.font = AppFonts.caption
        progressLabel.textColor = .white
        
        // Button
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Nghe tiếp"
        configuration.image = UIImage(systemName: "play.circle")
        configuration.imagePadding = 6
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = AppColors.primary
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 14, bottom: 12, trailing: 14
        )
        continueButton.configuration = configuration
        
        continueButton.addTarget(
            self,
            action: #selector(continueTapped),
            for: .touchUpInside
        )
        
        let footerStack = UIStackView()
        footerStack.axis = .horizontal
        footerStack.alignment = .center
        footerStack.spacing = 8
        
        footerStack.addArrangedSubview(progressLabel)
        footerStack.addArrangedSubview(UIView())
        footerStack.addArrangedSubview(continueButton)
        
        // Main column
        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            chineseLabel,
            pinyinLabel,
            lessonLabel,
            progressView,
            footerStack
        ])
        
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.spacing = 12
        
        mainStack.setCustomSpacing(20, after: headerStack)
        mainStack.setCustomSpacing(6, after: chineseLabel)
        mainStack.setCustomSpacing(12, after: pinyinLabel)
        mainStack.setCustomSpacing(12, after: lessonLabel)
        
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
    }
    @objc private func continueTapped() {
        onContinueTapped?()
    }
    func configure(
        chinese: String,
        pinyin: String,
        lesson: String,
        progress: Float
    ) {
        chineseLabel.text = chinese
        pinyinLabel.text = pinyin
        lessonLabel.text = lesson
        
        let value = min(max(progress, 0), 1)
        progressView.progress = value
        progressLabel.text = "Đã hoàn thành \(Int(value * 100))%"
    }
}
#Preview {
    ContinueLearningCardView()
}
