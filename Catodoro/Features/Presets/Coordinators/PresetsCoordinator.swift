//
//  PresetsCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

struct PresetsCoordinatorConfiguration {
    let shouldHideBottomBar: Bool

    init(shouldHideBottomBar: Bool = false) {
        self.shouldHideBottomBar = shouldHideBottomBar
    }
}

class PresetsCoordinator: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let timerCoordinator: TimerCoordiantor
    private var editorCompletion: (() -> Void)?
    private var configuration: PresetsCoordinatorConfiguration
    private let dependencies: AppDependencies

    private var preferences: CatodoroPreferences { dependencies.preferences }
    private var coreDataManager: CatodoroCoreDataManaging { dependencies.coreDataManager }

    init(navigationController: UINavigationController = BaseNavigationController(),
         configuration: PresetsCoordinatorConfiguration = PresetsCoordinatorConfiguration(),
         dependencies: AppDependencies
    ) {
        self.navigationController = navigationController
        self.configuration = configuration
        self.dependencies = dependencies
        timerCoordinator = TimerCoordiantor(
            navigationController: navigationController,
            configuration: TimerCoordinatorConfiguration(
                shouldHideBottomBarWhenTimerStart: configuration.shouldHideBottomBar),
            dependencies: dependencies
        )
        childCoordinators = [timerCoordinator]
    }

    func start() {
        let presetsViewController = PresetsViewController(preferences: preferences, viewModel: PresetsViewModel(coreDataManager: coreDataManager))
        presetsViewController.delegate = self
        navigationController.pushViewController(presetsViewController, animated: false)
    }

    private func navigateToAddPreset(onFinish: @escaping(() -> Void)) {
        editorCompletion = onFinish
        let addPresetViewController = AddPresetViewController(preferences: preferences, coreDataManager: coreDataManager)
        addPresetViewController.delegate = self
        navigationController.pushViewController(addPresetViewController, animated: true)
    }
}

extension PresetsCoordinator: PresetsViewControllerDelegate {
    func presetsViewControllerDidRequestEdit(_ viewController: PresetsViewController, preset: PresetModel) {
        let editor = AddPresetViewController(preferences: preferences, preset: preset, coreDataManager: coreDataManager)
        editor.delegate = self
        navigationController.pushViewController(editor, animated: true)
    }

    func presetsViewControllerDidSelectPreset(_ viewController: PresetsViewController, preset: PresetModel) {
        let configuration = preset.configuration
        guard configuration.isValid else { return }

        timerCoordinator.navigateToTimerView(viewModel: .init(timerModel: configuration, coreDataManager: coreDataManager))
    }
    
    func presetsViewControllerDidTapAddButton(_ viewController: PresetsViewController, onFinish: @escaping(() -> Void)) {
        navigateToAddPreset { [weak self] in
            guard self != nil else { return }
            onFinish()
        }
    }
}

extension PresetsCoordinator: AddPresetViewControllerDelegate {
    func onFinish() {
        navigationController.popViewController(animated: true)
        editorCompletion?()
        editorCompletion = nil
    }

    func presetEditorDidRequestImage(_ editor: AddPresetViewController) {
        let picker = PresetImagePickerViewController()
        picker.onSelect = { [weak self, weak editor] pose in
            editor?.selectImage(pose)
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(picker, animated: true)
    }
}

