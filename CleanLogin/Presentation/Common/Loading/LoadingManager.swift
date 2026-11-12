//
//  LoadingManager.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//



import UIKit

@MainActor
final class LoadingManager {

    static let shared = LoadingManager()

    private var overlay: LoadingOverlayView?

    private init() {}

    func show(in window: UIWindow? = nil) {
        guard overlay == nil else { return }

        guard let window = window ?? activeWindow() else {
            return
        }

        let loading = LoadingOverlayView()
        loading.translatesAutoresizingMaskIntoConstraints = false

        window.addSubview(loading)

        NSLayoutConstraint.activate([
            loading.topAnchor.constraint(equalTo: window.topAnchor),
            loading.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            loading.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            loading.trailingAnchor.constraint(equalTo: window.trailingAnchor)
        ])

        window.bringSubviewToFront(loading)
        overlay = loading
    }

    func hide() {
        overlay?.stop()
        overlay?.removeFromSuperview()
        overlay = nil
    }

    private func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
    }
}
