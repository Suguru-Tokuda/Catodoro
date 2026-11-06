//
//  TimerViewModelHapticsTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/5/26.
//

import XCTest
@testable import Catodoro

@MainActor
final class TimerViewModelHapticsTests: XCTestCase {
    private enum TestError: Error { case hapticsUnavailable }

    private var instant = Date(timeIntervalSince1970: 1000)
    private var isActive = true
    private let haptics = MockHapticsManager()

    /// 10s focus, 5s break, 2 sessions: focus → break → focus → finished.
    private func makeRunningTimer(focus: TimeInterval = 10,
                                  rest: TimeInterval = 5,
                                  sessions: Int = 2) -> TimerViewModel {
        let model = TimerViewModel(audioManager: MockAudioManager(), preferences: nil,
                                   liveActivityManager: nil, hapticsManager: haptics,
                                   now: { [unowned self] in self.instant },
                                   schedulesTicks: false,
                                   applicationIsActive: { [unowned self] in self.isActive })
        model.configure(totalDuration: focus, intervalDuration: rest, intervals: sessions)
        model.testHooks.startTimer()
        // configure() resets the timer, which calls stop(); only count what happens after start.
        haptics.reset()
        return model
    }

    private func advance(_ seconds: TimeInterval, _ model: TimerViewModel) {
        instant.addTimeInterval(seconds)
        model.refresh()
    }

    // MARK: - When haptics play

    func test_startingTimer_doesNotVibrate() {
        _ = makeRunningTimer()

        XCTAssertEqual(haptics.events, [])
    }

    func test_foreground_vibratesOnEveryPhaseChange() {
        let model = makeRunningTimer()

        advance(10, model)
        XCTAssertTrue(model.isBreak)
        XCTAssertEqual(haptics.startCount, 1, "focus → break")

        advance(5, model)
        XCTAssertFalse(model.isBreak)
        XCTAssertEqual(haptics.startCount, 2, "break → focus vibrates even though it plays no sound")

        advance(10, model)
        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(haptics.startCount, 3, "routine complete")
    }

    func test_foreground_refreshWithinSamePhase_doesNotVibrateAgain() {
        let model = makeRunningTimer()

        advance(10, model)
        advance(1, model)
        model.refresh()

        XCTAssertEqual(haptics.startCount, 1)
    }

    func test_foreground_catchingUpSeveralMissedPhases_vibratesOnce() {
        let model = makeRunningTimer()

        // Skips past focus #1 and the break in one refresh, landing 1s into focus #2.
        advance(16, model)

        XCTAssertFalse(model.isBreak)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 2)
        XCTAssertEqual(haptics.startCount, 1)
    }

    func test_background_neverVibrates() {
        isActive = false
        let model = makeRunningTimer()

        advance(10, model)
        advance(5, model)
        advance(10, model)

        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(haptics.startCount, 0)
    }

    // MARK: - When haptics stop

    func test_pause_stopsHaptics() {
        let model = makeRunningTimer()
        advance(10, model)

        model.handlePlayPauseButtonTap()

        XCTAssertEqual(model.timerStatus, .paused)
        XCTAssertEqual(haptics.events, ["start", "stop"])
    }

    func test_stop_stopsHaptics() {
        let model = makeRunningTimer()
        advance(10, model)

        model.stopTimer()

        XCTAssertEqual(haptics.events.last, "stop")
    }

    func test_repeatAfterFinishing_stopsHapticsBeforeRestarting() {
        let model = makeRunningTimer(rest: 0, sessions: 1)
        advance(10, model)
        XCTAssertEqual(model.timerStatus, .finished)

        model.handlePlayPauseButtonTap()

        XCTAssertEqual(model.timerStatus, .playing)
        XCTAssertEqual(haptics.events, ["start", "stop"])
    }

    // MARK: - Failures

    func test_hapticsFailure_isRecordedWithoutBreakingTransitions() {
        haptics.startError = TestError.hapticsUnavailable
        let model = makeRunningTimer()

        advance(10, model)
        advance(5, model)
        advance(10, model)

        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(haptics.startCount, 3)
        XCTAssertNotNil(model.testHooks.hapticsError)
    }

    // MARK: - Real manager

    func test_realManager_startAndStopDoNotThrow() {
        // On the simulator supportsHaptics is false, so this checks the guard path;
        // on a device it plays one short pulse.
        let manager = HapticsManager()

        XCTAssertNoThrow(try manager.start())
        manager.stop()
        manager.stop()
    }
}
