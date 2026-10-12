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
    var onStart: (() -> Void)?
    var onEnd: (() -> Void)?
    var startError: Error?
    private(set) var lastState: TimerAttributes.ContentState?

    var onUpdate: ((TimerStatus) -> Void)?

    private(set) var didStartLiveActivity = false
    private(set) var didUpdateLiveActivity = false
    private(set) var didEndLiveActivity = false

    func startLiveActivity(name: String,
                           currentTimerValue: TimeInterval,
                           endTime: Date,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus,
                           phaseDuration: TimeInterval,
                           accentCode: String?) throws {
        if let startError {
            throw startError
        }

        didStartLiveActivity = true
        didEndLiveActivity = false
        onStart?()
    }

    func updateLiveActivity(currentTimerValue: TimeInterval,
                            endTime: Date,
                            intervals: Int,
                            interval: Int,
                            timerType: CatodoroShared.TimerType,
                            timerStatus: CatodoroShared.TimerStatus,
                            soundName: String?,
                            phaseDuration: TimeInterval,
                            accentCode: String?) async {
        lastState = .init(currentTimerValue: currentTimerValue, endTime: endTime,
                          intervals: intervals, interval: interval,
                          timerType: timerType, timerStatus: timerStatus,
                          phaseDuration: phaseDuration, accentCode: accentCode)
        didUpdateLiveActivity = true
        onUpdate?(timerStatus)
    }

    func endLiveActivity() {
        didEndLiveActivity = true
        onEnd?()
    }

    func hasLiveActivity() -> Bool {
        return didStartLiveActivity && !didEndLiveActivity
    }
}
