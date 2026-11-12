//
//  AlertOnboardingView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Second onboarding step: alarms (iOS 26+) or notifications for phase endings.
final class AlertOnboardingView: BaseView {
    var onAllow: (() -> Void)?
    var onNotNow: (() -> Void)?

    private let kind: AlertOnboardingViewModel.Kind
    private let contentView = OnboardingContentView()
    private let allowButton: OnboardingButton
    private let notNowButton = OnboardingButton(title: AppStrings.Onboarding.notNow, kind: .secondary)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(kind: AlertOnboardingViewModel.Kind) {
        self.kind = kind
        allowButton = OnboardingButton(title: Self.allowTitle(for: kind), kind: .primary)
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func constructView() {
        super.constructView()
        backgroundColor = CatTheme.background
    }

    override func constructSubviews() {
        super.constructSubviews()
        addAutolayoutSubview(contentView)

        allowButton.onTap { [weak self] in self?.onAllow?() }
        notNowButton.onTap { [weak self] in self?.onNotNow?() }
        spinner.hidesWhenStopped = true

        contentView.addArrangedSubviews([
            OnboardingLabel(text: AppStrings.Onboarding.catodoro, style: .caption1, color: CatTheme.secondaryText),
            OnboardingImageView(imageName: "CatSleeping"),
            OnboardingLabel(text: AppStrings.Onboarding.alertHeadline, style: .title1, weight: .bold),
            OnboardingLabel(text: Self.bodyText(for: kind), style: .body, color: CatTheme.secondaryText),
            OnboardingBenefitsCardView(benefits: Self.benefits(for: kind)),
            allowButton,
            notNowButton,
            OnboardingLabel(text: AppStrings.Onboarding.youCanChangeThisLaterInSettings, style: .footnote, color: CatTheme.secondaryText),
            spinner
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

    func render(isBusy: Bool) {
        allowButton.isEnabled = !isBusy
        notNowButton.isEnabled = !isBusy
        if isBusy { spinner.startAnimating() } else { spinner.stopAnimating() }
    }

    // MARK: Copy for each kind

    static func bodyText(for kind: AlertOnboardingViewModel.Kind) -> String {
        switch kind {
        case .alarm: AppStrings.Onboarding.alarmDescription
        case .notification: AppStrings.Onboarding.notificationDescription
        }
    }

    static func allowTitle(for kind: AlertOnboardingViewModel.Kind) -> String {
        switch kind {
        case .alarm: AppStrings.Onboarding.allowAlarms
        case .notification: AppStrings.Onboarding.allowNotifications
        }
    }

    static func benefits(for kind: AlertOnboardingViewModel.Kind) -> [OnboardingBenefitsCardView.Benefit] {
        switch kind {
        case .alarm:
            [.init(symbolName: "speaker.wave.3", text: AppStrings.Onboarding.alarmRingsInSilentMode),
             .init(symbolName: "lock.iphone", text: AppStrings.Onboarding.alarmShowsCountdownOnLockScreen),
             .init(symbolName: "stop.circle", text: AppStrings.Onboarding.alarmStopFromLockScreen)]
        case .notification:
            [.init(symbolName: "bell.badge", text: AppStrings.Onboarding.notificationAlertsWhenPhaseEnds),
             .init(symbolName: "lock.iphone", text: AppStrings.Onboarding.notificationShowsOnLockScreen)]
        }
    }
}

#if DEBUG
extension AlertOnboardingView {
    var testHooks: TestHooks { .init(target: self) }

    struct TestHooks {
        let target: AlertOnboardingView

        var allowButton: OnboardingButton { target.allowButton }
        var notNowButton: OnboardingButton { target.notNowButton }
        var spinner: UIActivityIndicatorView { target.spinner }
        var benefitsCard: OnboardingBenefitsCardView? {
            target.contentView.arrangedSubviews.compactMap { $0 as? OnboardingBenefitsCardView }.first
        }
    }
}
#endif
