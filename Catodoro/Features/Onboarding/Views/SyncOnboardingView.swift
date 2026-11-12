//
//  SyncOnboardingView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import CatodoroShared
import UIKit

/// First onboarding step: iCloud sync or this device only.
final class SyncOnboardingView: BaseView {
    var onEnableSync: (() -> Void)?
    var onContinueLocally: (() -> Void)?

    private let contentView = OnboardingContentView()
    private let enableButton = OnboardingButton(title: AppStrings.Onboarding.enableICloudSync, kind: .primary)
    private let localButton = OnboardingButton(title: AppStrings.Onboarding.continueOnThisDevice, kind: .secondary)
    private let errorLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override func constructView() {
        super.constructView()
        backgroundColor = CatTheme.background
    }

    override func constructSubviews() {
        super.constructSubviews()
        addAutolayoutSubview(contentView)

        enableButton.onTap { [weak self] in self?.onEnableSync?() }
        localButton.onTap { [weak self] in self?.onContinueLocally?() }

        spinner.hidesWhenStopped = true
        errorLabel.numberOfLines = 0
        errorLabel.font = CatTheme.font(.footnote)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true

        contentView.addArrangedSubviews([
            OnboardingLabel(text: AppStrings.Onboarding.catodoro, style: .caption1, color: CatTheme.secondaryText),
            OnboardingImageView(imageName: "CatCloud"),
            OnboardingLabel(text: AppStrings.Onboarding.headline, style: .title1, weight: .bold),
            OnboardingLabel(text: AppStrings.Onboarding.syncDescription, style: .body, color: CatTheme.secondaryText),
            OnboardingBenefitsCardView(benefits: [
                .init(symbolName: "arrow.triangle.2.circlepath", text: AppStrings.Onboarding.keepPresetsInSyncAcrossYourDevices),
                .init(symbolName: "icloud.and.arrow.down", text: AppStrings.Onboarding.bringBackPresetsAlreadySavedInICloud),
                .init(symbolName: "wifi.slash", text: AppStrings.Onboarding.keepFocusingAndSavingPresetsOffline)
            ]),
            enableButton,
            localButton,
            OnboardingLabel(text: AppStrings.Onboarding.youCanChangeThisLaterInSettings, style: .footnote, color: CatTheme.secondaryText),
            spinner,
            errorLabel
        ])
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func render(isBusy: Bool, error: String?) {
        enableButton.isEnabled = !isBusy
        localButton.isEnabled = !isBusy
        enableButton.titleText = error == nil ? AppStrings.Onboarding.enableICloudSync : AppStrings.Onboarding.retryICloudSync
        errorLabel.text = error
        errorLabel.isHidden = error == nil
        if isBusy { spinner.startAnimating() } else { spinner.stopAnimating() }
    }
}

#if DEBUG
extension SyncOnboardingView {
    var testHooks: TestHooks { .init(target: self) }

    struct TestHooks {
        let target: SyncOnboardingView

        var enableButton: OnboardingButton { target.enableButton }
        var localButton: OnboardingButton { target.localButton }
        var errorLabel: UILabel { target.errorLabel }
        var spinner: UIActivityIndicatorView { target.spinner }
    }
}
#endif
