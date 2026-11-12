//
//  ColorSelectionCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Pushes the accent color screen onto the Settings stack.
final class ColorSelectionCoordinator: Coordinator {
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
        let viewModel = ColorSelectionViewModel(preferences: dependencies.preferences)
        let viewController = ColorSelectionViewController(viewModel: viewModel,
                                                          titleLabelText: AppStrings.Settings.color)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension ColorSelectionCoordinator: ColorSelectionViewControllerDelegate {
    func colorSelectionViewControllerDidFinish(_ viewController: ColorSelectionViewController) {
        guard navigationController.topViewController === viewController else { return }
        navigationController.popViewController(animated: true)
    }

    func colorSelectionViewControllerDidClose(_ viewController: ColorSelectionViewController) {
        finish()
    }
}
