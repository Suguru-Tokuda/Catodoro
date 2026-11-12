//
//  MainCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import CatodoroShared
import UIKit

enum TabBarPage {
    case timer
    case presets
    case settings

    init?(index: Int) {
        switch index {
        case 0:
            self = .timer
        case 1:
            self = .presets
        case 2:
            self = .settings
        default:
            return nil
        }
    }
    
    var tabTitle: String {
        switch self {
        case .timer:
            return AppStrings.Common.focus
        case .presets:
            return AppStrings.Common.presets
        case .settings:
            return AppStrings.Common.settings
        }
    }

    var tabOrderNumber: Int {
        switch self {
        case .timer:
            return 0
        case .presets:
            return 1
        case .settings:
            return 2
        }
    }

    var tabImage: UIImage? {
        switch self {
        case .timer:
            return UIImage(named: "CatPaw")?
                .preparingThumbnail(of: CGSize(width: 25, height: 25))?
                .withRenderingMode(.alwaysTemplate)
        case .presets:
            return UIImage(systemName: "list.bullet")
        case .settings:
            return UIImage(systemName: "gear")
        }
    }
}

protocol MainCoordinatorProtocol: Coordinator {
    func showMainFlow()
}

@MainActor
class MainCoordinator: @preconcurrency MainCoordinatorProtocol {
    weak var finishDelegate: CoordinatorFinishDelegate? = nil
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()
    var type: CoordinatorType { .app }
    private let dependencies: AppDependencies

    required init(_ navigationController: UINavigationController? = nil,
                  dependencies: AppDependencies) {
        self.navigationController = navigationController ?? BaseNavigationController()
        self.dependencies = dependencies
        self.navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        dependencies.syncLifecycleManager.start()

        if dependencies.preferences.hasCompletedOnboarding {
            showMainFlow()
        } else {
            let onboarding = OnboardingCoordinator(navigationController: navigationController,
                                                   dependencies: dependencies)
            onboarding.finishDelegate = self
            childCoordinators.append(onboarding)
            onboarding.start()
        }
    }

    func showMainFlow() {
        let tabCoordinator = TabCoordinator(navigationController, dependencies: dependencies)
        tabCoordinator.finishDelegate = self
        tabCoordinator.start()
        childCoordinators.append(tabCoordinator)
    }

    func handle(_ url: URL) {
        guard DeepLink.isTimer(url),
              let tabs = childCoordinators.first(where: { $0 is TabCoordinator }) as? TabCoordinator else {
            return
        }

        tabs.showRunningCycle()
    }
}

extension MainCoordinator: @preconcurrency CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === childCoordinator }
        if childCoordinator is OnboardingCoordinator {
            showMainFlow()
        }
    }
}
