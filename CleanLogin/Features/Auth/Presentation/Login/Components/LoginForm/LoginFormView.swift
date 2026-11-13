//
//  LoginFormView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//
import UIKit

final class LoginFormView: UIView {
    
    var onForgotPassword: (() -> Void)?
    
    private let emailLabel = UILabel()
    private let passwordLabel = UILabel()
    
    let emailTextField = UITextField()
    let passwordTextField = UITextField()
    
    private let togglePasswordButton = UIButton(type: .system)
    private let forgotPasswordButton = UIButton(type: .system)
    
    private let emailErrorLabel = UILabel()
    private let passwordErrorLabel = UILabel()
    
    private let borderColor = UIColor(
        red: 0.85, green: 0.89, blue: 0.96, alpha: 1
    )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Labels
        emailLabel.text = "Email hoặc số điện thoại"
        passwordLabel.text = "Mật khẩu"
        
        [emailLabel, passwordLabel].forEach {
            $0.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.textColor = UIColor(
                red: 0.08, green: 0.12, blue: 0.22, alpha: 1
            )
        }
        
        [emailErrorLabel, passwordErrorLabel].forEach {
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = .systemRed
            $0.numberOfLines = 0
            $0.isHidden = true
        }
        
        // Email
        configureTextField(emailTextField)
        emailTextField.placeholder = "Nhập email hoặc số điện thoại"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.textContentType = .username
        
        let emailIcon = makeIcon("envelope")
        emailTextField.leftView = makeAccessoryContainer(emailIcon)
        emailTextField.leftViewMode = .always
        
        // Password
        configureTextField(passwordTextField)
        passwordTextField.placeholder = "Nhập mật khẩu"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        
        let lockIcon = makeIcon("lock")
        passwordTextField.leftView = makeAccessoryContainer(lockIcon)
        passwordTextField.leftViewMode = .always
        
        togglePasswordButton.setImage(
            UIImage(systemName: "eye"),
            for: .normal
        )
        togglePasswordButton.tintColor = .systemGray
        togglePasswordButton.addTarget(
            self,
            action: #selector(togglePassword),
            for: .touchUpInside
        )
        
        passwordTextField.rightView = makeAccessoryContainer(
            togglePasswordButton
        )
        passwordTextField.rightViewMode = .always
        
        // Forgot password
        forgotPasswordButton.setTitle(
            "Quên mật khẩu?",
            for: .normal
        )
        forgotPasswordButton.titleLabel?.font =
            .systemFont(ofSize: 14, weight: .semibold)
        forgotPasswordButton.tintColor = UIColor(
            red: 0.12, green: 0.38, blue: 0.96, alpha: 1
        )
        
        forgotPasswordButton.addTarget(
            self,
            action: #selector(forgotPasswordTapped),
            for: .touchUpInside
        )
        
        let emailStack = UIStackView(arrangedSubviews: [
            emailLabel, emailTextField,emailErrorLabel
        ])
        emailStack.axis = .vertical
        emailStack.spacing = 8
        
        let passwordStack = UIStackView(arrangedSubviews: [
            passwordLabel, passwordTextField,passwordErrorLabel
        ])
        passwordStack.axis = .vertical
        passwordStack.spacing = 8
        
        let forgotRow = UIStackView(arrangedSubviews: [
            UIView(), forgotPasswordButton
        ])
        forgotRow.axis = .horizontal
        forgotRow.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [
            emailStack,
            passwordStack,
            forgotRow
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 18
        
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            emailTextField.heightAnchor.constraint(equalToConstant: 48),
            passwordTextField.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    func render(_ state: LoginViewState) {
        // Email error
        emailErrorLabel.text = state.emailError
        emailErrorLabel.isHidden = state.emailError == nil

        // Password error
        passwordErrorLabel.text = state.passwordError
        passwordErrorLabel.isHidden = state.passwordError == nil


        emailTextField.layer.borderColor =
            state.emailError == nil
            ? borderColor.cgColor
            : UIColor.systemRed.cgColor

        passwordTextField.layer.borderColor =
            state.passwordError == nil
            ? borderColor.cgColor
            : UIColor.systemRed.cgColor

        emailTextField.isEnabled = !state.isLoading
        passwordTextField.isEnabled = !state.isLoading
    }
    
    private func configureTextField(_ field: UITextField) {
        field.backgroundColor = .white
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = borderColor.cgColor
        field.font = .systemFont(ofSize: 14)
        field.textColor = .label
    }
    
    private func makeIcon(_ name: String) -> UIImageView {
        let imageView = UIImageView(
            image: UIImage(systemName: name)
        )
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    private func makeAccessoryContainer(_ view: UIView) -> UIView {
        let container = UIView(
            frame: CGRect(x: 0, y: 0, width: 46, height: 48)
        )
        
        container.addSubview(view)
        view.frame = CGRect(
            x: 13, y: 14, width: 20, height: 20
        )
        
        return container
    }
    
    @objc private func togglePassword() {
        passwordTextField.isSecureTextEntry.toggle()
        
        let icon = passwordTextField.isSecureTextEntry
        ? "eye"
        : "eye.slash"
        
        togglePasswordButton.setImage(
            UIImage(systemName: icon),
            for: .normal
        )
    }
    
    @objc private func forgotPasswordTapped() {
        onForgotPassword?()
    }
}
