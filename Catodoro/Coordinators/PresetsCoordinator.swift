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

    init(navigationController: UINavigationController = BaseNavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let presetsViewController = PresetsViewController()
        presetsViewController.delegate = self
        navigationController.pushViewController(presetsViewController, animated: false)
    }

    func navigateToAddPreset(onFinish: @escaping(() -> Void)) {
        let addPresetViewController = AddPresetViewController(preferences: preferences)
        addPresetViewController.delegate = self
        navigationController.pushViewController(addPresetViewController, animated: true)
    }
}

extension PresetsCoordinator: PresetsViewControllerDelegate {
    func presetsViewControllerDidSelectPreset(_ viewController: PresetsViewController, preset: PresetModel) {
        delegate?.startTimer(model: preset)
    }
    
    func presetsViewControllerDidTapAddButton(_ viewController: PresetsViewController, onFinish: @escaping(() -> Void)) {
        navigateToAddPreset { [weak self] in
            guard self != nil else { return }
            onFinish()
        }
    }
}

extension PresetsCoordinator: AddPresetViewControllerDelegate {
    func onFinish() {
        navigationController.popViewController(animated: true)
    }
}
