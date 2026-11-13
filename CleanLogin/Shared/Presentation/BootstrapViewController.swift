import UIKit

@MainActor
final class BootstrapViewController: UIViewController {
    var onRetry: (() -> Void)?
    var onReset: (() -> Void)?
    private let messageLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let retryButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Clean Login"
        view.backgroundColor = .systemBackground
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        retryButton.setTitle("Thử lại", for: .normal)
        resetButton.setTitle("Xóa phiên và đăng nhập lại", for: .normal)
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [spinner, messageLabel, retryButton, resetButton])
        stack.axis = .vertical
        stack.spacing = 20
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    func showLoading() {
        loadViewIfNeeded()
        messageLabel.text = "Đang kiểm tra phiên đăng nhập…"
        spinner.isHidden = false
        spinner.startAnimating()
        retryButton.isHidden = true
        resetButton.isHidden = true
    }

    func showError(_ message: String, canRetry: Bool = true) {
        loadViewIfNeeded()
        messageLabel.text = message
        spinner.stopAnimating()
        spinner.isHidden = true
        retryButton.isHidden = !canRetry
        resetButton.isHidden = !canRetry
    }

    @objc private func retry() { onRetry?() }
    @objc private func reset() { onReset?() }
}
