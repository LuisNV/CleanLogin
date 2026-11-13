//
//  ListeningTopicSectionView.swift
//  CleanLogin
//
//  Created by Administrator on 30/10/26.
//



import UIKit

final class ListeningTopicSectionView: UIView {

    var onTopicTapped: ((ListeningTopic) -> Void)?

    private let titleLabel = UILabel()
    private let listStack = UIStackView()
    private let mainStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        titleLabel.text = "Luyện nghe theo chủ đề"
        titleLabel.font = AppFonts.titleMedium
        titleLabel.textColor = AppColors.text

        // List dọc
        listStack.axis = .vertical
        listStack.spacing = 12
        listStack.alignment = .fill
        listStack.distribution = .fill

        // Section
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .fill

        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(listStack)

        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with topics: [ListeningTopic]) {

        // Xóa các card cũ khi cập nhật dữ liệu
        listStack.arrangedSubviews.forEach { view in
            listStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Tạo card từ dữ liệu mới
        topics.forEach { [weak self] topic in
            let card = ListeningTopicCardView()
            card.configure(with: topic)

            card.onTapped = { [weak self] in
                self?.onTopicTapped?(topic)
            }

            self?.listStack.addArrangedSubview(card)
        }
    }
}
