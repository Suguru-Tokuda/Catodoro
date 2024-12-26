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
    var preferences: CatodoroPreferencesProtocol?

    init(navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let timerConfigViewController = TimerConfigViewController(preferences: preferences)
        timerConfigViewController.delegate = self
        self.navigationController.pushViewController(timerConfigViewController, animated: false)
    }

    func navigateToTimerView(viewModel: TimerConfigViewModel) {
        let viewController = TimerViewController(preferences: preferences)
        viewController.delegate = self
        viewController.configure(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension TimerCoordiantor: TimerConfigViewControllerDelegate {
    func didFinishConfiguring(viewModel: TimerConfigViewModel) {
        navigateToTimerView(viewModel: viewModel)
    }
}

extension TimerCoordiantor: TimerViewControllerDelegate {
    func timerViewControllerDidFinish(_ controller: TimerViewController) {
        navigationController.popViewController(animated: true)
    }
}
