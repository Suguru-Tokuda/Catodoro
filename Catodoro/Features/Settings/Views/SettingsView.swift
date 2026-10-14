//
//  SettingsView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import UIKit

final class SettingsView: BaseView {
    var onThemeSelected: ((ThemeOption) -> Void)?
    var onColorSelected: ((ColorOptions) -> Void)?
    var onSoundRequested: (() -> Void)?
    var onLiveActivityChanged: ((Bool) -> Void)?
    var onSyncChanged: ((Bool) -> Void)?
    var onSystemSettingsRequested: (() -> Void)?

    private let scrollView = UIScrollView()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()

    private let mascot = CatIllustrationView(pose: .playful)
    private let appearanceCard = CatCardView()
    private let activityCard = CatCardView()
    private let syncCard = CatCardView()
    private let syncStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    private let syncSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.accessibilityLabel = "iCloud Sync"
        toggle.accessibilityIdentifier = "cloudSyncToggle"
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
        stack.spacing = 16
        return stack
    }()

    private let activityStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let appearanceTitle: UILabel = {
        let label = UILabel()
        label.text = "Your cozy corner"
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let themeLabel: UILabel = {
        let label = UILabel()
        label.text = "Theme"
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.secondaryText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let themeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ThemeOption.allCases.map(\.title))
        control.accessibilityLabel = "Theme"
        control.accessibilityIdentifier = "themeSelector"
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return control
    }()

    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Accent color"
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.secondaryText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let swatches: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
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
        button.accessibilityLabel = option.rawValue + " accent"
        button.accessibilityIdentifier = option.code
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }

    private let soundRow = CatSummaryRow(title: "Timer sound", value: "", symbol: "speaker.wave.2.fill")

    private let activityTitle: UILabel = {
        let label = UILabel()
        label.text = "Live Activity"
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let activitySwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.accessibilityLabel = "Live Activity"
        toggle.accessibilityIdentifier = "liveActivityToggle"
        return toggle
    }()

    private let activityHeader: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
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

    private let systemSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open iOS Settings", for: .normal)
        button.titleLabel?.font = CatTheme.font(.body, weight: .semibold)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }()

    override func constructSubviews() {
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stack)
        stack.addArrangedSubviews([mascot, appearanceCard, syncCard, activityCard])
        syncCard.addAutolayoutSubview(syncStack)
        let syncTitle = UILabel()
        syncTitle.text = "iCloud Sync"
        syncTitle.font = CatTheme.font(.headline, weight: .bold)
        syncTitle.textColor = CatTheme.text
        syncTitle.adjustsFontForContentSizeCategory = true
        let syncHeader = UIStackView(arrangedSubviews: [syncTitle, syncSwitch])
        syncHeader.spacing = 12
        syncHeader.alignment = .center
        syncStack.addArrangedSubviews([syncHeader, syncDescription])
        syncSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onSyncChanged?(self.syncSwitch.isOn)
        }, for: .valueChanged)
        appearanceCard.addAutolayoutSubview(appearanceStack)
        appearanceStack.addArrangedSubviews([appearanceTitle, themeLabel, themeControl, colorLabel, swatches, soundRow])
        themeControl.addAction(UIAction { [weak self] _ in
            guard let self,
                  ThemeOption.allCases.indices.contains(self.themeControl.selectedSegmentIndex) else { return }
            onThemeSelected?(ThemeOption.allCases[self.themeControl.selectedSegmentIndex])
        }, for: .valueChanged)
        swatches.addArrangedSubviews(colorButtons)
        activityCard.addAutolayoutSubview(activityStack)
        activityHeader.addArrangedSubviews([activityTitle, activitySwitch])
        activityStack.addArrangedSubviews([activityHeader, activityDescription, systemSettingsButton])

        for (option, button) in zip(ColorOptions.allCases, colorButtons) {
            button.addAction(UIAction { [weak self] _ in
                self?.onColorSelected?(option)
            }, for: .touchUpInside)
        }
        soundRow.addAction(UIAction { [weak self] _ in
            self?.onSoundRequested?()
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
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            mascot.heightAnchor.constraint(equalToConstant: 140)
        ])

        for (card, content) in [(appearanceCard, appearanceStack), (activityCard, activityStack), (syncCard, syncStack)] {
            NSLayoutConstraint.activate([
                content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                content.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
                content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
            ])
        }
    }

    func render(_ state: SettingsViewModel.State) {
        themeControl.selectedSegmentIndex = ThemeOption.allCases.firstIndex(of: state.theme) ?? 0
        themeControl.selectedSegmentTintColor = state.color.color
        themeControl.setTitleTextAttributes([.foregroundColor: CatTheme.text], for: .normal)
        themeControl.setTitleTextAttributes([.foregroundColor: CatTheme.onAccent], for: .selected)
        syncCard.isHidden = !state.syncAvailable
        syncSwitch.setOn(state.syncEnabled, animated: false)
        syncSwitch.isEnabled = state.syncToggleEnabled
        syncSwitch.onTintColor = state.color.color
        syncDescription.text = state.syncMessage
        soundRow.configureAccent(state.color.color)
        soundRow.setValue(state.sound.rawValue)
        activitySwitch.setOn(state.liveActivityEnabled, animated: false)
        activitySwitch.onTintColor = state.color.color
        systemSettingsButton.tintColor = state.color.color
        systemSettingsButton.isHidden = state.activitiesAuthorized
        activityDescription.text = state.activitiesAuthorized
            ? "Keep your timer and cat nearby on the Lock Screen and Dynamic Island."
            : "Live Activities are unavailable or disabled in iOS Settings. Your app preference is saved."

        for (option, button) in zip(ColorOptions.allCases, colorButtons) {
            let selected = option == state.color
            button.configuration?.image = selected ? UIImage(systemName: "checkmark") : nil
            button.accessibilityTraits = selected ? [.button, .selected] : [.button]
            button.accessibilityValue = selected ? "Selected" : nil
        }
    }
}
