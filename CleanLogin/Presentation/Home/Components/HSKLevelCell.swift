//
//  HSKLevelCell.swift
//  CleanLogin
//
//  Created by Administrator on 30/10/26.
//



import UIKit

final class HSKLevelCell: UICollectionViewCell {

    static let reuseIdentifier = "HSKLevelCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor =
            AppColors.avatarBackground.cgColor

        let iconContainer = UIView()
        iconContainer.backgroundColor = AppColors.avatarBackground
        iconContainer.layer.cornerRadius = 12

        iconView.image = UIImage(systemName: "book")
        iconView.tintColor = AppColors.primary
        iconView.contentMode = .scaleAspectFit

        iconContainer.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 38),
            iconContainer.heightAnchor.constraint(equalToConstant: 38),

            iconView.centerXAnchor.constraint(
                equalTo: iconContainer.centerXAnchor
            ),
            iconView.centerYAnchor.constraint(
                equalTo: iconContainer.centerYAnchor
            ),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])

        titleLabel.font = AppFonts.titleMedium
        titleLabel.textColor = AppColors.text

        subtitleLabel.font = AppFonts.caption
        subtitleLabel.textColor = AppColors.secondaryText

        progressLabel.font = AppFonts.subheadline
        progressLabel.textColor = AppColors.primary

        let stack = UIStackView(arrangedSubviews: [
            iconContainer,
            titleLabel,
            subtitleLabel,
            progressLabel
        ])

        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        stack.setCustomSpacing(12, after: iconContainer)
        stack.setCustomSpacing(10, after: titleLabel)

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 12
            ),
            stack.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12
            ),
            stack.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -12
            ),
            stack.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -12
            )
        ])
    }

    func configure(with item: HSKLevel) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        progressLabel.text = "\(item.progress)%"
    }
}
