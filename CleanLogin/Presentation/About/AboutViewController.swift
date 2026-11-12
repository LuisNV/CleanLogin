//
//  AboutViewController.swift
//  CleanLogin
//
//  Created by Administrator on 23/10/26.
//

import UIKit

@MainActor
final class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Thông tin ứng dụng"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Ứng dụng CleanLogin\nPhiên bản 1.0"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true

        view.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            ),
            label.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            label.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            )
        ])
    }
}

