//
//  TimerAttributes.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 1/14/25.
//

import ActivityKit
import Foundation

public enum TimerStatus: String, Codable {
    case paused
    case playing
    case finished
}

public enum TimerType: String, Codable {
    case main = "Main"
    case interval = "Interval"
}

public struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let currentTimerValue: TimeInterval
        public let endTime: Date
        public let intervals: Int
        public let interval: Int // Indicates the current interval position
        public let timerType: TimerType
        public let timerStatus: TimerStatus

        public init(currentTimerValue: TimeInterval,
                    endTime: Date,
                    intervals: Int,
                    interval: Int,
                    timerType: TimerType,
                    timerStatus: TimerStatus) {
            self.currentTimerValue = currentTimerValue
            self.endTime = endTime
            self.intervals = intervals
            self.interval = interval
            self.timerType = timerType
            self.timerStatus = timerStatus
        }
    }

    public var name: String

    public init(name: String) {
        self.name = name
    }
}

public extension TimerAttributes {
    enum TimerAction: Codable, Hashable {
        case play
        case stop
    }
}
