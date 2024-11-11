//
//  SettingsCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class SettingsCoordinator: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let settingsViewController = SettingsViewController()
        settingsViewController.setCoordinator(coordinator: self)
        self.navigationController.pushViewController(settingsViewController, animated: false)
    }
}
