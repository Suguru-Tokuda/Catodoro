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
    private let dependencies: AppDependencies

    init(navigationController: UINavigationController = BaseNavigationController(),
         configuration: TimerCoordinatorConfiguration = TimerCoordinatorConfiguration(),
         dependencies: AppDependencies
    ) {
        self.navigationController = navigationController
        self.configuration = configuration
        self.dependencies = dependencies
    }

    func start() {
        let timerConfigViewController = TimerConfigViewController(preferences: dependencies.preferences,
                                                                  viewModel: TimerConfigViewModel(coreDataManager: dependencies.coreDataManager))
        timerConfigViewController.delegate = self
        self.navigationController.pushViewController(timerConfigViewController, animated: false)
    }

    func navigateToTimerView(viewModel: TimerConfigViewModel) {
        let viewController = makeTimerViewController()
        viewController.configure(config: viewModel.timerModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    /// Puts the timer screen back for a cycle that survived a relaunch.
    func showRunningCycle(_ session: CycleSession) {
        let controller = makeTimerViewController()
        controller.attach(to: session)
        navigationController.pushViewController(controller, animated: false)
    }

    private func makeTimerViewController() -> TimerViewController {
        let timerViewModel = TimerViewModel(
            countdown: dependencies.countdown,
            preferences: dependencies.preferences,
            hapticsManager: dependencies.hapticsManager
        )
        let controller = TimerViewController(viewModel: timerViewModel,
                                             preferences: dependencies.preferences,
                                             shouldHidesBottomBarWhen: configuration.shouldHideBottomBarWhenTimerStart)
        controller.delegate = self
        return controller
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
