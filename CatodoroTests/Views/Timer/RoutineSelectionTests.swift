//
//  RoutineSelectionTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 10/10/26.
//

import XCTest
@testable import Catodoro

@MainActor
final class RoutineSelectionTests: XCTestCase {
    func test_allSelectionSheetsUseInjectedAccentAfterDraftChanges() {
        let presenter = UIViewController()
        let accent = ColorOptions.neonPink.color

        for selection in [RoutineSelection.focus, .catnap, .sessions] {
            let editor = presenter.makeRoutineSelectionEditor(selection, configuration: .standard,
                                                              accent: accent) { _ in }
            editor.loadViewIfNeeded()
            let sheet = editor as! RoutineSelectionViewController
            XCTAssertEqual(sheet.selectionView.tintColor, accent)
            XCTAssertEqual(sheet.confirmButton.configuration?.baseBackgroundColor, accent)

            if let duration = editor as? DurationSelectionViewController {
                duration.selectShortcut(minutes: 5)
                if selection == .focus {
                    duration.selectShortcut(minutes: 25)
                }
            }

            func descendants(_ view: UIView) -> [UIView] {
                view.subviews.flatMap { [$0] + descendants($0) }
            }

            if selection == .sessions {
                XCTAssertTrue(descendants(sheet.view).contains {
                    $0.backgroundColor == accent.withAlphaComponent(0.18)
                }, "The session-count card should use the selected accent tint")
            }

            for button in descendants(sheet.view).compactMap({ $0 as? UIButton }) {
                if button.isSelected || ["Fewer sessions", "More sessions"].contains(button.accessibilityLabel ?? "") {
                    XCTAssertEqual(button.configuration?.baseBackgroundColor, accent)
                }
            }
        }
    }

    func test_summaryIncludesOnlyBreaksBetweenSessionsAndKeepsSeconds() {
        var routine = TimerConfigModel.standard
        XCTAssertEqual(routine.totalDuration, 6900)
        XCTAssertEqual(TimerConfigModel.durationSummary(routine.totalDuration), "1 hr 55 min")

        routine.intervals = 1
        XCTAssertEqual(routine.breakSubtotal, 0)
        XCTAssertEqual(routine.totalDuration, 1500)

        routine.intervals = 20
        routine.interval = .init(hours: 0, minutes: 0, seconds: 0)
        XCTAssertEqual(routine.totalDuration, 30000)
        XCTAssertEqual(TimerConfigModel.durationSummary(3661), "1 hr 1 min 1 sec")
    }

    func test_validationCoversAllFieldsAndSessionBounds() {
        var routine = TimerConfigModel.standard
        XCTAssertTrue(routine.isValid)

        for count in [0, 21] {
            routine.intervals = count
            XCTAssertFalse(routine.isValid)
        }

        routine.intervals = 20
        routine.mainTimer = .init(hours: 0, minutes: 0, seconds: 0)
        XCTAssertFalse(routine.isValid)
        routine.mainTimer = .init(hours: 23, minutes: 59, seconds: 59)
        XCTAssertTrue(routine.isValid)

        for timer in [TimerModel(hours: -1, minutes: 0, seconds: 0),
                      TimerModel(hours: 24, minutes: 0, seconds: 0),
                      TimerModel(hours: 0, minutes: 60, seconds: 0),
                      TimerModel(hours: 0, minutes: 0, seconds: 60)] {
            routine.interval = timer
            XCTAssertFalse(routine.isValid)
        }

        routine.interval = .init(hours: 23, minutes: 59, seconds: 59)
        XCTAssertEqual(TimerConfigModel.durationSummary(routine.totalDuration), "935 hr 59 min 21 sec")

        routine.intervals = 21
        let viewModel = TimerConfigViewModel(timerModel: routine, coreDataManager: nil)
        XCTAssertFalse(viewModel.isValidSelection)
    }

    func test_durationDraftDoesNotCommitAndReopeningRestoresConfirmedTime() {
        let host = UIViewController()
        var routine = TimerConfigModel.standard
        let editor = host.makeRoutineSelectionEditor(.focus, configuration: routine) { routine = $0 }
            as! DurationSelectionViewController
        editor.loadViewIfNeeded()
        editor.selectShortcut(minutes: 50)
        XCTAssertEqual(routine.mainTimer.duration, 1500)

        // Discarding the editor (close or swipe) has no model mutation.
        let reopened = host.makeRoutineSelectionEditor(.focus, configuration: routine) { routine = $0 }
            as! DurationSelectionViewController
        reopened.loadViewIfNeeded()
        XCTAssertEqual(reopened.draft.duration, 1500)
        XCTAssertEqual(reopened.selectedMinutes, 25)

        reopened.updateDraft(.init(hours: 1, minutes: 2, seconds: 3))
        reopened.confirm()
        XCTAssertEqual(routine.mainTimer.duration, 3723)
        XCTAssertEqual(routine.interval.duration, 300)
        XCTAssertEqual(routine.intervals, 4)
    }

    func test_shortcutsResetSecondsAndConfirmationCommitsOnce() {
        let editor = DurationSelectionViewController(mode: .focus,
            duration: .init(hours: 1, minutes: 2, seconds: 3))
        editor.loadViewIfNeeded()
        var commits = 0
        editor.onCommit = { timer in
            commits += 1
            XCTAssertEqual(timer.duration, 900)
        }
        editor.selectShortcut(minutes: 15)
        XCTAssertEqual(editor.selectedMinutes, 15)
        XCTAssertEqual(editor.draft.hours, 0)
        XCTAssertEqual(editor.draft.seconds, 0)
        editor.confirm()
        editor.confirm()
        XCTAssertEqual(commits, 1)
    }

    func test_shortcutSelectionTracksExactDraftIncludingSeconds() {
        let editor = DurationSelectionViewController(mode: .focus,
            duration: .init(hours: 0, minutes: 25, seconds: 0))
        editor.loadViewIfNeeded()
        XCTAssertEqual(editor.selectedShortcut, 25)

        editor.selectShortcut(minutes: 15)
        XCTAssertEqual(editor.selectedShortcut, 15)

        editor.updateDraft(.init(hours: 0, minutes: 15, seconds: 1))
        XCTAssertNil(editor.selectedShortcut)
    }

    func test_zeroFocusIsBlockedButZeroBreakCanBeConfirmed() {
        let zero = TimerModel(hours: 0, minutes: 0, seconds: 0)
        let focus = DurationSelectionViewController(mode: .focus, duration: zero)
        focus.loadViewIfNeeded()
        focus.onCommit = { _ in XCTFail("Zero focus should not commit") }
        XCTAssertFalse(focus.confirmButton.isEnabled)
        focus.confirm()

        let catnap = DurationSelectionViewController(mode: .catnap, duration: zero)
        catnap.loadViewIfNeeded()
        var committed = false
        catnap.onCommit = { _ in committed = true }
        XCTAssertTrue(catnap.confirmButton.isEnabled)
        catnap.confirm()
        XCTAssertTrue(committed)
    }

    func test_sessionsClampDraftAndCommitWithoutChangingOtherFields() {
        let host = AddPresetViewController(preferences: nil)
        var routine = TimerConfigModel.standard
        let editor = host.makeRoutineSelectionEditor(.sessions, configuration: routine) { routine = $0 }
            as! SessionSelectionViewController
        editor.loadViewIfNeeded()
        XCTAssertEqual(editor.focusSummary, "25 min × 4")
        XCTAssertEqual(editor.breakSummary, "5 min × 3")
        XCTAssertEqual(editor.totalSummary, "1 hr 55 min")
        editor.adjustCount(by: -20)
        XCTAssertEqual(editor.draftCount, 1)
        XCTAssertFalse(editor.canDecrease)
        XCTAssertEqual(routine.intervals, 4)
        XCTAssertEqual(editor.breakSummary, "No breaks")

        editor.adjustCount(by: 20)
        XCTAssertEqual(editor.draftCount, 20)
        XCTAssertFalse(editor.canIncrease)
        editor.confirm()
        XCTAssertEqual(routine.intervals, 20)
        XCTAssertEqual(routine.mainTimer.duration, 1500)
        XCTAssertEqual(routine.interval.duration, 300)
    }

    func test_presentingAnotherScreenDoesNotFinishSetup() {
        let controller = BaseViewController()
        var didFinish = false
        controller.onFinish = { didFinish = true }
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        XCTAssertFalse(didFinish)
    }

    func test_invalidRoutineCannotBeSaved() async {
        let viewModel = TimerConfigViewModel(timerModel: .init(), coreDataManager: nil)

        do {
            try await viewModel.addPreset()
            XCTFail("An invalid routine must not be saved")
        } catch {
            XCTAssertTrue(error is TimerConfigViewModel.ValidationError)
        }
    }

    func test_durationViewModelValidatesDraftAndCommitsOnce() {
        let viewModel = DurationSelectionViewModel(mode: .focus,
            duration: .init(hours: 1, minutes: 2, seconds: 3))
        XCTAssertEqual(viewModel.shortcutMinutes, [15, 25, 50])
        XCTAssertNil(viewModel.selectedShortcut)
        XCTAssertFalse(viewModel.selectShortcut(minutes: 60))
        XCTAssertEqual(viewModel.draft.duration, 3723)

        viewModel.updateDraft(.init(hours: 0, minutes: 0, seconds: 0))
        XCTAssertFalse(viewModel.isValidSelection)
        XCTAssertNil(viewModel.confirm())

        XCTAssertTrue(viewModel.selectShortcut(minutes: 25))
        XCTAssertEqual(viewModel.selectedShortcut, 25)
        XCTAssertEqual(viewModel.confirm()?.duration, 1500)
        XCTAssertNil(viewModel.confirm())
    }

    func test_breakViewModelAllowsZeroAndRequiresExactShortcutMatch() {
        let viewModel = DurationSelectionViewModel(mode: .catnap,
            duration: .init(hours: 0, minutes: 5, seconds: 1))
        XCTAssertEqual(viewModel.shortcutMinutes, [0, 5, 10])
        XCTAssertNil(viewModel.selectedShortcut)
        XCTAssertFalse(viewModel.selectShortcut(minutes: 25))
        XCTAssertTrue(viewModel.selectShortcut(minutes: 0))
        XCTAssertTrue(viewModel.isValidSelection)
        XCTAssertEqual(viewModel.selectedShortcut, 0)
        XCTAssertEqual(viewModel.confirm()?.duration, 0)
    }

    func test_durationPickerDoesNotRetainItself() {
        weak var releasedPicker: TimerPickerView?

        autoreleasepool {
            let picker = TimerPickerView()
            releasedPicker = picker
        }

        XCTAssertNil(releasedPicker)
    }
}
