import UIKit
import RxSwift
import RxCocoa
import SwiftUI

@MainActor
final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    private var refreshTask: Task<Void, Never>?
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let errorLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refreshButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    var onAboutTapped: (()->Void)?
    var onTopicTapped: ((ListeningTopic) -> Void)?
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        
        //        viewModel.state.drive(onNext: { [weak self] state in self?.render(state) })
        //            .disposed(by: disposeBag)
        //        refreshButton.rx.tap.subscribe(onNext: { [weak self] in self?.refresh() })
        //            .disposed(by: disposeBag)
        
    }
    private func setUpLayout(){
        view.backgroundColor = AppColors.background
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(setupHeader())
        stackView.addArrangedSubview(setupContinueLearningCard())
        stackView.addArrangedSubview(setupHSKSection())
        stackView.addArrangedSubview(setupListeningTopics())
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 0
            ),
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            stackView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 0
            ),
            stackView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 20
            ),
            
            stackView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -20
            ),
            stackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -40
            ),
            stackView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -40
            )
        ])
    }
    private func setupListeningTopics() -> UIView {
        
        let section = ListeningTopicSectionView()
        
        let topics: [ListeningTopic] = [
            .init(
                id: 1,
                title: "Giao tiếp hằng ngày",
                subtitle: "12 bài nghe · HSK 1",
                icon: "bubble.left.and.bubble.right"
            ),
            .init(
                id: 2,
                title: "Ăn uống & mua sắm",
                subtitle: "8 bài nghe · HSK 1–2",
                icon: "cup.and.saucer"
            ),
            .init(
                id: 3,
                title: "Du lịch & phương tiện",
                subtitle: "10 bài nghe · HSK 2",
                icon: "tram"
            )
        ]
        
        section.configure(with: topics)
        
        section.onTopicTapped = { [weak self] topic in
            self?.onTopicTapped?(topic)
        }
        
        return section
    }
    private func setupHSKSection() -> UIView {
        let section = HSKSectionView()
        
        section.onLevelTapped = { level in
            print("Đã chọn \(level.title)")
        }
        
        section.onSeeAllTapped = {
            print("Xem tất cả cấp độ HSK")
        }
        
        return section
    }
    private func setupHeader() -> UIView {
        
        // 1. Stack dọc chứa 3 dòng text
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 0
        textStack.alignment = .leading
        
        let greetingLabel = UILabel()
        greetingLabel.text = "你好, chào buổi sáng! 👋"
        greetingLabel.font = AppFonts.greeting
        greetingLabel.textColor = AppColors.secondaryText
        
        let titleLabel = UILabel()
        titleLabel.text = "Học tiếng Trung"
        titleLabel.font = AppFonts.largeTitle
        titleLabel.textColor = AppColors.text
        
        let motivationLabel = UILabel()
        motivationLabel.text = "Mỗi ngày nghe một chút, tiến bộ mỗi ngày."
        motivationLabel.font = AppFonts.subheadline
        motivationLabel.textColor = AppColors.secondaryText
        motivationLabel.numberOfLines = 0
        
        textStack.addArrangedSubview(greetingLabel)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(motivationLabel)
        
        textStack.setCustomSpacing(8, after: greetingLabel)
        textStack.setCustomSpacing(6, after: titleLabel)
        
        // 2. Nút hình tròn bên phải
        let profileButton = UIButton(type: .system)
        
        profileButton.setImage(
            UIImage(systemName: "person.fill"),
            for: .normal
        )
        
        profileButton.tintColor = AppColors.primary
        profileButton.backgroundColor = AppColors.avatarBackground
        
        profileButton.layer.cornerRadius = 28
        profileButton.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            profileButton.widthAnchor.constraint(equalToConstant: 56),
            profileButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // 3. Stack ngang chứa text và button
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 16
        headerStack.alignment = .center
        headerStack.distribution = .fill
        
        let spacer = UIView()
        
        headerStack.addArrangedSubview(textStack)
        headerStack.addArrangedSubview(spacer)
        headerStack.addArrangedSubview(profileButton)
        
        
        // Ưu tiên giữ nguyên kích thước nút
        profileButton.setContentHuggingPriority(
            .required,
            for: .horizontal
        )
        
        // 4. Xử lý khi nhấn nút
        profileButton.addTarget(
            self,
            action: #selector(profileTapped),
            for: .touchUpInside
        )
        return headerStack
    }
    private func setupContinueLearningCard() -> UIView {
        let card = ContinueLearningCardView()
        
        card.configure(
            chinese: "你今天做什么？",
            pinyin: "Nǐ jīntiān zuò shénme?",
            lesson: "Bài 05 · Chủ đề sinh hoạt hằng ngày",
            progress: 0.65
        )
        
        card.onContinueTapped = { [weak self] in
            print("Nghe tiếp bài 05")
            // Sau này gọi Coordinator điều hướng sang màn nghe
        }
        
        return card
    }
    @objc private func profileTapped() {
        onAboutTapped?()
    }
    private func setupContinueLearningCard(){
        let cardView = UIView()
        cardView.backgroundColor = AppColors.primary
        cardView.layer.cornerRadius = 20
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refreshTask?.cancel()
    }
    
    private func configure(_ button: UIButton, title: String, color: UIColor) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = color
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        button.configuration = configuration
    }
    
    private func refresh() {
        guard refreshTask == nil else { return }
        let viewModel = viewModel
        refreshTask = Task { [weak self, viewModel] in
            await viewModel.refresh()
            self?.refreshTask = nil
        }
    }
    
    private func render(_ state: HomeViewState) {
        if state.isLoading { spinner.startAnimating() } else { spinner.stopAnimating() }
    }
}
#Preview {
    UINavigationController(
        rootViewController: HomeViewController(
            viewModel: HomeViewModel()
        )
    )
}
