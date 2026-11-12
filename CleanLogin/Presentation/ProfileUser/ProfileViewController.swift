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
    private let fullNameValueLabel = UILabel()
    private let emailValueLabel = UILabel()
    private let phoneValueLabel = UILabel()
    private let addressValueLabel = UILabel()
    private let errorLabel = UILabel()
    private var logoutTask: Task<Void, Never>?
    private let editButton = UIButton(type: .system)
    private let privacyLabel = UILabel()
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
        navigationItem.title = "Thông tin cá nhân"
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackTapped)
        )
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        
    }
    
    // MARK: Bố cục tổng thể
    @objc private func handleBackTapped(){
        navigationController?.popViewController(animated: true)
    }   
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 24
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
                constant: 18
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 24
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -24
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -32
            ),
            
            // Chỉ cuộn dọc, không cuộn ngang.
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -48
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
        avatarLabel.layer.cornerRadius = 44
        avatarLabel.clipsToBounds = true
        avatarLabel.isAccessibilityElement = false
        
        
        nameLabel.font = .systemFont(ofSize: 23, weight: .bold)
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
            avatarLabel.widthAnchor.constraint(equalToConstant: 88),
            avatarLabel.heightAnchor.constraint(equalToConstant: 88),
            
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
        titleLabel.text = "Thông tin cơ bản"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.text
        
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.backgroundColor = .white
        cardStack.layer.cornerRadius = 18
        cardStack.clipsToBounds = true
        
        cardStack.isLayoutMarginsRelativeArrangement = true
        cardStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 18,
            bottom: 0,
            trailing: 18
        )
        
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Họ và tên", valueLabel: fullNameValueLabel)
        )
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Email", valueLabel: emailValueLabel)
        )
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Số điện thoại", valueLabel: phoneValueLabel)
        )
        cardStack.addArrangedSubview(
            makeInformationRow(title: "Địa chỉ", valueLabel: addressValueLabel)
        )
        
        sectionStack.addArrangedSubview(titleLabel)
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
        
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
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
            // Cao tối thiểu 70, có thể tăng nếu nội dung dài.
            container.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 70
            ),
            rowStack.topAnchor.constraint(
                equalTo: container.topAnchor,
                constant: 12
            ),
            rowStack.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),
            rowStack.trailingAnchor.constraint(
                equalTo: container.trailingAnchor
            ),
            rowStack.bottomAnchor.constraint(
                lessThanOrEqualTo: container.bottomAnchor,
                constant: -12
            )
        ])
        
        return container
    }
    
    // MARK: Nút chỉnh sửa và ghi chú
    
    private func setupActions() {
        editButton.setTitle("Đăng xuất", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 16)
        editButton.backgroundColor = AppColors.primary
        editButton.layer.cornerRadius = 14
        
        editButton.addTarget(
            self,
            action: #selector(handleEditTapped),
            for: .touchUpInside
        )
        
        privacyLabel.text = "Thông tin của bạn được bảo mật"
        privacyLabel.font = .systemFont(ofSize: 12)
        privacyLabel.textColor = AppColors.secondaryText
        privacyLabel.textAlignment = .center
        privacyLabel.numberOfLines = 0
        
        contentStack.addArrangedSubview(editButton)
        contentStack.addArrangedSubview(privacyLabel)
        
        editButton.heightAnchor
            .constraint(equalToConstant: 52)
            .isActive = true
    }
    private func render(_ state: ProfileViewState) {
        avatarLabel.text = state.user?.initials
        nameLabel.text = state.user?.fullName
        fullNameValueLabel.text = state.user?.fullName
        emailValueLabel.text = state.user?.email
        phoneValueLabel.text = state.user?.phone
        addressValueLabel.text = state.user?.address
        spinner.isHidden = !state.isLoading
    }
    // MARK: Xử lý thao tác
    
    @objc private func handleEditTapped() {
        guard logoutTask == nil else { return }
        let viewModel = viewModel
        logoutTask = Task { [weak self, viewModel] in
            await viewModel.logoutTask()
            self?.logoutTask = nil
        }
    }
}

