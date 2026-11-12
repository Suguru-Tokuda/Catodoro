//
//  TimerViewModelHapticsTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/5/26.
//

import XCTest
@testable import Catodoro

final class TimerViewModelHapticsTests: TimerViewModelTestCase {
    private enum TestError: Error { case hapticsUnavailable }

    // MARK: - When haptics play

    func test_startingCycle_doesNotVibrate() async {
        let model = makeViewModel()
        countdown.startID = cycleID
        countdown.session = firstSession()

        model.configure(config: config)

        await waitUntil { model.testHooks.session != nil }
        XCTAssertEqual(haptics.startCount, 0)
    }

    func test_foreground_vibratesOnEveryPhaseChange() async {
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)
        XCTAssertEqual(haptics.startCount, 1, "focus → break")

        let last = first.moved(to: 2, state: .running(endDate: instant + 10))
        await deliver(last, to: model)
        XCTAssertEqual(haptics.startCount, 2, "break → focus vibrates even though it plays no sound")

        await deliver(last.with(state: .alerting), to: model)
        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(haptics.startCount, 3, "routine complete")
    }

    func test_sameStepUpdate_doesNotVibrateAgain() async {
        let model = makeViewModel()
        let first = await start(model)
        let rest = first.moved(to: 1, state: .running(endDate: instant + 5))
        await deliver(rest, to: model)

        await deliver(rest.with(state: .running(endDate: instant + 4)), to: model)

        XCTAssertEqual(haptics.startCount, 1)
    }

    func test_finishedUpdateRepeated_vibratesOnce() async {
        let model = makeViewModel()
        let first = await start(model)
        let finished = first.moved(to: 2, state: .alerting)
        await deliver(finished.with(state: .running(endDate: instant + 10)), to: model)
        haptics.reset()

        await deliver(finished, to: model)
        countdown.send(finished)
        await settle()

        XCTAssertEqual(haptics.startCount, 1)
    }

    func test_background_neverVibratesAndResumesInForeground() async {
        let model = makeViewModel()
        let first = await start(model)
        setAppActive(false)

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)
        XCTAssertEqual(haptics.startCount, 0)

        setAppActive(true)
        await deliver(first.moved(to: 2, state: .running(endDate: instant + 10)), to: model)
        XCTAssertEqual(haptics.startCount, 1)
    }

    // MARK: - When haptics stop

    func test_pause_stopsHaptics() async {
        let model = makeViewModel()
        let first = await start(model)
        let rest = first.moved(to: 1, state: .running(endDate: instant + 5))
        await deliver(rest, to: model)

        await deliver(rest.with(state: .paused(remaining: 5)), to: model)

        XCTAssertEqual(model.timerStatus, .paused)
        XCTAssertEqual(haptics.events, ["start", "stop"])
    }

    func test_cycleEnded_stopsHaptics() async {
        let model = makeViewModel()
        let first = await start(model)
        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)

        await deliverEnd(to: model)

        XCTAssertEqual(haptics.events, ["start", "stop"])
    }

    // MARK: - Failures

    func test_hapticsFailure_isRecordedWithoutBreakingTransitions() async {
        haptics.startError = TestError.hapticsUnavailable
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)
        let last = first.moved(to: 2, state: .running(endDate: instant + 10))
        await deliver(last, to: model)
        await deliver(last.with(state: .alerting), to: model)

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
