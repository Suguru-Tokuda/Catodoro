//
//  AlertStyleSelectionCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Pushes the alert style screen onto the Settings stack.
final class AlertStyleSelectionCoordinator: Coordinator {
    weak var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let dependencies: AppDependencies

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = AlertStyleSelectionViewModel(preferences: dependencies.preferences,
                                                     countdown: dependencies.countdown)
        let viewController = AlertStyleSelectionViewController(viewModel: viewModel,
                                                               titleLabelText: AppStrings.Settings.alarm)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension AlertStyleSelectionCoordinator: AlertStyleSelectionViewControllerDelegate {
    func alertStyleSelectionViewControllerDidFinish(_ viewController: AlertStyleSelectionViewController) {
        guard navigationController.topViewController === viewController else { return }
        navigationController.popViewController(animated: true)
    }

    func alertStyleSelectionViewControllerDidClose(_ viewController: AlertStyleSelectionViewController) {
        finish()
    }
}
