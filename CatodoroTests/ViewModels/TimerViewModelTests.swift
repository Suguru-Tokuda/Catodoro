// TimerViewModelTests.swift
// CatodoroTests
// Created by Suguru Tokuda on 12/23/24.

import XCTest
import Combine
import UIKit
@testable import Catodoro

final class TimerViewModelTests: XCTestCase {
    private var viewModel: TimerViewModel!
    private var audioManagerMock: MockAudioManager!
    private var preferencesMock: MockPreferences!
    private var liveActivityManagerMock: MockLiveActivityManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        audioManagerMock = MockAudioManager()
        preferencesMock = MockPreferences()
        liveActivityManagerMock = MockLiveActivityManager()
        viewModel = TimerViewModel(audioManager: audioManagerMock, preferences: preferencesMock, liveActivityManager: liveActivityManagerMock)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        audioManagerMock = nil
        preferencesMock = nil
        liveActivityManagerMock = nil
        cancellables = nil
        super.tearDown()
    }

    func test_init_expectInitialState() {
        XCTAssertEqual(viewModel.testHooks.timerStatus, .paused)
        XCTAssertEqual(viewModel.currentTimerValue, 0)
    }

    func test_configure_expectTimerIsConfiguredCorrectly() {
        let duration: TimeInterval = 1500 // 25 minutes
        let intervalTime: TimeInterval = 300 // 5 minutes
        let intervals = 4

        viewModel.configure(totalDuration: duration, intervalDuration: intervalTime, intervals: intervals)

        XCTAssertEqual(viewModel.duration, duration)
        XCTAssertEqual(viewModel.testHooks.totalDuration, duration)
        XCTAssertEqual(viewModel.testHooks.intervalDuration, intervalTime)
        XCTAssertEqual(viewModel.currentTimerValue, duration)
        XCTAssertEqual(viewModel.testHooks.timerType, .main)
        XCTAssertEqual(viewModel.testHooks.timerStatus, .paused)
    }

    func test_startTimer_expectTimerValueUpdates() {
        let expectation = self.expectation(description: "Timer updates current value")
        let expectedValue = "00:25:00"

        viewModel.timerSubject
            .first()
            .sink { value in
                expectation.fulfill()
                XCTAssertEqual(value, expectedValue)
            }
            .store(in: &cancellables)

        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()

        waitForExpectations(timeout: 2.0)
    }

    func test_pauseTimer_expectTimerIsPaused() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()
        viewModel.pauseTimer()

        XCTAssertEqual(viewModel.testHooks.timerStatus, .paused)
        XCTAssertNil(viewModel.testHooks.backgroundTimer)
    }

    func test_resumeTimer_expectTimerResumesPlaying() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()
        viewModel.pauseTimer()
        viewModel.resumeTimer()

        XCTAssertEqual(viewModel.testHooks.timerStatus, .playing)
        XCTAssertNotNil(viewModel.testHooks.backgroundTimer)
    }

    func test_stopTimer_expectTimerResets() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()
        viewModel.stopTimer()

        XCTAssertEqual(viewModel.testHooks.timerStatus, .paused)
        XCTAssertNil(viewModel.testHooks.backgroundTimer)
        XCTAssertEqual(viewModel.currentTimerValue, 1500)
        XCTAssertEqual(viewModel.testHooks.timerType, .main)
    }

    func test_startLiveActivity_expectLiveActivityIsStarted() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()

        XCTAssertTrue(liveActivityManagerMock.didStartLiveActivity)
    }

    func test_updateLiveActivity_expectLiveActivityIsUpdated() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()
        viewModel.pauseTimer()
        
        let expectation = self.expectation(description: "LiveActivityManager updates activity")
        
        Task {
            // Allow the async method in MockLiveActivityManager to execute
            if liveActivityManagerMock.didUpdateLiveActivity {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }

    func test_endLiveActivity_expectLiveActivityIsEnded() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.stopTimer()

        XCTAssertTrue(liveActivityManagerMock.didEndLiveActivity)
    }
}

@MainActor
final class TimerPresentationTests: XCTestCase {
    private var instant = Date(timeIntervalSince1970: 1000)

    private func makeTimer(focus: TimeInterval = 10, rest: TimeInterval = 5, count: Int = 3) -> TimerViewModel {
        let model = TimerViewModel(audioManager: MockAudioManager(), preferences: nil,
                                   liveActivityManager: nil, now: { [unowned self] in self.instant },
                                   schedulesTicks: false)
        model.configure(totalDuration: focus, intervalDuration: rest, intervals: count)
        model.startTimer()

        return model
    }

    func test_allFocusSessionsAndOnlyInterveningBreaksRun() {
        let model = makeTimer()
        for (elapsed, isBreak, index) in [(10.0, true, 1), (15, false, 2), (25, true, 2), (30, false, 3)] {
            instant = Date(timeIntervalSince1970: 1000 + elapsed)
            model.refresh()
            XCTAssertEqual(model.presentationSubject.value.isBreak, isBreak)
            XCTAssertEqual(model.presentationSubject.value.sessionIndex, index)
            XCTAssertEqual(model.timerStatus, .playing)
        }

        instant = Date(timeIntervalSince1970: 1040)
        model.refresh()
        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertEqual(model.currentTimerValue, 0)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 3)
        model.handlePlayPauseButtonTap()
        XCTAssertEqual(model.timerStatus, .playing)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 1)
        XCTAssertFalse(model.isBreak)
        XCTAssertEqual(model.currentTimerValue, 10)
    }

    func test_zeroBreakNeverCreatesAnEmptyBreakAndIncludesLastSession() {
        let model = makeTimer(rest: 0)
        instant.addTimeInterval(20)
        model.refresh()
        XCTAssertFalse(model.isBreak)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 3)
        XCTAssertEqual(model.currentTimerValue, 10)
        instant.addTimeInterval(10)
        model.refresh()
        XCTAssertEqual(model.timerStatus, .finished)
    }

    func test_singleSessionFinishesWithoutBreak() {
        let model = makeTimer(count: 1)
        instant.addTimeInterval(10)
        model.refresh()
        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertFalse(model.isBreak)
    }

    func test_pauseFreezesTimeAndResumeUsesRemainingDuration() {
        let model = makeTimer()
        instant.addTimeInterval(3)
        model.pauseTimer()
        XCTAssertEqual(model.currentTimerValue, 7)
        XCTAssertEqual(model.presentationSubject.value.progress, 0.3, accuracy: 0.001)
        instant.addTimeInterval(100)
        model.refresh()
        XCTAssertEqual(model.currentTimerValue, 7)
        model.resumeTimer()
        instant.addTimeInterval(2)
        model.refresh()
        XCTAssertEqual(model.currentTimerValue, 5)
        model.stopTimer()
        XCTAssertEqual(model.timerStatus, .paused)
        XCTAssertEqual(model.currentTimerValue, 10)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 1)
    }

    func test_appReturnConsumesElapsedPhasesAndReconcilesProgress() {
        let model = makeTimer()
        instant.addTimeInterval(32)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(model.presentationSubject.value.sessionIndex, 3)
        XCTAssertEqual(model.currentTimerValue, 8)
        XCTAssertEqual(model.presentationSubject.value.progress, 0.2, accuracy: 0.001)
        instant.addTimeInterval(100)
        model.refresh()
        XCTAssertEqual(model.timerStatus, .finished)
    }

    func test_remoteControlsPauseResumeRepeatAndStop() {
        let model = makeTimer(count: 1)
        NotificationCenter.default.post(name: .playTimerActionTriggered, object: nil)
        XCTAssertEqual(model.timerStatus, .paused)
        NotificationCenter.default.post(name: .playTimerActionTriggered, object: nil)
        XCTAssertEqual(model.timerStatus, .playing)
        instant.addTimeInterval(10)
        model.refresh()
        NotificationCenter.default.post(name: .repeatTimerActionTriggered, object: nil)
        XCTAssertEqual(model.timerStatus, .playing)
        XCTAssertEqual(model.currentTimerValue, 10)
        NotificationCenter.default.post(name: .stopTimerActionTriggered, object: nil)
        XCTAssertEqual(model.timerActionSubject.value, .stop)
        XCTAssertEqual(model.timerStatus, .paused)
        instant.addTimeInterval(100)
        model.refresh()
        XCTAssertEqual(model.currentTimerValue, 10)
    }

    func test_foregroundPhaseChangesAndCompletionPlayCueWithoutLiveActivity() async {
        let audio = MockAudioManager()
        let model = TimerViewModel(audioManager: audio, preferences: nil, liveActivityManager: nil,
                                   now: { [unowned self] in self.instant }, schedulesTicks: false,
                                   applicationIsActive: { true })
        model.configure(totalDuration: 10, intervalDuration: 5, intervals: 2)
        model.startTimer()
        await model.testHooks.flushAudioOperations()
        XCTAssertEqual(audio.playCount, 0)
        instant.addTimeInterval(10)
        model.refresh()
        await model.testHooks.flushAudioOperations()
        XCTAssertEqual(audio.playCount, 1)
        instant.addTimeInterval(5)
        model.refresh()
        await model.testHooks.flushAudioOperations()
        XCTAssertEqual(audio.playCount, 2)
        instant.addTimeInterval(10)
        model.refresh()
        await model.testHooks.flushAudioOperations()
        XCTAssertEqual(audio.playCount, 3)
        XCTAssertFalse(audio.wasCalledOnMainThread)
        XCTAssertEqual(Array(audio.commands.prefix(2)), ["setup", "stop"])
        XCTAssertEqual(audio.lastNumberOfLoops, 0)
        model.refresh()
        await model.testHooks.flushAudioOperations()
        XCTAssertEqual(audio.playCount, 3)
        model.handlePlayPauseButtonTap()
        await model.testHooks.flushAudioOperations()
        XCTAssertTrue(audio.isStopped)
        XCTAssertEqual(audio.commands.last, "stop")
    }

    func test_playbackFailureIsRecordedWithoutBreakingCompletion() async {
        let audio = MockAudioManager()
        audio.playbackError = AudioError.playbackFailed
        let model = TimerViewModel(audioManager: audio, preferences: nil, liveActivityManager: nil,
                                   now: { [unowned self] in self.instant }, schedulesTicks: false,
                                   applicationIsActive: { true })
        model.configure(totalDuration: 10, intervalDuration: 0, intervals: 1)
        model.startTimer()
        instant.addTimeInterval(10)
        model.refresh()
        await model.testHooks.flushAudioOperations()
        XCTAssertEqual(model.timerStatus, .finished)
        XCTAssertNotNil(model.audioError)
    }

    func test_countdownKeepsHoursOnlyWhenNeededAndRoundsRemainingSecondsUp() {
        let model = makeTimer(focus: 3661)
        XCTAssertEqual(model.presentationSubject.value.countdown, "1:01:01")
        instant.addTimeInterval(62.1)
        model.refresh()
        XCTAssertEqual(model.presentationSubject.value.countdown, "59:59")
    }
}
