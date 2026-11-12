//
//  SoundSelectionCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Pushes the alert sound screen onto the Settings stack.
final class SoundSelectionCoordinator: Coordinator {
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
        let viewModel = SoundSelectionViewModel(preferences: dependencies.preferences)
        let viewController = SoundSelectionViewController(viewModel: viewModel,
                                                          titleLabelText: AppStrings.Settings.sound)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension SoundSelectionCoordinator: SoundSelectionViewControllerDelegate {
    func soundSelectionViewControllerDidFinish(_ viewController: SoundSelectionViewController) {
        guard navigationController.topViewController === viewController else { return }
        navigationController.popViewController(animated: true)
    }

    func soundSelectionViewControllerDidClose(_ viewController: SoundSelectionViewController) {
        finish()
    }
}
