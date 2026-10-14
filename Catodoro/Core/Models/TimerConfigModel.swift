//
//  TimerConfigModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Foundation

struct TimerConfigModel {
    let id: UUID
    var mainTimer: TimerModel
    var interval: TimerModel
    var intervals: Int

    static var standard: TimerConfigModel {
        .init(mainTimer: .init(hours: 0, minutes: 25, seconds: 0),
              interval: .init(hours: 0, minutes: 5, seconds: 0),
              intervals: 4)
    }

    var isValid: Bool {
        Self.isValidDuration(mainTimer, allowsZero: false)
            && Self.isValidDuration(interval, allowsZero: true)
            && (1...20).contains(intervals)
    }

    var focusSubtotal: TimeInterval {
        mainTimer.duration * Double(max(0, intervals))
    }

    var breakSubtotal: TimeInterval {
        interval.duration * Double(max(0, max(0, intervals) - 1))
    }

    var totalDuration: TimeInterval {
        focusSubtotal + breakSubtotal
    }

    static func isValidDuration(_ timer: TimerModel, allowsZero: Bool) -> Bool {
        (0...23).contains(timer.hours)
            && (0...59).contains(timer.minutes)
            && (0...59).contains(timer.seconds)
            && (allowsZero || timer.duration > 0)
    }

    static func durationSummary(_ duration: TimeInterval) -> String {
        guard duration.isFinite, duration >= 0, duration < Double(Int.max) else {
            return "Unavailable"
        }

        let seconds = Int(duration)
        let components = [(seconds / 3600, "hr"),
                          (seconds % 3600 / 60, "min"),
                          (seconds % 60, "sec")]
        let text = components.filter { $0.0 > 0 }
            .map { "\($0.0) \($0.1)" }
            .joined(separator: " ")
        return text.isEmpty ? "0 min" : text
    }

    init(id: UUID = .init(),
          mainTimer: TimerModel = .init(hours: 0, minutes: 0, seconds: 0),
          interval: TimerModel = .init(hours: 0, minutes: 0, seconds: 0),
          intervals: Int = 1) {
        self.id = id
        self.mainTimer = mainTimer
        self.interval = interval
        self.intervals = intervals
    }
}
