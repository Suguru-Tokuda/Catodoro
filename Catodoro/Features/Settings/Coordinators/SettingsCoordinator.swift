//
//  SettingsCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import CatodoroShared
import UIKit

class SettingsCoordinator: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let dependencies: AppDependencies

    init(navigationController: UINavigationController = BaseNavigationController(),
         dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let settingsViewController = SettingsViewController(preferences: dependencies.preferences,
                                                            syncLifecycleManager: dependencies.syncLifecycleManager)
        settingsViewController.delegate = self
        navigationController.pushViewController(settingsViewController, animated: false)
    }

    /// Each option screen gets its own child coordinator. It removes itself
    /// through `coordinatorDidFinish` once its screen leaves the stack.
    private func startChild(_ child: Coordinator) {
        child.finishDelegate = self
        childCoordinators.append(child)
        child.start()
    }

    private func makeChild(for option: SettingOptions) -> Coordinator {
        switch option {
        case .alertStyle:
            AlertStyleSelectionCoordinator(navigationController: navigationController, dependencies: dependencies)
        case .color:
            ColorSelectionCoordinator(navigationController: navigationController, dependencies: dependencies)
        case .sound:
            SoundSelectionCoordinator(navigationController: navigationController, dependencies: dependencies)
        }
    }
}

extension SettingsCoordinator: SettingsViewControllerDelegate {
    func onSettingMenuSelected(settingOption: SettingOptions) {
        // One option screen at a time; ignores a quick double tap on a row.
        guard childCoordinators.isEmpty else { return }
        startChild(makeChild(for: settingOption))
    }
}

extension SettingsCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: Coordinator) {
        childCoordinators.removeAll { $0 === childCoordinator }
    }
}
