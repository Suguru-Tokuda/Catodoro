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
        public let phaseDuration: TimeInterval?
        public let accentCode: String?
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
                    timerStatus: TimerStatus,
                    phaseDuration: TimeInterval? = nil,
                    accentCode: String? = nil) {
            self.phaseDuration = phaseDuration
            self.accentCode = accentCode
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

public extension TimerAttributes.ContentState {
    var canSkipBreak: Bool {
        timerType == .interval && timerStatus != .finished && interval < intervals
    }

    var phaseTitle: String {
        timerStatus == .finished ? "Routine complete" : (timerStatus == .paused ? "Paused" : (timerType == .interval ? "Catnap break" : "Focus time"))
    }

    var sessionSummary: String {
        if timerStatus == .finished {
            return "\(intervals) sessions completed"
        }

        return timerType == .interval ? "Next: session \(min(interval + 1, intervals)) of \(intervals)"
            : "Session \(interval) of \(intervals)"
    }

    var artworkName: String {
        timerStatus == .finished ? "CatPlayful" : (timerType == .interval ? "CatBreak" : "CatFocus")
    }

    var countdown: String {
        guard currentTimerValue.isFinite else { return "--:--" }

        let seconds = Int(ceil(max(0, min(currentTimerValue, 86400))))
        return seconds >= 3600
            ? String(format: "%d:%02d:%02d", seconds / 3600, seconds % 3600 / 60, seconds % 60)
            : String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
