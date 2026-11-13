//
//  CountdownEngineAlertContentTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/12/26.
//

import AlarmKit
import CatodoroShared
import XCTest
@testable import Catodoro

/// The AlarmKit alert for each step: its title, its secondary button, and what both buttons run.
/// ✕ (Stop) is drawn by the system; only its intent is ours.
@MainActor
final class CountdownEngineAlertContentTests: XCTestCase {
    private let alarmID = UUID()
    /// focus #1 → break → focus #2 (last)
    private let steps = CycleStep.cycle(intervals: 2, focus: 1500, breakDuration: 300)

    private func content(_ index: Int, startsBreak: Bool) -> (
        presentation: AlarmPresentation.Alert,
        stopIntent: any LiveActivityIntent,
        secondaryIntent: (any LiveActivityIntent)?
    ) {
        CountdownEngine.alertContent(for: steps[index], alarmID: alarmID, startsBreak: startsBreak)
    }

    // MARK: Focus followed by a break

    func test_focusWithBreak_expectSkipBreakButton() throws {
        let alert = content(0, startsBreak: true).presentation

        XCTAssertEqual(String(localized: alert.title), String(localized: AppStrings.Alarm.focusComplete))
        let button = try XCTUnwrap(alert.secondaryButton)
        XCTAssertEqual(String(localized: button.text), "Skip break")
        XCTAssertEqual(button.systemImageName, "forward.end.fill")
    }

    func test_focusWithBreak_expectCustomBehaviorNotSystemCountdown() {
        // `.countdown` kept the alarm alive as a system break and broke Skip break.
        XCTAssertEqual(content(0, startsBreak: true).presentation.secondaryButtonBehavior, .custom)
    }

    func test_focusWithBreak_expectStopContinuesIntoBreakAndSecondarySkipsIt() throws {
        let alert = content(0, startsBreak: true)

        let stop = try XCTUnwrap(alert.stopIntent as? AdvanceIntent)
        let skip = try XCTUnwrap(alert.secondaryIntent as? SkipBreakIntent)
        XCTAssertEqual(stop.alarmID, alarmID.uuidString)
        XCTAssertEqual(skip.alarmID, alarmID.uuidString)
    }

    // MARK: Focus with nothing to skip

    func test_focusWithoutBreak_expectNoSecondaryButton() throws {
        let alert = content(0, startsBreak: false)

        XCTAssertNil(alert.presentation.secondaryButton)
        XCTAssertNil(alert.secondaryIntent)
        XCTAssertEqual(try XCTUnwrap(alert.stopIntent as? AdvanceIntent).alarmID, alarmID.uuidString)
    }

    // MARK: Break

    func test_breakEnd_expectBreakOverAndStopStartsNextFocus() throws {
        let alert = content(1, startsBreak: false)

        XCTAssertEqual(String(localized: alert.presentation.title), String(localized: AppStrings.Alarm.breakOver))
        XCTAssertNil(alert.presentation.secondaryButton)
        XCTAssertNil(alert.secondaryIntent)
        XCTAssertEqual(try XCTUnwrap(alert.stopIntent as? AdvanceIntent).alarmID, alarmID.uuidString)
    }

    // MARK: Last focus

    func test_lastStep_expectCycleCompleteWithRestart() throws {
        let alert = content(2, startsBreak: false)

        XCTAssertEqual(String(localized: alert.presentation.title), String(localized: AppStrings.Alarm.cycleComplete))
        XCTAssertEqual(alert.presentation.secondaryButton?.systemImageName, "arrow.counterclockwise")
        XCTAssertEqual(alert.presentation.secondaryButtonBehavior, .custom)
        XCTAssertEqual(try XCTUnwrap(alert.stopIntent as? StopTimerIntent).alarmID, alarmID.uuidString)
        XCTAssertEqual(try XCTUnwrap(alert.secondaryIntent as? RepeatTimerIntent).alarmID, alarmID.uuidString)
    }

    func test_lastStep_ignoresStartsBreak() {
        // A stray `true` must not put Skip break on the final alert.
        XCTAssertNotNil(content(2, startsBreak: true).secondaryIntent as? RepeatTimerIntent)
    }

    // MARK: Which steps get Skip break (the flag `startStep` passes)

    func test_startsBreakFlag_matchesStepsWithAFollowingBreak() {
        let flags = steps.indices.map { CountdownEngine.breakDuration(after: $0, in: steps) != nil }

        XCTAssertEqual(flags, [true, false, false], "only focus #1 has a break after it")
    }
}
