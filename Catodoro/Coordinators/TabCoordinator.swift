//
//  MainCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

protocol TabCoordinatorProtocol: Coordinator {
    var tabBarController: UITabBarController { get set }

    func selectPage(_ page: TabBarPage)

    func setSelectedIndex(_ index: Int)

    func currentPage() -> TabBarPage?
}

class TabCoordinator: NSObject, TabCoordinatorProtocol {
    var finishDelegate: (any CoordinatorFinishDelegate)?
    
    var type: CoordinatorType { .tab }
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var tabBarController: UITabBarController

    /// Coordinators
    var timerCoordinator: TimerCoordiantor?
    var presetsCoordiantor: PresetsCoordinator?
    var settingsCoordinator: SettingsCoordinator?

    required init(_ navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
        self.tabBarController = .init()
    }

    func start() {
        let pages: [TabBarPage] = [.timer, .presets, .settings].sorted(by: { $0.tabOrderNumber < $1.tabOrderNumber })
        // Initialization of ViewControllers
        let controllers: [UINavigationController] = pages.compactMap({ getTabController($0) })
        prepareTabBarController(withTabControllers: controllers)
    }

    private func getTabController(_ page: TabBarPage) -> UINavigationController? {
        var navController: UINavigationController?

        switch page {
        case .timer:
            timerCoordinator = .init()
            if let timerCoordinator {
                timerCoordinator.start()
                navController = timerCoordinator.navigationController
            }
        case .presets:
            presetsCoordiantor = .init()
            if let presetsCoordiantor {
                presetsCoordiantor.start()
                navController = presetsCoordiantor.navigationController
            }
        case .settings:
            settingsCoordinator = .init()
            if let settingsCoordinator {
                settingsCoordinator.start()
                navController = settingsCoordinator.navigationController
            }
        }

        navController?.setNavigationBarHidden(false, animated: false)

        navController?.tabBarItem = UITabBarItem.init(title: page.tabTitle,
                                                     image: page.tabImage,
                                                     tag: page.tabOrderNumber)
        return navController
    }
    
    private func prepareTabBarController(withTabControllers tabControllers: [UIViewController]) {
        /// Set delegate for UITabBarController
        tabBarController.delegate = self
        /// Assign page's controllers
        tabBarController.setViewControllers(tabControllers, animated: false)
        /// Let set index
        tabBarController.selectedIndex = TabBarPage.timer.tabOrderNumber
        /// Styling
        tabBarController.tabBar.isTranslucent = false

        /// In this step, we attach tabBarController to navigation controller associated with this coordiantor
        navigationController.viewControllers = [tabBarController]
    }

    func selectPage(_ page: TabBarPage) {
        UIView.performWithoutAnimation {
            tabBarController.selectedIndex = page.tabOrderNumber
        }
    }

    func setSelectedIndex(_ index: Int) {
        guard let page = TabBarPage.init(index: index) else { return }
        selectPage(page)
    }

    func currentPage() -> TabBarPage? {
        .init(index: tabBarController.selectedIndex)
    }
}

extension TabCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let newIndex = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        setSelectedIndex(newIndex)
        return false
    }
}