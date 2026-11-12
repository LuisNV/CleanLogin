//
//  RegisterPromptView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//



import UIKit

final class RegisterPromptView: UIView {

    var onRegister: (() -> Void)?

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Chưa có tài khoản?"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let registerButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Đăng ký ngay", for: .normal)

        button.setTitleColor(
            UIColor(
                red: 0.12, green: 0.39,
                blue: 0.94, alpha: 1
            ),
            for: .normal
        )

        button.titleLabel?.font = .systemFont(
            ofSize: 14,
            weight: .semibold
        )

        button.accessibilityIdentifier = "login.register"

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        let stack = UIStackView(arrangedSubviews: [
            descriptionLabel,
            registerButton
        ])

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 4

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(
                greaterThanOrEqualTo: leadingAnchor
            ),
            stack.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor
            )
        ])

        registerButton.addTarget(
            self,
            action: #selector(registerTapped),
            for: .touchUpInside
        )
    }

    @objc private func registerTapped() {
        onRegister?()
    }
}
