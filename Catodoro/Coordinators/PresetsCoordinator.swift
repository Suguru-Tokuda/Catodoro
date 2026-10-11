//
//  PresetsCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class PresetsCoordinator: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var type: CoordinatorType { .feature }
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let timerCoordinator: TimerCoordiantor
    weak var liveActivityManager: LiveActivityManaging?
    private var editorCompletion: (() -> Void)?
    weak var preferences: CatodoroPreferences?

    init(navigationController: UINavigationController = BaseNavigationController()) {
        self.navigationController = navigationController
        timerCoordinator = TimerCoordiantor(navigationController: navigationController)
        childCoordinators = [timerCoordinator]
    }

    func start() {
        let presetsViewController = PresetsViewController()
        presetsViewController.delegate = self
        navigationController.pushViewController(presetsViewController, animated: false)
    }

    func navigateToAddPreset(onFinish: @escaping(() -> Void)) {
        editorCompletion = onFinish
        let addPresetViewController = AddPresetViewController(preferences: preferences)
        addPresetViewController.delegate = self
        navigationController.pushViewController(addPresetViewController, animated: true)
    }
}

extension PresetsCoordinator: PresetsViewControllerDelegate {
    func presetsViewControllerDidRequestEdit(_ viewController: PresetsViewController, preset: PresetModel) {
        let editor = AddPresetViewController(preferences: preferences, preset: preset)
        editor.delegate = self
        navigationController.pushViewController(editor, animated: true)
    }

    func presetsViewControllerDidSelectPreset(_ viewController: PresetsViewController, preset: PresetModel) {
        let configuration = preset.configuration
        guard configuration.isValid else { return }

        timerCoordinator.preferences = preferences
        timerCoordinator.liveActivityManager = liveActivityManager
        timerCoordinator.navigateToTimerView(viewModel: .init(timerModel: configuration))
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

