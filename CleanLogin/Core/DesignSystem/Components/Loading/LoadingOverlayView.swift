//
//  LoadingOverlayView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//



import UIKit

final class LoadingOverlayView: UIView {

    private let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .white
        view.hidesWhenStopped = true
        return view
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
        // Nền đen mờ
        backgroundColor = UIColor.black.withAlphaComponent(0.35)

        // Chặn thao tác với màn hình phía dưới
        isUserInteractionEnabled = true

        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        spinner.startAnimating()
    }

    func stop() {
        spinner.stopAnimating()
    }
}
