//
//  TimerViewTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 10/10/26.
//

import CatodoroShared
import XCTest
@testable import Catodoro

final class TimerViewTests: XCTestCase {
    private func state(isBreak: Bool = false, status: TimerStatus = .playing) -> TimerPresentationState {
        .init(isBreak: isBreak, status: status, sessionIndex: 2, sessionCount: 4,
              remainingDuration: status == .finished ? 0 : 150, phaseDuration: 300)
    }

    func test_renderSynchronizesCountdownArtworkRingAndActions() {
        let view = TimerView(frame: .zero)
        view.render(state())
        let hooks = view.testHooks
        XCTAssertEqual(hooks.timerLabel.text, "02:30")
        XCTAssertEqual(hooks.timerCircleView.testHooks.shapeLayer.strokeEnd, 0.5)
        XCTAssertEqual(hooks.primaryButton.configuration?.title, "Pause")
        XCTAssertEqual(hooks.secondaryButton.configuration?.title, "End session")
        XCTAssertEqual(hooks.companion.pose, .focus)

        view.render(state(isBreak: true))
        XCTAssertEqual(hooks.companion.pose, .timerBreak)
        XCTAssertEqual(hooks.timerNameLabel.text, "CATNAP BREAK")
        view.render(state(status: .paused))
        XCTAssertEqual(hooks.statusLabel.text, "Paused")
        XCTAssertEqual(hooks.primaryButton.configuration?.title, "Resume")
    }

    func test_completionOffersRepeatAndExitAndRoutesCorrectActions() {
        let view = TimerView(frame: .zero)
        var primaryTaps = 0
        var endTaps = 0
        var backTaps = 0
        view.onPlayPauseButtonTap = { primaryTaps += 1 }
        view.onStopButtonTap = { endTaps += 1 }
        view.onDismissButtonTap = { backTaps += 1 }
        view.render(state())
        view.testHooks.secondaryButton.sendActions(for: .touchUpInside)
        view.render(state(status: .finished))
        XCTAssertEqual(view.testHooks.primaryButton.configuration?.title, "Focus again")
        XCTAssertEqual(view.testHooks.secondaryButton.configuration?.title, "Back to routine")
        XCTAssertEqual(view.testHooks.companion.pose, .playful)
        view.testHooks.primaryButton.sendActions(for: .touchUpInside)
        view.testHooks.secondaryButton.sendActions(for: .touchUpInside)
        XCTAssertEqual(primaryTaps, 1)
        XCTAssertEqual(endTaps, 1)
        XCTAssertEqual(backTaps, 1)
    }

    func test_artworkClipsInsideResponsiveRing() {
        let view = TimerView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.layoutIfNeeded()
        let hooks = view.testHooks
        XCTAssertEqual(hooks.artworkContainer.frame, hooks.timerCircleView.frame)
        XCTAssertLessThanOrEqual(hooks.timerCircleView.bounds.width, 280)
        let path = hooks.artworkMask.path!
        XCTAssertTrue(path.contains(CGPoint(x: hooks.artworkContainer.bounds.midX,
                                           y: hooks.artworkContainer.bounds.midY)))
        XCTAssertFalse(path.contains(.zero))
        XCTAssertLessThan(path.boundingBox.maxY, hooks.artworkContainer.bounds.maxY)
    }
}
