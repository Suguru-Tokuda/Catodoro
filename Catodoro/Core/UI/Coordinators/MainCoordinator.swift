//
//  MainCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

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
            return "Focus"
        case .presets:
            return "Presets"
        case .settings:
            return "Settings"
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
    private let preferences: CatodoroPreferences
    private let coreDataManager: CatodoroCoreDataManaging
    weak var liveActivityManager: LiveActivityManaging?
    private let syncLifecycleManager: SyncLifecycleManaging

    required init(_ navigationController: UINavigationController? = nil,
                  preferences: CatodoroPreferences,
                  liveActivityManager: LiveActivityManaging?,
                  coreDataManager: CatodoroCoreDataManaging,
                  syncLifecycleManager: SyncLifecycleManaging
    ) {
        self.coreDataManager = coreDataManager
        self.navigationController = navigationController ?? BaseNavigationController()
        self.preferences = preferences
        self.liveActivityManager = liveActivityManager
        self.syncLifecycleManager = syncLifecycleManager
        self.navigationController.setNavigationBarHidden(true, animated: false)        
    }

    func start() {
        syncLifecycleManager.start()

        if preferences.hasCompletedOnboarding {
            showMainFlow()
        } else {
            let viewModel = OnboardingViewModel(
                lifecycle: syncLifecycleManager,
                preferences: preferences
            )
            let onboarding = OnboardingCoordinator(navigationController: navigationController, viewModel: viewModel)
            onboarding.finishDelegate = self
            childCoordinators.append(onboarding)
            onboarding.start()
        }
    }

    func showMainFlow() {
        let tabCoordinator = TabCoordinator.init(navigationController,
                                                 preferences: preferences,
                                                 liveActivityManager: liveActivityManager,
                                                 coreDataManager: coreDataManager,
                                                 syncLifecycleManager: syncLifecycleManager)
        tabCoordinator.finishDelegate = self
        tabCoordinator.start()
        childCoordinators.append(tabCoordinator)
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
