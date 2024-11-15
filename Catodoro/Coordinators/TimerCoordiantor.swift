//
//  TimerCoordiantor.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class TimerCoordiantor: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let timerConfigViewController = TimerConfigViewController()
        timerConfigViewController.setCoordinator(coordinator: self)
        self.navigationController.pushViewController(timerConfigViewController, animated: false)
    }

    func navigateToTimerView(viewModel: TimerConfigViewModel) {
        let viewController = TimerViewController()
        viewController.setCoordinator(coordinator: self)
        viewController.configure(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
