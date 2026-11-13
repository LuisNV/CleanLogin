//
//  LoginSubmitView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//
import UIKit

final class LoginSubmitView: UIView {

    var onSubmit: (() -> Void)?

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Đăng nhập", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(
            ofSize: 16,
            weight: .semibold
        )
        button.backgroundColor = UIColor(
            red: 0.13, green: 0.39,
            blue: 0.94, alpha: 1
        )
        button.layer.cornerRadius = 12
        button.accessibilityIdentifier = "login.submit"
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
        addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: topAnchor),
            loginButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            loginButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        loginButton.addTarget(
            self,
            action: #selector(submitTapped),
            for: .touchUpInside
        )
    }

    func render(isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        loginButton.alpha = isLoading ? 0.6 : 1
    }

    @objc private func submitTapped() {
        onSubmit?()
    }
}
