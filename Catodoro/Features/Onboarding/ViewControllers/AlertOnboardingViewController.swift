//
//  AlertOnboardingViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import UIKit

final class AlertOnboardingViewController: BaseViewController {
    private let viewModel: AlertOnboardingViewModel
    private let alertOnboardingView: AlertOnboardingView

    init(viewModel: AlertOnboardingViewModel) {
        self.viewModel = viewModel
        alertOnboardingView = AlertOnboardingView(kind: viewModel.kind)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    func onCompletion(_ completion: @escaping () -> Void) {
        viewModel.onComplete = completion
    }

    override func constructView() {
        super.constructView()
        viewModel.onStateChanged = { [weak self] in self?.render() }
        alertOnboardingView.onAllow = { [weak self] in
            Task { [weak self] in await self?.viewModel.allow() }
        }
        alertOnboardingView.onNotNow = { [weak self] in
            self?.viewModel.skip()
        }
        render()
    }

    override func constructSubviews() {
        super.constructSubviews()
        view.addAutolayoutSubview(alertOnboardingView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            alertOnboardingView.topAnchor.constraint(equalTo: view.topAnchor),
            alertOnboardingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            alertOnboardingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            alertOnboardingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func render() {
        alertOnboardingView.render(isBusy: viewModel.isBusy)
    }
}

#if DEBUG
extension AlertOnboardingViewController {
    var testHooks: TestHooks { .init(target: self) }

    struct TestHooks {
        let target: AlertOnboardingViewController

        var alertOnboardingView: AlertOnboardingView { target.alertOnboardingView }
    }
}
#endif
