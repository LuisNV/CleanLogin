//
//  SocialLoginView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//



import UIKit

final class SocialLoginView: UIView {
    
    // MARK: - Callbacks
    
    var onAppleLogin: (() -> Void)?
    var onGoogleLogin: (() -> Void)?
    var onFacebookLogin: (() -> Void)?
    
    // MARK: - UI
    
    private let dividerLabel: UILabel = {
        let label = UILabel()
        label.text = "Hoặc đăng nhập với"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let appleButton = UIButton(type: .system)
    private let googleButton = UIButton(type: .system)
    private let facebookButton = UIButton(type: .system)
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        configureButton(
            appleButton,
            imageName: "icon_apple",
            size: 40
            
        )
        
        configureButton(
            googleButton,
            imageName: "icon_facebook",
            size: 26
            
        )
        
        configureButton(
            facebookButton,
            imageName: "icon_google",
            size: 40
            
        )
        
        appleButton.accessibilityLabel = "Đăng nhập bằng Apple"
        googleButton.accessibilityLabel = "Đăng nhập bằng Google"
        facebookButton.accessibilityLabel = "Đăng nhập bằng Facebook"
        
        let dividerStack = makeDividerSection()
        
        let buttonsStack = UIStackView(arrangedSubviews: [
            appleButton,
            facebookButton,
            googleButton
        ])
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [
            dividerStack,
            buttonsStack
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 22
        
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            buttonsStack.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    private func makeDividerSection() -> UIStackView {
        let leftLine = makeDivider()
        let rightLine = makeDivider()
        
        dividerLabel.setContentHuggingPriority(.required, for: .horizontal)
        dividerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [
            leftLine,
            dividerLabel,
            rightLine
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.distribution = .fill
        
        // Quan trọng: 2 line phải bằng nhau
        leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor).isActive = true
        
        return stack
    }
    private func configureButton(
        _ button: UIButton,
        imageName: String,
        size: CGFloat = 26
    ) {
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray5.cgColor
        
        // Tạo icon từ PNG trong Assets
        let iconView = UIImageView(
            image: UIImage(named: imageName)
        )
        
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isUserInteractionEnabled = false
        
        button.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(
                equalTo: button.centerXAnchor
            ),
            iconView.centerYAnchor.constraint(
                equalTo: button.centerYAnchor
            ),
            iconView.widthAnchor.constraint(
                equalToConstant: CGFloat(size)
            ),
            iconView.heightAnchor.constraint(
                equalToConstant: CGFloat(size)
            )
        ])
    }
    
    private func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor(
            red: 0.86,
            green: 0.90,
            blue: 0.96,
            alpha: 1
        )
        
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return line
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        appleButton.addTarget(
            self,
            action: #selector(appleTapped),
            for: .touchUpInside
        )
        
        googleButton.addTarget(
            self,
            action: #selector(googleTapped),
            for: .touchUpInside
        )
        
        facebookButton.addTarget(
            self,
            action: #selector(facebookTapped),
            for: .touchUpInside
        )
    }
    
    @objc private func appleTapped() {
        onAppleLogin?()
    }
    
    @objc private func googleTapped() {
        onGoogleLogin?()
    }
    
    @objc private func facebookTapped() {
        onFacebookLogin?()
    }
    
    // MARK: - State
    
    func render(isLoading: Bool) {
        [appleButton, googleButton, facebookButton].forEach {
            $0.isEnabled = !isLoading
            $0.alpha = isLoading ? 0.5 : 1
        }
    }
}
