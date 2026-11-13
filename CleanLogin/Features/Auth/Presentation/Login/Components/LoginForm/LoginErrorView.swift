//
//  LoginErrorView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//



import UIKit

final class LoginErrorView: UIView {

    private let iconView: UIImageView = {
        let view = UIImageView(
            image: UIImage(systemName: "exclamationmark.circle.fill")
        )
        view.tintColor = .systemRed
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Đăng nhập thất bại"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(
            red: 0.60, green: 0.10, blue: 0.10, alpha: 1
        )
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
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
        backgroundColor = UIColor(
            red: 1.0, green: 0.95, blue: 0.95, alpha: 1
        )

        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemRed
            .withAlphaComponent(0.2).cgColor

        let textStack = UIStackView(arrangedSubviews: [
            titleLabel,
            messageLabel
        ])
        textStack.axis = .vertical
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [
            iconView,
            textStack
        ])
        mainStack.axis = .horizontal
        mainStack.alignment = .top
        mainStack.spacing = 12

        addSubview(mainStack)

        mainStack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }

    func configure(message: String?) {
        messageLabel.text = message
        isHidden = message == nil || message?.isEmpty == true
    }
}
