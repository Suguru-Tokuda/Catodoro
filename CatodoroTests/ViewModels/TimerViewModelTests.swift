//
//  TimerViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/23/24.
//

import CatodoroShared
import XCTest
@testable import Catodoro

final class TimerViewModelTests: TimerViewModelTestCase {
    private enum TestError: Error { case failed }

    // MARK: - Setup

    func test_init_expectIdleStateAndPreferredSoundLoaded() async {
        preferences.setSound(.kitty)
        let model = makeViewModel()
        await flushAudioQueue()

        let state = model.presentationSubject.value
        XCTAssertEqual(state.status, .paused)
        XCTAssertEqual(state.sessionCount, 0)
        XCTAssertEqual(state.remainingDuration, 0)
        XCTAssertEqual(model.timerActionSubject.value, .stop)
        XCTAssertTrue(actions.isEmpty)
        XCTAssertEqual(audio.commands, ["setup"])
        XCTAssertEqual(audio.playedFileName, SoundOptions.kitty.fileName)
        XCTAssertEqual(audio.playedFileExtension, "mp3")
    }

    func test_configure_expectCycleStartedAndFirstFocusShown() async {
        let model = makeViewModel()
        let first = firstSession()
        countdown.startID = cycleID
        countdown.session = first

        model.configure(config: config)

        await waitUntil { model.testHooks.session == first }
        XCTAssertEqual(countdown.startedSteps, [config.cycleSteps])
        XCTAssertEqual(actions, [.start])
        XCTAssertEqual(model.presentationSubject.value, TimerPresentationState(
            isBreak: false, status: .playing, sessionIndex: 1, sessionCount: 2,
            remainingDuration: 10, phaseDuration: 10))
        await flushAudioQueue()
        XCTAssertEqual(audio.playCount, 0, "the first focus starts silently")
        XCTAssertEqual(haptics.startCount, 0)
    }

    func test_configure_whenStartFails_expectErrorAndScreenExits() async {
        countdown.startError = TestError.failed
        let model = makeViewModel()

        model.configure(config: config)

        await waitUntil { self.actions == [.stop] }
        XCTAssertNotNil(model.testHooks.countdownError)
        XCTAssertNil(model.testHooks.session)
    }

    // MARK: - Which sessions are shown

    func test_sessionBeforeStart_expectIgnored() async {
        let model = makeViewModel()

        countdown.send(firstSession())
        await settle()

        XCTAssertNil(model.testHooks.session)
        XCTAssertTrue(actions.isEmpty)
    }

    func test_sessionFromAnotherCycle_expectIgnored() async {
        let model = makeViewModel()
        let first = await start(model)

        countdown.send(.test(steps: steps, index: 1, state: .running(endDate: instant + 5)))
        await settle()

        XCTAssertEqual(model.testHooks.session, first)
        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - Presentation

    func test_runningRemaining_expectClampedBetweenZeroAndPhaseDuration() async {
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.with(state: .running(endDate: instant + 6.2)), to: model)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 6.2, accuracy: 0.001)
        XCTAssertEqual(model.presentationSubject.value.countdown, "00:07", "rounds remaining seconds up")

        await deliver(first.with(state: .running(endDate: instant + 100)), to: model)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 10)

        await deliver(first.with(state: .running(endDate: instant - 3)), to: model)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 0)
    }

    func test_break_expectBreakPresentation() async {
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)

        XCTAssertEqual(model.presentationSubject.value, TimerPresentationState(
            isBreak: true, status: .playing, sessionIndex: 1, sessionCount: 2,
            remainingDuration: 5, phaseDuration: 5))
        XCTAssertTrue(model.isBreak)
        XCTAssertEqual(actions, [.start])
    }

    func test_alertingBeforeLastStep_expectStillPlayingAtZero() async {
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.with(state: .alerting), to: model)

        XCTAssertEqual(model.timerStatus, .playing)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 0)
        XCTAssertFalse(actions.contains(.finish))
    }

    func test_lastStepAlerting_expectFinished() async {
        let model = makeViewModel()
        let first = await start(model)
        let last = first.moved(to: 2, state: .running(endDate: instant + 10))
        await deliver(last, to: model)

        await deliver(last.with(state: .alerting), to: model)

        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 2)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 0)
        XCTAssertEqual(actions, [.start, .finish])
    }

    func test_pauseAndResume_expectStatusRemainingAndActions() async {
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.with(state: .paused(remaining: 4)), to: model)
        XCTAssertEqual(model.timerStatus, .paused)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 4)

        instant += 30   // paused time doesn't count
        await deliver(first.with(state: .running(endDate: instant + 4)), to: model)
        XCTAssertEqual(model.timerStatus, .playing)
        XCTAssertEqual(model.presentationSubject.value.remainingDuration, 4)

        XCTAssertEqual(actions, [.pause, .resume])
    }

    func test_cycleEnded_expectScreenExitsAndSoundStops() async {
        let model = makeViewModel()
        await start(model)

        await deliverEnd(to: model)

        XCTAssertEqual(actions, [.stop])
        XCTAssertEqual(audio.commands, ["stop"])
        XCTAssertEqual(haptics.events, ["stop"])
    }

    // MARK: - Sound

    func test_foreground_expectSoundWhenBreakStartsAndOnCompletionOnly() async {
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)
        XCTAssertEqual(audio.playCount, 1, "break begins")

        let last = first.moved(to: 2, state: .running(endDate: instant + 10))
        await deliver(last, to: model)
        XCTAssertEqual(audio.playCount, 1, "focus begins silently")

        await deliver(last.with(state: .alerting), to: model)
        XCTAssertEqual(audio.playCount, 2, "routine complete")
        XCTAssertEqual(audio.lastNumberOfLoops, 0)
    }

    func test_background_expectNoInAppSound() async {
        let model = makeViewModel()
        let first = await start(model)
        setAppActive(false)
        defer { setAppActive(true) }

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)
        let last = first.moved(to: 2, state: .running(endDate: instant + 10))
        await deliver(last, to: model)
        await deliver(last.with(state: .alerting), to: model)

        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(audio.playCount, 0, "AlarmKit or the notification alerts in the background")
    }

    func test_playbackFailure_expectRecordedWithoutBreakingTransition() async {
        audio.playbackError = TestError.failed
        let model = makeViewModel()
        let first = await start(model)

        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)

        await waitUntil { model.audioError != nil }
        XCTAssertTrue(model.isBreak)
    }

    // MARK: - Buttons

    func test_playPause_whilePlayingOrPaused_expectToggleForShownAlarm() async {
        let model = makeViewModel()
        let first = await start(model)

        model.handlePlayPauseButtonTap()
        await waitUntil { self.countdown.calls.count == 1 }

        let paused = first.with(state: .paused(remaining: 4))
        await deliver(paused, to: model)
        model.handlePlayPauseButtonTap()
        await waitUntil { self.countdown.calls.count == 2 }

        XCTAssertEqual(countdown.calls, [.togglePauseResume(first.alarmID.uuidString),
                                         .togglePauseResume(first.alarmID.uuidString)])
    }

    func test_playPause_whenFinished_expectRestart() async {
        let model = makeViewModel()
        let first = await start(model)
        let finished = first.moved(to: 2, state: .alerting)
        await deliver(finished, to: model)

        model.handlePlayPauseButtonTap()

        await waitUntil { !self.countdown.calls.isEmpty }
        XCTAssertEqual(countdown.calls, [.restartCycle(finished.alarmID.uuidString)])
    }

    func test_skipBreak_duringFocusOrAfterFinishing_expectIgnored() async {
        let model = makeViewModel()
        let first = await start(model)

        model.skipBreak()
        await deliver(first.moved(to: 2, state: .alerting), to: model)
        model.skipBreak()
        await settle()

        XCTAssertTrue(countdown.calls.isEmpty)
    }

    func test_skipBreak_duringRunningOrPausedBreak_expectSkipForThatBreak() async {
        let model = makeViewModel()
        let first = await start(model)
        let rest = first.moved(to: 1, state: .running(endDate: instant + 5))
        await deliver(rest, to: model)

        model.skipBreak()
        await waitUntil { self.countdown.calls.count == 1 }
        await deliver(rest.with(state: .paused(remaining: 2)), to: model)
        model.skipBreak()
        await waitUntil { self.countdown.calls.count == 2 }

        XCTAssertEqual(countdown.calls, [.skipBreak(rest.alarmID.uuidString),
                                         .skipBreak(rest.alarmID.uuidString)])
    }

    func test_tapAfterPhaseChange_expectNewAlarmIDSent() async {
        let model = makeViewModel()
        let first = await start(model)
        let rest = first.moved(to: 1, state: .running(endDate: instant + 5))
        await deliver(rest, to: model)

        model.handlePlayPauseButtonTap()

        await waitUntil { !self.countdown.calls.isEmpty }
        XCTAssertNotEqual(rest.alarmID, first.alarmID)
        XCTAssertEqual(countdown.calls, [.togglePauseResume(rest.alarmID.uuidString)])
    }

    func test_stop_withoutCycle_expectScreenExitsWithoutEngineCall() async {
        let model = makeViewModel()

        model.stopTimer()
        await settle()

        XCTAssertEqual(actions, [.stop])
        XCTAssertTrue(countdown.calls.isEmpty)
    }

    func test_stop_duringCycle_expectCurrentCycleEnded() async {
        let model = makeViewModel()
        await start(model)

        model.stopTimer()

        await waitUntil { !self.countdown.calls.isEmpty }
        XCTAssertEqual(countdown.calls, [.endCycle("")], "an empty ID means the current session")
        XCTAssertTrue(actions.isEmpty, "the screen exits when the engine reports the end")
    }

    func test_actionFailure_expectErrorRecorded() async {
        countdown.actionError = TestError.failed
        let model = makeViewModel()
        await start(model)

        model.handlePlayPauseButtonTap()

        await waitUntil { model.testHooks.countdownError != nil }
    }

    func test_focusAfterBreak_expectBreakCueStopped() async {
        let model = makeViewModel()
        let first = await start(model)
        await deliver(first.moved(to: 1, state: .running(endDate: instant + 5)), to: model)
        XCTAssertEqual(audio.commands.last, "play", "break cue started")

        await deliver(first.moved(to: 2, state: .running(endDate: instant + 10)), to: model)

        XCTAssertEqual(audio.commands.last, "stop", "break cue doesn't carry into focus")
        XCTAssertEqual(audio.playCount, 1, "focus starts silently")
    }
}

/// Formatting of the snapshot the timer screen renders.
final class TimerPresentationStateTests: XCTestCase {
    private func state(isBreak: Bool = false, status: TimerStatus = .playing,
                       index: Int = 1, count: Int = 4,
                       remaining: TimeInterval, phase: TimeInterval = 10) -> TimerPresentationState {
        .init(isBreak: isBreak, status: status, sessionIndex: index, sessionCount: count,
              remainingDuration: remaining, phaseDuration: phase)
    }

    func test_countdown_expectHoursOnlyWhenNeededAndSecondsRoundedUp() {
        XCTAssertEqual(state(remaining: 3661).countdown, "1:01:01")
        XCTAssertEqual(state(remaining: 3598.1).countdown, "59:59")
        XCTAssertEqual(state(remaining: 0.2).countdown, "00:01")
        XCTAssertEqual(state(remaining: 0).countdown, "00:00")
        XCTAssertEqual(state(remaining: -5).countdown, "00:00")
    }

    func test_progress_expectFractionElapsedClampedToZeroAndOne() {
        XCTAssertEqual(state(remaining: 2.5, phase: 10).progress, 0.75, accuracy: 0.0001)
        XCTAssertEqual(state(remaining: 20, phase: 10).progress, 0)
        XCTAssertEqual(state(remaining: -1, phase: 10).progress, 1)
        XCTAssertEqual(state(remaining: 5, phase: 0).progress, 0)
    }

    func test_phaseTitle_expectFocusBreakOrComplete() {
        XCTAssertEqual(state(remaining: 1).phaseTitle, AppStrings.Timer.focusSession)
        XCTAssertEqual(state(isBreak: true, remaining: 1).phaseTitle, AppStrings.Common.catnapBreak)
        XCTAssertEqual(state(status: .finished, remaining: 0).phaseTitle, AppStrings.Common.routineComplete)
    }

    func test_sessionSummary_expectBreaksCountedOutOfOneFewer() {
        XCTAssertEqual(state(index: 2, count: 4, remaining: 1).sessionSummary,
                       AppStrings.Timer.sessionProgress(2, 4))
        XCTAssertEqual(state(isBreak: true, index: 2, count: 4, remaining: 1).sessionSummary,
                       AppStrings.Timer.sessionProgress(2, 3))
        XCTAssertEqual(state(status: .finished, index: 4, count: 4, remaining: 0).sessionSummary,
                       AppStrings.Timer.sessionsCompleted(4))
    }
}

/// Showing a cycle that survived a relaunch.
final class TimerViewModelAttachTests: TimerViewModelTestCase {
    func test_attach_expectSessionShownWithoutStartingAnything() async {
        let model = makeViewModel()
        let restored = firstSession().moved(to: 1, state: .paused(remaining: 3))
        countdown.session = restored

        model.attach(to: restored)

        XCTAssertEqual(model.testHooks.session, restored)
        XCTAssertEqual(model.presentationSubject.value, TimerPresentationState(
            isBreak: true, status: .paused, sessionIndex: 1, sessionCount: 2,
            remainingDuration: 3, phaseDuration: 5))
        XCTAssertTrue(countdown.startedSteps.isEmpty, "attaching must not start or replace a cycle")
        await settle()
        await flushAudioQueue()
        XCTAssertEqual(audio.playCount, 0, "no cue for a cycle that was already running")
        XCTAssertEqual(haptics.startCount, 0)
    }

    func test_attach_expectLaterUpdatesApplied() async {
        let model = makeViewModel()
        let restored = firstSession()
        countdown.session = restored
        model.attach(to: restored)

        await deliver(restored.moved(to: 1, state: .running(endDate: instant + 5)), to: model)

        XCTAssertTrue(model.isBreak)
    }

    func test_attach_expectNewerSessionPickedUp() async {
        let model = makeViewModel()
        let stale = firstSession()
        let newer = stale.with(state: .paused(remaining: 7))
        countdown.session = newer   // changed after the caller read `stale`

        model.attach(to: stale)

        await waitUntil { model.testHooks.session == newer }
        XCTAssertEqual(model.timerStatus, .paused)
    }

    func test_attach_whenCycleEndedMeanwhile_expectScreenExits() async {
        let model = makeViewModel()
        let stale = firstSession()
        countdown.session = nil

        model.attach(to: stale)

        await waitUntil { self.actions.last == .stop }
        XCTAssertNil(model.testHooks.session)
    }

    func test_attach_finishedCycle_expectFinishedScreenWithoutCue() async {
        let model = makeViewModel()
        let finished = firstSession().moved(to: 2, state: .alerting)
        countdown.session = finished

        model.attach(to: finished)

        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertFalse(actions.contains(.finish), "the routine finished before the relaunch")
        await flushAudioQueue()
        XCTAssertEqual(audio.playCount, 0)
    }

    func test_attach_expectButtonsActOnRestoredAlarm() async {
        let model = makeViewModel()
        let restored = firstSession()
        countdown.session = restored
        model.attach(to: restored)

        model.handlePlayPauseButtonTap()

        await waitUntil { !self.countdown.calls.isEmpty }
        XCTAssertEqual(countdown.calls, [.togglePauseResume(restored.alarmID.uuidString)])
    }
}
