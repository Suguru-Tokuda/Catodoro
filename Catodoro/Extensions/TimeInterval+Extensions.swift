//
//  TimeInterval+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/2/24.
//

import Foundation

extension TimeInterval {
    func getTimerLabelValue() -> String {
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

            let hoursString = hours.getTimeStr()
            let minuteString = minutes.getTimeStr()
            let secondString = timerValue.getTimeStr()

            return "\(hoursString):\(minuteString):\(secondString)"
        }

        return "00:00:00"
    }
}
