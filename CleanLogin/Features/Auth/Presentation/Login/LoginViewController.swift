import UIKit
import RxSwift
import RxCocoa
import SwiftUI

@MainActor
final class LoginViewController: UIViewController, UITextFieldDelegate {
    private let viewModel: LoginViewModel
    private let modeTitle: String
    private let showDemoCredentials: Bool
    private let disposeBag = DisposeBag()
    private var loginTask: Task<Void, Never>?
    
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let loginButton = LoginSubmitView()
    private let socialLoginView = SocialLoginView()
    private let registerPromptView = RegisterPromptView()
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "LoginBackground")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private let headerView = LoginHeaderView()
    private let loginFormView = LoginFormView()
    var onAboutTapped: (()->Void)?
    
    init(viewModel: LoginViewModel, modeTitle: String, showDemoCredentials: Bool) {
        self.viewModel = viewModel
        self.modeTitle = modeTitle
        self.showDemoCredentials = showDemoCredentials
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        bindInputs()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loginTask?.cancel()
    }
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        view.sendSubviewToBack(backgroundImageView)
        
        
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Đăng nhập"
        configuration.baseBackgroundColor = .systemIndigo
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 16, leading: 20, bottom: 16, trailing: 20
        )
        
//        loginButton.rx.tap.subscribe(onNext: { [weak self] in
//            self?.didTapLogin()
//        }).disposed(by: disposeBag)
        loginButton.onSubmit = {[weak self] in self?.didTapLogin()}
        
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        stack.axis = .vertical
        stack.spacing = 16
        [headerView, loginFormView, loginButton,socialLoginView,registerPromptView].forEach(stack.addArrangedSubview)
        stack.setCustomSpacing(32, after: headerView)
        
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        loginFormView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
            loginFormView.topAnchor.constraint(
                equalTo: headerView.bottomAnchor,
                constant: 48
            ),
            loginFormView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            loginFormView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            )
        ])
    }
    private func setupAboutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Thông tin",
            style: .plain,
            target: self,
            action: #selector(didTapAbout)
        )
    }
    
    @objc private func didTapAbout() {
        onAboutTapped?()
    }
    
    private func bindViewModel() {
        viewModel.state.drive(onNext: { [weak self] state in
            self?.render(state)
        }).disposed(by: disposeBag)
        viewModel.state
            .map { $0.errorMessage }
            .distinctUntilChanged()
            .compactMap { $0 }
            .drive(onNext: { message in
                ToastManager.shared.showError(message,title: "Đăng nhập thất bại")
            })
            .disposed(by: disposeBag)
    }
    private func bindInputs() {
        
        loginFormView.emailTextField.rx.text
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.clearEmailError()
                self?.viewModel.clearGeneralError()
            })
            .disposed(by: disposeBag)
        
        loginFormView.passwordTextField.rx.text
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.clearPasswordError()
                self?.viewModel.clearGeneralError()
            })
            .disposed(by: disposeBag)
    }
    private func render(_ state: LoginViewState) {
        
        // Truyền state xuống LoginFormView
        loginFormView.render(state)
        
        // Loading
        loginButton.render(isLoading: state.isLoading)
        
        if state.isLoading {
            LoadingManager.shared.show()
        } else {
            LoadingManager.shared.hide()
        }
    }
    
    @objc private func didTapLogin() {
        // Guard cả trước khi tạo Task để tránh double tap trong cùng một frame.
        guard loginTask == nil else { return }
        view.endEditing(true)
        let email = loginFormView.emailTextField.text ?? ""
        let password = loginFormView.passwordTextField.text ?? ""
        let viewModel = viewModel
        loginTask = Task { [weak self, viewModel] in
            await viewModel.login(email: email, password: password)
            self?.loginTask = nil
        }
    }
    
}
