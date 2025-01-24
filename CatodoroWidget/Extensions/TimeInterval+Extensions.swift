//
//  TimeInterval+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/22/25.
//

import Foundation

extension TimeInterval {
    func getTimerLabelValue() -> String {
        if self >= 0 {
            let adjustedTime = max(0, self - 0.5)
            let totalSeconds = Int(ceil(adjustedTime))

            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60

            let hoursString = hours.getTimeStr()
            let minuteString = minutes.getTimeStr()
            let secondString = seconds.getTimeStr()

            return "\(hoursString):\(minuteString):\(secondString)"
        }

        return "00:00:00"
    }

    func toTimerModel() -> (Int, Int, Int)? {
        if self >= 0 {
            var timerValue: Int = Int(self)
            let hours = timerValue / 3600

            if hours > 0 {
                timerValue -= hours * 3600
            }

            let minutes = timerValue / 60

            if minutes > 0 {
                timerValue -= minutes * 60
            }

            return (hours, minutes, timerValue)
        }

        return nil
    }
}
