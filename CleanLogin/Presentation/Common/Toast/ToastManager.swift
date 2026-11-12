//
//  ToastManager.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//
import UIKit

@MainActor
final class ToastManager {

    static let shared = ToastManager()

    private var toastView: UIView?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func showError(_ message: String,title: String = "Thông báo lỗi", in window: UIWindow? = nil) {
        guard let window = window ?? activeWindow() else { return }

        // Xóa notification cũ
        dismissTask?.cancel()
        toastView?.removeFromSuperview()

        let toast = UIView()
        toast.backgroundColor = UIColor(
            red: 1, green: 0.95, blue: 0.95, alpha: 1
        )
        toast.layer.cornerRadius = 14
        toast.layer.borderWidth = 1
        toast.layer.borderColor = UIColor.systemRed
            .withAlphaComponent(0.25).cgColor

        toast.layer.shadowColor = UIColor.black.cgColor
        toast.layer.shadowOpacity = 0.12
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 5)

        let icon = UIImageView(
            image: UIImage(systemName: "xmark.circle.fill")
        )
        icon.tintColor = .systemRed
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .systemRed

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [
            titleLabel, messageLabel
        ])
        textStack.axis = .vertical
        textStack.spacing = 4

        let stack = UIStackView(arrangedSubviews: [
            icon, textStack
        ])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 12

        toast.addSubview(stack)
        window.addSubview(toast)

        toast.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toast.topAnchor.constraint(
                equalTo: window.safeAreaLayoutGuide.topAnchor,
                constant: 12
            ),
            toast.leadingAnchor.constraint(
                equalTo: window.leadingAnchor,
                constant: 20
            ),
            toast.trailingAnchor.constraint(
                equalTo: window.trailingAnchor,
                constant: -20
            ),

            stack.topAnchor.constraint(equalTo: toast.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -16)
        ])

        window.layoutIfNeeded()

        toast.transform = CGAffineTransform(
            translationX: 0, y: -150
        )
        toast.alpha = 0

        toastView = toast

        // Animation trượt xuống
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5
        ) {
            toast.transform = .identity
            toast.alpha = 1
        }

        // Tự ẩn sau 3 giây
        dismissTask = Task { [weak self, weak toast] in
            try? await Task.sleep(for: .seconds(3))

            guard !Task.isCancelled,
                  let self,
                  let toast,
                  self.toastView === toast else { return }

            UIView.animate(withDuration: 0.25) {
                toast.alpha = 0
                toast.transform = CGAffineTransform(
                    translationX: 0, y: -80
                )
            } completion: { _ in
                toast.removeFromSuperview()
                if self.toastView === toast {
                    self.toastView = nil
                }
            }
        }
    }

    private func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
    }
}
