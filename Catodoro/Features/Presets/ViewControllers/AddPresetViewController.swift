//
//  AddPresetViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/24/24.
//

import CatodoroShared
import UIKit

protocol AddPresetViewControllerDelegate: AnyObject {
    func onFinish()
    func presetEditorDidRequestImage(_ editor: AddPresetViewController)
}

final class AddPresetViewController: BaseViewController {
    weak var delegate: AddPresetViewControllerDelegate?
    private let viewModel: PresetEditorViewModel
    private let accent: UIColor
    private let editorView = PresetEditorView()
    private var saveTask: Task<Void, Never>?

    init(preferences: CatodoroPreferencesProtocol? = nil,
         preset: PresetModel? = nil,
         viewModel: PresetEditorViewModel,
         shouldHideBottomBar: Bool = false
    ) {
        self.viewModel = viewModel
        accent = ColorOptions(preferences?.color ?? ColorOptions.neonBlue.code).color
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = shouldHideBottomBar
    }

    convenience init(preferences: CatodoroPreferencesProtocol? = nil,
                     preset: PresetModel? = nil,
                     coreDataManager: CatodoroCoreDataManaging
    ) {
        self.init(preferences: preferences,
                  preset: preset,
                  viewModel: PresetEditorViewModel(
                    preset: preset,
                    coreDataManager: coreDataManager
                  )
        )
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = editorView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = accent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        editorView.configureAccent(accent)
        navigationItem.title = viewModel.isEditing ? AppStrings.Presets.editPreset : AppStrings.Presets.newPreset
        setupClosures()
        render()
    }

    func selectImage(_ pose: CatPose) {
        viewModel.pose = pose
        render()
    }

    private func render() {
        editorView.render(name: viewModel.name,
                          pose: viewModel.pose,
                          configuration: viewModel.configuration,
                          canSave: viewModel.canSave,
                          isSaving: viewModel.isSaving
        )
    }

    private func save() {
        guard viewModel.canSave else { return }

        saveTask?.cancel()

        saveTask = Task { [weak self] in
            guard let self else { return }

            do {
                try Task.checkCancellation()
                try await viewModel.save()
                try Task.checkCancellation()
                delegate?.onFinish()
            } catch {
                let alert = UIAlertController(
                    title: AppStrings.Presets.couldntSavePreset,
                    message: AppStrings.Presets.saveErrorMessage,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: AppStrings.Common.ok, style: .default))
                present(alert, animated: true)
            }

            render()
        }
    }

    private func setupClosures() {
        editorView.onNameChanged = { [weak self] name in
            self?.viewModel.name = name
            self?.render()
        }

        editorView.onImageRequested = { [weak self] in
            guard let self else { return }
            delegate?.presetEditorDidRequestImage(self)
        }

        editorView.onSelectionRequested = { [weak self] selection in
            guard let self else { return }

            presentRoutineSelection(selection,
                                    configuration: viewModel.configuration,
                                    accent: self.accent
            ) { [weak self] updated in
                guard let self else { return }

                viewModel.configuration = updated
                render()
            }
        }

        viewModel.onStateChanged = { [weak self] in
            self?.render()
        }

        editorView.onSave = { [weak self] in
            self?.save()
        }
    }
}

