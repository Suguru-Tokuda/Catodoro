//
//  MainCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
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

    weak var preferences: CatodoroPreferences?
    private let coreDataManager: CatodoroCoreDataManaging
    weak var liveActivityManager: LiveActivityManaging?

    private var subscriptions: Set<AnyCancellable> = .init()

    required init(_ navigationController: UINavigationController = BaseNavigationController(),
                  preferences: CatodoroPreferences?,
                  liveActivityManager: LiveActivityManaging?,
                  coreDataManager: CatodoroCoreDataManaging) {
        self.coreDataManager = coreDataManager
        self.navigationController = navigationController
        self.preferences = preferences
        self.liveActivityManager = liveActivityManager
        self.tabBarController = .init()
        super.init()
        self.addSubscriptions()
    }

    private func addSubscriptions() {
        preferences?
            .colorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] color in
                guard let self else { return }
                if let color {
                    let colorOption = ColorOptions(color)
                    tabBarController.tabBar.tintColor = colorOption.color
                } else {
                    tabBarController.tabBar.tintColor = ColorOptions.neonBlue.color
                }
            }
            .store(in: &subscriptions)
    }

    private func removeSubscriptions() {
        subscriptions.removeAll()
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
            timerCoordinator = TimerCoordiantor(configuration: TimerCoordinatorConfiguration(shouldHideBottomBarWhenTimerStart: true), coreDataManager: coreDataManager)
            timerCoordinator?.preferences = preferences
            timerCoordinator?.liveActivityManager = liveActivityManager
            if let timerCoordinator {
                timerCoordinator.start()
                navController = timerCoordinator.navigationController
            }
        case .presets:
            presetsCoordiantor = PresetsCoordinator(configuration: PresetsCoordinatorConfiguration(shouldHideBottomBar: true), coreDataManager: coreDataManager)
            presetsCoordiantor?.preferences = preferences
            presetsCoordiantor?.liveActivityManager = liveActivityManager
            if let presetsCoordiantor {
                presetsCoordiantor.start()
                navController = presetsCoordiantor.navigationController
            }
        case .settings:
            settingsCoordinator = SettingsCoordinator()
            settingsCoordinator?.preferences = preferences
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
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CatTheme.background
        appearance.shadowColor = .clear
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.unselectedItemTintColor = CatTheme.secondaryText
        tabBarController.tabBar.tintColor = ColorOptions(preferences?.color ?? "").color
        tabBarController.view.backgroundColor = CatTheme.background
        tabBarController.tabBar.backgroundColor = CatTheme.background
        tabBarController.tabBar.isTranslucent = false

        /// In this step, we attach tabBarController to navigation controller associated with this coordiantor
        navigationController.viewControllers = [tabBarController]
    }

    func selectPage(_ page: TabBarPage) {
        UIView.performWithoutAnimation { [weak self] in
            self?.tabBarController.selectedIndex = page.tabOrderNumber
        }
    }

    func setSelectedIndex(_ index: Int) {
        guard let page = TabBarPage.init(index: index) else { return }
        selectPage(page)
    }

    func currentPage() -> TabBarPage? {
        .init(index: tabBarController.selectedIndex)
    }

    deinit {
        removeSubscriptions()
    }
}

extension TabCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let newIndex = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        setSelectedIndex(newIndex)
        return false
    }
}

