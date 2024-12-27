//
//  SettingsCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class SettingsCoordinator: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var preferences: CatodoroPreferencesProtocol?

    init(navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let settingsViewController = SettingsViewController()
        settingsViewController.delegate = self
        settingsViewController.preferences = preferences
        navigationController.pushViewController(settingsViewController, animated: false)
    }

    func pop() {
        navigationController.popViewController(animated: true)
    }

    func popToRoot() {
        navigationController.popToRootViewController(animated: true)
    }

    func navigateToColorSelectionsView() {
        var options: [OptionModel] = []
        let selectedColorCode = preferences?.color ?? ColorOptions.neonBlue.code
        ColorOptions.allCases.forEach {
            options.append(.init(id: $0.code,
                                 title: $0.rawValue,
                                 selected: $0.code == selectedColorCode,
                                 color: $0.color))
        }
        let viewModel = OptionSelectionViewModel(options: options)
        viewModel.preferences = preferences
        viewModel.selectedId = selectedColorCode

        let colorSelectionViewController = ColorSelectionViewController(viewModel: viewModel, titleLabelText: "Color")
        colorSelectionViewController.delegate = self
        navigationController.pushViewController(colorSelectionViewController, animated: true)
    }

    func navigateToSoundSelectionsView() {
        var options: [OptionModel] = []
        let selectedSoundId = preferences?.sound ?? SoundOptions.meowRegular.id
        SoundOptions.allCases.forEach {
            options.append(.init(id: $0.id, title: $0.rawValue, selected: $0.id == selectedSoundId))
        }
        let viewModel = OptionSelectionViewModel(options: options)
        viewModel.preferences = preferences
        viewModel.selectedId = selectedSoundId
        
        let soundSelectionViewController = SoundSelectionViewController(viewModel: viewModel, titleLabelText: "Sound")
        soundSelectionViewController.delegate = self
        navigationController.pushViewController(soundSelectionViewController, animated: true)
    }
}

extension SettingsCoordinator: SettingsViewControllerDelegate {
    func onSettingMenuSelected(settingOption: SettingOptions) {
        switch settingOption {
        case .color:
            navigateToColorSelectionsView()
        case .sound:
            navigateToSoundSelectionsView()
        }
    }
}

extension SettingsCoordinator: SoundSelectionViewControllerDelegate {
    func onSoundSelect() {
        navigationController.popViewController(animated: true)
    }
}

extension SettingsCoordinator: ColorSelectionViewControllerDelegate {
    func onColorSelected() {
        navigationController.popViewController(animated: true)
    }
}
