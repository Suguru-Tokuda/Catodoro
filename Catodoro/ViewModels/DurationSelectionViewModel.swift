//
//  DurationSelectionViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import Foundation

final class DurationSelectionViewModel {
    let mode: RoutineSelection
    private(set) var draft: TimerModel
    private var hasCommitted = false

    init(mode: RoutineSelection, duration: TimerModel) {
        self.mode = mode
        self.draft = duration
    }

    var shortcutMinutes: [Int] {
        mode == .focus ? [15, 25, 50] : [0, 5, 10]
    }

    var isValidSelection: Bool {
        TimerConfigModel.isValidDuration(draft, allowsZero: mode == .catnap)
    }

    var selectedShortcut: Int? {
        guard draft.hours == 0, draft.seconds == 0 else {
            return nil
        }

        return shortcutMinutes.first(where: { $0 == draft.minutes })
    }

    func updateDraft(_ duration: TimerModel) {
        draft = duration
    }

    @discardableResult
    func selectShortcut(minutes: Int) -> Bool {
        guard shortcutMinutes.contains(minutes) else {
            return false
        }

        draft = .init(hours: 0, minutes: minutes, seconds: 0)

        return true
    }

    /// Return the confirmed draft once; cancellation never touches the caller's routine.
    func confirm() -> TimerModel? {
        guard !hasCommitted, isValidSelection else {
            return nil
        }

        hasCommitted = true

        return draft
    }
}
