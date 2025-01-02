//
//  TimerCircleViewTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

class TimerCircleViewTests: XCTestCase {

    var timerCircleView: TimerCircleView!

    override func setUp() {
        super.setUp()
        timerCircleView = TimerCircleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        timerCircleView = nil
        super.tearDown()
    }

    func test_setupCircleLayers_shouldConfigureLayersCorrectly() {
        // Arrange & Act
        timerCircleView.setupSubviews()

        // Assert
        XCTAssertEqual(timerCircleView.layer.sublayers?.count, 2, "There should be two sublayers added.")
        XCTAssertNotNil(timerCircleView.layer.sublayers?.contains(where: { $0 is CAShapeLayer }), "CAShapeLayers should be added.")
    }

    func test_startTimer_shouldAddAnimationToShapeLayer() {
        // Arrange
        let duration: TimeInterval = 5

        // Act
        timerCircleView.startTimer(duration: duration)

        // Assert
        let animation = timerCircleView.testHooks.shapeLayer.animation(forKey: timerCircleView.timerAnimationKey)
        XCTAssertNotNil(animation, "Animation should be added to the shape layer.")
        XCTAssertEqual(animation?.duration, duration, "Animation duration should match the input.")
    }

    func test_pauseTimer_shouldStopAnimationAndStorePausedTime() {
        // Arrange
        timerCircleView.startTimer(duration: 5)

        // Act
        timerCircleView.pauseTimer()
        let pausedTime = timerCircleView.testHooks.shapeLayer.timeOffset

        // Assert
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.speed, 0.0, "Shape layer speed should be 0 after pausing.")
        XCTAssertGreaterThan(pausedTime, 0, "Paused time should be greater than 0.")
    }

    func test_resumeTimer_shouldResumeAnimationFromPausedTime() {
        // Arrange
        timerCircleView.startTimer(duration: 5)
        timerCircleView.pauseTimer()
        let pausedTime = timerCircleView.testHooks.shapeLayer.timeOffset

        // Act
        timerCircleView.resumeTimer()

        // Assert
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.speed, 1.0, "Shape layer speed should be 1 after resuming.")
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.timeOffset, 0.0, "Time offset should reset to 0 after resuming.")
        XCTAssertNotEqual(timerCircleView.testHooks.shapeLayer.beginTime, 0.0, "Begin time should not be 0 after resuming.")
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.beginTime, CACurrentMediaTime() - pausedTime, accuracy: 0.01, "Begin time should reflect the resumed animation.")
    }

    func test_resetTimer_shouldRemoveAnimationAndResetStrokeEnd() {
        // Arrange
        timerCircleView.startTimer(duration: 5)

        // Act
        timerCircleView.resetTimer()

        // Assert
        XCTAssertNil(timerCircleView.testHooks.shapeLayer.animation(forKey: timerCircleView.timerAnimationKey), "Animation should be removed from the shape layer.")
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.strokeEnd, 0.0, "StrokeEnd should be reset to 0.")
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.speed, 0.0, "Shape layer speed should be reset to 0.")
    }

    func test_restartTimer_shouldResetAndStartTimer() {
        // Arrange
        let duration: TimeInterval = 5

        // Act
        timerCircleView.restartTimer(duration: duration)
        let animation = timerCircleView.testHooks.shapeLayer.animation(forKey: timerCircleView.timerAnimationKey)

        // Assert
        XCTAssertNotNil(animation, "Animation should be added to the shape layer after restarting.")
        XCTAssertEqual(animation?.duration, duration, "Animation duration should match the input after restarting.")
        XCTAssertEqual(timerCircleView.testHooks.shapeLayer.strokeEnd, 0.0, "StrokeEnd should be reset to 0 before starting the new animation.")
    }
}
