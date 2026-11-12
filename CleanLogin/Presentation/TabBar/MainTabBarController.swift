//
//  MainTabBarController.swift
//  CleanLogin
//
//  Created by Administrator on 30/10/26.
//



import UIKit

@MainActor
final class MainTabBarController: UITabBarController {

    init(
        home: UIViewController,
        listening: UIViewController,
        progress: UIViewController,
        profile: UIViewController
    ) {
        super.init(nibName: nil, bundle: nil)

        setupTabs(
            home: home,
            listening: listening,
            progress: progress,
            profile: profile
        )
        setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use custom initializer")
    }

    private func setupTabs(
        home: UIViewController,
        listening: UIViewController,
        progress: UIViewController,
        profile: UIViewController
    ) {
        viewControllers = [
            makeTab(
                home,
                title: "Trang chủ",
                icon: "house",
                selectedIcon: "house.fill"
            ),
            makeTab(
                listening,
                title: "Luyện nghe",
                icon: "headphones",
                selectedIcon: "headphones"
            ),
            makeTab(
                progress,
                title: "Tiến độ",
                icon: "chart.bar",
                selectedIcon: "chart.bar.fill"
            ),
            makeTab(
                profile,
                title: "Cá nhân",
                icon: "person",
                selectedIcon: "person.fill"
            )
        ]
    }

    private func makeTab(
        _ screen: UIViewController,
        title: String,
        icon: String,
        selectedIcon: String
    ) -> UIViewController {

        let navigation = UINavigationController(
            rootViewController: screen
        )

        navigation.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: selectedIcon)
        )

        return navigation
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = .white

        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        tabBar.tintColor = AppColors.primary
        tabBar.unselectedItemTintColor = AppColors.secondaryText

        // Bỏ shadow nếu được thêm thủ công
        tabBar.layer.shadowOpacity = 0
        tabBar.layer.shadowColor = UIColor.clear.cgColor
        tabBar.layer.shadowRadius = 0
        tabBar.layer.shadowOffset = .zero
    }
}
