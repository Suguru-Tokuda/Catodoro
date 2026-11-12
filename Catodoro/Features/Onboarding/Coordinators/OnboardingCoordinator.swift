//
//  OnboardingCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import UIKit

/// Runs the first-launch steps as pages: iCloud sync, then alerts.
@MainActor
final class OnboardingCoordinator: @preconcurrency Coordinator {
    enum Step: Int, CaseIterable {
        case sync
        case alert
    }

    weak var finishDelegate: CoordinatorFinishDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var type: CoordinatorType { .feature }
    private let dependencies: AppDependencies
    private var pageViewController: OnboardingPageViewController?

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let sync = OnboardingViewController(viewModel: OnboardingViewModel(
            lifecycle: dependencies.syncLifecycleManager,
            preferences: dependencies.preferences))
        sync.onCompletion { [weak self] in self?.show(.alert) }

        let alert = AlertOnboardingViewController(viewModel: AlertOnboardingViewModel(
            countdown: dependencies.countdown,
            preferences: dependencies.preferences))
        alert.onCompletion { [weak self] in self?.finish() }

        let pages = OnboardingPageViewController(pages: [sync, alert])
        pageViewController = pages
        navigationController.setViewControllers([pages], animated: false)
    }

    func show(_ step: Step) {
        pageViewController?.showPage(at: step.rawValue)
    }
}
