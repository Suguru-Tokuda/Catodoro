//
//  OnboardingCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import UIKit

final class OnboardingCoordinator: Coordinator {
    weak var finishDelegate: CoordinatorFinishDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var type: CoordinatorType { .feature }
    private let viewModel: OnboardingViewModel

    init(navigationController: UINavigationController, viewModel: OnboardingViewModel) {
        self.navigationController = navigationController
        self.viewModel = viewModel
    }

    func start() {
        let controller = OnboardingViewController(viewModel: viewModel)
        controller.onCompletion { [weak self] in self?.finish() }
        navigationController.setViewControllers([controller], animated: false)
    }
}
