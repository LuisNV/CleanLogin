
import UIKit

final class HSKSectionView: UIView {

    var onLevelTapped: ((HSKLevel) -> Void)?
    var onSeeAllTapped: (() -> Void)?

    private let items: [HSKLevel] = [
        .init(title: "HSK 1", subtitle: "Cơ bản", progress: 70),
        .init(title: "HSK 2", subtitle: "Sơ cấp", progress: 0),
        .init(title: "HSK 3", subtitle: "Trung cấp", progress: 0),
        .init(title: "HSK 4", subtitle: "Trung cấp", progress: 0),
        .init(title: "HSK 5", subtitle: "Cao cấp", progress: 0),
        .init(title: "HSK 6", subtitle: "Cao cấp", progress: 0)
    ]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 116, height: 144)
        layout.minimumLineSpacing = 8
        layout.sectionInset = .zero

        let collection = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true

        collection.register(
            HSKLevelCell.self,
            forCellWithReuseIdentifier: HSKLevelCell.reuseIdentifier
        )

        collection.dataSource = self
        collection.delegate = self

        return collection
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
        let titleLabel = UILabel()
        titleLabel.text = "Lộ trình HSK"
        titleLabel.font = AppFonts.titleMedium
        titleLabel.textColor = AppColors.text

        let seeAllButton = UIButton(type: .system)
        seeAllButton.setTitle("Xem tất cả", for: .normal)
        seeAllButton.setTitleColor(AppColors.primary, for: .normal)
        seeAllButton.titleLabel?.font = AppFonts.caption

        seeAllButton.addTarget(
            self,
            action: #selector(seeAllTapped),
            for: .touchUpInside
        )

        let headerStack = UIStackView(arrangedSubviews: [
            titleLabel,
            UIView(),
            seeAllButton
        ])

        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .fill

        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            collectionView
        ])

        mainStack.axis = .vertical
        mainStack.spacing = 14
        mainStack.alignment = .fill

        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            // UICollectionView cần chiều cao xác định
            collectionView.heightAnchor.constraint(
                equalToConstant: 144
            )
        ])
    }

    @objc private func seeAllTapped() {
        onSeeAllTapped?()
    }
}

extension HSKSectionView: UICollectionViewDataSource,
                          UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HSKLevelCell.reuseIdentifier,
            for: indexPath
        ) as! HSKLevelCell

        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        onLevelTapped?(items[indexPath.item])
    }
}
