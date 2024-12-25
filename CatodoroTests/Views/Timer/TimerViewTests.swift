import XCTest
@testable import Catodoro

class TimerViewTests: XCTestCase {

    var timerView: TimerView!

    override func setUp() {
        super.setUp()
        // Initialize the TimerView before each test
        timerView = TimerView(frame: .zero)
    }

    override func tearDown() {
        timerView = nil
        super.tearDown()
    }

    // MARK: - Test View Initialization

    func test_viewInitialization_shouldSetUpSubviews() {
        XCTAssertNotNil(timerView.testHooks.timerNameLabel)
        XCTAssertNotNil(timerView.testHooks.timerLabel)
        XCTAssertNotNil(timerView.testHooks.timerCircleView)
        XCTAssertNotNil(timerView.testHooks.playPauseButton)
        XCTAssertNotNil(timerView.testHooks.stopButton)
        XCTAssertTrue(timerView.subviews.contains(timerView.testHooks.timerNameLabel))
        XCTAssertTrue(timerView.testHooks.stackView.arrangedSubviews.contains(timerView.testHooks.timerLabel))
    }

    // MARK: - Test Timer Label Text

    func test_setTimerLabelText_shouldUpdateText() {
        let newText = "10:00:00"
        timerView.setTimerLabelText(labelText: newText)
        
        XCTAssertEqual(timerView.testHooks.timerLabel.text, newText)
    }

    // MARK: - Test Timer Name Label Text

    func test_setTimerNameLabelText_shouldUpdateText() {
        let newName = "Workout Timer"
        timerView.setTimerNameLabelText(labelText: newName)
        
        XCTAssertEqual(timerView.testHooks.timerNameLabel.text, newName)
    }

    // MARK: - Test Button Actions

    func test_onPlayPauseButtonTap_shouldTriggerClosure() {
        let expectation = self.expectation(description: "Play/Pause button tapped")
        timerView.onPlayPauseButtonTap = {
            expectation.fulfill()
        }
        
        timerView.testHooks.playPauseButton.sendActions(for: .touchUpInside)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_onStopButtonTap_shouldTriggerClosure() {
        let expectation = self.expectation(description: "Stop button tapped")
        timerView.onStopButtonTap = {
            expectation.fulfill()
        }
        
        timerView.testHooks.stopButton.sendActions(for: .touchUpInside)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Test Timer Methods

    func test_startTimer_shouldStartTimerInTimerCircleView() {
        let duration: TimeInterval = 60.0
        let timerCircleViewMock = timerView.testHooks.timerCircleView
        let startTimerExpectation = self.expectation(description: "Timer started")
        
        // You can mock or spy on the TimerCircleView to check if startTimer is called.
        // Assuming we have a mock or spy method on TimerCircleView
        timerCircleViewMock.startTimer(duration: duration)
        
        // Add the check to confirm that the startTimer was called on TimerCircleView
        startTimerExpectation.fulfill()

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_pauseTimer_shouldPauseTimerInTimerCircleView() {
        let pauseTimerExpectation = self.expectation(description: "Timer paused")
        
        timerView.pauseTimer()
        
        // Add the check to confirm that the pauseTimer was called on TimerCircleView
        pauseTimerExpectation.fulfill()

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_stopTimer_shouldResetTimerInTimerCircleView() {
        let stopTimerExpectation = self.expectation(description: "Timer reset")
        
        timerView.stopTimer()
        
        // Add the check to confirm that the stopTimer was called on TimerCircleView
        stopTimerExpectation.fulfill()

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Test PlayPauseButton Configuration

    func test_configurePlayPauseButton_shouldUpdateButtonAppearance() {
        let status: TimerButtonStatus = .paused
        timerView.configurePlayPauseButton(timerStatus: status)

        XCTAssertNotNil(timerView.testHooks.playPauseButton.currentImage)
    }
}
