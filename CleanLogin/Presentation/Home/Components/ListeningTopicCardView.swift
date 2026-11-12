//
//  ListeningTopicCardView.swift
//  CleanLogin
//
//  Created by Administrator on 30/10/26.
//



import UIKit

final class ListeningTopicCardView: UIControl {

    var onTapped: (() -> Void)?

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let arrowView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16

        // Icon container
        iconContainer.backgroundColor = AppColors.avatarBackground
        iconContainer.layer.cornerRadius = 12
        iconContainer.isUserInteractionEnabled = false

        iconView.tintColor = AppColors.primary
        iconView.contentMode = .scaleAspectFit

        iconContainer.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        // Text
        titleLabel.font = AppFonts.bodyMedium
        titleLabel.textColor = AppColors.text
        titleLabel.numberOfLines = 0

        subtitleLabel.font = AppFonts.caption
        subtitleLabel.textColor = AppColors.secondaryText
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel
        ])

        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .fill

        // Arrow
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = AppColors.secondaryText
        arrowView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            arrowView.widthAnchor.constraint(equalToConstant: 12),
            arrowView.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Row
        let row = UIStackView(arrangedSubviews: [
            iconContainer,
            textStack,
            arrowView
        ])

        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.distribution = .fill
        row.isUserInteractionEnabled = false

        addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])

        addTarget(
            self,
            action: #selector(handleTap),
            for: .touchUpInside
        )
    }

    func configure(with topic: ListeningTopic) {
        titleLabel.text = topic.title
        subtitleLabel.text = topic.subtitle
        iconView.image = UIImage(systemName: topic.icon)
    }

    @objc private func handleTap() {
        onTapped?()
    }
}
