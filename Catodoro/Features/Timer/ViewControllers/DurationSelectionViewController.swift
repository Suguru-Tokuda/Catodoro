//
//  DurationSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import CatodoroShared
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

    override func constructView() {
        super.constructView()
        title = viewModel.mode == .focus ? AppStrings.Common.focusTime : AppStrings.Common.catnapBreak
    }

    override func constructSubviews() {
        super.constructSubviews()
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

    private func updateDraft(_ value: TimerModel) {
        viewModel.updateDraft(value)
        updateConfirmation()
    }

    private func selectShortcut(minutes: Int) {
        guard viewModel.selectShortcut(minutes: minutes) else {
            return
        }

        durationView.renderDraft(viewModel.draft)
        updateConfirmation()
    }

    private func confirm() {
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

}

#if DEBUG
extension DurationSelectionViewController {
    var draft: TimerModel {
        viewModel.draft
    }

    var selectedShortcut: Int? {
        durationView.selectedShortcut
    }

    var selectedMinutes: Int {
        durationView.selectedMinutes
    }

    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: DurationSelectionViewController

        func updateDraft(_ value: TimerModel) { target.updateDraft(value) }
        func selectShortcut(minutes: Int) { target.selectShortcut(minutes: minutes) }
        func confirm() { target.confirm() }
    }
}
#endif
