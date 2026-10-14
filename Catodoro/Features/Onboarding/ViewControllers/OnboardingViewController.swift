//
//  OnboardingViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import UIKit

final class OnboardingViewController: BaseViewController {
    private let viewModel: OnboardingViewModel
    private let onboardingView = OnboardingView()

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    func onCompletion(_ completion: @escaping () -> Void) {
        viewModel.onComplete = completion
    }

    override func constructView() {
        super.constructView()
        viewModel.onStateChanged = { [weak self] in self?.render() }
        onboardingView.onEnableSync = { [weak self] in
            Task { [weak self] in await self?.viewModel.enableSync() }
        }
        onboardingView.onContinueLocally = { [weak self] in
            Task { [weak self] in await self?.viewModel.continueLocally() }
        }
        render()
    }

    override func constructSubviews() {
        super.constructSubviews()
        view.addAutolayoutSubview(onboardingView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            onboardingView.topAnchor.constraint(equalTo: view.topAnchor),
            onboardingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            onboardingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func render() {
        onboardingView.render(isBusy: viewModel.isBusy, error: viewModel.errorMessage)
    }
}
