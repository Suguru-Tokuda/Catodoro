//
//  PresetsCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

protocol PresetsCoordinatorDelegate: AnyObject {
    func startTimer(model: PresetModel)
}

class PresetsCoordinator: Coordinator {
    weak var delegate: PresetsCoordinatorDelegate?
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var preferences: CatodoroPreferences?

    init(navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let presetsViewController = PresetsViewController()
        presetsViewController.setCoordinator(coordinator: self)
        presetsViewController.onPresetSelected = { [weak self] preset in
            guard let self else { return }
            delegate?.startTimer(model: preset)
        }

        navigationController.pushViewController(presetsViewController, animated: false)
    }

    func navigateToAddPreset(onFinish: @escaping(() -> Void)) {
        let addPresetViewController = AddPresetViewController(preferences: preferences)
        addPresetViewController.setCoordinator(coordinator: self)
        addPresetViewController.onFinish = { [weak self] in
            guard let self else { return }
            onFinish()
            navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(addPresetViewController, animated: true)
    }
}
