//
//  TimerCoordiantor.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

struct TimerCoordinatorConfiguration {
    let shouldHideBottomBarWhenTimerStart: Bool

    init(shouldHideBottomBarWhenTimerStart: Bool = false) {
        self.shouldHideBottomBarWhenTimerStart = shouldHideBottomBarWhenTimerStart
    }
}

class TimerCoordiantor: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private var configuration: TimerCoordinatorConfiguration
    weak var preferences: CatodoroPreferencesProtocol?
    weak var liveActivityManager: LiveActivityManaging?

    init(navigationController: UINavigationController = BaseNavigationController(),
         configuration: TimerCoordinatorConfiguration = TimerCoordinatorConfiguration()
    ) {
        self.navigationController = navigationController
        self.configuration = configuration
    }

    func start() {
        let timerConfigViewController = TimerConfigViewController(preferences: preferences)
        timerConfigViewController.delegate = self
        self.navigationController.pushViewController(timerConfigViewController, animated: false)
    }

    func navigateToTimerView(viewModel: TimerConfigViewModel) {
        let viewController = TimerViewController(preferences: preferences,
                                                 liveActivityManager: liveActivityManager,
                                                 shouldHidesBottomBarWhen: configuration.shouldHideBottomBarWhenTimerStart
        )
        viewController.delegate = self
        viewController.configure(timerConfigViewModel: viewModel)
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
