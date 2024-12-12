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

        self.navigationController.pushViewController(presetsViewController, animated: false)
    }
}
