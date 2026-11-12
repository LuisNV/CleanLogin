//
//  ProfileViewController.swift
//  CleanLogin
//
//  Created by Administrator on 26/10/26.
//

import UIKit
import RxSwift
import RxCocoa

final class ProfileViewController: UIViewController {
    
    // MARK: Dữ liệu và callback
    
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    private var refreshTask: Task<Void, Never>?
    // Coordinator hoặc màn hình trước sẽ xử lý mở trang chỉnh sửa.
    var onEditTapped: ((ProfileUser) -> Void)?
    
    // MARK: Các thành phần giao diện
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let accountLabel = UILabel()
    private let birthdayValueLabel = UILabel()
    private var currentUser: User?
    private var editedDraft: ProfileEditDraft?
    private let editedAvatarView = UIImageView()
    var onChangePasswordTapped: (() -> Void)?
    var onVerifyEmailTapped: (() -> Void)?
    private let emailValueLabel = UILabel()
    private let phoneValueLabel = UILabel()
    private let addressValueLabel = UILabel()
    private let errorLabel = UILabel()
    private var logoutTask: Task<Void, Never>?
    private let editButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    
    // MARK: Khởi tạo
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Màn hình này được khởi tạo bằng code.")
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupLayout()
        setupProfileHeader()
        setupInformationCard()
        setupActions()
        spinner.hidesWhenStopped = true
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        contentStack.addArrangedSubview(spinner)
        contentStack.addArrangedSubview(errorLabel)
        viewModel.state.drive(onNext: { [weak self] state in
            self?.render(state)
        }).disposed(by: disposeBag)
        refreshTask = Task { [weak self] in
            await self?.viewModel.loadUser()
        }
    }
    
    deinit {
        refreshTask?.cancel()
        logoutTask?.cancel()
    }
    
    
    
    // MARK: Navigation bar
    
    private func setupNavigationBar() {
        navigationItem.title = "Cá nhân"
        view.backgroundColor = AppColors.background
        
        navigationItem.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: AppColors.text,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationItem.hidesBackButton = true
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        
    }
    
    // MARK: Bố cục tổng thể
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            // ScrollView nằm dưới navigation bar, trong vùng an toàn.
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            
            // Nội dung cách hai mép màn hình 24 điểm.
            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 20
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 20
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -20
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -32
            ),
            
            // Chỉ cuộn dọc, không cuộn ngang.
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -40
            )
        ])
    }
    
    // MARK: Avatar và tên người dùng
    
    private func setupProfileHeader() {
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 8
        
        avatarLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        avatarLabel.textAlignment = .center
        avatarLabel.textColor = AppColors.primary
        avatarLabel.backgroundColor = AppColors.avatarBackground
        avatarLabel.layer.cornerRadius = 40
        avatarLabel.clipsToBounds = true
        avatarLabel.isAccessibilityElement = false
        
        
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = AppColors.text
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        
        accountLabel.text = "Tài khoản cá nhân"
        accountLabel.font = .systemFont(ofSize: 14)
        accountLabel.textColor = AppColors.secondaryText
        accountLabel.textAlignment = .center
        
        headerStack.addArrangedSubview(avatarLabel)
        headerStack.addArrangedSubview(nameLabel)
        headerStack.addArrangedSubview(accountLabel)
        
        contentStack.addArrangedSubview(headerStack)
        
        NSLayoutConstraint.activate([
            avatarLabel.widthAnchor.constraint(equalToConstant: 80),
            avatarLabel.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.widthAnchor.constraint(
                equalTo: headerStack.widthAnchor
            )
        ])
    }
    
    // MARK: Thẻ thông tin
    
    private func setupInformationCard() {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 12
        
        let titleLabel = UILabel()
        titleLabel.text = "Thông tin cá nhân"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.text
        
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.backgroundColor = .white
        cardStack.layer.cornerRadius = 14
        cardStack.clipsToBounds = true
        
        cardStack.isLayoutMarginsRelativeArrangement = true
        cardStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 18,
            bottom: 0,
            trailing: 18
        )
        
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Email", valueLabel: emailValueLabel)
        )
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Số điện thoại", valueLabel: phoneValueLabel)
        )
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Ngày sinh", valueLabel: birthdayValueLabel)
        )
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Khu vực", valueLabel: addressValueLabel)
        )
        for row in cardStack.arrangedSubviews.dropLast() {
            let separator = makeSeparator()
            row.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])
        }
        
        editButton.setTitle("Sửa", for: .normal)
        editButton.setTitleColor(AppColors.primary, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 15)
        editButton.addTarget(self, action: #selector(handleEditTapped), for: .touchUpInside)
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        let sectionHeader = UIStackView(arrangedSubviews: [titleLabel, editButton])
        sectionHeader.alignment = .center
        sectionHeader.spacing = 8
        sectionStack.addArrangedSubview(sectionHeader)
        sectionStack.addArrangedSubview(cardStack)
        
        contentStack.addArrangedSubview(sectionStack)
    }
    
    // Dùng chung cho cả 4 dòng, tránh viết lại cùng một đoạn code.
    private func makeInformationRow(
        title: String,
        valueLabel: UILabel
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = AppColors.secondaryText
        
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = AppColors.text
        valueLabel.numberOfLines = 0
        
        let rowStack = UIStackView(
            arrangedSubviews: [titleLabel, valueLabel]
        )
        rowStack.axis = .vertical
        rowStack.spacing = 3
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.addSubview(rowStack)
        
        NSLayoutConstraint.activate([
            // Cao tối thiểu 58, có thể tăng nếu nội dung dài.
            container.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 58
            ),
            rowStack.topAnchor.constraint(
                equalTo: container.topAnchor,
                constant: 10
            ),
            rowStack.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),
            rowStack.trailingAnchor.constraint(
                equalTo: container.trailingAnchor
            ),
            rowStack.bottomAnchor.constraint(
                lessThanOrEqualTo: container.bottomAnchor,
                constant: -10
            )
        ])
        
        return container
    }
    
    // MARK: Nút chỉnh sửa và ghi chú
    
    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 225 / 255, green: 231 / 255, blue: 241 / 255, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return separator
    }

    private func setupActions() {
        let actions = UIStackView()
        actions.axis = .vertical
        actions.backgroundColor = .white
        actions.layer.cornerRadius = 14
        actions.isLayoutMarginsRelativeArrangement = true
        actions.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        actions.addArrangedSubview(makeActionRow(title: "Đổi mật khẩu", subtitle: nil, action: #selector(handleChangePasswordTapped)))
        actions.addArrangedSubview(makeSeparator())
        actions.addArrangedSubview(makeActionRow(title: "Xác thực email", subtitle: "Chưa có thông tin", action: #selector(handleVerifyEmailTapped)))
        contentStack.addArrangedSubview(actions)

        logoutButton.setTitle("Đăng xuất", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 16)
        logoutButton.backgroundColor = AppColors.primary
        logoutButton.layer.cornerRadius = 10
        logoutButton.layer.borderWidth = 0.75
        logoutButton.layer.borderColor = AppColors.primary.cgColor
        logoutButton.addTarget(self, action: #selector(handleLogoutTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(logoutButton)
        logoutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    private func makeActionRow(title: String, subtitle: String?, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = AppColors.text
        titleLabel.numberOfLines = 0
        let statusLabel = UILabel()
        statusLabel.text = subtitle
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .systemOrange
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .right
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = AppColors.secondaryText
        chevron.contentMode = .scaleAspectFit
        let stack = UIStackView(arrangedSubviews: [titleLabel, statusLabel, chevron])
        stack.spacing = 10
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(stack)
        button.accessibilityLabel = [title, subtitle].compactMap { $0 }.joined(separator: ", ")
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])
        return button
    }

    private func render(_ state: ProfileViewState) {
        avatarLabel.text = state.user?.initials
        nameLabel.text = state.user?.fullName
        currentUser = state.user
        birthdayValueLabel.text = "Chưa cập nhật"
        emailValueLabel.text = state.user?.email
        phoneValueLabel.text = state.user?.phone
        addressValueLabel.text = state.user?.address
        editButton.isEnabled = state.user != nil && !state.isLoading
        logoutButton.isEnabled = !state.isLoading
        spinner.isHidden = !state.isLoading
        if state.isLoading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        errorLabel.text = state.errorMessage
        errorLabel.isHidden = state.errorMessage == nil
        renderEditedDraft()
    }
    private func renderEditedDraft() {
        guard let draft = editedDraft else { return }
        nameLabel.text = draft.user.fullName
        avatarLabel.text = draft.user.initials
        emailValueLabel.text = draft.user.email
        phoneValueLabel.text = draft.user.phone
        addressValueLabel.text = draft.user.address
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        birthdayValueLabel.text = draft.birthday.map { formatter.string(from: $0) } ?? "Chưa cập nhật"
        if editedAvatarView.superview == nil {
            editedAvatarView.translatesAutoresizingMaskIntoConstraints = false
            editedAvatarView.contentMode = .scaleAspectFill
            editedAvatarView.layer.cornerRadius = 40
            editedAvatarView.clipsToBounds = true
            avatarLabel.addSubview(editedAvatarView)
            NSLayoutConstraint.activate([
                editedAvatarView.leadingAnchor.constraint(equalTo: avatarLabel.leadingAnchor),
                editedAvatarView.trailingAnchor.constraint(equalTo: avatarLabel.trailingAnchor),
                editedAvatarView.topAnchor.constraint(equalTo: avatarLabel.topAnchor),
                editedAvatarView.bottomAnchor.constraint(equalTo: avatarLabel.bottomAnchor)
            ])
        }
        editedAvatarView.image = draft.avatar
    }

    // MARK: Xử lý thao tác
    
    @objc private func handleLogoutTapped() {
        guard logoutTask == nil else { return }
        let viewModel = viewModel
        logoutTask = Task { [weak self, viewModel] in
            await viewModel.logoutTask()
            self?.logoutTask = nil
        }
    }
    @objc private func handleEditTapped() {
        guard let user = currentUser else { return }
        if let onEditTapped {
            onEditTapped(ProfileUser(fullName: user.fullName, email: user.email, phone: user.phone, address: user.address))
        } else {
            let draft = editedDraft ?? ProfileEditDraft(
                user: ProfileUser(fullName: user.fullName, email: user.email, phone: user.phone, address: user.address)
            )
            let screen = EditProfileViewController(draft: draft)
            screen.onSave = { [weak self] draft in
                self?.editedDraft = draft
                self?.renderEditedDraft()
            }
            navigationController?.pushViewController(screen, animated: true)
        }
    }

    @objc private func handleChangePasswordTapped() {
        if let onChangePasswordTapped {
            onChangePasswordTapped()
        } else {
            showUnavailableMessage(title: "Đổi mật khẩu")
        }
    }

    @objc private func handleVerifyEmailTapped() {
        if let onVerifyEmailTapped {
            onVerifyEmailTapped()
        } else {
            showUnavailableMessage(title: "Xác thực email")
        }
    }

    private func showUnavailableMessage(title: String) {
        let alert = UIAlertController(title: title, message: "Tính năng này hiện chưa được hỗ trợ.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }

}

