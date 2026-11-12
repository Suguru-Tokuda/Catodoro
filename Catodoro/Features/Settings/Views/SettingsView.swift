//
//  SettingsView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import CatodoroShared
import UIKit

final class SettingsView: BaseView {
    var onThemeSelected: ((ThemeOption) -> Void)?
    var onColorSelected: ((ColorOptions) -> Void)?
    var onSoundRequested: (() -> Void)?
    var onAlertStyleRequested: (() -> Void)?
    var onLiveActivityChanged: ((Bool) -> Void)?
    var onSyncChanged: ((Bool) -> Void)?
    var onSystemSettingsRequested: (() -> Void)?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space20
        return stack
    }()

    private let mascot = CatIllustrationView(pose: .playful)
    private let appearanceCard = CatCardView()
    private let syncCard = CatCardView()
    private let activityCard = CatCardView()
    private let alarmCard = CatCardView()
    private let syncStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space12
        return stack
    }()
    private let syncSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.accessibilityLabel = AppStrings.Settings.icloudSync
        toggle.accessibilityIdentifier = AccessibilityID.cloudSyncToggle
        return toggle
    }()
    private let syncDescription: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let appearanceStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space16
        return stack
    }()

    private let activityStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space12
        return stack
    }()

    private let alarmStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space12
        return stack
    }()

    private let appearanceTitle: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Settings.yourCozyCorner
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let themeLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Settings.theme
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.secondaryText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let themeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ThemeOption.allCases.map(\.title))
        control.accessibilityLabel = AppStrings.Settings.theme
        control.accessibilityIdentifier = AccessibilityID.themeSelector
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: Spacing.space44).isActive = true
        return control
    }()

    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Settings.accentColor
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.secondaryText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let swatches: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Spacing.space4
        stack.distribution = .fillEqually
        return stack
    }()

    private let colorButtons: [UIButton] = ColorOptions.allCases.map { option in
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = option.color
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .zero
        button.configuration = configuration
        button.accessibilityLabel = AppStrings.Settings.accentLabel(option.title)
        button.accessibilityIdentifier = option.code
        button.heightAnchor.constraint(equalToConstant: Spacing.space44).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: Spacing.space44).isActive = true
        return button
    }

    private let soundRow = CatSummaryRow(title: AppStrings.Settings.timerSound, value: "", symbol: "speaker.wave.2.fill")

    private let alarmRow = CatSummaryRow(title: AppStrings.Settings.alarm, value: "", symbol: "bell.fill")

    private let activityTitle: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Settings.liveActivity
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let activitySwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.accessibilityLabel = AppStrings.Settings.liveActivity
        toggle.accessibilityIdentifier = AccessibilityID.liveActivityToggle
        return toggle
    }()

    private let activityHeader: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.space12
        return stack
    }()

    private let activityDescription: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let alarmTitle: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Settings.alarm
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let alarmHeader: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.space12
        return stack
    }()

    private let alarmDescription: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let systemSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(AppStrings.Settings.openIOSSettings, for: .normal)
        button.titleLabel?.font = CatTheme.font(.body, weight: .semibold)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Spacing.space44).isActive = true
        return button
    }()

    override func constructSubviews() {
        super.constructSubviews()
        constructScrollContent()
        constructSyncCard()
        constructAppearanceCard()
        constructActivityCard()
        constructAlarmCard()
        configureColorActions()
        configureSoundAndActivityActions()
    }

    private func constructScrollContent() {
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stack)
        stack.addArrangedSubviews([mascot, appearanceCard, syncCard, activityCard, alarmCard])
    }

    private func constructSyncCard() {
        syncCard.addAutolayoutSubview(syncStack)

        let syncTitle = UILabel()
        syncTitle.text = AppStrings.Settings.icloudSync
        syncTitle.font = CatTheme.font(.headline, weight: .bold)
        syncTitle.textColor = CatTheme.text
        syncTitle.adjustsFontForContentSizeCategory = true

        let syncHeader = UIStackView(arrangedSubviews: [syncTitle, syncSwitch])
        syncHeader.spacing = Spacing.space12
        syncHeader.alignment = .center

        syncStack.addArrangedSubviews([syncHeader, syncDescription])
        syncSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onSyncChanged?(self.syncSwitch.isOn)
        }, for: .valueChanged)
    }

    private func constructAppearanceCard() {
        appearanceCard.addAutolayoutSubview(appearanceStack)
        appearanceStack.addArrangedSubviews([appearanceTitle, themeLabel, themeControl, colorLabel, swatches, soundRow])
        swatches.addArrangedSubviews(colorButtons)

        themeControl.addAction(UIAction { [weak self] _ in
            guard let self,
                  ThemeOption.allCases.indices.contains(self.themeControl.selectedSegmentIndex) else { return }
            onThemeSelected?(ThemeOption.allCases[self.themeControl.selectedSegmentIndex])
        }, for: .valueChanged)
    }

    private func constructActivityCard() {
        activityCard.addAutolayoutSubview(activityStack)
        activityHeader.addArrangedSubviews([activityTitle, activitySwitch])
        activityStack.addArrangedSubviews([activityHeader, activityDescription, systemSettingsButton])
    }

    private func constructAlarmCard() {
        alarmCard.addAutolayoutSubview(alarmStack)
        alarmHeader.addArrangedSubview(alarmTitle)
        alarmStack.addArrangedSubviews([alarmHeader, alarmDescription, alarmRow])
    }

    private func configureColorActions() {
        for (option, button) in zip(ColorOptions.allCases, colorButtons) {
            button.addAction(UIAction { [weak self] _ in
                self?.onColorSelected?(option)
            }, for: .touchUpInside)
        }
    }

    private func configureSoundAndActivityActions() {
        soundRow.addAction(UIAction { [weak self] _ in
            self?.onSoundRequested?()
        }, for: .touchUpInside)

        alarmRow.addAction(UIAction { [weak self] _ in
            self?.onAlertStyleRequested?()
        }, for: .touchUpInside)

        activitySwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            self.onLiveActivityChanged?(self.activitySwitch.isOn)
        }, for: .valueChanged)

        systemSettingsButton.addAction(UIAction { [weak self] _ in
            self?.onSystemSettingsRequested?()
        }, for: .touchUpInside)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.space20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.space24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Spacing.space20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Spacing.space20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Spacing.space20 * 2),
            mascot.heightAnchor.constraint(equalToConstant: Spacing.space140)
        ])

        for (card, content) in [(appearanceCard, appearanceStack), (activityCard, activityStack), (syncCard, syncStack), (alarmCard, alarmStack)] {
            NSLayoutConstraint.activate([
                content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.space16),
                content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.space16),
                content.topAnchor.constraint(equalTo: card.topAnchor, constant: Spacing.space20),
                content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Spacing.space20)
            ])
        }
    }

    func render(_ state: SettingsViewModel.State) {
        configureTheme(state)
        configureSync(state)
        configureSound(state)
        configureActivity(state)
        configureAlarm(state)
        configureColors(state)
    }

    private func configureTheme(_ state: SettingsViewModel.State) {
        themeControl.selectedSegmentIndex = ThemeOption.allCases.firstIndex(of: state.theme) ?? 0
        themeControl.selectedSegmentTintColor = state.color.color
        themeControl.setTitleTextAttributes([.foregroundColor: CatTheme.text], for: .normal)
        themeControl.setTitleTextAttributes([.foregroundColor: CatTheme.onAccent], for: .selected)
    }

    private func configureSync(_ state: SettingsViewModel.State) {
        syncCard.isHidden = !state.syncAvailable
        syncSwitch.setOn(state.syncEnabled, animated: false)
        syncSwitch.isEnabled = state.syncToggleEnabled
        syncSwitch.onTintColor = state.color.color
        syncDescription.text = state.syncMessage
    }

    private func configureSound(_ state: SettingsViewModel.State) {
        soundRow.configureAccent(state.color.color)
        soundRow.setValue(state.sound.title)
    }

    private func configureActivity(_ state: SettingsViewModel.State) {
        activitySwitch.setOn(state.liveActivityEnabled, animated: false)
        activitySwitch.onTintColor = state.color.color
        systemSettingsButton.tintColor = state.color.color
        systemSettingsButton.isHidden = state.activitiesAuthorized
        activityDescription.text = state.activitiesAuthorized
            ? AppStrings.Settings.liveActivityDescription
            : AppStrings.Settings.liveActivityUnavailableMessage
    }

    private func configureAlarm(_ state: SettingsViewModel.State) {
        alarmRow.configureAccent(state.color.color)
        alarmRow.setValue(state.alertStyle.title)
        alarmDescription.text = state.alertStyle.detail
    }

    private func configureColors(_ state: SettingsViewModel.State) {
        for (option, button) in zip(ColorOptions.allCases, colorButtons) {
            let selected = option == state.color
            button.configuration?.image = selected ? UIImage(systemName: "checkmark") : nil
            button.accessibilityTraits = selected ? [.button, .selected] : [.button]
            button.accessibilityValue = selected ? AppStrings.Common.selected : nil
        }
    }
}
