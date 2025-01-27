//
//  MockLiveActivityManager.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 1/24/25.
//

import CatodoroShared
import Foundation
@testable import Catodoro

final class MockLiveActivityManager: LiveActivityManaging {
    private(set) var didStartLiveActivity = false
    private(set) var didUpdateLiveActivity = false
    private(set) var didEndLiveActivity = false

    func startLiveActivity(name: String,
                           currentTimerValue: TimeInterval,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus) throws {
        didStartLiveActivity = true
    }

    func updateLiveActivity(currentTimerValue: TimeInterval,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus) async {
        didUpdateLiveActivity = true
    }

    func endLiveActivity() {
        didEndLiveActivity = true
    }

    func hasLiveActivity() -> Bool {
        return didStartLiveActivity && !didEndLiveActivity
    }
}
