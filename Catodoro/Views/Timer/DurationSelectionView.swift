//
//  DurationSelectionView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import UIKit

final class DurationSelectionView: RoutineSelectionView {
    private let mode: RoutineSelection
    var onDurationChange: ((TimerModel) -> Void)?
    var onShortcutSelection: ((Int) -> Void)?

    private var shortcutButtons: [(minutes: Int, button: UIButton)] = []

    private let picker = TimerPickerView()

    private let shortcutsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = CatTheme.Spacing.small

        return stack
    }()

    init(mode: RoutineSelection, shortcuts: [Int]) {
        self.mode = mode
        super.init(frame: .zero)
        let title = mode == .focus ? "Focus time" : "Catnap break"
        confirmButton.setTitle(mode == .focus ? "Set focus time" : "Set break time", for: .normal)
        configureHeader(title: title,
                        subtitle: mode == .focus ? "A little time for deep focus." : "Rest your paws between sessions.",
                        pose: mode == .focus ? .stretching : .sleeping)
        contentStack.addArrangedSubviews([picker, shortcutsStack])
        picker.onSelect = { [weak self] hours, minutes, seconds in
            self?.onDurationChange?(.init(hours: hours, minutes: minutes, seconds: seconds))
        }

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            shortcutsStack.axis = .vertical
        }

        for minutes in shortcuts {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.filled()
            configuration.title = minutes == 0 ? "No break" : "\(minutes) min"
            configuration.baseForegroundColor = CatTheme.text
            configuration.baseBackgroundColor = CatTheme.color(0xF1E8DC, 0x39333D)
            configuration.cornerStyle = .capsule
            button.configuration = configuration
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.onShortcutSelection?(minutes)
            }, for: .touchUpInside)
            shortcutButtons.append((minutes, button))
            shortcutsStack.addArrangedSubview(button)
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    func renderDraft(_ draft: TimerModel) {
        picker.configure(hour: draft.hours, minute: draft.minutes, second: draft.seconds)
    }

    func renderSelection(isValid valid: Bool, selectedShortcut: Int?) {
        confirmButton.isEnabled = valid
        explanationLabel.text = valid
            ? (mode == .focus ? "A little time for deep focus." : "Rest your paws between sessions.")
            : "Choose a focus time greater than zero."

        for shortcut in shortcutButtons {
            let selected = selectedShortcut == shortcut.minutes
            shortcut.button.isSelected = selected
            shortcut.button.configuration?.baseBackgroundColor = selected
                ? ColorOptions.neonBlue.color : CatTheme.color(0xF1E8DC, 0x39333D)
            shortcut.button.configuration?.baseForegroundColor = selected ? CatTheme.onAccent : CatTheme.text
            shortcut.button.accessibilityTraits = selected ? [.button, .selected] : .button
        }
    }

    #if DEBUG
    var selectedShortcut: Int? {
        shortcutButtons.first(where: { $0.button.isSelected })?.minutes
    }

    var selectedMinutes: Int {
        picker.testHooks.minutePicker.selectedRow(inComponent: 0)
    }

    #endif
}
