//
//  TimerViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/23/24.
//

import XCTest
import Combine
@testable import Catodoro

final class TimerViewModelTests: XCTestCase {
    private var viewModel: TimerViewModel!
    private var audioManagerMock: MockAudioManager!
    private var preferencesMock: MockPreferences!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        audioManagerMock = MockAudioManager()
        preferencesMock = MockPreferences()
        viewModel = TimerViewModel(audioManager: audioManagerMock, preferences: preferencesMock)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        audioManagerMock = nil
        preferencesMock = nil
        cancellables = nil
        super.tearDown()
    }

    func test_init_expectInitialState() {
        XCTAssertEqual(viewModel.timerStatus, .paused)
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
        XCTAssertEqual(viewModel.timerStatus, .paused)
    }

    func test_startTimer_expectTimerValueUpdates() {
        let expectation = self.expectation(description: "Timer updates current value")
        let expectedValue = "00:25:00"
        viewModel.timerSubject
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

        XCTAssertEqual(viewModel.timerStatus, .paused)
        XCTAssertNil(viewModel.testHooks.timer)
    }

    func test_resumeTimer_expectTimerResumesPlaying() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()
        viewModel.pauseTimer()
        viewModel.resumeTimer()

        XCTAssertEqual(viewModel.timerStatus, .playing)
        XCTAssertNotNil(viewModel.testHooks.timer)
    }

    func test_stopTimer_expectTimerResets() {
        viewModel.configure(totalDuration: 1500, intervalDuration: 300, intervals: 4)
        viewModel.startTimer()
        viewModel.stopTimer()

        XCTAssertEqual(viewModel.timerStatus, .paused)
        XCTAssertNil(viewModel.testHooks.timer)
        XCTAssertEqual(viewModel.currentTimerValue, 1500)
        XCTAssertEqual(viewModel.testHooks.timerType, .main)
    }

    func test_playFinishSound_expectAudioManagerPlaysFinishSound() {
        preferencesMock.sound = "finishSound"
        viewModel.playFinishSound()

        XCTAssertEqual(audioManagerMock.playedFileName, "cat_meow_regular")
        XCTAssertEqual(audioManagerMock.playedFileExtension, "mp3")
    }
}
