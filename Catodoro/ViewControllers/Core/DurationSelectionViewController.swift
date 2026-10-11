//
//  DurationSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import UIKit

final class DurationSelectionViewController: RoutineSelectionViewController {
    private let viewModel: DurationSelectionViewModel
    var onCommit: ((TimerModel) -> Void)?
    private let durationView: DurationSelectionView

    init(mode: RoutineSelection, duration: TimerModel) {
        let viewModel = DurationSelectionViewModel(mode: mode, duration: duration)
        self.viewModel = viewModel
        self.durationView = DurationSelectionView(mode: mode, shortcuts: viewModel.shortcutMinutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func makeSelectionView() -> RoutineSelectionView {
        durationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.mode == .focus ? "Focus time" : "Catnap break"
        durationView.renderDraft(viewModel.draft)
        durationView.onDurationChange = { [weak self] duration in
            self?.updateDraft(duration)
        }
        durationView.onShortcutSelection = { [weak self] minutes in
            self?.selectShortcut(minutes: minutes)
        }
        durationView.onConfirm = { [weak self] in
            self?.confirm()
        }
        updateConfirmation()
    }

    func updateDraft(_ value: TimerModel) {
        viewModel.updateDraft(value)
        updateConfirmation()
    }

    func selectShortcut(minutes: Int) {
        guard viewModel.selectShortcut(minutes: minutes) else {
            return
        }

        durationView.renderDraft(viewModel.draft)
        updateConfirmation()
    }

    func confirm() {
        guard let duration = viewModel.confirm() else {
            return
        }

        onCommit?(duration)
        dismiss(animated: true)
    }

    private func updateConfirmation() {
        durationView.renderSelection(isValid: viewModel.isValidSelection,
                                     selectedShortcut: viewModel.selectedShortcut)
    }

    #if DEBUG
    var draft: TimerModel {
        viewModel.draft
    }

    var selectedShortcut: Int? {
        durationView.selectedShortcut
    }

    var selectedMinutes: Int {
        durationView.selectedMinutes
    }
    #endif
}
